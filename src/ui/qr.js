/**
 * A small QR code encoder (byte mode, error-correction level L, versions 1–5:
 * up to 106 bytes — plenty for a local URL). No dependencies; used by the dev
 * server to print a scannable code in the terminal and by the page to show
 * one in the help dialog.
 *
 * qrMatrix(text) -> { size, modules } where modules[row][col] is true for a
 * dark module (no quiet zone included).
 */

// Level L, versions 1..5: total data codewords and error-correction codewords (one block each).
const DATA_CODEWORDS = [0, 19, 34, 55, 80, 108];
const ECC_CODEWORDS = [0, 7, 10, 15, 20, 26];

/* ---- GF(256) arithmetic (primitive polynomial x^8 + x^4 + x^3 + x^2 + 1) ---- */
const EXP = new Uint8Array(512);
const LOG = new Uint8Array(256);
for (let i = 0, x = 1; i < 255; i++) {
  EXP[i] = x; LOG[x] = i;
  x <<= 1; if (x & 0x100) x ^= 0x11d;
}
for (let i = 255; i < 512; i++) EXP[i] = EXP[i - 255];
const mul = (a, b) => (a && b ? EXP[LOG[a] + LOG[b]] : 0);

/** Reed–Solomon error-correction codewords for `data`. */
function reedSolomon(data, count) {
  // generator polynomial: product of (x - α^i), i = 0..count-1
  let gen = [1];
  for (let i = 0; i < count; i++) {
    const next = new Array(gen.length + 1).fill(0);
    for (let j = 0; j < gen.length; j++) {
      next[j] ^= gen[j];
      next[j + 1] ^= mul(gen[j], EXP[i]);
    }
    gen = next;
  }
  const rem = new Array(count).fill(0);
  for (const byte of data) {
    const factor = byte ^ rem.shift();
    rem.push(0);
    for (let j = 0; j < count; j++) rem[j] ^= mul(gen[j + 1], factor);
  }
  return rem;
}

/** UTF-8 bytes of a string. */
function utf8(text) {
  if (typeof TextEncoder !== 'undefined') return [...new TextEncoder().encode(text)];
  return [...unescape(encodeURIComponent(text))].map((c) => c.charCodeAt(0));
}

/** Data + error-correction codewords for the text at the smallest version that fits. */
function encode(text) {
  const bytes = utf8(text);
  let version = 1;
  while (version <= 5 && bytes.length > DATA_CODEWORDS[version] - 2) version++;
  if (version > 5) throw new Error('Text too long for this QR encoder (max 106 bytes)');
  const capacity = DATA_CODEWORDS[version];
  const bits = [];
  const push = (value, length) => { for (let i = length - 1; i >= 0; i--) bits.push((value >> i) & 1); };
  push(0b0100, 4);            // byte mode
  push(bytes.length, 8);      // character count (8 bits for versions 1–9)
  for (const b of bytes) push(b, 8);
  for (let i = 0; i < 4 && bits.length < capacity * 8; i++) bits.push(0); // terminator
  while (bits.length % 8) bits.push(0);
  const data = [];
  for (let i = 0; i < bits.length; i += 8) data.push(parseInt(bits.slice(i, i + 8).join(''), 2));
  for (let pad = 0xec; data.length < capacity; pad ^= 0xec ^ 0x11) data.push(pad);
  return { version, codewords: [...data, ...reedSolomon(data, ECC_CODEWORDS[version])] };
}

const MASKS = [
  (r, c) => (r + c) % 2 === 0,
  (r) => r % 2 === 0,
  (r, c) => c % 3 === 0,
  (r, c) => (r + c) % 3 === 0,
  (r, c) => (Math.floor(r / 2) + Math.floor(c / 3)) % 2 === 0,
  (r, c) => ((r * c) % 2) + ((r * c) % 3) === 0,
  (r, c) => (((r * c) % 2) + ((r * c) % 3)) % 2 === 0,
  (r, c) => (((r + c) % 2) + ((r * c) % 3)) % 2 === 0,
];

/** 15-bit format information for level L and a mask pattern. */
function formatBits(mask) {
  const data = (0b01 << 3) | mask; // level L = 01
  let rem = data;
  for (let i = 0; i < 10; i++) rem = (rem << 1) ^ ((rem >> 9) * 0x537);
  return ((data << 10) | rem) ^ 0x5412;
}

function build(version, codewords, mask) {
  const size = 17 + 4 * version;
  const modules = Array.from({ length: size }, () => new Array(size).fill(false));
  const reserved = Array.from({ length: size }, () => new Array(size).fill(false));
  const set = (r, c, dark) => { modules[r][c] = dark; reserved[r][c] = true; };

  // Finder patterns with separators
  for (const [r0, c0] of [[0, 0], [0, size - 7], [size - 7, 0]]) {
    for (let r = -1; r <= 7; r++) {
      for (let c = -1; c <= 7; c++) {
        const rr = r0 + r, cc = c0 + c;
        if (rr < 0 || cc < 0 || rr >= size || cc >= size) continue;
        const inside = r >= 0 && r <= 6 && c >= 0 && c <= 6;
        const dark = inside && (r === 0 || r === 6 || c === 0 || c === 6 || (r >= 2 && r <= 4 && c >= 2 && c <= 4));
        set(rr, cc, dark);
      }
    }
  }
  // Timing patterns
  for (let i = 8; i < size - 8; i++) { set(6, i, i % 2 === 0); set(i, 6, i % 2 === 0); }
  // Alignment pattern (versions 2–5 have exactly one, centred 6 modules from the bottom-right edges)
  if (version >= 2) {
    const centre = size - 7;
    for (let r = -2; r <= 2; r++) for (let c = -2; c <= 2; c++) set(centre + r, centre + c, Math.max(Math.abs(r), Math.abs(c)) !== 1);
  }
  // Dark module and format information areas
  set(size - 8, 8, true);
  const format = formatBits(mask);
  const bit = (i) => ((format >> i) & 1) === 1;
  for (let i = 0; i <= 5; i++) set(8, i, bit(14 - i));
  set(8, 7, bit(8)); set(8, 8, bit(7)); set(7, 8, bit(6));
  for (let i = 0; i <= 5; i++) set(i, 8, bit(i));
  for (let i = 0; i <= 6; i++) set(size - 1 - i, 8, bit(14 - i));
  for (let i = 0; i <= 7; i++) set(8, size - 8 + i, bit(7 - i));

  // Data: zigzag upward/downward in two-module-wide columns from the bottom-right, skipping the timing column
  const stream = [];
  for (const cw of codewords) for (let i = 7; i >= 0; i--) stream.push((cw >> i) & 1);
  let index = 0;
  let upward = true;
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right = 5;
    for (let step = 0; step < size; step++) {
      const r = upward ? size - 1 - step : step;
      for (let k = 0; k < 2; k++) {
        const c = right - k;
        if (reserved[r][c]) continue;
        const dark = index < stream.length ? stream[index] === 1 : false;
        index++;
        modules[r][c] = dark !== MASKS[mask](r, c);
      }
    }
    upward = !upward;
  }
  return { size, modules };
}

/** Standard penalty score used to choose the mask that scans most reliably. */
function penalty({ size, modules }) {
  let score = 0;
  const line = (get) => {
    for (let a = 0; a < size; a++) {
      let run = 1;
      for (let b = 1; b < size; b++) {
        if (get(a, b) === get(a, b - 1)) run++;
        else { if (run >= 5) score += run - 2; run = 1; }
      }
      if (run >= 5) score += run - 2;
      // finder-like 1:1:3:1:1 patterns with four light modules on either side
      for (let b = 0; b + 10 < size; b++) {
        const seq = [];
        for (let k = 0; k < 11; k++) seq.push(get(a, b + k) ? 1 : 0);
        const s = seq.join('');
        if (s === '10111010000' || s === '00001011101') score += 40;
      }
    }
  };
  line((r, c) => modules[r][c]);
  line((c, r) => modules[r][c]);
  for (let r = 0; r + 1 < size; r++) {
    for (let c = 0; c + 1 < size; c++) {
      const v = modules[r][c];
      if (v === modules[r][c + 1] && v === modules[r + 1][c] && v === modules[r + 1][c + 1]) score += 3;
    }
  }
  let dark = 0;
  for (const row of modules) for (const m of row) if (m) dark++;
  score += Math.floor(Math.abs((dark * 100) / (size * size) - 50) / 5) * 10;
  return score;
}

/**
 * Encode text as a QR code.
 * @param {string} text
 * @param {{mask?: number}} [options] force a mask pattern (0–7); default picks the best one
 * @returns {{size:number, modules:boolean[][], version:number, mask:number}}
 */
export function qrMatrix(text, { mask } = {}) {
  const { version, codewords } = encode(text);
  if (mask !== undefined) return { ...build(version, codewords, mask), version, mask };
  let best = null;
  for (let m = 0; m < 8; m++) {
    const candidate = build(version, codewords, m);
    const score = penalty(candidate);
    if (!best || score < best.score) best = { ...candidate, version, mask: m, score };
  }
  const { score, ...result } = best;
  return result;
}

/** Render for a terminal: black modules on a white block, two rows per text line, with a quiet zone. */
export function qrToTerminal(text) {
  const { size, modules } = qrMatrix(text);
  const quiet = 2;
  const at = (r, c) => r >= 0 && c >= 0 && r < size && c < size && modules[r][c];
  const lines = [];
  for (let r = -quiet; r < size + quiet; r += 2) {
    let line = '';
    for (let c = -quiet; c < size + quiet; c++) {
      const top = at(r, c), bottom = at(r + 1, c);
      line += top && bottom ? '█' : top ? '▀' : bottom ? '▄' : ' ';
    }
    lines.push(`\x1b[47m\x1b[30m${line}\x1b[0m`);
  }
  return lines.join('\n');
}

/** Draw onto a canvas (browser). */
export function qrToCanvas(canvas, text, { scale = 5, quiet = 3 } = {}) {
  const { size, modules } = qrMatrix(text);
  const px = (size + quiet * 2) * scale;
  canvas.width = px; canvas.height = px;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, px, px);
  ctx.fillStyle = '#000000';
  for (let r = 0; r < size; r++) for (let c = 0; c < size; c++) if (modules[r][c]) ctx.fillRect((c + quiet) * scale, (r + quiet) * scale, scale, scale);
}
