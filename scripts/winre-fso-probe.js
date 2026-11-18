// WinRE probe: which bytes does FSO ASCII Write preserve?
// Run in a booted WinRE: cscript //nologo winre-fso-probe.js
// Not a hardware proof. Expect size=1 for a preserved byte.
var fso = new ActiveXObject("Scripting.FileSystemObject");
var sh = new ActiveXObject("WScript.Shell");
var log = fso.CreateTextFile("fso-probe.txt", true);
function hx(n) {
  var s = n.toString(16);
  return (s.length < 2 ? "0" : "") + s;
}
sh.Run("cmd /c fsutil file createnew fsutil00.bin 1", 0, true);
try {
  log.WriteLine("fsutil00.size=" + fso.GetFile("fsutil00.bin").Size);
} catch (e) {
  log.WriteLine("fsutil00.ERR=" + e.message);
}
var i, name, t, sz;
for (i = 0; i < 256; i++) {
  name = "p" + hx(i) + ".bin";
  try {
    t = fso.CreateTextFile(name, true, false);
    t.Write(String.fromCharCode(i));
    t.Close();
    sz = fso.GetFile(name).Size;
    log.WriteLine(hx(i) + " size=" + sz + (sz === 1 ? " OK" : " BAD"));
  } catch (e) {
    log.WriteLine(hx(i) + " ERR " + e.message);
  }
}
log.Close();
WScript.Echo("wrote fso-probe.txt");
