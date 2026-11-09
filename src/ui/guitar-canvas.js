/**
 * GuitarCanvas — draws the instrument and maps pointer positions to strings,
 * frets and controls.
 *
 * Geometry lives in "guitar space": x runs along the neck from the headstock
 * tip (0) to the end of the body (length), y runs across the strings from the
 * high-E side (0) to the low-E side (cross). Horizontal layouts map this 1:1
 * to the screen (nut on the left, low E at the bottom — the usual fretboard
 * diagram orientation). Vertical layouts rotate 90° clockwise (nut at the
 * top, low E on the left — chord-diagram orientation).
 *
 * Rendering is split in a cached static layer (wood, hardware) and a dynamic
 * layer (strings, fingers, overlays) redrawn on demand.
 */
import { fretDistanceFraction, SINGLE_MARKER_FRETS, DOUBLE_MARKER_FRETS, STRING_GAUGES_INCHES, STRING_WOUND, STRING_COUNT } from '../theory/fretboard.js';
import { pitchClass, pitchClassName } from '../theory/notes.js';
import { scalePositions } from '../theory/scales.js';
import { voicingBarres } from '../theory/chords.js';
import { PICKUP_DISTANCES } from '../audio/engine.js';

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const lerp = (a, b, t) => a + (b - a) * t;

/* -------------------------------------------------------------------------- */
/* Layout                                                                     */
/* -------------------------------------------------------------------------- */

// Fender-style six-in-line headstock (u 0 = tip, 1 = nut; v 0 = treble edge,
// the nut occupies v 0 .. 0.835, the bass-side edge bulges to v = 1).
const HEAD_OUTLINE = [
  [1.00, 0.00], [0.60, 0.00], [0.30, 0.035], [0.12, 0.10], [0.03, 0.22], [0.00, 0.40], [0.02, 0.60],
  [0.06, 0.80], [0.12, 0.95], [0.20, 1.00], [0.30, 0.98], [0.50, 0.93], [0.75, 0.88], [1.00, 0.835],
];
const HEAD_BASS_EDGE = HEAD_OUTLINE.slice(5).sort((a, b) => a[0] - b[0]);
/** v of the bass-side headstock edge at u (linear interpolation along the outline). */
function headEdgeV(u) {
  for (let i = 1; i < HEAD_BASS_EDGE.length; i++) {
    const [u0, v0] = HEAD_BASS_EDGE[i - 1], [u1, v1] = HEAD_BASS_EDGE[i];
    if (u <= u1) return v0 + (v1 - v0) * ((u - u0) / Math.max(1e-6, u1 - u0));
  }
  return HEAD_BASS_EDGE[HEAD_BASS_EDGE.length - 1][1];
}

/**
 * Compute every geometric quantity needed for drawing and hit-testing.
 * @param {object} o
 * @param {number} o.length  size along the neck (CSS px)
 * @param {number} o.cross   size across the strings (CSS px)
 * @param {'full'|'focus'} o.view
 * @param {number} o.fretCount frets shown in focus view
 */
export function computeLayout({ length: W, cross: H, view, fretCount = 12 }) {
  const full = view === 'full';
  const N = full ? 22 : fretCount;
  let nutX, L, bridgeX, headLen;
  if (full) {
    headLen = W * 0.15;
    nutX = W * 0.162;
    bridgeX = W * 0.89;
    L = bridgeX - nutX;
  } else {
    headLen = W * 0.028;
    nutX = W * 0.042;
    const lastX = W * 0.775;
    L = (lastX - nutX) / fretDistanceFraction(N);
    bridgeX = nutX + L;
  }
  const fretX = (n) => nutX + L * fretDistanceFraction(n);
  const fbEndX = Math.min(fretX(N) + L * 0.014, W);
  const cy = H * 0.5;
  const fbHalfNut = H * 0.265;
  const fbHalfEnd = H * 0.305;
  const taperT = (x) => clamp((x - nutX) / (fbEndX - nutX), -0.2, 1.6);
  const fbHalf = (x) => lerp(fbHalfNut, fbHalfEnd, taperT(x));
  const fbTop = (x) => cy - fbHalf(x);
  const fbBottom = (x) => cy + fbHalf(x);
  const inset = (x) => fbHalf(x) * 2 * 0.085;
  const spacing = (x) => (fbHalf(x) * 2 - 2 * inset(x)) / (STRING_COUNT - 1);
  // String index 0 (low E) is at the bottom (large y); index 5 (high E) at the top.
  const stringY = (i, x) => fbTop(x) + inset(x) + (STRING_COUNT - 1 - i) * spacing(x);

  const strum = full
    ? { x0: fbEndX + L * 0.012, x1: bridgeX - L * 0.012 }
    : { x0: W * 0.80, x1: W * 0.985 };
  strum.y0 = stringY(5, strum.x0) - spacing(strum.x0) * 1.6;
  strum.y1 = stringY(0, strum.x1) + spacing(strum.x1) * 1.6;
  strum.xm = (strum.x0 + strum.x1) / 2;

  const body = full ? {
    x0: fretX(16) - L * 0.01,
    x1: W,
    y0: H * 0.015,
    y1: H * 0.985,
  } : null;

  // Headstock box: the nut spans v = 0 .. 0.835 of it; the Fender-style hook
  // bulges past the nut on the bass side (large y).
  const head = {
    x0: full ? W * 0.008 : -W * 0.05,
    x1: nutX,
    y0: cy - fbHalfNut * 1.02,
    y1: cy + fbHalfNut * 1.4,
  };
  // Tuner posts: six in a line that follows the bass-side edge (as on a real
  // Fender headstock); post 0 (nearest the tip) takes the high E, post 5 the low E.
  const posts = [];
  for (let k = 0; k < STRING_COUNT; k++) {
    const u = 0.17 + k * 0.13;
    const v = headEdgeV(u) - 0.16;
    posts.push({ x: head.x0 + (head.x1 - head.x0) * u, y: head.y0 + (head.y1 - head.y0) * v });
  }

  const pickups = full ? ['neck', 'middle', 'bridge'].map((name) => {
    const x = bridgeX - PICKUP_DISTANCES[name] * L;
    return { name, x, w: L * 0.021, y0: stringY(5, x) - spacing(x) * 0.75, y1: stringY(0, x) + spacing(x) * 0.75, angle: name === 'bridge' ? -0.09 : 0 };
  }) : [];

  const knobR = H * 0.046;
  const knobs = full ? [
    { id: 'volume', label: 'VOLUME', x: bridgeX - L * 0.055, y: cy - H * 0.385, r: knobR },
    { id: 'tone', label: 'TONE', x: bridgeX + L * 0.03, y: cy - H * 0.33, r: knobR },
  ] : [];
  const selector = full ? { x: fretX(22) + L * 0.075, y: cy - H * 0.375, w: L * 0.09, h: H * 0.05 } : null;

  const cellWidth = (fret) => (fret <= 0 ? L * 0.02 : fretX(fret) - fretX(fret - 1));
  const positionCenter = (string, fret) => {
    const x = fret <= 0 ? nutX - L * 0.012 : (fretX(fret - 1) + fretX(fret)) / 2 + cellWidth(fret) * 0.08;
    return { x, y: stringY(string, x) };
  };

  return {
    W, H, full, N, nutX, L, bridgeX, headLen, fretX, fbEndX, cy, fbTop, fbBottom, fbHalf, inset, spacing, stringY,
    strum, body, head, posts, pickups, knobs, selector, cellWidth, positionCenter,
    stringEndX: full ? bridgeX : W + 4,
  };
}

/* -------------------------------------------------------------------------- */
/* Drawing helpers                                                            */
/* -------------------------------------------------------------------------- */

/** Catmull-Rom smoothed closed/open path through points [{x,y}]. */
function smoothPath(ctx, pts, closed = true, tension = 0.5) {
  const n = pts.length;
  if (n < 2) return;
  const p = (i) => pts[closed ? (i + n) % n : clamp(i, 0, n - 1)];
  ctx.beginPath();
  ctx.moveTo(pts[0].x, pts[0].y);
  const count = closed ? n : n - 1;
  for (let i = 0; i < count; i++) {
    const p0 = p(i - 1), p1 = p(i), p2 = p(i + 1), p3 = p(i + 2);
    const c1x = p1.x + (p2.x - p0.x) / 6 * tension * 2;
    const c1y = p1.y + (p2.y - p0.y) / 6 * tension * 2;
    const c2x = p2.x - (p3.x - p1.x) / 6 * tension * 2;
    const c2y = p2.y - (p3.y - p1.y) / 6 * tension * 2;
    ctx.bezierCurveTo(c1x, c1y, c2x, c2y, p2.x, p2.y);
  }
  if (closed) ctx.closePath();
}

function roundRect(ctx, x, y, w, h, r) {
  const rr = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

/** Deterministic pseudo-random for textures. */
function seeded(seed) {
  let s = seed >>> 0 || 1;
  return () => { s ^= s << 13; s >>>= 0; s ^= s >>> 17; s ^= s << 5; s >>>= 0; return s / 4294967296; };
}

// Stratocaster-like body outline, normalised to a unit box (u along the neck, v across; v = 0 is the treble side).
const BODY_OUTLINE = [
  [0.21, 0.37], [0.13, 0.24], [0.07, 0.11], [0.12, 0.03], [0.25, 0.02], [0.40, 0.085], [0.50, 0.17],
  [0.62, 0.085], [0.80, 0.02], [0.93, 0.10], [1.00, 0.36], [1.00, 0.62], [0.95, 0.86], [0.85, 0.975],
  [0.70, 1.00], [0.56, 0.93], [0.47, 0.81], [0.36, 0.86], [0.22, 0.985], [0.10, 1.00], [0.02, 0.91],
  [0.045, 0.77], [0.14, 0.66], [0.21, 0.62],
];
// Pickguard outline (same box), hugging the neck pocket and pickups.
const PICKGUARD_OUTLINE = [
  [0.19, 0.34], [0.12, 0.24], [0.10, 0.15], [0.17, 0.10], [0.30, 0.12], [0.42, 0.17], [0.52, 0.19],
  [0.64, 0.17], [0.72, 0.13], [0.76, 0.22], [0.75, 0.35], [0.72, 0.52], [0.70, 0.70], [0.66, 0.86],
  [0.55, 0.91], [0.42, 0.85], [0.30, 0.84], [0.17, 0.92], [0.08, 0.86], [0.08, 0.73], [0.15, 0.63], [0.19, 0.58],
];


const STRING_COLORS = {
  wound: ['#c9b88a', '#8f7d55'],
  plain: ['#f2f2f2', '#9ea3a8'],
};

/* -------------------------------------------------------------------------- */
/* GuitarCanvas                                                               */
/* -------------------------------------------------------------------------- */

export class GuitarCanvas {
  /**
   * @param {HTMLCanvasElement} canvas
   * @param {import('../state.js').AppState} state
   */
  constructor(canvas, state) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.state = state;
    this.dpr = 1;
    this.orientation = 'horizontal';
    this.view = 'full';
    this.fretCount = 12;
    this.layout = null;
    this.staticLayer = document.createElement('canvas');
    this.staticDirty = true;
    this.dirty = true;
    this.hover = null;
    this.controls = { volume: 0.8, tone: 0.7, pickup: 4 };
    this.vib = Array.from({ length: STRING_COUNT }, () => ({ amp: 0, t0: 0, tau: 1.2, phase: 0, freq: 6 }));
    this.pressed = Array.from({ length: STRING_COUNT }, () => 0); // time of last pluck flash
    this.strumHint = true;
    this.lastFrame = performance.now();
    this.rafId = 0;
    this.frame = this.frame.bind(this);
    this.resize();
    for (const ev of ['tuning', 'capo', 'option', 'chord', 'scale', 'highlight', 'finger', 'played']) {
      state.addEventListener(ev, () => this.requestRender());
    }
    state.addEventListener('option', (e) => {
      if (e.detail.key === 'view' || e.detail.key === 'orientation') this.resize();
      if (e.detail.key === 'fretNumbers' || e.detail.key === 'noteNames') this.staticDirty = true;
    });
  }

  /* ---------------- sizing ---------------- */

  cssSize() {
    const rect = this.canvas.getBoundingClientRect();
    return { w: Math.max(50, rect.width), h: Math.max(50, rect.height) };
  }

  resolveOrientation() {
    const o = this.state.options.orientation;
    if (o !== 'auto') return o;
    return window.innerHeight > window.innerWidth && window.innerWidth < 760 ? 'vertical' : 'horizontal';
  }

  resolveView(length) {
    const v = this.state.options.view;
    if (v === 'full') return { view: 'full', fretCount: 22 };
    if (v === '12' || v === '15') return { view: 'focus', fretCount: Number(v) };
    if (length >= 1050) return { view: 'full', fretCount: 22 };
    if (length >= 760) return { view: 'focus', fretCount: 15 };
    return { view: 'focus', fretCount: 12 };
  }

  resize() {
    const { w, h } = this.cssSize();
    this.dpr = Math.min(3, window.devicePixelRatio || 1);
    this.cssW = w; this.cssH = h;
    this.canvas.width = Math.round(w * this.dpr);
    this.canvas.height = Math.round(h * this.dpr);
    this.staticLayer.width = this.canvas.width;
    this.staticLayer.height = this.canvas.height;
    this.orientation = this.resolveOrientation();
    const length = this.orientation === 'vertical' ? h : w;
    const cross = this.orientation === 'vertical' ? w : h;
    const { view, fretCount } = this.resolveView(length);
    this.view = view; this.fretCount = fretCount;
    this.layout = computeLayout({ length, cross, view, fretCount });
    this.staticDirty = true;
    this.requestRender();
  }

  /* ---------------- coordinate mapping ---------------- */

  /** Apply the guitar-space transform (including device pixel ratio) to a context. */
  applyTransform(ctx) {
    const d = this.dpr;
    if (this.orientation === 'vertical') ctx.setTransform(0, d, -d, 0, this.layout.H * d, 0);
    else ctx.setTransform(d, 0, 0, d, 0, 0);
  }

  /** Guitar-space point for a client (viewport) coordinate. */
  toGuitar(clientX, clientY) {
    const rect = this.canvas.getBoundingClientRect();
    const sx = clientX - rect.left;
    const sy = clientY - rect.top;
    if (this.orientation === 'vertical') return { x: sy, y: this.layout.H - sx };
    return { x: sx, y: sy };
  }

  /** Screen (CSS px, relative to the canvas) point for a guitar-space coordinate. */
  toScreen(gx, gy) {
    if (this.orientation === 'vertical') return { x: this.layout.H - gy, y: gx };
    return { x: gx, y: gy };
  }

  /** Screen rectangle of the canvas, for positioning DOM elements over it. */
  positionCenterScreen(string, fret) {
    const p = this.layout.positionCenter(string, fret);
    return this.toScreen(p.x, p.y);
  }

  /**
   * Classify a guitar-space point.
   * @returns {{zone:string, string?:number, fret?:number, pickPosition?:number, knob?:object, position?:number}}
   */
  hitTest(gx, gy) {
    const L = this.layout;
    // Body controls first (full view only).
    for (const k of L.knobs) {
      if (Math.hypot(gx - k.x, gy - k.y) <= k.r * 1.35) return { zone: 'knob', knob: k };
    }
    if (L.selector) {
      const s = L.selector;
      if (gx >= s.x - s.w * 0.6 && gx <= s.x + s.w * 0.6 && gy >= s.y - s.h * 1.4 && gy <= s.y + s.h * 1.4) {
        const t = clamp((gx - (s.x - s.w / 2)) / s.w, 0, 0.999);
        // Lever toward the neck = neck pickup (position 5), toward the bridge = position 1.
        return { zone: 'selector', position: 5 - Math.floor(t * 5) };
      }
    }
    const sp = L.spacing(gx);
    const nearestString = (x, y, tolerance) => {
      let best = -1, bestD = Infinity;
      for (let i = 0; i < STRING_COUNT; i++) {
        const d = Math.abs(y - L.stringY(i, x));
        if (d < bestD) { bestD = d; best = i; }
      }
      return bestD <= tolerance ? best : -1;
    };
    // Strum zone
    const st = L.strum;
    if (gx >= st.x0 && gx <= st.x1 && gy >= st.y0 && gy <= st.y1) {
      const string = nearestString(gx, gy, sp * 0.5);
      const pickPosition = clamp((L.bridgeX - gx) / L.L, 0.03, 0.45);
      return { zone: 'strum', string, pickPosition, x: gx, y: gy };
    }
    // Fretboard
    if (gx >= L.nutX - L.L * 0.004 && gx <= L.fretX(L.N) && gy >= L.fbTop(gx) - sp * 0.4 && gy <= L.fbBottom(gx) + sp * 0.4) {
      const string = nearestString(gx, gy, sp * 0.62);
      let fret = 1;
      while (fret < L.N && gx > L.fretX(fret)) fret++;
      if (string < 0) return { zone: 'neck', fret };
      return { zone: 'fretboard', string, fret };
    }
    // Open-string zone over the nut/headstock: plucks the open string.
    if (gx < L.nutX && gx > L.nutX - L.L * 0.05 && gy >= L.fbTop(L.nutX) && gy <= L.fbBottom(L.nutX)) {
      const string = nearestString(L.nutX, gy, sp * 0.55);
      if (string >= 0) return { zone: 'nut', string };
    }
    return { zone: 'none' };
  }

  /* ---------------- dynamic state ---------------- */

  setHover(hit) {
    const changed = JSON.stringify(hit) !== JSON.stringify(this.hover);
    this.hover = hit;
    if (changed) this.requestRender();
  }

  setControls(partial) {
    Object.assign(this.controls, partial);
    this.requestRender();
  }

  pluckVisual(string, velocity = 0.8) {
    const v = this.vib[string];
    const sp = this.layout.spacing(this.layout.strum.xm);
    v.amp = clamp(sp * (0.12 + 0.42 * velocity), 1.5, sp * 0.52);
    v.t0 = performance.now();
    v.tau = 0.7 + 0.55 * (1 - string / 5); // thick strings swing longer
    v.freq = 5.5 + (5 - string) * 1.4;
    v.phase = Math.random() * Math.PI * 2;
    this.pressed[string] = v.t0;
    this.strumHint = false;
    this.requestRender();
  }

  stopVisual(string) {
    const v = this.vib[string];
    const now = performance.now();
    v.amp = this.currentAmp(string, now) * 0.6;
    v.t0 = now;
    v.tau = 0.09;
    this.requestRender();
  }

  currentAmp(string, now) {
    const v = this.vib[string];
    if (v.amp <= 0) return 0;
    return v.amp * Math.exp(-(now - v.t0) / 1000 / v.tau);
  }

  requestRender() {
    this.dirty = true;
    if (!this.rafId) this.rafId = requestAnimationFrame(this.frame);
  }

  frame(now) {
    this.rafId = 0;
    const animating = this.vib.some((v, i) => this.currentAmp(i, now) > 0.4) || this.pressed.some((t) => now - t < 2600) || this.strumHint;
    if (this.dirty || animating) {
      this.render(now);
      this.dirty = false;
    }
    if (animating) this.rafId = requestAnimationFrame(this.frame);
  }

  /* ---------------- rendering ---------------- */

  render(now = performance.now()) {
    if (this.staticDirty) { this.renderStatic(); this.staticDirty = false; }
    const ctx = this.ctx;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    ctx.drawImage(this.staticLayer, 0, 0);
    this.applyTransform(ctx);
    this.drawOverlays(ctx);
    this.drawControls(ctx);
    this.drawStrings(ctx, now);
    this.drawChordDots(ctx);
    this.drawFingers(ctx);
    this.drawHover(ctx);
    this.drawHints(ctx, now);
  }

  renderStatic() {
    const ctx = this.staticLayer.getContext('2d');
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.staticLayer.width, this.staticLayer.height);
    this.applyTransform(ctx);
    const L = this.layout;
    this.drawBackground(ctx);
    if (L.full) this.drawBody(ctx);
    else this.drawFocusPanel(ctx);
    this.drawHeadstock(ctx);
    this.drawNeck(ctx);
    if (L.full) { this.drawPickups(ctx); this.drawBridge(ctx); }
    this.drawFretNumbers(ctx);
  }

  /** Draw text unrotated at a guitar-space anchor. */
  text(ctx, gx, gy, str, { font = '600 12px system-ui, sans-serif', color = '#ddd', align = 'center', baseline = 'middle', alpha = 1 } = {}) {
    const p = this.toScreen(gx, gy);
    ctx.save();
    ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    ctx.globalAlpha = alpha;
    ctx.font = font;
    ctx.fillStyle = color;
    ctx.textAlign = align;
    ctx.textBaseline = baseline;
    ctx.fillText(str, p.x, p.y);
    ctx.restore();
  }

  drawBackground(ctx) {
    const { W, H } = this.layout;
    const g = ctx.createRadialGradient(W * 0.55, H * 0.5, H * 0.1, W * 0.5, H * 0.5, W * 0.7);
    g.addColorStop(0, '#1a1d24');
    g.addColorStop(1, '#0c0d11');
    ctx.fillStyle = g;
    ctx.fillRect(-10, -10, W + 20, H + 20);
    // Soft floor shadow under the instrument
    const sh = ctx.createRadialGradient(W * 0.55, H * 0.55, H * 0.05, W * 0.55, H * 0.55, W * 0.5);
    sh.addColorStop(0, 'rgba(0,0,0,0.5)');
    sh.addColorStop(0.5, 'rgba(0,0,0,0.25)');
    sh.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = sh;
    ctx.fillRect(-10, -10, W + 20, H + 20);
  }

  bodyPoint([u, v]) {
    const b = this.layout.body;
    return { x: b.x0 + (b.x1 - b.x0) * u, y: b.y0 + (b.y1 - b.y0) * v };
  }

  drawBody(ctx) {
    const L = this.layout;
    const b = L.body;
    const pts = BODY_OUTLINE.map((p) => this.bodyPoint(p));
    // Shadow
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.65)';
    ctx.shadowBlur = 24;
    ctx.shadowOffsetX = 6;
    ctx.shadowOffsetY = 12;
    smoothPath(ctx, pts, true);
    ctx.fillStyle = '#4a2a16';
    ctx.fill();
    ctx.restore();
    // Sunburst finish
    smoothPath(ctx, pts, true);
    const cx = b.x0 + (b.x1 - b.x0) * 0.55, cy = L.cy;
    const g = ctx.createRadialGradient(cx, cy, (b.y1 - b.y0) * 0.1, cx, cy, (b.y1 - b.y0) * 0.75);
    g.addColorStop(0, '#e2b35f');
    g.addColorStop(0.45, '#b4652a');
    g.addColorStop(0.8, '#5a2412');
    g.addColorStop(1, '#1b0c07');
    ctx.fillStyle = g;
    ctx.fill();
    // Wood grain
    ctx.save();
    ctx.clip();
    const rnd = seeded(42);
    ctx.globalAlpha = 0.08;
    for (let i = 0; i < 60; i++) {
      const y = b.y0 + rnd() * (b.y1 - b.y0);
      ctx.strokeStyle = rnd() > 0.5 ? '#000' : '#fff';
      ctx.lineWidth = 0.6 + rnd() * 1.4;
      ctx.beginPath();
      ctx.moveTo(b.x0, y);
      ctx.bezierCurveTo(b.x0 + (b.x1 - b.x0) * 0.3, y + (rnd() - 0.5) * 12, b.x0 + (b.x1 - b.x0) * 0.7, y + (rnd() - 0.5) * 12, b.x1, y + (rnd() - 0.5) * 6);
      ctx.stroke();
    }
    // Gloss
    ctx.globalAlpha = 1;
    const gloss = ctx.createLinearGradient(0, b.y0, 0, b.y1);
    gloss.addColorStop(0, 'rgba(255,255,255,0.16)');
    gloss.addColorStop(0.35, 'rgba(255,255,255,0.03)');
    gloss.addColorStop(0.6, 'rgba(255,255,255,0)');
    gloss.addColorStop(1, 'rgba(0,0,0,0.25)');
    ctx.fillStyle = gloss;
    ctx.fillRect(b.x0 - 10, b.y0, b.x1 - b.x0 + 20, b.y1 - b.y0);
    ctx.restore();
    // Edge binding highlight
    smoothPath(ctx, pts, true);
    ctx.strokeStyle = 'rgba(255,220,160,0.25)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    // Pickguard (3-ply parchment)
    const pg = PICKGUARD_OUTLINE.map((p) => this.bodyPoint(p));
    smoothPath(ctx, pg, true);
    ctx.fillStyle = '#0d0c0a';
    ctx.lineWidth = 3;
    ctx.strokeStyle = '#0d0c0a';
    ctx.stroke();
    const pgG = ctx.createLinearGradient(b.x0, b.y0, b.x1, b.y1);
    pgG.addColorStop(0, '#efe9d6');
    pgG.addColorStop(1, '#d9d1b8');
    ctx.fillStyle = pgG;
    ctx.fill();
    smoothPath(ctx, pg, true);
    ctx.strokeStyle = 'rgba(255,255,255,0.7)';
    ctx.lineWidth = 1;
    ctx.stroke();
    // Pickguard screws
    ctx.fillStyle = '#9a9a9a';
    for (const u of [[0.12, 0.17], [0.71, 0.145], [0.73, 0.52], [0.66, 0.84], [0.10, 0.84], [0.42, 0.17], [0.44, 0.86]]) {
      const p = this.bodyPoint(u);
      ctx.beginPath(); ctx.arc(p.x, p.y, 2.2, 0, Math.PI * 2); ctx.fill();
    }
    // Output jack plate
    const jack = this.bodyPoint([0.86, 0.72]);
    ctx.fillStyle = '#b9b9b9';
    ctx.beginPath(); ctx.ellipse(jack.x, jack.y, 11, 15, 0.4, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#111';
    ctx.beginPath(); ctx.arc(jack.x, jack.y, 4.5, 0, Math.PI * 2); ctx.fill();
    // Strap button on the tail
    const tail = this.bodyPoint([0.995, 0.5]);
    ctx.fillStyle = '#c8c8c8';
    ctx.beginPath(); ctx.arc(tail.x, tail.y, 4, 0, Math.PI * 2); ctx.fill();
  }

  /** Focus view: a dark pickguard-like panel where the strum zone sits. */
  drawFocusPanel(ctx) {
    const L = this.layout;
    const st = L.strum;
    const x0 = L.fbEndX + 2, x1 = L.W + 10;
    const g = ctx.createLinearGradient(x0, 0, x1, 0);
    g.addColorStop(0, '#2a1a12');
    g.addColorStop(0.3, '#4a2416');
    g.addColorStop(1, '#2c160e');
    ctx.fillStyle = g;
    roundRect(ctx, x0, L.fbTop(L.fbEndX) - L.spacing(L.fbEndX) * 1.6, x1 - x0, L.fbHalf(L.fbEndX) * 2 + L.spacing(L.fbEndX) * 3.2, 16);
    ctx.fill();
    // a single pickup under the strum zone
    const px = st.xm;
    const y0 = st.y0 + 4, y1 = st.y1 - 4;
    this.drawPickupShape(ctx, px, y0, y1, L.spacing(px) * 0.9, 0);
  }

  drawHeadstock(ctx) {
    const L = this.layout;
    const h = L.head;
    const pts = HEAD_OUTLINE.map(([u, v]) => ({ x: h.x0 + (h.x1 - h.x0) * u, y: h.y0 + (h.y1 - h.y0) * v }));
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.55)';
    ctx.shadowBlur = 14;
    ctx.shadowOffsetX = 3;
    ctx.shadowOffsetY = 6;
    smoothPath(ctx, pts, true, 0.35);
    ctx.fillStyle = '#c9a15a';
    ctx.fill();
    ctx.restore();
    smoothPath(ctx, pts, true, 0.35);
    const g = ctx.createLinearGradient(0, h.y0, 0, h.y1);
    g.addColorStop(0, '#e3c784');
    g.addColorStop(0.5, '#cfa75e');
    g.addColorStop(1, '#a9803d');
    ctx.fillStyle = g;
    ctx.fill();
    ctx.strokeStyle = 'rgba(60,35,10,0.6)';
    ctx.lineWidth = 1.2;
    ctx.stroke();
    if (!L.full) return;
    const hw = h.x1 - h.x0, hh = h.y1 - h.y0;
    // Logo
    this.text(ctx, h.x0 + hw * 0.5, h.y0 + hh * 0.2, 'Fable', { font: `italic 700 ${Math.max(11, hh * 0.09)}px Georgia, serif`, color: 'rgba(40,24,8,0.85)' });
    this.text(ctx, h.x0 + hw * 0.5, h.y0 + hh * 0.2 + Math.max(10, hh * 0.07), 'STRATOCASTER STYLE', { font: `600 ${Math.max(5, hh * 0.03)}px system-ui, sans-serif`, color: 'rgba(40,24,8,0.6)' });
    // String tree holding the two thin strings down
    const treeX = h.x0 + hw * 0.42;
    ctx.fillStyle = '#d0d0d0';
    ctx.beginPath(); ctx.arc(treeX, (L.stringY(5, L.nutX) + L.stringY(4, L.nutX)) / 2 - hh * 0.02, 3.2, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#6a6a6a';
    ctx.beginPath(); ctx.arc(treeX, (L.stringY(5, L.nutX) + L.stringY(4, L.nutX)) / 2 - hh * 0.02, 1.4, 0, Math.PI * 2); ctx.fill();
    // Tuners: posts on the face, shafts through the head to buttons on the bass edge.
    const btnLen = Math.max(14, hh * 0.1), btnW = Math.max(7, hh * 0.05);
    for (const p of L.posts) {
      const u = (p.x - h.x0) / hw;
      const edgeY = h.y0 + hh * headEdgeV(u) - 2;
      ctx.strokeStyle = '#8c8c8c';
      ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(p.x, edgeY + 4); ctx.stroke();
      const bg = ctx.createLinearGradient(p.x - btnW, edgeY, p.x + btnW, edgeY + btnLen);
      bg.addColorStop(0, '#f5f5f5'); bg.addColorStop(0.5, '#a8a8a8'); bg.addColorStop(1, '#e6e6e6');
      ctx.fillStyle = bg;
      roundRect(ctx, p.x - btnW / 2, edgeY + 2, btnW, btnLen, btnW / 3);
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.4)'; ctx.lineWidth = 1; ctx.stroke();
      // Post + bushing
      ctx.fillStyle = '#9d9d9d';
      ctx.beginPath(); ctx.arc(p.x, p.y, Math.max(4.5, hh * 0.028), 0, Math.PI * 2); ctx.fill();
      ctx.fillStyle = '#e9e9e9';
      ctx.beginPath(); ctx.arc(p.x, p.y, Math.max(2.5, hh * 0.016), 0, Math.PI * 2); ctx.fill();
    }
  }

  drawNeck(ctx) {
    const L = this.layout;
    const x0 = L.nutX, x1 = L.fbEndX;
    // Fretboard (rosewood) with tapered edges
    ctx.beginPath();
    ctx.moveTo(x0, L.fbTop(x0));
    ctx.lineTo(x1, L.fbTop(x1));
    ctx.lineTo(x1, L.fbBottom(x1));
    ctx.lineTo(x0, L.fbBottom(x0));
    ctx.closePath();
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.7)';
    ctx.shadowBlur = 14;
    ctx.shadowOffsetY = 4;
    ctx.fillStyle = '#2c1a11';
    ctx.fill();
    ctx.restore();
    ctx.save();
    ctx.clip();
    const g = ctx.createLinearGradient(0, L.fbTop(x0), 0, L.fbBottom(x0));
    g.addColorStop(0, '#2a160e');
    g.addColorStop(0.4, '#4a2b1b');
    g.addColorStop(0.6, '#45281a');
    g.addColorStop(1, '#22120b');
    ctx.fillStyle = g;
    ctx.fillRect(x0, L.fbTop(x0) - 2, x1 - x0, L.fbHalf(x1) * 2 + 8);
    // Grain
    const rnd = seeded(7);
    for (let i = 0; i < 90; i++) {
      const y = L.fbTop(x0) + rnd() * L.fbHalf(x1) * 2.1;
      ctx.strokeStyle = rnd() > 0.5 ? 'rgba(0,0,0,0.25)' : 'rgba(255,200,150,0.07)';
      ctx.lineWidth = 0.5 + rnd();
      ctx.beginPath();
      ctx.moveTo(x0, y);
      ctx.bezierCurveTo(x0 + (x1 - x0) * 0.3, y + (rnd() - 0.5) * 6, x0 + (x1 - x0) * 0.7, y + (rnd() - 0.5) * 6, x1, y + (rnd() - 0.5) * 4);
      ctx.stroke();
    }
    ctx.restore();
    // Inlays
    const inlayR = Math.max(3, L.spacing(x0) * 0.22);
    const drawInlay = (x, y) => {
      const ig = ctx.createRadialGradient(x - inlayR * 0.3, y - inlayR * 0.3, inlayR * 0.1, x, y, inlayR);
      ig.addColorStop(0, '#fbf7ea');
      ig.addColorStop(1, '#d9d0b4');
      ctx.fillStyle = ig;
      ctx.beginPath(); ctx.arc(x, y, inlayR, 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.35)'; ctx.lineWidth = 0.8; ctx.stroke();
    };
    for (const f of SINGLE_MARKER_FRETS) {
      if (f > L.N) continue;
      const x = (L.fretX(f - 1) + L.fretX(f)) / 2;
      drawInlay(x, L.cy);
    }
    for (const f of DOUBLE_MARKER_FRETS) {
      if (f > L.N) continue;
      const x = (L.fretX(f - 1) + L.fretX(f)) / 2;
      drawInlay(x, (L.stringY(1, x) + L.stringY(2, x)) / 2);
      drawInlay(x, (L.stringY(3, x) + L.stringY(4, x)) / 2);
    }
    // Frets (nickel-silver)
    const fretW = Math.max(2.2, L.L * 0.0045);
    for (let n = 1; n <= L.N; n++) {
      const x = L.fretX(n);
      const fg = ctx.createLinearGradient(x - fretW, 0, x + fretW, 0);
      fg.addColorStop(0, '#6f7378');
      fg.addColorStop(0.35, '#f4f6f8');
      fg.addColorStop(0.6, '#c3c7cc');
      fg.addColorStop(1, '#5a5e63');
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      ctx.fillRect(x - fretW / 2 + 1.2, L.fbTop(x), fretW, L.fbHalf(x) * 2);
      ctx.fillStyle = fg;
      roundRect(ctx, x - fretW / 2, L.fbTop(x) - 0.5, fretW, L.fbHalf(x) * 2 + 1, fretW / 2);
      ctx.fill();
    }
    // Nut (bone)
    const nutW = Math.max(4, L.L * 0.008);
    const ng = ctx.createLinearGradient(x0 - nutW, 0, x0 + nutW, 0);
    ng.addColorStop(0, '#d8cfb4'); ng.addColorStop(0.5, '#f7f1dd'); ng.addColorStop(1, '#bfb393');
    ctx.fillStyle = ng;
    ctx.fillRect(x0 - nutW, L.fbTop(x0) - 1, nutW * 1.6, L.fbHalf(x0) * 2 + 2);
    ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 1;
    ctx.strokeRect(x0 - nutW, L.fbTop(x0) - 1, nutW * 1.6, L.fbHalf(x0) * 2 + 2);
    // Fretboard edge highlight
    ctx.strokeStyle = 'rgba(255,255,255,0.08)';
    ctx.beginPath(); ctx.moveTo(x0, L.fbTop(x0)); ctx.lineTo(x1, L.fbTop(x1)); ctx.stroke();
  }

  drawPickupShape(ctx, x, y0, y1, w, angle) {
    ctx.save();
    ctx.translate(x, (y0 + y1) / 2);
    ctx.rotate(angle);
    const h = y1 - y0;
    ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 6; ctx.shadowOffsetY = 2;
    ctx.fillStyle = '#efe9da';
    roundRect(ctx, -w / 2, -h / 2, w, h, w / 2);
    ctx.fill();
    ctx.shadowColor = 'transparent';
    ctx.strokeStyle = 'rgba(0,0,0,0.35)'; ctx.lineWidth = 1; ctx.stroke();
    // pole pieces
    const poleR = Math.max(1.8, w * 0.17);
    for (let i = 0; i < STRING_COUNT; i++) {
      const t = (i + 0.5) / STRING_COUNT;
      const py = -h / 2 + h * (0.06 + 0.88 * t);
      const pg = ctx.createRadialGradient(-1, py - 1, 0.5, 0, py, poleR);
      pg.addColorStop(0, '#d8d8d8'); pg.addColorStop(1, '#4a4a4a');
      ctx.fillStyle = pg;
      ctx.beginPath(); ctx.arc(0, py, poleR, 0, Math.PI * 2); ctx.fill();
    }
    // mounting screws
    ctx.fillStyle = '#8a8a8a';
    ctx.beginPath(); ctx.arc(0, -h / 2 - 0, 1.8, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(0, h / 2, 1.8, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
  }

  drawPickups(ctx) {
    const L = this.layout;
    for (const p of L.pickups) {
      // pole pieces must line up with the strings: pass real string y-range
      this.drawPickupShape(ctx, p.x, p.y0, p.y1, p.w, p.angle);
    }
  }

  drawBridge(ctx) {
    const L = this.layout;
    const x = L.bridgeX;
    const sp = L.spacing(x);
    const y0 = L.stringY(5, x) - sp * 1.1, y1 = L.stringY(0, x) + sp * 1.1;
    const w = L.L * 0.04;
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 8; ctx.shadowOffsetY = 3;
    const g = ctx.createLinearGradient(x - w, 0, x + w, 0);
    g.addColorStop(0, '#9c9fa3'); g.addColorStop(0.5, '#e9ebee'); g.addColorStop(1, '#7d8084');
    ctx.fillStyle = g;
    roundRect(ctx, x - w * 0.35, y0, w, y1 - y0, 3);
    ctx.fill();
    ctx.restore();
    ctx.strokeStyle = 'rgba(0,0,0,0.4)'; ctx.lineWidth = 1;
    roundRect(ctx, x - w * 0.35, y0, w, y1 - y0, 3); ctx.stroke();
    // Saddles
    for (let i = 0; i < STRING_COUNT; i++) {
      const y = L.stringY(i, x);
      ctx.fillStyle = '#c9ccd0';
      roundRect(ctx, x - w * 0.2, y - sp * 0.3, w * 0.55, sp * 0.6, 2);
      ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.stroke();
      ctx.fillStyle = '#4d4f52';
      ctx.beginPath(); ctx.arc(x + w * 0.3, y, 1.6, 0, Math.PI * 2); ctx.fill();
    }
    // Tremolo arm socket
    ctx.fillStyle = '#3a3a3a';
    ctx.beginPath(); ctx.arc(x + w * 0.45, y0 + sp * 0.5, 3.5, 0, Math.PI * 2); ctx.fill();
  }

  drawFretNumbers(ctx) {
    if (!this.state.options.fretNumbers) return;
    const L = this.layout;
    const y = L.fbBottom(L.fbEndX) + Math.max(10, L.spacing(L.nutX) * 0.5);
    for (let n = 1; n <= L.N; n++) {
      const x = (L.fretX(n - 1) + L.fretX(n)) / 2;
      const marker = SINGLE_MARKER_FRETS.includes(n) || DOUBLE_MARKER_FRETS.includes(n) || n === 1;
      this.text(ctx, x, L.fbBottom(x) + (y - L.fbBottom(L.fbEndX)), String(n), { font: `${marker ? 700 : 500} 11px system-ui, sans-serif`, color: marker ? '#c9ccd3' : '#6c7079' });
    }
  }

  /* ---------------- dynamic layers ---------------- */

  drawOverlays(ctx) {
    const L = this.layout;
    const st = this.state;
    const flats = st.options.flats;
    const sp = L.spacing(L.nutX);
    const r = Math.max(5, sp * 0.3);
    const drawn = new Set();
    const key = (s, f) => s * 100 + f;
    // Scale positions
    if (st.scale) {
      for (const p of scalePositions(st.fretboard, st.scale.scale, st.scale.rootPc)) {
        if (p.fret > L.N) continue;
        const c = L.positionCenter(p.string, p.fret);
        const rr = p.fret === 0 ? r * 0.85 : r;
        ctx.fillStyle = p.isRoot ? 'rgba(245,158,11,0.95)' : 'rgba(56,189,248,0.82)';
        ctx.beginPath(); ctx.arc(c.x, c.y, rr, 0, Math.PI * 2); ctx.fill();
        const label = st.options.scaleLabels === 'names' ? pitchClassName(p.pitchClass, { flats }) : p.degree;
        this.text(ctx, c.x, c.y, label, { font: `700 ${Math.max(8, rr * 1.05)}px system-ui, sans-serif`, color: '#0b0d12' });
        drawn.add(key(p.string, p.fret));
      }
    }
    // Highlighted pitch class
    if (st.highlightPc !== null) {
      for (const p of st.fretboard.positionsOfPitchClass(st.highlightPc)) {
        if (p.fret > L.N) continue;
        const c = L.positionCenter(p.string, p.fret);
        ctx.fillStyle = 'rgba(16,185,129,0.9)';
        ctx.beginPath(); ctx.arc(c.x, c.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = 'rgba(255,255,255,0.8)'; ctx.lineWidth = 1.5; ctx.stroke();
        this.text(ctx, c.x, c.y, pitchClassName(st.highlightPc, { flats }), { font: `700 ${Math.max(8, r * 1.0)}px system-ui, sans-serif`, color: '#06120d' });
        drawn.add(key(p.string, p.fret));
      }
    }
    // All note names
    if (st.options.noteNames === 'all') {
      for (let s = 0; s < STRING_COUNT; s++) {
        for (let f = 0; f <= L.N; f++) {
          if (drawn.has(key(s, f))) continue;
          const c = L.positionCenter(s, f);
          const name = st.fretboard.noteNameAt(s, f, { flats }).replace(/-?\d+$/, '');
          this.text(ctx, c.x, c.y - (f === 0 ? 0 : 0), name, { font: `600 ${Math.max(8, sp * 0.32)}px system-ui, sans-serif`, color: 'rgba(230,225,210,0.55)' });
        }
      }
    }
    // Capo
    if (st.capo > 0 && st.capo <= L.N) {
      const x = L.fretX(st.capo) - L.cellWidth(st.capo) * 0.28;
      const w = Math.max(8, L.cellWidth(st.capo) * 0.32);
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 6;
      const g = ctx.createLinearGradient(x - w / 2, 0, x + w / 2, 0);
      g.addColorStop(0, '#1f2328'); g.addColorStop(0.5, '#4b5159'); g.addColorStop(1, '#1f2328');
      ctx.fillStyle = g;
      roundRect(ctx, x - w / 2, L.fbTop(x) - sp * 0.6, w, L.fbHalf(x) * 2 + sp * 1.2, 4);
      ctx.fill();
      ctx.restore();
      ctx.fillStyle = '#d14b3a';
      roundRect(ctx, x - w / 2 + 1, L.fbTop(x) - 1, w - 2, L.fbHalf(x) * 2 + 2, 3);
      ctx.fill();
    }
  }

  drawControls(ctx) {
    const L = this.layout;
    for (const k of L.knobs) {
      const value = this.controls[k.id];
      const r = k.r;
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 8; ctx.shadowOffsetY = 3;
      const g = ctx.createRadialGradient(k.x - r * 0.3, k.y - r * 0.3, r * 0.1, k.x, k.y, r);
      g.addColorStop(0, '#fbfbfb'); g.addColorStop(0.6, '#c9ccd0'); g.addColorStop(1, '#6f7377');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(k.x, k.y, r, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      // knurl
      ctx.strokeStyle = 'rgba(0,0,0,0.25)'; ctx.lineWidth = 1;
      for (let i = 0; i < 24; i++) {
        const a = (i / 24) * Math.PI * 2;
        ctx.beginPath(); ctx.moveTo(k.x + Math.cos(a) * r * 0.78, k.y + Math.sin(a) * r * 0.78); ctx.lineTo(k.x + Math.cos(a) * r, k.y + Math.sin(a) * r); ctx.stroke();
      }
      // indicator
      const angle = -Math.PI * 0.75 + value * Math.PI * 1.5 + Math.PI / 2;
      ctx.strokeStyle = '#1b1d21'; ctx.lineWidth = Math.max(2, r * 0.14); ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(k.x + Math.cos(angle) * r * 0.25, k.y + Math.sin(angle) * r * 0.25); ctx.lineTo(k.x + Math.cos(angle) * r * 0.85, k.y + Math.sin(angle) * r * 0.85); ctx.stroke();
      this.text(ctx, k.x, k.y + r * 1.45, k.label, { font: `700 ${Math.max(7, r * 0.3)}px system-ui, sans-serif`, color: 'rgba(40,30,20,0.75)' });
      this.text(ctx, k.x, k.y - r * 1.4, String(Math.round(value * 10)), { font: `600 ${Math.max(7, r * 0.32)}px system-ui, sans-serif`, color: 'rgba(40,30,20,0.65)' });
    }
    const s = L.selector;
    if (s) {
      // slot
      ctx.fillStyle = '#15171b';
      roundRect(ctx, s.x - s.w / 2, s.y - s.h * 0.22, s.w, s.h * 0.44, s.h * 0.2);
      ctx.fill();
      // position marks (5 = neck on the left, 1 = bridge on the right)
      for (let i = 0; i < 5; i++) {
        const mx = s.x - s.w / 2 + s.w * ((i + 0.5) / 5);
        ctx.fillStyle = 5 - i === this.controls.pickup ? '#f59e0b' : 'rgba(0,0,0,0.3)';
        ctx.beginPath(); ctx.arc(mx, s.y - s.h * 0.75, 2.2, 0, Math.PI * 2); ctx.fill();
      }
      // lever
      const t = ((5 - this.controls.pickup) + 0.5) / 5;
      const lx = s.x - s.w / 2 + s.w * t;
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.5)'; ctx.shadowBlur = 5; ctx.shadowOffsetY = 2;
      ctx.strokeStyle = '#d6d8db'; ctx.lineWidth = Math.max(3, s.h * 0.22); ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(lx, s.y); ctx.lineTo(lx + (t - 0.5) * s.w * 0.5, s.y + s.h * 1.1); ctx.stroke();
      ctx.restore();
      ctx.fillStyle = '#f3efe6';
      ctx.beginPath(); ctx.arc(lx + (t - 0.5) * s.w * 0.5, s.y + s.h * 1.1, Math.max(3.5, s.h * 0.26), 0, Math.PI * 2); ctx.fill();
      ctx.strokeStyle = 'rgba(0,0,0,0.4)'; ctx.lineWidth = 1; ctx.stroke();
      this.text(ctx, s.x, s.y - s.h * 1.5, 'PICKUP', { font: `700 ${Math.max(7, s.h * 0.3)}px system-ui, sans-serif`, color: 'rgba(40,30,20,0.7)' });
    }
  }

  drawStrings(ctx, now) {
    const L = this.layout;
    const st = this.state;
    const thicknessScale = L.H / 6.8;
    for (let i = 0; i < STRING_COUNT; i++) {
      const gauge = STRING_GAUGES_INCHES[i];
      const width = Math.max(1.1, gauge * thicknessScale);
      const wound = STRING_WOUND[i];
      const colors = STRING_COLORS[wound ? 'wound' : 'plain'];
      const sounding = st.soundingFret(i);
      const muted = sounding < 0;
      const amp = this.currentAmp(i, now);
      const v = this.vib[i];
      const xStart = L.full ? L.posts[STRING_COUNT - 1 - i].x : L.head.x0;
      const yStart = L.full ? L.posts[STRING_COUNT - 1 - i].y : L.stringY(i, L.nutX);
      const xNut = L.nutX;
      const xVib0 = sounding > 0 ? L.fretX(Math.min(sounding, L.N)) + 1 : xNut;
      const xEnd = L.stringEndX;

      // Shadow on the fretboard/body
      ctx.strokeStyle = 'rgba(0,0,0,0.45)';
      ctx.lineWidth = width + 0.8;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(xNut, L.stringY(i, xNut) + width + 2);
      ctx.lineTo(xEnd, L.stringY(i, xEnd) + width + 2.5);
      ctx.stroke();

      const grad = ctx.createLinearGradient(0, L.stringY(i, L.nutX) - width, 0, L.stringY(i, L.nutX) + width);
      grad.addColorStop(0, colors[0]);
      grad.addColorStop(0.5, '#ffffff');
      grad.addColorStop(1, colors[1]);
      ctx.strokeStyle = muted ? 'rgba(160,160,160,0.55)' : grad;
      ctx.lineWidth = width;

      // Headstock → nut (straight, static)
      ctx.beginPath();
      ctx.moveTo(xStart, yStart);
      ctx.lineTo(xNut, L.stringY(i, xNut));
      ctx.stroke();
      // Nut → fretted position (static part)
      if (xVib0 > xNut) {
        ctx.beginPath();
        ctx.moveTo(xNut, L.stringY(i, xNut));
        ctx.lineTo(xVib0, L.stringY(i, xVib0));
        ctx.stroke();
      }
      // Vibrating part
      const drawVib = (phaseOffset, alpha) => {
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.beginPath();
        const steps = amp > 0.2 ? 28 : 2;
        for (let k = 0; k <= steps; k++) {
          const u = k / steps;
          const x = xVib0 + (xEnd - xVib0) * u;
          const base = L.stringY(i, x);
          const disp = amp > 0.2 ? amp * Math.sin(Math.PI * u) * Math.sin(2 * Math.PI * v.freq * (now - v.t0) / 1000 + v.phase + phaseOffset) : 0;
          const disp2 = amp > 0.2 ? amp * 0.25 * Math.sin(2 * Math.PI * u) * Math.sin(2 * Math.PI * v.freq * 2.1 * (now - v.t0) / 1000 + v.phase * 1.7) : 0;
          if (k === 0) ctx.moveTo(x, base + disp + disp2); else ctx.lineTo(x, base + disp + disp2);
        }
        ctx.stroke();
        ctx.restore();
      };
      if (amp > 0.6) {
        drawVib(Math.PI * 0.5, 0.28);
        drawVib(-Math.PI * 0.5, 0.28);
      }
      drawVib(0, 1);
      // Wound texture
      if (wound && width > 2) {
        ctx.save();
        ctx.globalAlpha = 0.35;
        ctx.strokeStyle = colors[1];
        ctx.lineWidth = width * 0.5;
        ctx.setLineDash([1.2, 1.6]);
        ctx.beginPath();
        ctx.moveTo(xNut, L.stringY(i, xNut));
        ctx.lineTo(xEnd, L.stringY(i, xEnd));
        ctx.stroke();
        ctx.restore();
      }
      // Pluck flash near the strum zone
      const flashAge = now - this.pressed[i];
      if (flashAge < 350 && this.pressed[i] > 0) {
        const a = 1 - flashAge / 350;
        ctx.save();
        ctx.globalAlpha = a * 0.55;
        ctx.strokeStyle = '#fde68a';
        ctx.lineWidth = width + 3;
        ctx.shadowColor = '#fde68a';
        ctx.shadowBlur = 8;
        ctx.beginPath();
        ctx.moveTo(xVib0, L.stringY(i, xVib0));
        ctx.lineTo(xEnd, L.stringY(i, xEnd));
        ctx.stroke();
        ctx.restore();
      }
    }
  }

  drawChordDots(ctx) {
    const st = this.state;
    const L = this.layout;
    const voicing = st.chordVoicing;
    if (!voicing) return;
    const hold = st.holdChord;
    const sp = L.spacing(L.nutX);
    const r = Math.max(7, sp * 0.4);
    const barres = voicingBarres(voicing);
    ctx.save();
    for (const b of barres) {
      if (b.fret > L.N) continue;
      const c0 = L.positionCenter(b.from, b.fret);
      const c1 = L.positionCenter(b.to, b.fret);
      ctx.fillStyle = hold ? 'rgba(45,212,191,0.95)' : 'rgba(45,212,191,0.55)';
      roundRect(ctx, c0.x - r * 0.75, Math.min(c0.y, c1.y) - r, r * 1.5, Math.abs(c1.y - c0.y) + r * 2, r);
      ctx.fill();
    }
    for (let s = 0; s < STRING_COUNT; s++) {
      const f = voicing.frets[s];
      const finger = voicing.fingers[s];
      if (f < 0) {
        const c = L.positionCenter(s, 0);
        this.text(ctx, c.x - r * 0.2, c.y, '×', { font: `700 ${r * 1.6}px system-ui, sans-serif`, color: 'rgba(248,113,113,0.95)' });
      } else if (f === 0) {
        const c = L.positionCenter(s, 0);
        ctx.strokeStyle = hold ? 'rgba(45,212,191,0.95)' : 'rgba(45,212,191,0.7)';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(c.x - r * 0.2, c.y, r * 0.55, 0, Math.PI * 2); ctx.stroke();
      } else if (f <= L.N) {
        const c = L.positionCenter(s, f);
        const inBarre = barres.some((b) => b.fret === f && s >= b.from && s <= b.to);
        if (!inBarre) {
          ctx.save();
          if (hold) { ctx.shadowColor = 'rgba(45,212,191,0.9)'; ctx.shadowBlur = 12; }
          ctx.fillStyle = hold ? 'rgba(45,212,191,0.97)' : 'rgba(45,212,191,0.6)';
          ctx.beginPath(); ctx.arc(c.x, c.y, r, 0, Math.PI * 2); ctx.fill();
          ctx.restore();
        }
        if (finger) this.text(ctx, c.x, c.y, String(finger), { font: `800 ${r * 1.1}px system-ui, sans-serif`, color: '#04231f' });
      }
    }
    ctx.restore();
  }

  drawFingers(ctx) {
    const st = this.state;
    const L = this.layout;
    const sp = L.spacing(L.nutX);
    const r = Math.max(9, sp * 0.46);
    const showName = st.options.noteNames !== 'off';
    for (const [, f] of st.fingers) {
      if (f.fret > L.N) continue;
      const c = L.positionCenter(f.string, f.fret);
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.7)'; ctx.shadowBlur = 10; ctx.shadowOffsetY = 3;
      const g = ctx.createRadialGradient(c.x - r * 0.3, c.y - r * 0.35, r * 0.1, c.x, c.y, r);
      g.addColorStop(0, '#f6cfb3');
      g.addColorStop(0.7, '#e2a07f');
      g.addColorStop(1, '#b86f52');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(c.x, c.y, r, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      ctx.strokeStyle = 'rgba(255,255,255,0.45)'; ctx.lineWidth = 1.2;
      ctx.beginPath(); ctx.arc(c.x, c.y, r, 0, Math.PI * 2); ctx.stroke();
      // pressed glow on the string
      ctx.save();
      const glow = ctx.createRadialGradient(c.x, c.y, r * 0.9, c.x, c.y, r * 1.7);
      glow.addColorStop(0, 'rgba(251,191,36,0.4)');
      glow.addColorStop(1, 'rgba(251,191,36,0)');
      ctx.fillStyle = glow;
      ctx.beginPath(); ctx.arc(c.x, c.y, r * 1.7, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      if (showName) {
        const note = st.fretboard.noteAt(f.string, Math.max(f.fret, st.capo), { flats: st.options.flats });
        this.text(ctx, c.x, c.y, note.name, { font: `800 ${Math.max(9, r * 0.8)}px system-ui, sans-serif`, color: '#2b1308' });
      }
    }
    // Names of sounding open/capo/chord notes when 'played' mode and the string is ringing
    if (st.options.noteNames === 'played') {
      const now = performance.now();
      for (let s = 0; s < STRING_COUNT; s++) {
        if (now - this.pressed[s] > 2500 || this.pressed[s] === 0) continue;
        if (st.fingerFret(s) !== null) continue;
        const fret = st.soundingFret(s);
        if (fret < 0) continue;
        const c = L.positionCenter(s, Math.min(fret, L.N));
        const note = st.fretboard.noteAt(s, fret, { flats: st.options.flats });
        const alpha = clamp(1 - (now - this.pressed[s] - 1500) / 1000, 0, 1);
        ctx.save();
        ctx.globalAlpha = alpha;
        ctx.fillStyle = 'rgba(12,14,18,0.85)';
        roundRect(ctx, c.x - r * 1.0, c.y - r * 0.55, r * 2.0, r * 1.1, r * 0.3);
        ctx.fill();
        ctx.restore();
        this.text(ctx, c.x, c.y, note.name, { font: `700 ${Math.max(9, r * 0.75)}px system-ui, sans-serif`, color: '#fde68a', alpha });
      }
    }
  }

  drawHover(ctx) {
    const h = this.hover;
    if (!h) return;
    const L = this.layout;
    if (h.zone === 'fretboard' && this.state.fingers.size === 0) {
      const c = L.positionCenter(h.string, h.fret);
      const w = L.cellWidth(h.fret) * 0.86;
      const sp = L.spacing(c.x);
      ctx.fillStyle = 'rgba(255,255,255,0.08)';
      roundRect(ctx, c.x - w / 2, c.y - sp * 0.45, w, sp * 0.9, 5);
      ctx.fill();
      ctx.strokeStyle = 'rgba(253,230,138,0.6)'; ctx.lineWidth = 1;
      ctx.stroke();
      const note = this.state.fretboard.noteAt(h.string, Math.max(h.fret, this.state.capo), { flats: this.state.options.flats });
      this.text(ctx, c.x, c.y - sp * 0.75, note.name, { font: '700 11px system-ui, sans-serif', color: '#fde68a' });
    } else if (h.zone === 'strum') {
      const st = L.strum;
      ctx.fillStyle = 'rgba(253,230,138,0.05)';
      roundRect(ctx, st.x0, st.y0, st.x1 - st.x0, st.y1 - st.y0, 10);
      ctx.fill();
      if (h.string >= 0) {
        const y = L.stringY(h.string, h.x);
        ctx.strokeStyle = 'rgba(253,230,138,0.6)';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(h.x - 10, y); ctx.lineTo(h.x + 10, y); ctx.stroke();
      }
    } else if (h.zone === 'knob' || h.zone === 'selector') {
      this.canvas.style.cursor = 'ns-resize';
      return;
    }
    this.canvas.style.cursor = h.zone === 'none' ? 'default' : 'pointer';
  }

  drawHints(ctx, now) {
    if (!this.strumHint) return;
    const L = this.layout;
    const st = L.strum;
    const pulse = 0.5 + 0.5 * Math.sin(now / 500);
    const sp = L.spacing(st.xm);
    const y0 = L.stringY(5, st.xm) - sp * 0.8, y1 = L.stringY(0, st.xm) + sp * 0.8;
    ctx.save();
    ctx.setLineDash([6, 6]);
    ctx.strokeStyle = `rgba(253,230,138,${0.25 + 0.25 * pulse})`;
    ctx.lineWidth = 1.5;
    roundRect(ctx, st.x0, y0, st.x1 - st.x0, y1 - y0, 12);
    ctx.stroke();
    ctx.restore();
    this.text(ctx, (st.x0 + st.x1) / 2, y1 + sp * 0.7, 'strum here', { font: '600 11px system-ui, sans-serif', color: `rgba(253,230,138,${0.5 + 0.4 * pulse})` });
  }
}
