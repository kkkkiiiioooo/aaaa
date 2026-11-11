// teste-msxml-binario.js - mede no PE se MSXML2.DOMDocument converte binario
// (bin.base64 / bin.hex) SEM ADODB. msxml3.dll e msxml6.dll existem no WinRE 1809.
// Se roundtrip 0..255 sobreviver, ResponseBody->bytes fecha o transporte do ESD.
// Tambem grava o payload via FSO Unicode empacotado (mesmo algoritmo de download-js.js).
// Uso: cscript //nologo teste-msxml-binario.js <prefixo>
var fso = new ActiveXObject("Scripting.FileSystemObject");
var p = WScript.Arguments.Count > 0 ? WScript.Arguments(0) : "C:\\msxml-t";
var ids = ["Msxml2.DOMDocument.6.0", "Msxml2.DOMDocument.3.0", "MSXML2.DOMDocument", "Microsoft.XMLDOM"];
var abc = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

function b64enc(bytes) {
    var i, n, a, b, c, o = "";
    for (i = 0; i < bytes.length; i += 3) {
        a = bytes[i];
        b = i + 1 < bytes.length ? bytes[i + 1] : 0;
        c = i + 2 < bytes.length ? bytes[i + 2] : 0;
        n = (a << 16) | (b << 8) | c;
        o += abc.charAt((n >> 18) & 63) + abc.charAt((n >> 12) & 63);
        o += (i + 1 < bytes.length) ? abc.charAt((n >> 6) & 63) : "=";
        o += (i + 2 < bytes.length) ? abc.charAt(n & 63) : "=";
    }
    return o;
}

function packBytes(bytes) {
    var s = "", i, n = bytes.length;
    for (i = 0; i < n; i += 2)
        s += String.fromCharCode(bytes[i] | (((i + 1 < n) ? bytes[i + 1] : 0) << 8));
    return s;
}

var orig = [];
var i;
for (i = 0; i < 256; i++) orig.push(i);
var b64 = b64enc(orig);
WScript.Echo("payload b64_len=" + b64.length);

var ok = 0;
var iId;
for (iId = 0; iId < ids.length; iId++) {
    var id = ids[iId];
    try {
        var xml = new ActiveXObject(id);
        var el = xml.createElement("x");
        el.dataType = "bin.base64";
        el.text = b64;
        var bin = el.nodeTypedValue;
        var el2 = xml.createElement("y");
        el2.dataType = "bin.hex";
        el2.nodeTypedValue = bin;
        var hex = ("" + el2.text).replace(/[\r\n\s]/g, "");
        WScript.Echo("msxml " + id + " hex_len=" + hex.length);
        var mismatch = 0;
        for (i = 0; i < 256; i++) {
            var got = parseInt(hex.substr(i * 2, 2), 16);
            if (got !== i) mismatch++;
        }
        WScript.Echo("msxml " + id + " mismatches=" + mismatch);
        if (mismatch === 0) {
            ok++;
            var packed = packBytes(orig);
            try {
                fso.CreateTextFile(p + ".u", true, false).Close();
                var t = fso.OpenTextFile(p + ".u", 8, false, -1);
                t.Write(packed); t.Close();
            } catch (eW) {
                var t2 = fso.CreateTextFile(p + ".u", true, true);
                t2.Write(packed); t2.Close();
            }
            var tlen = fso.CreateTextFile(p + ".len", true, false);
            tlen.Write("256"); tlen.Close();
            WScript.Echo("msxml-binario: wrote " + p + ".u size=" + fso.GetFile(p + ".u").Size);
            break;
        }
    } catch (e) {
        WScript.Echo("msxml " + id + " falhou: " + e.description);
    }
}
WScript.Echo("msxml-binario: progids_ok=" + ok);
if (ok < 1) WScript.Quit(2);
