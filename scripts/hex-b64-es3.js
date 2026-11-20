// hex-b64-es3.js - ES3 decoders (no atob, no Buffer in the decoders) for hex and base64.
// Same style as WinRE JScript. HOST TEST ONLY: node here is NOT WinRE and NOT hardware proof.
// Usage: node scripts/hex-b64-es3.js hex|b64 in.txt out.bin
function hexDecode(t) {
  var s = t.replace(/[ \t\r\n]/g, ""), o = [], i;
  if (!/^(?:[0-9a-fA-F]{2})*$/.test(s)) throw new Error("invalid hex");
  for (i = 0; i < s.length; i += 2) o.push(parseInt(s.substr(i, 2), 16));
  return o;
}
function b64Decode(t) {
  var A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  var s = t.replace(/[ \t\r\n]/g, ""), o = [], i, a, b, c, d;
  if (!/^[A-Za-z0-9+\/]*={0,2}$/.test(s) || s.length % 4) throw new Error("invalid base64");
  for (i = 0; i < s.length; i += 4) {
    a = A.indexOf(s.charAt(i)); b = A.indexOf(s.charAt(i + 1));
    c = s.charAt(i + 2) == "=" ? -1 : A.indexOf(s.charAt(i + 2));
    d = s.charAt(i + 3) == "=" ? -1 : A.indexOf(s.charAt(i + 3));
    o.push((a << 2) | (b >> 4));
    if (c >= 0) o.push(((b & 15) << 4) | (c >> 2));
    if (d >= 0) o.push(((c & 3) << 6) | d);
  }
  return o;
}
var fs = require("fs"), m = process.argv[2];
var out = (m == "hex" ? hexDecode : b64Decode)(fs.readFileSync(process.argv[3], "latin1"));
fs.writeFileSync(process.argv[4], Buffer.from(out));
