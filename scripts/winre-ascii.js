// winre-ascii.js - ASCII ONLY, Windows Script Host / ES3.
// Type this file through Notepad (save ANSI); never pre-seed the guest.
// selftest | write PATH HEX SHA256 | verify PATH SIZE SHA256
// No network, native binary sink, certutil, PowerShell or driver changes.
// Host mocks test algorithms only; FSO must still be proved inside WinRE.
function ascii(s) {
    for (var i = 0; i < s.length; i++) {
        var n = s.charCodeAt(i);
        if (n != 9 && n != 10 && n != 13 && (n < 32 || n > 126)) {
            throw new Error("non-ASCII text byte at " + i);
        }
    }
    return s;
}
function decode(h) {
    if (!/^(?:[0-9a-fA-F]{2})+$/.test(h)) throw new Error("invalid hex");
    var s = "";
    for (var i = 0; i < h.length; i += 2) {
        s += String.fromCharCode(parseInt(h.substr(i, 2), 16));
    }
    return ascii(s);
}
function sha256(s) {
    ascii(s);
    var k = [0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,
        0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,
        0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,
        0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,
        0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,
        0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,
        0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,
        0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,
        0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2];
    var h = [0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
        0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19];
    var b = [], i, j, w = [], a, c, d, e, f, g, v, t1, t2;
    function r(x, n) { return (x >>> n) | (x << (32 - n)); }
    for (i = 0; i < s.length; i++) b.push(s.charCodeAt(i));
    var bits = s.length * 8;
    b.push(128);
    while (b.length % 64 != 56) b.push(0);
    var hi = Math.floor(bits / 4294967296), lo = bits >>> 0;
    for (i = 3; i >= 0; i--) b.push((hi >>> (i * 8)) & 255);
    for (i = 3; i >= 0; i--) b.push((lo >>> (i * 8)) & 255);
    for (i = 0; i < b.length; i += 64) {
        for (j = 0; j < 16; j++) {
            var p = i + j * 4;
            w[j] = (b[p] << 24) | (b[p+1] << 16) | (b[p+2] << 8) | b[p+3];
        }
        for (j = 16; j < 64; j++) {
            var x = w[j-15], y = w[j-2];
            w[j] = (w[j-16] + (r(x,7)^r(x,18)^(x>>>3)) + w[j-7]
                + (r(y,17)^r(y,19)^(y>>>10))) | 0;
        }
        a=h[0]; v=h[1]; c=h[2]; d=h[3]; e=h[4]; f=h[5]; g=h[6]; var z=h[7];
        for (j = 0; j < 64; j++) {
            t1 = (z + (r(e,6)^r(e,11)^r(e,25)) + ((e&f)^((~e)&g)) + k[j] + w[j]) | 0;
            t2 = ((r(a,2)^r(a,13)^r(a,22)) + ((a&v)^(a&c)^(v&c))) | 0;
            z=g; g=f; f=e; e=(d+t1)|0; d=c; c=v; v=a; a=(t1+t2)|0;
        }
        var state = [a,v,c,d,e,f,g,z];
        for (j = 0; j < 8; j++) h[j] = (h[j] + state[j]) | 0;
    }
    var out = "";
    for (i = 0; i < 8; i++) out += ("00000000" + (h[i] >>> 0).toString(16)).slice(-8);
    return out;
}
function digest(h) {
    if (!/^[0-9a-fA-F]{64}$/.test(h)) throw new Error("invalid SHA-256");
    return h.toLowerCase();
}
function read(fso, path) {
    var stream = fso.OpenTextFile(path, 1, false, 0); // ASCII, not Unicode
    var s = stream.ReadAll();
    stream.Close();
    ascii(s);
    if (fso.GetFile(path).Size != s.length) throw new Error("size/encoding mismatch");
    return s;
}
function selftest() {
    var inputs = ["", "abc", "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"];
    var expected = [
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"];
    for (var i = 0; i < inputs.length; i++) {
        if (sha256(inputs[i]) != expected[i]) throw new Error("SHA-256 vector " + i);
    }
    WScript.Echo("PASS SHA256 selftest vectors=3");
}
function main() {
    var args = WScript.Arguments;
    if (args.length == 1 && args(0) == "selftest") { selftest(); return; }
    if (args.length != 4) throw new Error("usage: selftest | write PATH HEX SHA256 | verify PATH SIZE SHA256");
    var mode = args(0), path = args(1), wanted = digest(args(3));
    var s, size;
    // Fully validate payload/hash BEFORE opening or overwriting an output file.
    if (mode == "write") {
        s = decode(args(2));
        if (sha256(s) != wanted) throw new Error("input digest mismatch");
        size = s.length;
    } else if (mode == "verify") {
        if (!/^[0-9]+$/.test(args(2))) throw new Error("invalid size");
        size = Number(args(2));
        if (size > 16777216) throw new Error("size exceeds text-probe limit");
    } else throw new Error("unknown mode");
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    if (mode == "write") {
        var stream = fso.CreateTextFile(path, true, false); // ANSI, no BOM
        stream.Write(s); // NOT WriteLine: preserve CR/LF and final byte
        stream.Close();
    }
    var actual = read(fso, path), got = sha256(actual);
    if (actual.length != size || got != wanted) throw new Error("readback mismatch");
    WScript.Echo("ACK " + path + " bytes=" + size + " sha256=" + got);
}
try { main(); }
catch (err) { WScript.Echo("FAIL " + err.message); WScript.Quit(1); }
WScript.Quit(0);
