// WinRE alphabet decoder (UNPROVEN until E1 boots and fso-probe passes).
// Requires: hex text file (argv 0), output path (argv 1).
// Builds 1-byte alphabet: fsutil for 0x00, FSO Write for 1..255, then copy /b.
// cscript //nologo winre-alphabet-decode.js payload.hex payload.bin
var fso = new ActiveXObject("Scripting.FileSystemObject");
var sh = new ActiveXObject("WScript.Shell");
var args = WScript.Arguments;
if (args.length < 2) {
  WScript.Echo("usage: cscript //nologo winre-alphabet-decode.js <hex.txt> <out.bin>");
  WScript.Quit(2);
}
function hx(n) {
  var s = n.toString(16);
  return (s.length < 2 ? "0" : "") + s;
}
function run(cmd) {
  var rc = sh.Run("cmd /c " + cmd, 0, true);
  if (rc !== 0) {
    WScript.Echo("fail: " + cmd + " rc=" + rc);
    WScript.Quit(1);
  }
}
var i, t, hex, out, chunk, n, cmd, k;
if (!fso.FolderExists("alph")) fso.CreateFolder("alph");
run("fsutil file createnew alph\\00 1");
for (i = 1; i < 256; i++) {
  t = fso.CreateTextFile("alph\\" + hx(i), true, false);
  t.Write(String.fromCharCode(i));
  t.Close();
}
t = fso.OpenTextFile(args(0), 1);
hex = t.ReadAll();
t.Close();
hex = hex.replace(/[^0-9A-Fa-f]/g, "");
if (hex.length % 2) {
  WScript.Echo("odd hex length");
  WScript.Quit(1);
}
out = args(1);
if (fso.FileExists(out)) fso.DeleteFile(out);
chunk = "";
n = 0;
for (k = 0; k < hex.length; k += 2) {
  if (chunk) chunk += "+";
  chunk += "alph\\" + hex.substr(k, 2).toLowerCase();
  n += 1;
  if (n === 16 || k + 2 === hex.length) {
    if (!fso.FileExists(out)) cmd = "copy /b " + chunk + " " + out;
    else cmd = "copy /b " + out + "+" + chunk + " " + out;
    run(cmd);
    chunk = "";
    n = 0;
  }
}
WScript.Echo("wrote " + out + " bytes=" + fso.GetFile(out).Size);
