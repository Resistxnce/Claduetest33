/**
 * Rotary knob control (SVG). Drag vertically or horizontally, scroll, or use
 * the arrow keys. Exposes an ARIA slider.
 */
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const SVG_NS = 'http://www.w3.org/2000/svg';

function arcPath(cx, cy, r, a0, a1) {
  const x0 = cx + r * Math.cos(a0), y0 = cy + r * Math.sin(a0);
  const x1 = cx + r * Math.cos(a1), y1 = cy + r * Math.sin(a1);
  const large = a1 - a0 > Math.PI ? 1 : 0;
  return `M ${x0.toFixed(2)} ${y0.toFixed(2)} A ${r} ${r} 0 ${large} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}`;
}

export class Knob {
  /**
   * @param {object} o
   * @param {string} o.label
   * @param {number} [o.value=0]
   * @param {(v:number)=>string} [o.format]
   * @param {(v:number)=>void} o.onChange
   * @param {number} [o.size=64]
   */
  constructor({ label, value = 0, format = (v) => String(Math.round(v * 10)), onChange, size = 64, id }) {
    this.value = clamp(value, 0, 1);
    this.format = format;
    this.onChange = onChange;
    this.size = size;
    this.element = document.createElement('div');
    this.element.className = 'knob';
    if (id) this.element.dataset.param = id;
    this.element.innerHTML = `
      <div class="knob-dial" role="slider" tabindex="0" aria-label="${label}" aria-valuemin="0" aria-valuemax="10" aria-valuenow="0"></div>
      <div class="knob-label">${label}</div>
      <div class="knob-value"></div>`;
    this.dial = this.element.querySelector('.knob-dial');
    this.valueEl = this.element.querySelector('.knob-value');
    this.buildSvg();
    this.bind();
    this.render();
  }

  buildSvg() {
    const s = this.size;
    const svg = document.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', `0 0 ${s} ${s}`);
    svg.setAttribute('width', s);
    svg.setAttribute('height', s);
    const c = s / 2, r = s * 0.42;
    const track = document.createElementNS(SVG_NS, 'path');
    track.setAttribute('class', 'knob-track');
    track.setAttribute('d', arcPath(c, c, r, Math.PI * 0.75, Math.PI * 2.25));
    const fill = document.createElementNS(SVG_NS, 'path');
    fill.setAttribute('class', 'knob-fill');
    const cap = document.createElementNS(SVG_NS, 'circle');
    cap.setAttribute('class', 'knob-cap');
    cap.setAttribute('cx', c); cap.setAttribute('cy', c); cap.setAttribute('r', s * 0.3);
    const pointer = document.createElementNS(SVG_NS, 'line');
    pointer.setAttribute('class', 'knob-pointer');
    svg.append(track, fill, cap, pointer);
    this.dial.appendChild(svg);
    this.svg = { c, r, fill, pointer, s };
  }

  bind() {
    let dragging = false, startY = 0, startX = 0, startValue = 0;
    this.dial.addEventListener('pointerdown', (e) => {
      dragging = true; startY = e.clientY; startX = e.clientX; startValue = this.value;
      this.dial.setPointerCapture(e.pointerId);
      this.dial.classList.add('active');
      e.preventDefault();
    });
    this.dial.addEventListener('pointermove', (e) => {
      if (!dragging) return;
      const delta = (startY - e.clientY + (e.clientX - startX) * 0.5) / 150;
      this.set(startValue + delta, true);
    });
    const end = () => { dragging = false; this.dial.classList.remove('active'); };
    this.dial.addEventListener('pointerup', end);
    this.dial.addEventListener('pointercancel', end);
    this.dial.addEventListener('dblclick', () => this.set(this.defaultValue ?? 0.5, true));
    this.dial.addEventListener('wheel', (e) => {
      if (document.activeElement !== this.dial) return; // not focused: let the page scroll past
      e.preventDefault();
      this.set(this.value - Math.sign(e.deltaY) * 0.03, true);
    }, { passive: false });
    this.dial.addEventListener('keydown', (e) => {
      const step = e.shiftKey ? 0.1 : 0.02;
      if (e.key === 'ArrowUp' || e.key === 'ArrowRight') { this.set(this.value + step, true); e.preventDefault(); }
      else if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') { this.set(this.value - step, true); e.preventDefault(); }
      else if (e.key === 'Home') { this.set(0, true); e.preventDefault(); }
      else if (e.key === 'End') { this.set(1, true); e.preventDefault(); }
    });
  }

  set(value, emit = false) {
    const v = clamp(value, 0, 1);
    if (v === this.value && !emit) return;
    this.value = v;
    this.render();
    if (emit && this.onChange) this.onChange(v);
  }

  render() {
    const { c, r, fill, pointer, s } = this.svg;
    const a0 = Math.PI * 0.75;
    const a1 = a0 + this.value * Math.PI * 1.5;
    fill.setAttribute('d', this.value > 0.002 ? arcPath(c, c, r, a0, a1) : '');
    const pr0 = s * 0.12, pr1 = s * 0.27;
    pointer.setAttribute('x1', c + pr0 * Math.cos(a1));
    pointer.setAttribute('y1', c + pr0 * Math.sin(a1));
    pointer.setAttribute('x2', c + pr1 * Math.cos(a1));
    pointer.setAttribute('y2', c + pr1 * Math.sin(a1));
    this.dial.setAttribute('aria-valuenow', (this.value * 10).toFixed(1));
    this.dial.setAttribute('aria-valuetext', this.format(this.value));
    this.valueEl.textContent = this.format(this.value);
  }
}
