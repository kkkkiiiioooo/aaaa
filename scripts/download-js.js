// download-js.js — baixa por HTTP e grava em disco DENTRO do WinRE 1809.
//
// Por que existe: o scripts/download.vbs (VBScript) chega no servidor, mas nao
// consegue gravar o corpo da resposta: o WinRE 1809 nao tem ADODB.Stream
// (falta o pacote WinPE-MDAC) -> "ADODB.Stream indisponivel". Medido em
// 2026-11-07 no PE.
//
// A saida usa o Scripting.FileSystemObject em modo ASCII: 1 caractere = 1 byte.
// Como o codepage do PE e 1252 (Latin-1 estendido), cada byte 0..255 volta como o
// MESMO byte. ATENCAO: os bytes 0x81..0x9F nao tem representacao no 1252 e saem
// como '?' (0x3F). Para um ESD assinado isso corrompe o arquivo: nesse caso o
// caminho a usar e o FTP (binario nativo) ou um servidor que entregue o
// conteudo de um jeito que o PE grave sem perda.
//
// Uso: cscript //nologo download-js.js <URL> <destino>

var url = WScript.Arguments(0);
var dest = WScript.Arguments(1);

if (!url || !dest) {
    WScript.Echo("uso: cscript //nologo download-js.js <URL> <destino>");
    WScript.Quit(1);
}

var http = new ActiveXObject("WinHttp.WinHttpRequest.5.1");
http.Open("GET", url, false);
http.SetTimeouts(30000, 30000, 600000, 600000);
http.Send();

if (http.Status !== 200) {
    WScript.Echo("ERRO HTTP: " + http.Status + " " + http.StatusText);
    WScript.Quit(4);
}

var arr = new VBArray(http.ResponseBody).toArray();
var s = "";
for (var i = 0; i < arr.length; i++) {
    s += String.fromCharCode(arr[i]);
}

var fso = new ActiveXObject("Scripting.FileSystemObject");
var ts = fso.CreateTextFile(dest, true, false);   // ascii: 1 byte por caractere
ts.Write(s);
ts.Close();

WScript.Echo("ok: " + dest + " (" + arr.length + " bytes)");
