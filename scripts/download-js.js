// download-js.js — baixa por HTTP e grava em disco DENTRO do WinRE 1809.
//
// Por que existe: o scripts/download.vbs (VBScript) chega no servidor, mas nao
// consegue gravar o corpo da resposta: o WinRE 1809 nao tem ADODB.Stream
// (falta o pacote WinPE-MDAC) -> "ADODB.Stream indisponivel". Medido em
// 2026-11-07 no PE.
//
// Tenta tres caminhos, em ordem, e registra qual funcionou:
//   1) WinHttp.WinHttpRequest.5.1 + ResponseBody (VBArray/array de bytes)
//   2) MSXML2.XMLHTTP (msxml3.dll existe na imagem) + responseText
// A saida usa o Scripting.FileSystemObject em modo ASCII: 1 caractere = 1 byte.
// Como o codepage do PE e 1252, cada byte 0..255 volta como o MESMO byte.
// ATENCAO: os bytes 0x81..0x9F nao tem representacao no 1252 e saem como '?'.
// Para um ESD assinado isso corrompe o arquivo: nesse caso o caminho a usar e o
// FTP (binario nativo) ou um servidor que entregue o conteudo sem perda.
//
// Uso: cscript //nologo download-js.js <URL> <destino>

var url = WScript.Arguments(0);
var dest = WScript.Arguments(1);

if (!url || !dest) {
    WScript.Echo("uso: cscript //nologo download-js.js <URL> <destino>");
    WScript.Quit(1);
}

var corpo = null;
var origem = "";

try {
    var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
    http.Open("GET", url, false);
    http.SetTimeouts(30000, 30000, 600000, 600000);
    http.Send();
    WScript.Echo("winhttp status=" + http.Status);
    if (http.Status === 200) {
        // ResponseText primeiro: e string e ja serve para gravar (o corpo
        // binario volta como caracteres). ResponseBody no JScript do WinRE 1809
        // vem como objeto Automation sem .length e sem Item() utilizavel.
        try {
            var rt = http.ResponseText;
            if (rt !== null && typeof rt !== "undefined" && rt.length > 0) {
                WScript.Echo("winhttp ResponseText: " + rt.length + " chars");
                corpo = rt;
                origem = "winhttp-text";
            }
        } catch (eR) {
            WScript.Echo("winhttp ResponseText falhou: " + eR.description);
        }
        var b = http.ResponseBody;
        if (corpo === null && b !== null && typeof b !== "undefined") {
            WScript.Echo("winhttp ResponseBody: tipo=" + (typeof b));
            corpo = b;
            origem = "winhttp";
        } else if (corpo === null) {
            WScript.Echo("winhttp ResponseBody: nulo");
            try {
                var t2 = http.ResponseText;
                if (t2 !== null && typeof t2 !== "undefined") {
                    WScript.Echo("winhttp ResponseText: " + t2.length + " chars");
                    corpo = t2;
                    origem = "winhttp-text";
                }
            } catch (eT) {
                WScript.Echo("winhttp ResponseText falhou: " + eT.description);
            }
        }
    }
} catch (e) {
    WScript.Echo("winhttp falhou: " + e.description);
}

if (corpo === null) {
    try {
        var x = new ActiveXObject("MSXML2.XMLHTTP");
        x.open("GET", url, false);
        x.send();
        WScript.Echo("xmlhttp status=" + x.status);
        if (x.status === 200) {
            corpo = x.responseText;
            origem = "xmlhttp";
        }
    } catch (e2) {
        WScript.Echo("xmlhttp falhou: " + e2.description);
    }
}

if (corpo === null) {
    WScript.Echo("ERRO: nenhum dos dois clientes devolveu corpo");
    WScript.Quit(3);
}

// o ResponseBody do WinHttp chega no JScript como objeto Automation (typeof
// "unknown"): nao tem .length, mas expoe os bytes por Item(i) (medido em
// 2026-11-07). Se vier como string (ResponseText / responseText), usa direto.
var s;
if (typeof corpo === "string") {
    s = corpo;
} else {
    var n = null;
    try {
        if (corpo.length !== null && typeof corpo.length !== "undefined") {
            n = corpo.length;
        }
    } catch (eL) {
        n = null;
    }
    if (n === null) {
        var arr = [];
        try {
            for (var i = 0; ; i++) {
                arr.push(corpo.Item(i));
            }
        } catch (eI) {
            n = arr.length;
            corpo = arr;
        }
    } else {
        WScript.Echo("corpo: array com length=" + n);
    }
    s = "";
    for (var j = 0; j < (n !== null ? n : corpo.length); j++) {
        s += String.fromCharCode(corpo[j]);
    }
}

var fso = new ActiveXObject("Scripting.FileSystemObject");
var ts = fso.CreateTextFile(dest, true, false);   // ascii: 1 byte por caractere
ts.Write(s);
ts.Close();

WScript.Echo("ok: " + dest + " (" + s.length + " bytes, via " + origem + ")");
