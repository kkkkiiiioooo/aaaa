// teste-fso-binario.js - mede se o FSO do WinRE 1809 grava os 256 bytes sem perda.
// Hipotese (N0): em modo Unicode o FSO grava cada wchar como 2 bytes (lo,hi).
// Empacotando 2 bytes por caractere (lo | hi<<8) o arquivo sai identico ao binario,
// inclusive 0x81..0x9F, sem precisar de ADODB. Risco conhecido: BOM FF FE no inicio
// de arquivo novo, e substitutos 0xD800..0xDFFF. O host le o disco e compara.
// Uso no PE: cscript //nologo teste-fso-binario.js <prefixo>   (gera .a .u .p .r .s)
//
// MEDIDO NO PE (run 2026-11-12, brianwoo-auto): FSO ASCII Write LANCA "Invalid
// procedure call or argument" em string com chars 0..255 (o fso-t.a ficou com 0 B)
// — a escrita ASCII nao "perde com ?", ela QUEBRA. Cada caminho agora roda em
// try/catch proprio: um erro nao impede de medir os outros.
var fso = new ActiveXObject("Scripting.FileSystemObject");
var p = WScript.Arguments.length > 0 ? WScript.Arguments(0) : "C:\\fso-t";
var i, s, res = "";

function tentar(rotulo, fn) {
    try { fn(); WScript.Echo("fso " + rotulo + ": OK"); }
    catch (e) { WScript.Echo("fso " + rotulo + ": ERRO " + e.description); }
}
function tam(suf) { try { return fso.GetFile(p + suf).Size; } catch (e2) { return -1; } }

// A) ASCII: 256 chars (referencia do caminho atual; esperado perder 0x81..0x9F
//    ou, medido 2026-11-12, lancar erro no Write)
s = ""; for (i = 0; i < 256; i++) s += String.fromCharCode(i);
tentar("A-ascii", function () {
    var a = fso.CreateTextFile(p + ".a", true, false); a.Write(s); a.Close();
});

// U) Unicode novo: 128 chars, cada um = 2 bytes consecutivos (tem substitutos)
s = ""; for (i = 0; i < 256; i += 2) s += String.fromCharCode(i | ((i + 1) << 8));
tentar("U-unicode-bom", function () {
    var u = fso.CreateTextFile(p + ".u", true, true); u.Write(s); u.Close();
});

// P) Unicode em arquivo pre-criado vazio, abrindo para append (ver se evita o BOM)
tentar("P-unicode-append", function () {
    fso.CreateTextFile(p + ".p", true, false).Close();
    var q = fso.OpenTextFile(p + ".p", 8, false, -1); q.Write(s); q.Close();
});

// R) controle: Unicode com so ASCII (isola se o erro e do conteudo ou do modo)
tentar("R-unicode-ascii", function () {
    var t = fso.CreateTextFile(p + ".r", true, true);
    t.Write("ABCDEFGHIJKLMNOPQRSTUVWXYZ"); t.Close();
});

// S) controle: ASCII printable (caminho que o m0715345077 provou N3)
tentar("S-ascii-printable", function () {
    var t = fso.CreateTextFile(p + ".s", true, false);
    t.Write("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"); t.Close();
});

WScript.Echo("fso-binario: a=" + tam(".a") + " u=" + tam(".u") + " p=" + tam(".p") +
    " r=" + tam(".r") + " s=" + tam(".s") +
    " (esperado se hipotese vale: u=258 BOM+256 ou 256, p=256)");
