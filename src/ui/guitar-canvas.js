/**
 * GuitarCanvas — draws a top-down 24-fret fretboard and maps pointer
 * positions to strings and frets.
 *
 * Geometry lives in "guitar space": x runs along the neck from the
 * open-string zone (0) past the nut to just beyond the 24th fret (W); y runs
 * across the strings from the high-E side (0) to the low-E side (H), i.e. the
 * usual fretboard-diagram / tablature orientation with the thick strings at
 * the bottom. Horizontal layouts map this 1:1 to the screen. Vertical layouts
 * (phones in portrait) rotate it so the nut is at the top and the low E is on
 * the left, matching chord diagrams.
 *
 * All 24 frets always exist. When the screen is too small to make them
 * comfortably tappable, the neck is drawn larger than the viewport and can be
 * panned (minimap, shift+wheel, arrow keys); `scroll` is the pan offset.
 *
 * Rendering is split in a cached static layer (wood, frets, nut, inlays) and
 * a dynamic layer (strings, note dots, overlays) redrawn on demand.
 */
import { fretDistanceFraction, SINGLE_MARKER_FRETS, DOUBLE_MARKER_FRETS, STRING_GAUGES_INCHES, STRING_WOUND, STRING_COUNT } from '../theory/fretboard.js';
import { pitchClassName, pitchClass, midiToName } from '../theory/notes.js';
import { scalePositions } from '../theory/scales.js';
import { voicingBarres, detectChord } from '../theory/chords.js';

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

export const FRET_COUNT = 24;
/** Below this viewport length (CSS px) the neck is zoomed and pannable in the "auto" view. */
const FIT_THRESHOLD = 900;
const ZOOMED_LENGTH = 1040;
/**
 * On touch screens the "auto" view makes the neck at least this long, so even the
 * 24th fret is a finger-sized target (about 31 px) with real fret spacing.
 */
const TOUCH_NECK_LENGTH = 1700;
/** Upper bound for the cached static layer, in device pixels. */
const MAX_STATIC_PIXELS = 7e6;
/** The neck never gets wider than this across the strings (CSS px), however tall the screen. */
const MAX_NECK_CROSS = 470;

/* -------------------------------------------------------------------------- */
/* Layout                                                                     */
/* -------------------------------------------------------------------------- */

/**
 * Compute every geometric quantity needed for drawing and hit-testing.
 * @param {object} o
 * @param {number} o.length    full neck length in guitar space (CSS px)
 * @param {number} o.cross     size across the strings (CSS px)
 * @param {number} [o.fretCount=24]
 * @param {number} [o.tail=0]   room past the last fret (where the strum strip sits when the neck ends there)
 */
export function computeLayout({ length: W, cross: H, fretCount = FRET_COUNT, tail = 0 }) {
  const N = fretCount;
  const openW = clamp(W * 0.06, 60, 84);          // tappable open-string zone
  const nutW = clamp(W * 0.016, 10, 26);            // a wide marble nut, as on the reference fretboard
  const nutX = openW + nutW;                       // fret 0 (bridge-side edge of the nut)
  const rightPad = Math.max(10, W * 0.012) + tail; // a little wood past the last fret, then the strum strip
  const L = (W - rightPad - nutX) / fretDistanceFraction(N); // scale length in px
  const fretX = (n) => nutX + L * fretDistanceFraction(n);
  // On tall screens the neck is a centred band rather than a stretched fretboard.
  const band = Math.min(H, MAX_NECK_CROSS);
  const bandTop = (H - band) / 2;
  const fbTop = bandTop + Math.max(6, band * 0.04);
  const fbBottom = bandTop + band - Math.max(18, band * 0.085); // margin below carries the fret numbers
  const fbH = fbBottom - fbTop;
  const inset = fbH * 0.095;
  const spacing = (fbH - 2 * inset) / (STRING_COUNT - 1);
  // String index 0 (low E) is at the bottom (large y); index 5 (high E) at the top.
  const stringY = (i) => fbTop + inset + (STRING_COUNT - 1 - i) * spacing;
  const cellWidth = (fret) => (fret <= 0 ? openW : fretX(fret) - fretX(fret - 1));
  const positionCenter = (string, fret) => {
    if (fret <= 0) return { x: openW * 0.66, y: stringY(string) };
    // Just behind the fret wire, like a real fingertip; centred in cells too narrow for that
    // (the tap target is the whole cell, so the dot should leave equal margin on both sides).
    const cell = cellWidth(fret);
    return { x: fretX(fret) - cell * clamp(0.5 - (cell - 30) * 0.004, 0.42, 0.5), y: stringY(string) };
  };
  return {
    W, H, N, openW, nutW, nutX, L, fretX, fbTop, fbBottom, fbH, inset, spacing, stringY, cellWidth, positionCenter, band, bandTop,
    openLabelX: openW * 0.22, lastX: fretX(N), bridgeX: nutX + L,
  };
}

/* -------------------------------------------------------------------------- */
/* Drawing helpers                                                            */
/* -------------------------------------------------------------------------- */

function roundRect(ctx, x, y, w, h, r) {
  const rr = Math.max(0, Math.min(r, w / 2, h / 2));
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

/** Glossy sphere (note dot) in the style of a classic fretboard trainer. */
function glossyDot(ctx, x, y, r, [light, mid, dark], vertical = false) {
  // In the vertical layout guitar space is rotated: mirror the offsets so the gloss stays top-left on screen.
  const hx = vertical ? -r * 0.4 : -r * 0.2, hy = vertical ? r * 0.2 : -r * 0.4;
  const rx = vertical ? r * 0.35 : r * 0.55, ry = vertical ? r * 0.55 : r * 0.35;
  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,0.55)';
  ctx.shadowBlur = r * 0.6;
  ctx.shadowOffsetY = r * 0.18;
  const bx = vertical ? -r * 0.35 : -r * 0.3, by = vertical ? r * 0.3 : -r * 0.35;
  const g = ctx.createRadialGradient(x + bx, y + by, r * 0.1, x, y, r);
  g.addColorStop(0, light);
  g.addColorStop(0.55, mid);
  g.addColorStop(1, dark);
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
  ctx.restore();
  // specular highlight
  const hg = ctx.createRadialGradient(x + hx, y + hy, 0, x + hx, y + hy, r * 0.6);
  hg.addColorStop(0, 'rgba(255,255,255,0.75)');
  hg.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = hg;
  ctx.beginPath(); ctx.ellipse(x + hx, y + hy, rx, ry, 0, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = 'rgba(0,0,0,0.35)';
  ctx.lineWidth = 1;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
}

const DOT_BLUE = ['#bfe3ff', '#2f8dff', '#0a3fb8'];
const DOT_TEAL = ['#c9fff5', '#22c8b4', '#0b6e63'];
const DOT_GREEN = ['#d2ffe4', '#22b86b', '#0a6b3a'];
const DOT_GREY = ['#ffffff', '#b9bcc4', '#5a5e68'];

/* -------------------------------------------------------------------------- */
/* GuitarCanvas                                                               */
/* -------------------------------------------------------------------------- */

export class GuitarCanvas {
  /**
   * @param {HTMLCanvasElement} canvas
   * @param {import('../state.js').AppState} state
   * @param {object} [o]
   * @param {HTMLCanvasElement} [o.navCanvas] minimap canvas for panning the neck
   */
  constructor(canvas, state, { navCanvas = null } = {}) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.state = state;
    this.dpr = 1;
    this.orientation = 'horizontal';
    this.fretCount = FRET_COUNT;
    this.layout = null;
    this.viewLen = 0;          // viewport size along the neck (CSS px)
    this.scroll = 0;           // pan offset along the neck (CSS px)
    this.staticLayer = document.createElement('canvas');
    this.staticScale = 1;
    this.staticDirty = true;
    this.dirty = true;
    this.hover = null;
    this.cur = { scale: 1, scroll: 0 }; // transform of the context being drawn into
    this.pickW = 60; // width of the strum strip (set by resize)
    this.vib = Array.from({ length: STRING_COUNT }, () => ({ amp: 0, t0: 0, tau: 1, phase: 0, freq: 6 }));
    /** time + fret of the last pluck per string (for ring indicators) */
    this.lastPluck = Array.from({ length: STRING_COUNT }, () => ({ t: 0, fret: 0, name: '' }));
    /** Keyboard cursor {string, fret}, shown while the fretboard has keyboard focus. */
    this.cursor = null;
    this.rafId = 0;
    this.frame = this.frame.bind(this);
    /** Called when the neck moves under the pointers (pan or re-layout). */
    this.onViewChange = null;
    this.nav = navCanvas ? new NeckNavigator(navCanvas, this) : null;
    this.resize();
    for (const ev of ['tuning', 'capo', 'option', 'chord', 'scale', 'highlight', 'finger', 'played', 'ringing']) {
      state.addEventListener(ev, () => this.requestRender());
    }
    state.addEventListener('option', (e) => {
      if (e.detail.key === 'view' || e.detail.key === 'orientation') this.resize();
      if (e.detail.key === 'fretNumbers') this.staticDirty = true;
    });
    state.addEventListener('chord', () => this.revealChord());
    canvas.addEventListener('wheel', (e) => this.onWheel(e), { passive: false });
  }

  /* ---------------- sizing ---------------- */

  get pannable() {
    return this.layout && this.layout.W > this.viewLen + 0.5;
  }

  get maxScroll() {
    return this.layout ? Math.max(0, this.layout.W - this.viewLen) : 0;
  }

  cssSize() {
    const rect = this.canvas.getBoundingClientRect();
    return { w: Math.max(50, rect.width), h: Math.max(50, rect.height) };
  }

  resolveOrientation() {
    const o = this.state.options.orientation;
    if (o !== 'auto') return o;
    const portrait = window.innerHeight > window.innerWidth;
    // Filling the screen: the neck runs along the longer side. Otherwise only
    // narrow (phone-sized) portrait screens turn the neck upright.
    if (document.body.classList.contains('play-mode')) return portrait ? 'vertical' : 'horizontal';
    return portrait && window.innerWidth < 760 ? 'vertical' : 'horizontal';
  }

  /** Full neck length in guitar space for a viewport length. */
  resolveNeckLength(viewLen) {
    const v = this.state.options.view;
    if (v === 'fit') return viewLen;
    if (v === 'zoom') return Math.max(viewLen * 1.6, 1500);
    if (this.coarsePointer()) return Math.max(viewLen, TOUCH_NECK_LENGTH);
    return viewLen >= FIT_THRESHOLD ? viewLen : ZOOMED_LENGTH;
  }

  /** Is the main pointer a finger (phone, tablet)? */
  coarsePointer() {
    return typeof window.matchMedia === 'function' && window.matchMedia('(pointer: coarse)').matches;
  }

  resize() {
    const orientation = this.resolveOrientation();
    {
      // Nothing changed (Safari's toolbar sliding in or out fires resize events all the time):
      // keep the fingers that are down and the cached fretboard.
      const now = this.cssSize();
      const key = [orientation, now.w.toFixed(1), now.h.toFixed(1), Math.min(3, window.devicePixelRatio || 1), this.state.options.view].join('|');
      if (this.layout && key === this.sizeKey) return;
    }
    this.orientation = orientation;
    const vertical = this.orientation === 'vertical';
    let { w, h } = this.cssSize();
    const viewLen = vertical ? h : w;
    const neck = this.resolveNeckLength(viewLen);
    // Showing/hiding the minimap changes the canvas' cross size: toggle first, then measure again.
    if (this.nav) {
      const show = neck > viewLen + 0.5;
      if (this.nav.canvas.hidden === show) {
        this.nav.canvas.hidden = !show;
        ({ w, h } = this.cssSize());
      }
    }
    this.dpr = Math.min(3, window.devicePixelRatio || 1);
    this.cssW = w; this.cssH = h;
    this.canvas.width = Math.round(w * this.dpr);
    this.canvas.height = Math.round(h * this.dpr);
    this.viewLen = vertical ? h : w;
    const cross = vertical ? w : h;
    // The strum strip is pinned to the bridge-side end of the view; the neck gets that much
    // extra length so the last frets are never stuck underneath it.
    this.pickW = clamp(this.viewLen * 0.09, 54, 86);
    const zoomed = neck > this.viewLen + 0.5;
    this.layout = computeLayout({ length: zoomed ? neck + this.pickW : this.viewLen, cross, tail: this.pickW });
    this.scroll = clamp(this.scroll, 0, this.maxScroll);
    // Static layer covers the whole neck; cap its pixel count on very large/zoomed necks.
    const L = this.layout;
    this.staticScale = Math.min(this.dpr, Math.sqrt(MAX_STATIC_PIXELS / (L.W * L.H)));
    this.staticLayer.width = Math.max(1, Math.ceil((vertical ? L.H : L.W) * this.staticScale));
    this.staticLayer.height = Math.max(1, Math.ceil((vertical ? L.W : L.H) * this.staticScale));
    this.staticDirty = true;
    if (this.nav) this.nav.resize();
    {
      // Remember the size that was actually laid out (showing the minimap may have changed it).
      const done = this.cssSize();
      this.sizeKey = [this.orientation, done.w.toFixed(1), done.h.toFixed(1), this.dpr, this.state.options.view].join('|');
    }
    if (this.onViewChange) this.onViewChange();
    this.requestRender();
  }

  /* ---------------- panning ---------------- */

  setScroll(value) {
    const next = clamp(value, 0, this.maxScroll);
    if (next === this.scroll) return;
    this.scroll = next;
    if (this.nav) this.nav.draw();
    if (this.onViewChange) this.onViewChange();
    this.requestRender();
  }

  panBy(delta) {
    this.setScroll(this.scroll + delta);
  }

  /** Scroll so frets [minFret, maxFret] are inside the viewport. */
  ensureFretsVisible(minFret, maxFret) {
    if (!this.pannable) return;
    const L = this.layout;
    const pad = L.spacing * 0.8;
    const x0 = (minFret <= 0 ? 0 : L.fretX(minFret - 1)) - pad;
    const x1 = L.fretX(Math.min(L.N, Math.max(1, maxFret))) + pad;
    const clear = this.viewLen - this.pickW; // the strum strip covers the end of the view
    if (x0 >= this.scroll && x1 <= this.scroll + clear) return;
    const centre = (x0 + x1) / 2;
    this.setScroll(x1 - x0 >= clear ? x0 : centre - clear / 2);
  }

  revealChord() {
    const v = this.state.chordVoicing;
    if (!v) return;
    // Chord shapes are fingered relative to the capo.
    const capo = this.state.capo;
    const fretted = v.frets.filter((f) => f > 0).map((f) => f + capo);
    const hasOpen = v.frets.some((f) => f === 0);
    if (!fretted.length) { this.ensureFretsVisible(capo, capo + 1); return; }
    const max = Math.max(...fretted);
    const min = Math.min(...fretted);
    // Include the nut (or capo) when the shape uses open strings near it.
    this.ensureFretsVisible(hasOpen && max - capo <= 5 ? capo : min, max);
  }

  onWheel(e) {
    if (!this.pannable) return;
    // Horizontal neck: sideways scrolling or shift+wheel. Vertical neck: shift+wheel
    // (plain vertical scrolling is left to the page).
    const delta = this.orientation === 'vertical'
      ? (e.shiftKey ? (e.deltaY || e.deltaX) : 0)
      : (Math.abs(e.deltaX) > Math.abs(e.deltaY) ? e.deltaX : (e.shiftKey ? e.deltaY : 0));
    if (!delta) return;
    e.preventDefault();
    this.panBy(delta);
  }

  /* ---------------- coordinate mapping ---------------- */

  /** Apply the guitar-space transform to a context. */
  applyTransform(ctx, scale, scroll) {
    this.cur = { scale, scroll };
    const k = scale;
    // Vertical: nut at the top, low E (large guitar y) on the left.
    if (this.orientation === 'vertical') ctx.setTransform(0, k, -k, 0, this.layout.H * k, -scroll * k);
    else ctx.setTransform(k, 0, 0, k, -scroll * k, 0);
  }

  /** Guitar-space x where the strum strip begins (it is pinned to the bridge-side end of the view). */
  get pickX() {
    return this.scroll + this.viewLen - this.pickW;
  }

  /** Guitar-space point for a client (viewport) coordinate. */
  toGuitar(clientX, clientY) {
    const rect = this.canvas.getBoundingClientRect();
    // If the page squeezed the canvas since the last layout, map through the drawn scale
    // so the fret under the pointer is the fret that is drawn there.
    const sx = (clientX - rect.left) * (rect.width > 0 ? this.cssW / rect.width : 1);
    const sy = (clientY - rect.top) * (rect.height > 0 ? this.cssH / rect.height : 1);
    if (this.orientation === 'vertical') return { x: sy + this.scroll, y: this.layout.H - sx };
    return { x: sx + this.scroll, y: sy };
  }

  /** Screen (CSS px, relative to the canvas) point for a guitar-space coordinate. */
  toScreen(gx, gy, scroll = this.scroll) {
    if (this.orientation === 'vertical') return { x: this.layout.H - gy, y: gx - scroll };
    return { x: gx - scroll, y: gy };
  }

  positionCenterScreen(string, fret) {
    const p = this.layout.positionCenter(string, fret);
    return this.toScreen(p.x, p.y);
  }

  /**
   * Classify a guitar-space point.
   * @returns {{zone:'open'|'fretboard'|'none', string?:number, fret?:number}}
   */
  hitTest(gx, gy, { pick = true } = {}) {
    const L = this.layout;
    if (gy < L.fbTop - L.spacing * 0.3 || gy > L.fbBottom + L.spacing * 0.3) return { zone: 'none' };
    // Nearest string (index 0 = low E at the bottom).
    const fromTop = clamp(Math.round((gy - L.stringY(STRING_COUNT - 1)) / L.spacing), 0, STRING_COUNT - 1);
    const string = STRING_COUNT - 1 - fromTop;
    // The strum strip: the last stretch of the *view* (it does not scroll with the neck).
    if (pick && gx >= this.pickX && gx <= this.scroll + this.viewLen + 4) return { zone: 'pick', string, fret: 0 };
    if (gx < L.nutX - L.nutW * 0.5) {
      if (gx < -4) return { zone: 'none' };
      return { zone: 'open', string, fret: 0 };
    }
    if (gx > L.lastX + 4) return { zone: 'none' };
    let fret = 1;
    while (fret < L.N && gx > L.fretX(fret)) fret++;
    return { zone: 'fretboard', string, fret };
  }

  /* ---------------- dynamic state ---------------- */

  setHover(hit) {
    const a = this.hover, b = hit;
    const same = (!a && !b) || (a && b && a.zone === b.zone && a.string === b.string && a.fret === b.fret);
    this.hover = hit;
    if (!same) this.requestRender();
  }

  pluckVisual(string, velocity = 0.8, fret = null, name = '') {
    const v = this.vib[string];
    const sp = this.layout.spacing;
    v.amp = clamp(sp * (0.05 + 0.13 * velocity), 1.2, sp * 0.17); // half-width of the blur around the string
    v.t0 = performance.now();
    v.tau = 0.7 + 0.55 * (1 - string / 5); // thick strings swing longer
    v.freq = 5.5 + (5 - string) * 1.3;
    v.phase = Math.random() * Math.PI * 2;
    // Ring indicator: only for real notes (a muted "chuck" has no pitch to show).
    const lp = this.lastPluck[string];
    if (fret !== null) { lp.t = v.t0; lp.fret = fret; lp.name = name; } else lp.t = 0;
    this.requestRender();
  }

  /** Move a string's ring indicator (slides, hammer-ons, pull-offs) without re-plucking. */
  setRingPosition(string, fret, name) {
    const lp = this.lastPluck[string];
    lp.fret = fret; lp.name = name;
    if (lp.t) lp.t = performance.now();
    this.requestRender();
  }

  stopVisual(string) {
    const v = this.vib[string];
    const now = performance.now();
    v.amp = this.currentAmp(string, now) * 0.6;
    v.t0 = now;
    v.tau = 0.09;
    this.lastPluck[string].t = 0;
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
    const animating = this.vib.some((v, i) => this.currentAmp(i, now) > 0.4) || this.lastPluck.some((p) => p.t && now - p.t < 3200);
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
    const L = this.layout;
    const ss = this.staticScale;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    // The source rectangle is kept in whole pixels and inside the layer: Safari 15 draws
    // nothing at all when it sticks out by even a fraction of a pixel.
    const layer = this.staticLayer;
    const k = this.dpr / ss; // layer pixels -> canvas pixels
    if (this.orientation === 'vertical') {
      const sy = Math.min(Math.max(0, Math.round(this.scroll * ss)), layer.height - 1);
      const sh = Math.max(1, Math.min(Math.round(this.viewLen * ss), layer.height - sy));
      ctx.drawImage(layer, 0, sy, layer.width, sh, 0, 0, this.canvas.width, sh * k);
    } else {
      const sx = Math.min(Math.max(0, Math.round(this.scroll * ss)), layer.width - 1);
      const sw = Math.max(1, Math.min(Math.round(this.viewLen * ss), layer.width - sx));
      ctx.drawImage(layer, sx, 0, sw, layer.height, 0, 0, sw * k, this.canvas.height);
    }
    this.applyTransform(ctx, this.dpr, this.scroll);
    this.drawPickStrip(ctx);  // under the strings, so they stay visible to aim at
    this.drawStrings(ctx, now);
    this.drawOverlays(ctx);   // labels and markers sit on top of the strings so they stay readable
    this.drawOpenLabels(ctx);
    this.drawChordDots(ctx);
    this.drawRinging(ctx, now);
    this.drawFingers(ctx);
    this.drawHover(ctx);
    this.drawCursor(ctx);
    this.drawHud(ctx, now);
  }

  /**
   * When the neck does not fill the screen across the strings (full-screen
   * play mode on a tablet), the free space shows what is sounding: the notes
   * and, when they form one, the chord.
   */
  drawHud(ctx, now) {
    const L = this.layout;
    if (L.bandTop < 54) return;
    const st = this.state;
    const notes = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      const ring = st.ringing[s];
      const lp = this.lastPluck[s];
      if (ring && lp.t && now - lp.t < 3200) notes.push(ring);
    }
    if (!notes.length) return;
    notes.sort((a, b) => a.midi - b.midi);
    const flats = st.options.flats;
    const list = notes.map((n) => midiToName(n.midi, { flats }));
    const names = list.join('  ');
    const pcs = new Set(notes.map((n) => pitchClass(n.midi)));
    const chord = pcs.size >= 2 ? detectChord(pcs, { bassPc: pitchClass(notes[0].midi), flats }) : null;
    const headline = chord ? chord.name : (notes.length === 1 ? names : '');
    const gy = L.bandTop * 0.5;
    const bigPx = Math.min(34, Math.max(20, L.bandTop * 0.3));
    const face = 'system-ui, sans-serif';
    const dim = 'rgba(231,233,238,0.75)';
    const width = (str, font) => { ctx.font = font; return ctx.measureText(str).width; };
    if (this.orientation === 'vertical') {
      // The band beside an upright neck is narrow: shrink the chord name to fit and wrap the notes.
      const maxW = L.bandTop - 14;
      let y = this.scroll + 34;
      if (headline) {
        const px = Math.max(13, Math.min(bigPx, (bigPx * maxW) / width(headline, `800 ${bigPx}px ${face}`)));
        this.text(ctx, y, gy, headline, { font: `800 ${px}px ${face}`, color: '#fde68a' });
        y += px * 0.75 + 16;
      }
      if (headline !== names) {
        const small = `600 14px ${face}`;
        const rows = [];
        for (const name of list) {
          const last = rows[rows.length - 1];
          if (last !== undefined && width(`${last}  ${name}`, small) <= maxW) rows[rows.length - 1] = `${last}  ${name}`;
          else rows.push(name);
        }
        for (const row of rows) { this.text(ctx, y, gy, row, { font: small, color: dim }); y += 20; }
      }
    } else {
      const x = this.scroll + 20;
      const small = `600 14px ${face}`;
      if (headline) this.text(ctx, x, gy - (headline !== names ? 10 : 0), headline, { font: `800 ${bigPx}px ${face}`, color: '#fde68a', align: 'left' });
      if (headline !== names) this.text(ctx, x, gy + (headline ? 20 : 0), names, { font: small, color: dim, align: 'left' });
    }
  }

  renderStatic() {
    const ctx = this.staticLayer.getContext('2d');
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.staticLayer.width, this.staticLayer.height);
    this.applyTransform(ctx, this.staticScale, 0);
    this.drawBackground(ctx);
    this.drawOpenZone(ctx);
    this.drawFretboard(ctx);
    this.drawInlays(ctx);
    this.drawFrets(ctx);
    this.drawNut(ctx);
    this.drawFretNumbers(ctx);
  }

  /** Draw text upright at a guitar-space anchor (uses the transform set by applyTransform). */
  text(ctx, gx, gy, str, { font = '600 12px system-ui, sans-serif', color = '#ddd', align = 'center', baseline = 'middle', alpha = 1 } = {}) {
    const { scale, scroll } = this.cur;
    const p = this.toScreen(gx, gy, scroll);
    ctx.save();
    ctx.setTransform(scale, 0, 0, scale, 0, 0);
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
    const g = ctx.createLinearGradient(0, 0, 0, H);
    g.addColorStop(0, '#1b1e24');
    g.addColorStop(0.5, '#14161b');
    g.addColorStop(1, '#0d0e12');
    ctx.fillStyle = g;
    ctx.fillRect(-10, -10, W + 20, H + 20);
  }

  /** Open-string zone: a dark strip before the nut where open strings are tapped. */
  drawOpenZone(ctx) {
    const L = this.layout;
    const g = ctx.createLinearGradient(0, L.fbTop, 0, L.fbBottom);
    g.addColorStop(0, '#26221f');
    g.addColorStop(0.5, '#302925');
    g.addColorStop(1, '#201c19');
    ctx.fillStyle = g;
    ctx.fillRect(0, L.fbTop, L.nutX, L.fbH);
    const edge = ctx.createLinearGradient(L.openW - 14, 0, L.openW, 0);
    edge.addColorStop(0, 'rgba(0,0,0,0)');
    edge.addColorStop(1, 'rgba(0,0,0,0.45)');
    ctx.fillStyle = edge;
    ctx.fillRect(L.openW - 14, L.fbTop, 14, L.fbH);
  }

  drawFretboard(ctx) {
    const L = this.layout;
    const x0 = L.nutX - L.nutW, x1 = L.W;
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.7)';
    ctx.shadowBlur = 16;
    ctx.shadowOffsetY = 5;
    ctx.fillStyle = '#3a2526';
    ctx.fillRect(x0, L.fbTop, x1 - x0, L.fbH);
    ctx.restore();
    ctx.save();
    ctx.beginPath();
    ctx.rect(x0, L.fbTop, x1 - x0, L.fbH);
    ctx.clip();
    // Dark rosewood with a soft light falloff toward the edges
    const base = ctx.createLinearGradient(0, L.fbTop, 0, L.fbBottom);
    base.addColorStop(0, '#372324');
    base.addColorStop(0.3, '#472d2c');
    base.addColorStop(0.65, '#422a29');
    base.addColorStop(1, '#2c1a1a');
    ctx.fillStyle = base;
    ctx.fillRect(x0, L.fbTop, x1 - x0, L.fbH);
    // Grain: long, slightly wavy streaks
    const rnd = seeded(1234);
    const streaks = Math.round(L.fbH * 1.7);
    for (let i = 0; i < streaks; i++) {
      const y = L.fbTop + rnd() * L.fbH;
      const dark = rnd() < 0.62;
      const alpha = dark ? 0.08 + rnd() * 0.24 : 0.04 + rnd() * 0.1;
      ctx.strokeStyle = dark ? `rgba(16,7,7,${alpha})` : `rgba(160,100,92,${alpha})`;
      ctx.lineWidth = 0.6 + rnd() * (dark ? 1.7 : 1.1);
      const xs = x0 + rnd() * (x1 - x0) * 0.7 - (x1 - x0) * 0.1;
      const len = (x1 - x0) * (0.25 + rnd() * 0.9);
      const wob = 0.6 + rnd() * 1.6;
      ctx.beginPath();
      ctx.moveTo(xs, y);
      const segs = 8;
      for (let k = 1; k <= segs; k++) ctx.lineTo(xs + (len * k) / segs, y + Math.sin(k * 1.3 + i * 0.7) * wob);
      ctx.stroke();
    }
    // Sheen
    const sheen = ctx.createLinearGradient(0, L.fbTop, 0, L.fbBottom);
    sheen.addColorStop(0, 'rgba(255,255,255,0.05)');
    sheen.addColorStop(0.45, 'rgba(255,255,255,0)');
    sheen.addColorStop(1, 'rgba(0,0,0,0.2)');
    ctx.fillStyle = sheen;
    ctx.fillRect(x0, L.fbTop, x1 - x0, L.fbH);
    ctx.restore();
    ctx.strokeStyle = 'rgba(255,220,200,0.16)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(x0, L.fbTop + 0.5); ctx.lineTo(x1, L.fbTop + 0.5); ctx.stroke();
    ctx.strokeStyle = 'rgba(0,0,0,0.6)';
    ctx.beginPath(); ctx.moveTo(x0, L.fbBottom - 0.5); ctx.lineTo(x1, L.fbBottom - 0.5); ctx.stroke();
  }

  drawInlays(ctx) {
    const L = this.layout;
    const drawInlay = (x, y, r, label) => {
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.5)';
      ctx.shadowBlur = 3;
      const g = ctx.createRadialGradient(x - r * 0.3, y - r * 0.3, r * 0.1, x, y, r);
      g.addColorStop(0, '#f6f3ec');
      g.addColorStop(0.7, '#d8d3c9');
      g.addColorStop(1, '#a9a49b');
      ctx.fillStyle = g;
      ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
      ctx.strokeStyle = 'rgba(0,0,0,0.45)'; ctx.lineWidth = 0.8;
      ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
      if (label && r >= 5) this.text(ctx, x, y + r * 0.04, label, { font: `500 ${Math.max(7.5, r * 1.15)}px Georgia, "Times New Roman", serif`, color: '#2c2622' });
    };
    const radius = (f) => Math.max(4, Math.min(L.spacing * 0.3, L.cellWidth(f) * 0.3));
    const cy = (L.fbTop + L.fbBottom) / 2;
    for (const f of SINGLE_MARKER_FRETS) {
      if (f > L.N) continue;
      drawInlay((L.fretX(f - 1) + L.fretX(f)) / 2, cy, radius(f), String(f));
    }
    for (const f of DOUBLE_MARKER_FRETS) {
      if (f > L.N) continue;
      const x = (L.fretX(f - 1) + L.fretX(f)) / 2;
      drawInlay(x, (L.stringY(0) + L.stringY(1)) / 2, radius(f), '');
      drawInlay(x, (L.stringY(4) + L.stringY(5)) / 2, radius(f), '');
    }
  }

  drawFrets(ctx) {
    const L = this.layout;
    const fw = clamp(L.W * 0.0042, 3, 7);
    for (let n = 1; n <= L.N; n++) {
      const x = L.fretX(n);
      ctx.fillStyle = 'rgba(0,0,0,0.55)';
      ctx.fillRect(x + fw * 0.35, L.fbTop, fw * 0.7, L.fbH);
      const g = ctx.createLinearGradient(x - fw / 2, 0, x + fw / 2, 0);
      g.addColorStop(0, '#565c66');
      g.addColorStop(0.2, '#a9b0ba');
      g.addColorStop(0.45, '#fafbfd');
      g.addColorStop(0.7, '#c1c7cf');
      g.addColorStop(1, '#4a505a');
      ctx.fillStyle = g;
      roundRect(ctx, x - fw / 2, L.fbTop - 1, fw, L.fbH + 2, fw / 2);
      ctx.fill();
    }
  }

  drawNut(ctx) {
    const L = this.layout;
    const x0 = L.nutX - L.nutW, w = L.nutW;
    ctx.save();
    ctx.shadowColor = 'rgba(0,0,0,0.6)';
    ctx.shadowBlur = 6;
    ctx.shadowOffsetX = 2;
    const g = ctx.createLinearGradient(x0, 0, x0 + w, 0);
    g.addColorStop(0, '#a9aaa8');
    g.addColorStop(0.35, '#e6e7e4');
    g.addColorStop(0.7, '#c9cac7');
    g.addColorStop(1, '#9a9b99');
    ctx.fillStyle = g;
    ctx.fillRect(x0, L.fbTop - 2, w, L.fbH + 4);
    ctx.restore();
    const rnd = seeded(99);
    ctx.save();
    ctx.beginPath(); ctx.rect(x0, L.fbTop - 2, w, L.fbH + 4); ctx.clip();
    for (let i = 0; i < 18; i++) {
      ctx.strokeStyle = `rgba(70,72,76,${0.12 + rnd() * 0.3})`;
      ctx.lineWidth = 0.5 + rnd() * 1.2;
      const y = L.fbTop + rnd() * L.fbH;
      ctx.beginPath(); ctx.moveTo(x0, y); ctx.bezierCurveTo(x0 + w * 0.3, y + (rnd() - 0.5) * 16, x0 + w * 0.7, y + (rnd() - 0.5) * 16, x0 + w, y + (rnd() - 0.5) * 34); ctx.stroke();
    }
    // string slots
    for (let i = 0; i < STRING_COUNT; i++) {
      const sw = Math.max(1.4, L.spacing * (0.058 + 0.088 * ((STRING_GAUGES_INCHES[i] - 0.010) / 0.036))) + 1.5;
      ctx.fillStyle = 'rgba(40,40,44,0.45)';
      ctx.fillRect(x0, L.stringY(i) - sw / 2, w, sw);
    }
    ctx.restore();
    ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 1;
    ctx.strokeRect(x0 + 0.5, L.fbTop - 1.5, w - 1, L.fbH + 3);
  }

  drawFretNumbers(ctx) {
    if (!this.state.options.fretNumbers) return;
    const L = this.layout;
    const margin = L.bandTop + L.band - L.fbBottom;
    const y = L.fbBottom + margin * 0.5;
    const size = clamp(margin * 0.55, 8, 12);
    for (let n = 1; n <= L.N; n++) {
      const x = (L.fretX(n - 1) + L.fretX(n)) / 2;
      const marker = SINGLE_MARKER_FRETS.includes(n) || DOUBLE_MARKER_FRETS.includes(n);
      this.text(ctx, x, y, String(n), { font: `${marker ? 700 : 500} ${size}px system-ui, sans-serif`, color: marker ? '#cfd3da' : '#767b86' });
    }
  }

  /* ---------------- dynamic layers ---------------- */

  /** Radius of a note dot at a fret (shrinks a little on the narrow high frets). */
  dotRadius(fret, factor = 0.42) {
    const L = this.layout;
    const byCell = fret <= 0 ? L.openW * 0.3 : Math.max(8, L.cellWidth(fret) * 0.52);
    return Math.max(7, Math.min(L.spacing * factor, byCell));
  }

  drawOverlays(ctx) {
    const L = this.layout;
    const st = this.state;
    const flats = st.options.flats;
    const drawn = new Set();
    const key = (s, f) => s * 100 + f;
    // Capo
    if (st.capo > 0 && st.capo <= L.N) {
      const x = L.fretX(st.capo) - L.cellWidth(st.capo) * 0.3;
      const w = Math.max(8, Math.min(L.cellWidth(st.capo) * 0.34, 18));
      ctx.save();
      ctx.shadowColor = 'rgba(0,0,0,0.6)'; ctx.shadowBlur = 6;
      const g = ctx.createLinearGradient(x - w / 2, 0, x + w / 2, 0);
      g.addColorStop(0, '#1f2328'); g.addColorStop(0.5, '#4b5159'); g.addColorStop(1, '#1f2328');
      ctx.fillStyle = g;
      roundRect(ctx, x - w / 2, L.fbTop - 3, w, L.fbH + 6, 4);
      ctx.fill();
      ctx.restore();
      ctx.fillStyle = '#d14b3a';
      roundRect(ctx, x - w / 2 + 1.5, L.fbTop + 2, w - 3, L.fbH - 4, 3);
      ctx.fill();
    }
    // Scale positions
    if (st.scale) {
      for (const p of scalePositions(st.fretboard, st.scale.scale, st.scale.rootPc)) {
        if (p.fret > L.N) continue;
        const c = L.positionCenter(p.string, p.fret);
        const r = this.dotRadius(p.fret, 0.3);
        ctx.fillStyle = p.isRoot ? 'rgba(245,158,11,0.95)' : 'rgba(56,189,248,0.88)';
        ctx.beginPath(); ctx.arc(c.x, c.y, r, 0, Math.PI * 2); ctx.fill();
        ctx.strokeStyle = 'rgba(0,0,0,0.4)'; ctx.lineWidth = 1; ctx.stroke();
        const label = st.options.scaleLabels === 'names' ? pitchClassName(p.pitchClass, { flats }) : p.degree;
        this.text(ctx, c.x, c.y, label, { font: `700 ${Math.max(8, r * 1.0)}px system-ui, sans-serif`, color: '#0b0d12' });
        drawn.add(key(p.string, p.fret));
      }
    }
    // Highlighted pitch class
    if (st.highlightPc !== null) {
      for (const p of st.fretboard.positionsOfPitchClass(st.highlightPc)) {
        if (p.fret > L.N) continue;
        const c = L.positionCenter(p.string, p.fret);
        const r = this.dotRadius(p.fret, 0.33);
        glossyDot(ctx, c.x, c.y, r, DOT_GREEN, this.orientation === 'vertical');
        this.text(ctx, c.x, c.y, pitchClassName(st.highlightPc, { flats }), { font: `800 ${Math.max(8, r * 0.95)}px system-ui, sans-serif`, color: '#ffffff' });
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
          // Narrow frets only have room for the natural notes at a readable size.
          if (f > 0 && L.cellWidth(f) < 23 && name.length > 1) continue;
          const size = clamp(Math.min(L.spacing * 0.3, L.cellWidth(f) * 0.42), 9.5, 13);
          const w = size * (name.length > 1 ? 1.9 : 1.5), h = size * 1.4;
          ctx.fillStyle = 'rgba(10,8,8,0.62)';
          this.pill(ctx, c.x, c.y, w, h);
          ctx.fill();
          this.text(ctx, c.x, c.y, name, { font: `700 ${size}px system-ui, sans-serif`, color: 'rgba(245,240,228,0.95)' });
        }
      }
    }
  }

  drawStrings(ctx, now) {
    const L = this.layout;
    const st = this.state;
    const xEnd = L.W + 6;
    for (let i = 0; i < STRING_COUNT; i++) {
      const t = (STRING_GAUGES_INCHES[i] - 0.010) / 0.036;
      const width = Math.max(1.4, L.spacing * (0.058 + 0.088 * t));
      const wound = STRING_WOUND[i];
      const sounding = st.soundingFret(i);
      const muted = sounding < 0;
      const amp = this.currentAmp(i, now);
      const v = this.vib[i];
      const y = L.stringY(i);
      // Vibrating length: from the finger (or capo); after a lift, from the fret that still rings.
      const ring = this.lastPluck[i];
      const ringFret = st.fingerFret(i) === null && ring.t && now - ring.t < 3200 ? ring.fret : 0;
      const vibFret = Math.max(sounding, ringFret);
      const xVib0 = vibFret > 0 ? L.fretX(Math.min(vibFret, L.N)) + 1 : L.nutX;
      // A bent string is pulled sideways at the fret: straight from the nut to the
      // bend point, then straight on to the bridge.
      const bendOff = sounding > 0 ? this.bendOffset(i) : 0;
      const lineY = (x) => (bendOff ? y + bendOff * (x <= xVib0 ? (x - L.nutX) / Math.max(1, xVib0 - L.nutX) : (L.bridgeX - x) / (L.bridgeX - xVib0)) : y);
      // Shadow on the wood
      ctx.strokeStyle = 'rgba(0,0,0,0.5)';
      ctx.lineWidth = width + 0.6;
      ctx.lineCap = 'butt';
      ctx.lineJoin = 'round';
      ctx.setLineDash([]);
      const sh = width * 0.7 + 1.5;
      ctx.beginPath(); ctx.moveTo(-6, y + sh); ctx.lineTo(L.nutX, y + sh); ctx.lineTo(xVib0, lineY(xVib0) + sh); ctx.lineTo(xEnd, lineY(xEnd) + sh); ctx.stroke();
      // Pale brass string with a highlight, like the reference fretboard
      const grad = ctx.createLinearGradient(0, y - width / 2, 0, y + width / 2);
      grad.addColorStop(0, '#cfcf86');
      grad.addColorStop(0.3, '#fbf8c4');
      grad.addColorStop(0.5, '#e6e68a');
      grad.addColorStop(1, '#9c9647');
      ctx.strokeStyle = muted ? 'rgba(150,150,140,0.55)' : grad;
      ctx.lineWidth = width;
      // Static part: open zone → nut → fretted point
      ctx.beginPath(); ctx.moveTo(-6, y); ctx.lineTo(L.nutX, y); ctx.lineTo(xVib0, lineY(xVib0)); ctx.stroke();
      // Vibrating part: fretted point → bridge (the bridge lies beyond the visible neck).
      // The string itself stays crisp on its rest line; its motion shows as a symmetric
      // translucent blur whose two edges shimmer, widest toward the middle of the string.
      const span = L.bridgeX - xVib0;
      if (amp > 0.35 && !muted) {
        const tt = (now - v.t0) / 1000;
        const wobble = 0.82 + 0.18 * Math.sin(2 * Math.PI * v.freq * tt + v.phase);
        const env = (x) => amp * wobble * Math.pow(Math.sin(Math.PI * clamp((x - xVib0) / span, 0, 1)), 0.6);
        const steps = 28;
        ctx.save();
        ctx.beginPath();
        for (let k = 0; k <= steps; k++) { const x = xVib0 + ((xEnd - xVib0) * k) / steps; const yy = lineY(x) - env(x) - width / 2; if (k === 0) ctx.moveTo(x, yy); else ctx.lineTo(x, yy); }
        for (let k = steps; k >= 0; k--) { const x = xVib0 + ((xEnd - xVib0) * k) / steps; ctx.lineTo(x, lineY(x) + env(x) + width / 2); }
        ctx.closePath();
        ctx.fillStyle = 'rgba(240,238,160,0.2)';
        ctx.fill();
        ctx.globalAlpha = 0.32;
        ctx.lineWidth = Math.max(1, width * 0.5);
        for (const side of [-1, 1]) {
          ctx.beginPath();
          for (let k = 0; k <= steps; k++) { const x = xVib0 + ((xEnd - xVib0) * k) / steps; const yy = lineY(x) + side * env(x); if (k === 0) ctx.moveTo(x, yy); else ctx.lineTo(x, yy); }
          ctx.stroke();
        }
        ctx.restore();
      }
      ctx.beginPath(); ctx.moveTo(xVib0, lineY(xVib0)); ctx.lineTo(xEnd, lineY(xEnd)); ctx.stroke();
      // Wound-string texture
      if (wound && width > 2.4 && !muted) {
        ctx.save();
        ctx.globalAlpha = 0.32;
        ctx.strokeStyle = '#6f6730';
        ctx.lineWidth = width * 0.7;
        ctx.setLineDash([1, 1.6]);
        ctx.beginPath(); ctx.moveTo(-6, y); ctx.lineTo(L.nutX, y); ctx.lineTo(xVib0, lineY(xVib0)); ctx.lineTo(xEnd, lineY(xEnd));
        ctx.stroke();
        ctx.restore();
      }
      // Pluck flash
      const flashAge = now - this.lastPluck[i].t;
      if (this.lastPluck[i].t && flashAge < 300) {
        const a = 1 - flashAge / 300;
        ctx.save();
        ctx.globalAlpha = a * 0.5;
        ctx.strokeStyle = '#fff7c2';
        ctx.lineWidth = width + 2.5;
        ctx.shadowColor = '#ffe680'; ctx.shadowBlur = 8;
        ctx.beginPath(); ctx.moveTo(xVib0, lineY(xVib0)); ctx.lineTo(xEnd, lineY(xEnd)); ctx.stroke();
        ctx.restore();
      }
    }
  }

  /** Sideways displacement (px) of a string at its fretted point when a finger bends it. */
  bendOffset(string) {
    const fret = this.state.fingerFret(string);
    if (fret === null) return 0;
    let off = 0;
    for (const f of this.state.fingers.values()) if (f.string === string && f.fret === fret && Math.abs(f.offset || 0) > Math.abs(off)) off = f.offset;
    return off;
  }

  /** Path of a label background `w` wide and `h` tall on screen, centred on a guitar-space point. */
  pill(ctx, gx, gy, w, h) {
    if (this.orientation === 'vertical') roundRect(ctx, gx - h / 2, gy - w / 2, h, w, h * 0.35);
    else roundRect(ctx, gx - w / 2, gy - h / 2, w, h, h * 0.35);
  }

  /** Font and text for a note name inside a dot of radius r: the octave is dropped when the dot is small. */
  dotLabel(name, r) {
    if (r * 0.72 >= 9.5) return { label: name, font: `800 ${r * 0.72}px system-ui, sans-serif` };
    return { label: name.replace(/-?\d+$/, ''), font: `800 ${Math.max(9, Math.min(12, r * 0.95))}px system-ui, sans-serif` };
  }

  /** Open-string note letters at the outer edge of the open zone. */
  drawOpenLabels(ctx) {
    const st = this.state;
    if (st.options.noteNames === 'all') return; // already labelled by the overlay
    const L = this.layout;
    const size = clamp(L.spacing * 0.32, 9, 13);
    for (let s = 0; s < STRING_COUNT; s++) {
      const name = st.fretboard.noteNameAt(s, 0, { flats: st.options.flats }).replace(/-?\d+$/, '');
      const w = size * (name.length > 1 ? 2.0 : 1.6), h = size * 1.45;
      ctx.fillStyle = 'rgba(14,12,11,0.85)';
      this.pill(ctx, L.openLabelX, L.stringY(s), w, h);
      ctx.fill();
      this.text(ctx, L.openLabelX, L.stringY(s), name, { font: `700 ${size}px system-ui, sans-serif`, color: 'rgba(240,235,222,0.9)' });
    }
  }

  drawChordDots(ctx) {
    const st = this.state;
    const L = this.layout;
    const voicing = st.chordVoicing;
    if (!voicing) return;
    const hold = st.holdChord;
    const capo = st.capo; // shapes are fingered relative to the capo
    const barres = voicingBarres(voicing).map((b) => ({ ...b, fret: b.fret + capo }));
    for (const b of barres) {
      if (b.fret > L.N) continue;
      const r = this.dotRadius(b.fret, 0.36);
      const c0 = L.positionCenter(b.from, b.fret);
      const c1 = L.positionCenter(b.to, b.fret);
      ctx.save();
      ctx.globalAlpha = hold ? 0.95 : 0.6;
      const g = ctx.createLinearGradient(c0.x - r, 0, c0.x + r, 0);
      g.addColorStop(0, '#0b6e63'); g.addColorStop(0.5, '#2fd3bd'); g.addColorStop(1, '#0b6e63');
      ctx.fillStyle = g;
      roundRect(ctx, c0.x - r * 0.75, Math.min(c0.y, c1.y) - r, r * 1.5, Math.abs(c1.y - c0.y) + r * 2, r);
      ctx.fill();
      ctx.restore();
    }
    for (let s = 0; s < STRING_COUNT; s++) {
      const rel = voicing.frets[s];
      const f = st.chordFret(rel);
      const finger = voicing.fingers[s];
      // Muted and open strings are marked before the nut — or just behind the capo, which
      // stands in for the nut — and stay in view when the neck is panned to a shape higher up.
      const c = L.positionCenter(s, rel > 0 ? f : 0);
      let r = this.dotRadius(rel > 0 ? f : 0, 0.36);
      if (rel <= 0) {
        if (capo > 0 && capo <= L.N) { c.x = L.fretX(capo - 1) + L.cellWidth(capo) * 0.2; r = Math.min(r, this.dotRadius(capo, 0.36)); }
        const edge = this.scroll + r + 6;
        if (c.x < edge) {
          c.x = edge;
          ctx.fillStyle = 'rgba(12,13,17,0.78)';
          ctx.beginPath(); ctx.arc(c.x, c.y, r * 0.95, 0, Math.PI * 2); ctx.fill();
        }
      }
      if (rel < 0) {
        this.text(ctx, c.x, c.y, '×', { font: `800 ${r * 1.7}px system-ui, sans-serif`, color: 'rgba(248,113,113,0.95)' });
      } else if (rel === 0) {
        ctx.strokeStyle = hold ? 'rgba(45,212,191,0.95)' : 'rgba(45,212,191,0.7)';
        ctx.lineWidth = 2.2;
        ctx.beginPath(); ctx.arc(c.x, c.y, r * 0.62, 0, Math.PI * 2); ctx.stroke();
      } else if (f <= L.N) {
        const inBarre = barres.some((b) => b.fret === f && s >= b.from && s <= b.to);
        if (!inBarre) {
          ctx.save();
          ctx.globalAlpha = hold ? 1 : 0.65;
          glossyDot(ctx, c.x, c.y, r, DOT_TEAL, this.orientation === 'vertical');
          ctx.restore();
        }
        if (finger) this.text(ctx, c.x, c.y, String(finger), { font: `800 ${r * 1.05}px system-ui, sans-serif`, color: '#ffffff' });
      }
    }
  }

  /** Fading dots on strings that still ring after the finger lifted (or open strings that were picked). */
  drawRinging(ctx, now) {
    const st = this.state;
    const L = this.layout;
    const showName = st.options.noteNames !== 'off';
    // A held chord keeps its teal finger dots (with finger numbers) while it rings.
    const voicing = st.holdChord ? st.chordVoicing : null;
    const heldFret = (s) => (voicing ? st.chordFret(voicing.frets[s]) : null);
    for (let s = 0; s < STRING_COUNT; s++) {
      const lp = this.lastPluck[s];
      if (!lp.t) continue;
      const age = now - lp.t;
      if (age > 3200) continue;
      if (st.fingerFret(s) !== null) continue; // a finger dot is drawn instead
      if (lp.fret > L.N) continue;
      const alpha = clamp(1 - (age - 1800) / 1400, 0, 1);
      const c = L.positionCenter(s, lp.fret);
      const r = this.dotRadius(lp.fret, 0.36);
      if (heldFret(s) === lp.fret && lp.fret > st.capo) {
        ctx.save();
        ctx.globalAlpha = alpha * 0.95;
        ctx.strokeStyle = '#8fd0ff';
        ctx.lineWidth = Math.max(2, r * 0.2);
        ctx.shadowColor = '#4aa8ff'; ctx.shadowBlur = 8;
        ctx.beginPath(); ctx.arc(c.x, c.y, r + 2.5 + 4 * Math.exp(-age / 220), 0, Math.PI * 2); ctx.stroke();
        ctx.restore();
        continue;
      }
      ctx.save();
      ctx.globalAlpha = alpha;
      glossyDot(ctx, c.x, c.y, r, lp.fret === 0 ? DOT_GREY : DOT_BLUE, this.orientation === 'vertical');
      ctx.restore();
      if (showName && lp.name) {
        // Named at draw time, so the label follows the sharps/flats option and a retune.
        const { label, font } = this.dotLabel(midiToName(st.fretboard.midiAt(s, lp.fret), { flats: st.options.flats }), r);
        this.text(ctx, c.x, c.y, label, { font, color: lp.fret === 0 ? '#1b1d22' : '#ffffff', alpha });
      }
    }
  }

  drawFingers(ctx) {
    const st = this.state;
    const L = this.layout;
    const vertical = this.orientation === 'vertical';
    const showName = st.options.noteNames !== 'off';
    for (const [, f] of st.fingers) {
      if (f.fret > L.N) continue;
      const strings = st.fingerStrings(f);
      const r = this.dotRadius(f.fret, 0.44);
      const x = L.positionCenter(f.string, f.fret).x;
      if (strings.length > 1) {
        // A finger lying across the strings: one bar, like the barre in a chord diagram.
        const yA = L.stringY(strings[strings.length - 1]), yB = L.stringY(strings[0]);
        const w = r * 1.5;
        ctx.save();
        ctx.shadowColor = 'rgba(0,0,0,0.55)'; ctx.shadowBlur = r * 0.6; ctx.shadowOffsetY = r * 0.18;
        const g = ctx.createLinearGradient(x - w / 2, 0, x + w / 2, 0);
        g.addColorStop(0, DOT_BLUE[2]); g.addColorStop(0.45, DOT_BLUE[1]); g.addColorStop(0.7, '#6fb4ff'); g.addColorStop(1, DOT_BLUE[2]);
        ctx.fillStyle = g;
        roundRect(ctx, x - w / 2, yA - r, w, yB - yA + r * 2, w / 2);
        ctx.fill();
        ctx.restore();
        ctx.strokeStyle = f.held ? '#fbbf24' : 'rgba(0,0,0,0.4)';
        ctx.lineWidth = f.held ? 2 : 1;
        roundRect(ctx, x - w / 2, yA - r, w, yB - yA + r * 2, w / 2);
        ctx.stroke();
        if (showName) {
          for (const s of strings) {
            // Only where this finger is the one that sets the pitch (another finger may be in front of it).
            if (st.soundingFret(s) !== Math.max(f.fret, st.capo)) continue;
            const note = st.fretboard.noteAt(s, Math.max(f.fret, st.capo), { flats: st.options.flats });
            const { label, font } = this.dotLabel(note.name, Math.min(r, L.spacing * 0.4));
            this.text(ctx, x, L.stringY(s), label, { font, color: '#ffffff' });
          }
        }
        continue;
      }
      const c = L.positionCenter(f.string, f.fret);
      const y = c.y + (f.offset || 0); // a bending finger drags its dot (and the string) sideways
      glossyDot(ctx, c.x, y, r, DOT_BLUE, vertical);
      if (f.held) {
        // A held finger: an amber ring, so it is clear it stays without a touch (tap it to let go).
        ctx.strokeStyle = '#fbbf24'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(c.x, y, r + 1.5, 0, Math.PI * 2); ctx.stroke();
      }
      if (showName) {
        const note = st.fretboard.noteAt(f.string, Math.max(f.fret, st.capo), { flats: st.options.flats });
        const { label, font } = this.dotLabel(note.name, r);
        this.text(ctx, c.x, y, label, { font, color: '#ffffff' });
      }
    }
  }

  /** The strum strip: tap or sweep it to pick the strings, whatever the other hand is fretting. */
  drawPickStrip(ctx) {
    const L = this.layout;
    const x = this.pickX, w = this.pickW;
    const top = L.fbTop - 2, h = L.fbH + 4;
    ctx.save();
    const g = ctx.createLinearGradient(x, 0, x + w, 0);
    g.addColorStop(0, 'rgba(16,18,24,0.9)');
    g.addColorStop(1, 'rgba(24,27,35,0.96)');
    ctx.fillStyle = g;
    ctx.fillRect(x, top, w + 8, h);
    ctx.fillStyle = 'rgba(245,158,11,0.75)';
    ctx.fillRect(x, top, 2, h);
    ctx.restore();
    // A pick, and the word, between the strings (upright in both layouts).
    const midY = (L.stringY(2) + L.stringY(3)) / 2;
    const p = this.toScreen(x + w / 2, midY, this.cur.scroll);
    const k = this.cur.scale;
    ctx.save();
    ctx.setTransform(k, 0, 0, k, 0, 0);
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = '#f59e0b';
    const s = Math.min(w, L.spacing) * 0.36;
    ctx.beginPath();
    ctx.moveTo(p.x - s, p.y - s * 0.8);
    ctx.quadraticCurveTo(p.x, p.y - s * 1.25, p.x + s, p.y - s * 0.8);
    ctx.quadraticCurveTo(p.x + s * 0.55, p.y + s * 0.6, p.x, p.y + s * 1.2);
    ctx.quadraticCurveTo(p.x - s * 0.55, p.y + s * 0.6, p.x - s, p.y - s * 0.8);
    ctx.fill();
    ctx.restore();
    // The word sits inside the strip (the margin beside it carries fret numbers).
    this.text(ctx, x + w / 2, (L.stringY(3) + L.stringY(4)) / 2, 'STRUM', { font: '700 9px system-ui, sans-serif', color: 'rgba(245,158,11,0.9)' });
  }

  /** Show (or hide, with null) the keyboard cursor: the position the Enter key plays. */
  setCursor(cursor) {
    this.cursor = cursor ? { string: cursor.string, fret: cursor.fret } : null;
    this.requestRender();
  }

  drawCursor(ctx) {
    const k = this.cursor;
    if (!k) return;
    const L = this.layout;
    const c = L.positionCenter(k.string, k.fret);
    const sp = L.spacing;
    const x0 = k.fret === 0 ? L.openW * 0.4 : L.fretX(k.fret - 1) + L.cellWidth(k.fret) * 0.06;
    const w = k.fret === 0 ? L.openW * 0.56 : L.cellWidth(k.fret) * 0.88;
    ctx.save();
    ctx.strokeStyle = '#fbbf24';
    ctx.lineWidth = 2.5;
    ctx.shadowColor = 'rgba(251,191,36,0.7)'; ctx.shadowBlur = 8;
    roundRect(ctx, x0, c.y - sp * 0.47, w, sp * 0.94, 6);
    ctx.stroke();
    ctx.restore();
    const note = this.state.fretboard.noteAt(k.string, Math.max(k.fret, this.state.capo), { flats: this.state.options.flats });
    const above = c.y - sp * 0.7 > L.fbTop - 2;
    this.text(ctx, x0 + w / 2, above ? c.y - sp * 0.68 : c.y + sp * 0.68, note.name, { font: '800 12px system-ui, sans-serif', color: '#fde68a' });
  }

  drawHover(ctx) {
    const h = this.hover;
    if (!h || h.zone === 'none') { this.canvas.style.cursor = 'default'; return; }
    this.canvas.style.cursor = 'pointer';
    for (const f of this.state.fingers.values()) if (!f.held) return; // a finger of one's own is down
    const L = this.layout;
    const sp = L.spacing;
    if (h.zone === 'pick') {
      ctx.fillStyle = 'rgba(245,158,11,0.16)';
      roundRect(ctx, this.pickX + 4, L.stringY(h.string) - sp * 0.42, this.pickW - 8, sp * 0.84, 5);
      ctx.fill();
      return;
    }
    const c = L.positionCenter(h.string, h.fret);
    const x0 = h.fret === 0 ? L.openW * 0.4 : L.fretX(h.fret - 1) + L.cellWidth(h.fret) * 0.08;
    const w = h.fret === 0 ? L.openW * 0.56 : L.cellWidth(h.fret) * 0.84;
    ctx.fillStyle = 'rgba(255,255,255,0.09)';
    roundRect(ctx, x0, c.y - sp * 0.45, w, sp * 0.9, 5);
    ctx.fill();
    ctx.strokeStyle = 'rgba(191,227,255,0.55)'; ctx.lineWidth = 1;
    ctx.stroke();
    const note = this.state.fretboard.noteAt(h.string, Math.max(h.fret, this.state.capo), { flats: this.state.options.flats });
    const above = c.y - sp * 0.66 > L.fbTop - 2;
    this.text(ctx, x0 + w / 2, above ? c.y - sp * 0.64 : c.y + sp * 0.64, note.name, { font: '700 11px system-ui, sans-serif', color: '#dbeeff' });
  }
}

/* -------------------------------------------------------------------------- */
/* NeckNavigator                                                              */
/* -------------------------------------------------------------------------- */

/**
 * Minimap of the whole neck with a draggable viewport window. Shown only when
 * the neck is larger than the viewport.
 */
export class NeckNavigator {
  /**
   * @param {HTMLCanvasElement} canvas
   * @param {GuitarCanvas} guitar
   */
  constructor(canvas, guitar) {
    this.canvas = canvas;
    this.guitar = guitar;
    this.ctx = canvas.getContext('2d');
    this.dragging = false;
    canvas.style.touchAction = 'none';
    const seek = (e) => {
      const g = this.guitar;
      const rect = canvas.getBoundingClientRect();
      const vertical = g.orientation === 'vertical';
      const f = vertical ? (e.clientY - rect.top) / rect.height : (e.clientX - rect.left) / rect.width;
      g.setScroll(f * g.layout.W - g.viewLen / 2);
    };
    canvas.addEventListener('pointerdown', (e) => {
      this.dragging = true;
      try { canvas.setPointerCapture(e.pointerId); } catch { /* ignore */ }
      seek(e);
      e.preventDefault();
    });
    canvas.addEventListener('pointermove', (e) => { if (this.dragging) seek(e); });
    const end = () => { this.dragging = false; };
    canvas.addEventListener('pointerup', end);
    canvas.addEventListener('pointercancel', end);
  }

  resize() {
    if (this.canvas.hidden) return;
    const rect = this.canvas.getBoundingClientRect();
    const dpr = Math.min(3, window.devicePixelRatio || 1);
    this.canvas.width = Math.max(1, Math.round(rect.width * dpr));
    this.canvas.height = Math.max(1, Math.round(rect.height * dpr));
    this.dpr = dpr;
    this.cssW = rect.width; this.cssH = rect.height;
    this.draw();
  }

  draw() {
    if (this.canvas.hidden || !this.guitar.layout) return;
    const g = this.guitar;
    const L = g.layout;
    const ctx = this.ctx;
    const vertical = g.orientation === 'vertical';
    const long = vertical ? this.cssH : this.cssW;   // along the neck
    const short = vertical ? this.cssW : this.cssH;
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    // Draw in "neck space": u along the neck (0..long), v across (0..short).
    if (vertical) ctx.setTransform(0, this.dpr, this.dpr, 0, 0, 0);
    else ctx.setTransform(this.dpr, 0, 0, this.dpr, 0, 0);
    const k = long / L.W;
    ctx.fillStyle = '#1a1412';
    roundRect(ctx, 0, 2, long, short - 4, 5);
    ctx.fill();
    ctx.fillStyle = '#3a2526';
    ctx.fillRect(L.nutX * k, 4, (L.W - L.nutX) * k, short - 8);
    ctx.fillStyle = '#e9e3d4';
    ctx.fillRect((L.nutX - L.nutW) * k, 4, Math.max(2, L.nutW * k), short - 8);
    ctx.fillStyle = 'rgba(210,216,224,0.75)';
    for (let n = 1; n <= L.N; n++) ctx.fillRect(L.fretX(n) * k - 0.5, 4, 1, short - 8);
    ctx.fillStyle = '#e6e0d2';
    const dot = (f, v) => { ctx.beginPath(); ctx.arc(((L.fretX(f - 1) + L.fretX(f)) / 2) * k, v, Math.max(1.6, short * 0.09), 0, Math.PI * 2); ctx.fill(); };
    for (const f of SINGLE_MARKER_FRETS) if (f <= L.N) dot(f, short / 2);
    for (const f of DOUBLE_MARKER_FRETS) if (f <= L.N) { dot(f, short * 0.32); dot(f, short * 0.68); }
    // Viewport window
    const x0 = g.scroll * k, w = g.viewLen * k;
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(0, 2, x0, short - 4);
    ctx.fillRect(x0 + w, 2, long - x0 - w, short - 4);
    ctx.strokeStyle = '#f59e0b';
    ctx.lineWidth = 2;
    roundRect(ctx, x0 + 1, 1.5, Math.max(8, w - 2), short - 3, 5);
    ctx.stroke();
  }
}
