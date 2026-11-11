// teste-fso-binario.js - mede se o FSO do WinRE 1809 grava os 256 bytes sem perda.
// Hipotese (N0): em modo Unicode o FSO grava cada wchar como 2 bytes (lo,hi).
// Empacotando 2 bytes por caractere (lo | hi<<8) o arquivo sai identico ao binario,
// inclusive 0x81..0x9F, sem precisar de ADODB. Risco conhecido: BOM FF FE no inicio
// de arquivo novo, e substitutos 0xD800..0xDFFF. O host le o disco e compara.
// Uso no PE: cscript //nologo teste-fso-binario.js <prefixo>   (gera .a .u .p)
var fso = new ActiveXObject("Scripting.FileSystemObject");
var p = WScript.Arguments(0), i, s;
// A) ASCII: 256 chars (referencia do caminho atual; esperado perder 0x81..0x9F)
s = ""; for (i = 0; i < 256; i++) s += String.fromCharCode(i);
var a = fso.CreateTextFile(p + ".a", true, false); a.Write(s); a.Close();
// U) Unicode novo: 128 chars, cada um = 2 bytes consecutivos
s = ""; for (i = 0; i < 256; i += 2) s += String.fromCharCode(i | ((i + 1) << 8));
var u = fso.CreateTextFile(p + ".u", true, true); u.Write(s); u.Close();
// P) Unicode em arquivo pre-criado vazio, abrindo para append (ver se evita o BOM)
fso.CreateTextFile(p + ".p", true, false).Close();
var q = fso.OpenTextFile(p + ".p", 8, false, -1); q.Write(s); q.Close();
WScript.Echo("fso-binario: " + fso.GetFile(p + ".a").Size + " " +
             fso.GetFile(p + ".u").Size + " " + fso.GetFile(p + ".p").Size);
// Esperado se a hipotese vale: .a=256 (com '?' nos 0x81..0x9F), .u=258 (BOM+256) ou 256, .p=256.
