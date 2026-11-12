// download-js.js — baixa por HTTP e grava em disco DENTRO do WinRE 1809.
//
// Por que existe: download.vbs chega no servidor mas nao grava (ADODB.Stream
// ausente). ResponseText + FSO ASCII foi medido N3 para arquivo ASCII, mas o
// FSO ASCII (cp1252) perde 0x81..0x9F — um ESD assinado corrompe.
//
// Caminhos, nesta ordem; o log diz qual fechou:
//   1) WinHttp.ResponseBody -> MSXML2.DOMDocument (bin.hex) -> FSO Unicode empacotado
//      msxml3.dll e msxml6.dll EXISTEM no WinRE 1809 (INVENTARIO). Hipotese N0 ate o PE.
//   2) corpo base64 (URL termina em .b64 ou 3o arg = b64) + decoder JS + FSO Unicode
//      ResponseText so ve ASCII -> transporte sem perda; Unicode evita 0x81..0x9F na escrita.
//   3) ResponseText + FSO ASCII (N3, so seguro se o arquivo nao tiver 0x81..0x9F)
//
// Empacote Unicode: cada wchar = 2 bytes (lo | hi<<8). CreateTextFile unicode
// escreve BOM FF FE; o caminho P cria ASCII vazio e abre append unicode (hipotese
// de evitar o BOM — medir com teste-fso-binario.js). Sidecar <dest>.len = tamanho
// original em ASCII, para o host truncar padding de byte impar.
//
// Uso: cscript //nologo download-js.js <URL> <destino> [auto|ascii|unicode|b64]

// MEDIDO NO PE (run 2026-11-12, brianwoo-auto): WScript.Arguments.Count NAO existe
// em JScript (so em VBScript) — "Object doesn't support this property or method"
// na propria linha do Arguments. Em JScript e .length. Isto matou o downloader na
// 1a linha do run anterior; corrigido e provado no run seguinte.
var url = WScript.Arguments.length > 0 ? WScript.Arguments(0) : "";
var dest = WScript.Arguments.length > 1 ? WScript.Arguments(1) : "";
var modo = WScript.Arguments.length > 2 ? WScript.Arguments(2) : "auto";
modo = ("" + modo).toLowerCase();

if (!url || !dest) {
    WScript.Echo("uso: cscript //nologo download-js.js <URL> <destino> [auto|ascii|unicode|b64]");
    WScript.Quit(1);
}

function echo(s) { WScript.Echo(s); }

function stringToBytes(s) {
    var b = [];
    var i;
    for (i = 0; i < s.length; i++) b.push(s.charCodeAt(i) & 0xFF);
    return b;
}

function packBytes(bytes) {
    var s = "";
    var i, lo, hi, n;
    n = bytes.length;
    for (i = 0; i < n; i += 2) {
        lo = bytes[i];
        hi = (i + 1 < n) ? bytes[i + 1] : 0;
        s += String.fromCharCode(lo | (hi << 8));
    }
    return s;
}

function b64Decode(s) {
    var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    var i, a, b, c, d, n, out, buf;
    s = ("" + s).replace(/[\r\n\s]/g, "");
    while (s.length % 4) s += "=";
    out = [];
    for (i = 0; i < s.length; i += 4) {
        a = abc.indexOf(s.charAt(i));
        b = abc.indexOf(s.charAt(i + 1));
        c = abc.indexOf(s.charAt(i + 2));
        d = abc.indexOf(s.charAt(i + 3));
        n = ((a & 63) << 18) | ((b & 63) << 12) | (((c < 0 ? 0 : c) & 63) << 6) | ((d < 0 ? 0 : d) & 63);
        out.push((n >> 16) & 0xFF);
        if (c >= 0) out.push((n >> 8) & 0xFF);
        if (d >= 0) out.push(n & 0xFF);
    }
    return out;
}

function msxmlBodyToBytes(bin) {
    var ids = ["Msxml2.DOMDocument.6.0", "Msxml2.DOMDocument.3.0", "MSXML2.DOMDocument", "Microsoft.XMLDOM"];
    var i, xml, el, hex, j, b, ch;
    if (bin === null || typeof bin === "undefined") return null;
    for (i = 0; i < ids.length; i++) {
        try {
            xml = new ActiveXObject(ids[i]);
            el = xml.createElement("x");
            el.dataType = "bin.hex";
            el.nodeTypedValue = bin;
            hex = el.text;
            if (hex && hex.length) {
                hex = ("" + hex).replace(/[\r\n\s]/g, "");
                b = [];
                for (j = 0; j < hex.length; j += 2) {
                    ch = parseInt(hex.substr(j, 2), 16);
                    if (isNaN(ch)) return null;
                    b.push(ch);
                }
                echo("msxml " + ids[i] + " hex_bytes=" + b.length);
                return b;
            }
        } catch (e) {
            echo("msxml " + ids[i] + " falhou: " + e.description);
        }
    }
    return null;
}

function writeLen(fso, dest, n) {
    try {
        var t = fso.CreateTextFile(dest + ".len", true, false);
        t.Write("" + n);
        t.Close();
    } catch (e) {
        echo("aviso: nao gravou " + dest + ".len: " + e.description);
    }
}

function writeAscii(fso, dest, s) {
    var ts = fso.CreateTextFile(dest, true, false);
    ts.Write(s);
    ts.Close();
    echo("escrita ascii: " + dest + " chars=" + s.length);
    writeLen(fso, dest, s.length);
    return "ascii";
}

function writeUnicodePacked(fso, dest, bytes) {
    var packed = packBytes(bytes);
    var via = "unicode-bom";
    try {
        var t0 = fso.CreateTextFile(dest, true, false);
        t0.Close();
        var t1 = fso.OpenTextFile(dest, 8, false, -1);
        t1.Write(packed);
        t1.Close();
        via = "unicode-append";
    } catch (e) {
        echo("unicode-append falhou (" + e.description + "), caindo p/ CreateTextFile unicode");
        var t2 = fso.CreateTextFile(dest, true, true);
        t2.Write(packed);
        t2.Close();
        via = "unicode-bom";
    }
    echo("escrita " + via + ": " + dest + " bytes=" + bytes.length + " packed_chars=" + packed.length + " size=" + fso.GetFile(dest).Size);
    writeLen(fso, dest, bytes.length);
    return via;
}

function looksB64Url(u) {
    var x = ("" + u).toLowerCase();
    return x.length >= 4 && x.substring(x.length - 4) === ".b64";
}

var corpoStr = null;
var corpoBin = null;
var origem = "";
var httpStatus = 0;

try {
    var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
    http.Open("GET", url, false);
    http.SetTimeouts(30000, 30000, 600000, 600000);
    http.Send();
    httpStatus = http.Status;
    echo("winhttp status=" + httpStatus);
    if (httpStatus === 200 || httpStatus === 206) {
        try {
            var rt = http.ResponseText;
            if (rt !== null && typeof rt !== "undefined" && rt.length > 0) {
                echo("winhttp ResponseText: " + rt.length + " chars");
                corpoStr = rt;
                origem = "winhttp-text";
            }
        } catch (eR) {
            echo("winhttp ResponseText falhou: " + eR.description);
        }
        try {
            var rb = http.ResponseBody;
            if (rb !== null && typeof rb !== "undefined") {
                echo("winhttp ResponseBody: tipo=" + (typeof rb));
                corpoBin = rb;
                if (origem === "") origem = "winhttp-body";
            }
        } catch (eB) {
            echo("winhttp ResponseBody falhou: " + eB.description);
        }
    }
} catch (e) {
    echo("winhttp falhou: " + e.description);
}

if (corpoStr === null && corpoBin === null) {
    try {
        var x = new ActiveXObject("MSXML2.XMLHTTP");
        x.open("GET", url, false);
        x.send();
        echo("xmlhttp status=" + x.status);
        if (x.status === 200) {
            try { corpoStr = x.responseText; origem = "xmlhttp-text"; } catch (eT) {}
            try { corpoBin = x.responseBody; if (origem === "") origem = "xmlhttp-body"; } catch (eB2) {}
        }
    } catch (e2) {
        echo("xmlhttp falhou: " + e2.description);
    }
}

if (corpoStr === null && corpoBin === null) {
    echo("ERRO: nenhum cliente devolveu corpo");
    WScript.Quit(3);
}

var fso = new ActiveXObject("Scripting.FileSystemObject");
var via = "";
var querB64 = (modo === "b64") || (modo === "auto" && looksB64Url(url));
var querUnicode = (modo === "unicode") || (modo === "auto") || querB64;
var querAscii = (modo === "ascii") || (modo === "auto");

if (querB64 && corpoStr !== null) {
    try {
        var dec = b64Decode(corpoStr);
        echo("b64 decoded bytes=" + dec.length + " via " + origem);
        via = writeUnicodePacked(fso, dest, dec);
        echo("ok: " + dest + " (" + dec.length + " bytes, via b64+" + via + ", origem=" + origem + ")");
        WScript.Quit(0);
    } catch (e64) {
        echo("b64 decode/escrita falhou: " + e64.description);
        if (modo === "b64") WScript.Quit(4);
    }
}

if (querUnicode && corpoBin !== null && modo !== "ascii") {
    var bytes = msxmlBodyToBytes(corpoBin);
    if (bytes !== null && bytes.length > 0) {
        via = writeUnicodePacked(fso, dest, bytes);
        echo("ok: " + dest + " (" + bytes.length + " bytes, via msxml+" + via + ", origem=" + origem + ")");
        WScript.Quit(0);
    } else {
        echo("msxml nao converteu ResponseBody");
    }
}

if (querUnicode && corpoStr !== null && modo === "unicode") {
    via = writeUnicodePacked(fso, dest, stringToBytes(corpoStr));
    echo("ok: " + dest + " (" + corpoStr.length + " chars empacotados, via " + via + ", origem=" + origem + ")");
    WScript.Quit(0);
}

if (querAscii && corpoStr !== null) {
    via = writeAscii(fso, dest, corpoStr);
    echo("ok: " + dest + " (" + corpoStr.length + " bytes, via " + via + ", origem=" + origem + ")");
    echo("aviso: ascii perde 0x81..0x9F no cp1252; use b64 ou unicode para ESD");
    WScript.Quit(0);
}

echo("ERRO: nenhum caminho de escrita fechou (modo=" + modo + ")");
WScript.Quit(5);
