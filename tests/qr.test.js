import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { qrMatrix, qrToTerminal } from '../src/ui/qr.js';
import { lanScore, lanAddresses, reachable } from '../tools/lan.mjs';

const reference = JSON.parse(readFileSync(new URL('./fixtures/qr-reference.json', import.meta.url), 'utf8'));
const rowsOf = (modules) => modules.map((row) => BigInt(`0b${row.map((m) => (m ? 1 : 0)).join('')}`).toString(16));

test('QR: every module matches a reference encoder (versions 1–5, all eight masks)', () => {
  assert.equal(reference.codes.length, 56);
  const versions = new Set();
  for (const code of reference.codes) {
    const mine = qrMatrix(code.text, { mask: code.mask });
    versions.add(mine.version);
    assert.equal(mine.version, code.version, `version for ${JSON.stringify(code.text)}`);
    assert.equal(mine.size, 17 + 4 * code.version);
    assert.deepEqual(rowsOf(mine.modules), code.rows, `modules for ${JSON.stringify(code.text)} mask ${code.mask}`);
  }
  assert.deepEqual([...versions].sort(), [1, 2, 3, 4, 5]);
});

/* ---- an independent reader: format info -> unmask -> codewords -> Reed–Solomon check -> text ---- */

const MASKS = [
  (r, c) => (r + c) % 2 === 0, (r) => r % 2 === 0, (r, c) => c % 3 === 0, (r, c) => (r + c) % 3 === 0,
  (r, c) => (Math.floor(r / 2) + Math.floor(c / 3)) % 2 === 0, (r, c) => ((r * c) % 2) + ((r * c) % 3) === 0,
  (r, c) => (((r * c) % 2) + ((r * c) % 3)) % 2 === 0, (r, c) => (((r + c) % 2) + ((r * c) % 3)) % 2 === 0,
];
const ECC = [0, 7, 10, 15, 20, 26];

function gfTables() {
  const exp = new Array(510); const log = new Array(256).fill(0);
  for (let i = 0, x = 1; i < 255; i++) { exp[i] = x; exp[i + 255] = x; log[x] = i; x <<= 1; if (x & 0x100) x ^= 0x11d; }
  return { exp, log };
}

function readQr({ size, modules }) {
  const version = (size - 17) / 4;
  const m = (r, c) => (modules[r][c] ? 1 : 0);
  // both copies of the 15 format bits (most significant first)
  const copyA = [[8, 0], [8, 1], [8, 2], [8, 3], [8, 4], [8, 5], [8, 7], [8, 8], [7, 8], [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8]];
  const copyB = [];
  for (let i = 0; i < 7; i++) copyB.push([size - 1 - i, 8]);
  for (let i = 0; i < 8; i++) copyB.push([8, size - 8 + i]);
  const word = (cells) => cells.reduce((acc, [r, c]) => (acc << 1) | m(r, c), 0) ^ 0x5412;
  const a = word(copyA); const b = word(copyB);
  assert.equal(a, b, 'the two copies of the format information agree');
  // BCH(15,5): remainder of the whole word by the generator must be zero
  let rem = a;
  for (let i = 14; i >= 10; i--) if ((rem >> i) & 1) rem ^= 0x537 << (i - 10);
  assert.equal(rem, 0, 'format information is a valid BCH codeword');
  assert.equal(a >> 13, 0b01, 'error-correction level L');
  const mask = (a >> 10) & 7;

  const fn = Array.from({ length: size }, () => new Array(size).fill(false));
  const mark = (r0, c0, h, w) => { for (let r = r0; r < r0 + h; r++) for (let c = c0; c < c0 + w; c++) if (r >= 0 && c >= 0 && r < size && c < size) fn[r][c] = true; };
  mark(0, 0, 9, 9); mark(0, size - 8, 9, 8); mark(size - 8, 0, 8, 9);
  mark(6, 0, 1, size); mark(0, 6, size, 1);
  if (version >= 2) mark(size - 9, size - 9, 5, 5);

  const bits = [];
  let up = true;
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right = 5;
    for (let step = 0; step < size; step++) {
      const r = up ? size - 1 - step : step;
      for (const c of [right, right - 1]) if (!fn[r][c]) bits.push(m(r, c) ^ (MASKS[mask](r, c) ? 1 : 0));
    }
    up = !up;
  }
  const codewords = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) codewords.push(parseInt(bits.slice(i, i + 8).join(''), 2));
  // Reed–Solomon: the codeword polynomial vanishes at α^0 … α^(n-1)
  const { exp, log } = gfTables();
  for (let i = 0; i < ECC[version]; i++) {
    let s = 0;
    for (const cw of codewords) s = (s ? exp[log[s] + i] : 0) ^ cw;
    assert.equal(s, 0, `Reed–Solomon syndrome ${i} is zero`);
  }
  assert.equal(codewords[0] >> 4, 0b0100, 'byte mode');
  const length = ((codewords[0] & 15) << 4) | (codewords[1] >> 4);
  const bytes = [];
  for (let i = 0; i < length; i++) bytes.push(((codewords[i + 1] & 15) << 4) | (codewords[i + 2] >> 4));
  return { version, mask, text: new TextDecoder().decode(new Uint8Array(bytes)) };
}

test('QR: codes read back to the original text with valid error correction', () => {
  const texts = ['http://192.168.1.23:8080/', 'https://192.168.100.200:8443/', 'http://10.0.0.5:8080/', 'a', 'x'.repeat(17), 'x'.repeat(18), 'y'.repeat(53), 'z'.repeat(106), 'café ✓'];
  for (const text of texts) {
    const code = qrMatrix(text);
    const read = readQr(code);
    assert.equal(read.text, text);
    assert.equal(read.mask, code.mask);
    assert.equal(read.version, code.version);
  }
});

test('QR: fixed patterns — finders, timing, dark module', () => {
  const { size, modules } = qrMatrix('http://192.168.1.23:8080/');
  const finder = ['1111111', '1000001', '1011101', '1011101', '1011101', '1000001', '1111111'];
  for (const [r0, c0] of [[0, 0], [0, size - 7], [size - 7, 0]]) {
    for (let r = 0; r < 7; r++) assert.equal(modules[r0 + r].slice(c0, c0 + 7).map((m) => (m ? 1 : 0)).join(''), finder[r]);
  }
  for (let i = 8; i < size - 8; i++) {
    assert.equal(modules[6][i], i % 2 === 0, 'horizontal timing pattern');
    assert.equal(modules[i][6], i % 2 === 0, 'vertical timing pattern');
  }
  assert.equal(modules[size - 8][8], true, 'dark module');
});

test('QR: picks the smallest version that fits and rejects text that is too long', () => {
  assert.equal(qrMatrix('x'.repeat(17)).version, 1);
  assert.equal(qrMatrix('x'.repeat(18)).version, 2);
  assert.equal(qrMatrix('x'.repeat(32)).version, 2);
  assert.equal(qrMatrix('x'.repeat(33)).version, 3);
  assert.equal(qrMatrix('x'.repeat(78)).version, 4);
  assert.equal(qrMatrix('x'.repeat(106)).version, 5);
  assert.throws(() => qrMatrix('x'.repeat(107)), /too long/);
  // multi-byte characters count as bytes
  assert.equal(qrMatrix('é'.repeat(9)).version, 2);
});

test('QR: terminal rendering is a rectangle with a quiet zone, dark modules on a light block', () => {
  const text = 'http://192.168.1.23:8080/';
  const { size, modules } = qrMatrix(text);
  const lines = qrToTerminal(text).split('\n');
  const visible = lines.map((l) => l.replace(/\x1b\[[0-9;]*m/g, ''));
  assert.equal(lines.length, Math.ceil((size + 4) / 2));
  for (const l of lines) assert.ok(l.startsWith('\x1b[47m\x1b[30m') && l.endsWith('\x1b[0m'), 'black on white, colours reset at the end of each line');
  for (const v of visible) assert.equal([...v].length, size + 4);
  assert.match(visible[0], /^ +$/, 'quiet zone above');
  // every cell shows the two modules it stands for
  const at = (r, c) => r >= 0 && c >= 0 && r < size && c < size && modules[r][c];
  visible.forEach((v, i) => [...v].forEach((ch, j) => {
    const top = at(i * 2 - 2, j - 2), bottom = at(i * 2 - 1, j - 2);
    assert.equal(ch, top && bottom ? '█' : top ? '▀' : bottom ? '▄' : ' ');
  }));
});

test('LAN addresses: Wi-Fi/Ethernet ranges come before virtual adapters and self-assigned addresses', () => {
  assert.ok(lanScore('192.168.1.20', 'en0') < lanScore('10.8.0.2', 'en5'));
  assert.ok(lanScore('10.0.0.5', 'eth0') < lanScore('172.20.1.1', 'eth1'));
  assert.ok(lanScore('192.168.1.20', 'wlan0') < lanScore('172.17.0.1', 'docker0'));
  assert.ok(lanScore('192.168.1.20', 'Wi-Fi') < lanScore('192.168.56.1', 'vboxnet0'));
  assert.ok(lanScore('192.168.1.20', 'en0') < lanScore('169.254.10.10', 'en3'));
  const interfaces = {
    lo: [{ address: '127.0.0.1', family: 'IPv4', internal: true }],
    docker0: [{ address: '172.17.0.1', family: 'IPv4', internal: false }],
    utun3: [{ address: '100.64.0.9', family: 'IPv4', internal: false }],
    en0: [{ address: 'fe80::1', family: 'IPv6', internal: false }, { address: '192.168.1.20', family: 'IPv4', internal: false }],
  };
  assert.deepEqual(lanAddresses(interfaces), ['192.168.1.20', '172.17.0.1', '100.64.0.9']);
});

test('LAN addresses: documentation/test ranges are never offered (a phone cannot reach them)', () => {
  for (const ip of ['192.0.2.2', '198.51.100.7', '203.0.113.9', '198.18.0.1', '127.0.0.1']) assert.equal(reachable(ip), false, ip);
  for (const ip of ['192.168.1.20', '10.0.0.5', '172.20.1.1', '100.64.0.9', '192.0.3.1']) assert.equal(reachable(ip), true, ip);
  assert.deepEqual(lanAddresses({ eth0: [{ address: '192.0.2.2', family: 'IPv4', internal: false }] }), []);
});
