/**
 * Control panel: tone presets, amp/effect knobs, pickup selector, tuning,
 * capo, delay time and display/playing options. Everything is wired to the
 * engine and the state in both directions so the panel always reflects
 * reality (e.g. choosing a preset moves the knobs and the pickup selector).
 */
import { Knob } from './knob.js';
import { PRESETS, PARAM_DEFS, PICKUP_SELECTOR, DELAY_TIMES } from '../audio/engine.js';
import { TUNINGS, tuningLabel } from '../theory/tunings.js';

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === 'class') node.className = v;
    else if (k === 'text') node.textContent = v;
    else if (k === 'html') node.innerHTML = v;
    else if (k.startsWith('on')) node.addEventListener(k.slice(2), v);
    else node.setAttribute(k, v);
  }
  for (const c of [].concat(children)) if (c) node.append(c);
  return node;
}

export class ControlPanel {
  /**
   * @param {HTMLElement} root
   * @param {object} o
   * @param {import('../audio/engine.js').GuitarAudioEngine} o.engine
   * @param {import('../state.js').AppState} o.state
   * @param {import('./interaction.js').Player} o.player
   */
  constructor(root, { engine, state, player }) {
    this.root = root;
    this.engine = engine;
    this.state = state;
    this.player = player;
    this.knobs = new Map();
    this.build();
    this.bindEngine();
  }

  build() {
    const { engine, state } = this;
    const root = this.root;
    root.innerHTML = '';

    // Presets
    const presetRow = el('div', { class: 'preset-row', role: 'group', 'aria-label': 'Tone presets' });
    for (const p of PRESETS) {
      presetRow.append(el('button', {
        class: 'preset-btn', type: 'button', 'data-preset': p.id, title: p.description, text: p.name,
        onclick: () => { this.player.ensureAudio(); engine.setPreset(p.id); },
      }));
    }
    root.append(el('section', { class: 'control-group' }, [el('h3', { text: 'Amp presets' }), presetRow]));

    // Knobs
    const knobRow = el('div', { class: 'knob-row' });
    for (const def of PARAM_DEFS) {
      const knob = new Knob({
        id: def.id,
        label: def.name,
        value: engine.params[def.id],
        onChange: (v) => { this.player.ensureAudio(); engine.setParam(def.id, v); },
      });
      knob.defaultValue = def.default;
      this.knobs.set(def.id, knob);
      knobRow.append(knob.element);
    }
    const delaySel = el('select', { class: 'select', 'aria-label': 'Delay time', onchange: (e) => engine.setDelayTime(e.target.value) },
      DELAY_TIMES.map((d) => el('option', { value: d.id, text: d.name })));
    delaySel.value = engine.delayTimeId;
    this.delaySelect = delaySel;
    root.append(el('section', { class: 'control-group' }, [
      el('h3', { text: 'Amp & effects' }),
      knobRow,
      el('div', { class: 'inline-row' }, [el('label', { class: 'inline-label', text: 'Delay time' }), delaySel]),
    ]));

    // Pickup selector
    const pickupRow = el('div', { class: 'segmented', role: 'group', 'aria-label': 'Pickup selector' });
    for (const p of [...PICKUP_SELECTOR].reverse()) {
      pickupRow.append(el('button', {
        class: 'seg-btn', type: 'button', 'data-pickup': p.position, title: p.name, text: p.short, 'aria-label': `${p.name} pickup`,
        'aria-pressed': String(p.position === engine.pickupPosition),
        onclick: () => { this.player.ensureAudio(); engine.setPickupSelector(p.position); },
      }));
    }
    this.pickupRow = pickupRow;
    this.pickupHint = el('p', { class: 'hint-text', text: 'The acoustic guitar has no pickups: the selector is off for this preset.', hidden: '' });
    root.append(el('section', { class: 'control-group' }, [el('h3', { text: 'Pickup selector (neck → bridge)' }), pickupRow, this.pickupHint]));

    // Tuning & capo
    const tuningSel = el('select', { class: 'select', id: 'tuning-select', 'aria-label': 'Tuning', onchange: (e) => state.setTuning(e.target.value) },
      TUNINGS.map((t) => el('option', { value: t.id, text: `${t.name} — ${tuningLabel(t, { flats: state.options.flats })}` })));
    tuningSel.value = state.tuning.id;
    const capoSel = el('select', { class: 'select', id: 'capo-select', 'aria-label': 'Capo', onchange: (e) => state.setCapo(Number(e.target.value)) },
      [...Array(8).keys()].map((n) => el('option', { value: n, text: n === 0 ? 'No capo' : `Capo fret ${n}` })));
    this.tuningSelect = tuningSel;
    this.capoSelect = capoSel;
    const tuningInfo = el('div', { class: 'tuning-info', id: 'tuning-info' });
    this.tuningInfo = tuningInfo;
    root.append(el('section', { class: 'control-group' }, [
      el('h3', { text: 'Tuning & capo' }),
      el('div', { class: 'inline-row wrap' }, [tuningSel, capoSel]),
      tuningInfo,
    ]));

    // Playing & display options
    const opt = (key, label, { type = 'checkbox', values } = {}) => {
      if (type === 'select') {
        const sel = el('select', { class: 'select small', 'aria-label': label, onchange: (e) => state.setOption(key, e.target.value) },
          values.map(([v, t]) => el('option', { value: v, text: t })));
        sel.value = state.options[key];
        this.optionInputs.set(key, sel);
        return el('label', { class: 'option option-select' }, [el('span', { text: label }), sel]);
      }
      if (type === 'range') {
        const [min, max, step, lo, hi] = values;
        const input = el('input', { type: 'range', min, max, step, 'aria-label': label, oninput: (e) => state.setOption(key, Number(e.target.value)) });
        input.value = state.options[key];
        this.optionInputs.set(key, input);
        return el('label', { class: 'option option-range' }, [el('span', { text: label }), el('span', { class: 'range-end', text: lo }), input, el('span', { class: 'range-end', text: hi })]);
      }
      const input = el('input', { type: 'checkbox', onchange: (e) => state.setOption(key, e.target.checked) });
      input.checked = !!state.options[key];
      this.optionInputs.set(key, input);
      return el('label', { class: 'option' }, [input, el('span', { text: label })]);
    };
    this.optionInputs = new Map();
    const strumRow = el('div', { class: 'inline-row wrap' }, [
      el('button', { class: 'btn', type: 'button', text: '⬇ Strum down', title: 'Space', onclick: () => this.player.strum('down') }),
      el('button', { class: 'btn', type: 'button', text: '⬆ Strum up', title: 'Shift+Space', onclick: () => this.player.strum('up') }),
      el('button', { class: 'btn ghost', type: 'button', text: 'Mute all', title: 'Esc', onclick: () => this.player.releaseEverything() }),
    ]);
    root.append(el('section', { class: 'control-group' }, [
      el('h3', { text: 'Playing' }),
      strumRow,
      el('div', { class: 'options' }, [
        opt('tapToPlay', 'Tapping a string plays it'),
        opt('releaseMutes', 'Lifting a finger mutes the string'),
        opt('holdFingers', 'Hold: fingers stay down after lifting (tap one to let go)'),
        opt('palmMute', 'Palm mute'),
        opt('dragAcross', 'Dragging across strings', { type: 'select', values: [['strum', 'Strums them / lays a barre'], ['bend', 'Bends the string (vibrato)']] }),
      ]),
      el('div', { class: 'options column' }, [
        opt('pickStrength', 'Pick strength', { type: 'range', values: [0.2, 1, 0.01, 'soft', 'hard'] }),
        opt('pickPosition', 'Pick position', { type: 'range', values: [0.05, 0.3, 0.005, 'bridge', 'neck'] }),
      ]),
    ]));
    root.append(el('section', { class: 'control-group' }, [
      el('h3', { text: 'Display' }),
      el('div', { class: 'options' }, [
        opt('noteNames', 'Note names', { type: 'select', values: [['off', 'Hidden'], ['played', 'Played notes'], ['all', 'All positions']] }),
        opt('fretNumbers', 'Fret numbers'),
        opt('flats', 'Prefer flats (D♭ instead of C♯)'),
        opt('view', 'Neck view', { type: 'select', values: [['auto', 'Auto'], ['fit', 'Fit all 24 frets'], ['zoom', 'Zoomed (pan with the minimap)']] }),
        opt('orientation', 'Orientation', { type: 'select', values: [['auto', 'Auto'], ['horizontal', 'Horizontal'], ['vertical', 'Vertical']] }),
      ]),
    ]));

    this.syncPreset();
    this.syncPickup();
    this.syncTuningInfo();
    state.addEventListener('option', (e) => {
      if (e.detail.key === 'palmMute') engine.setPalmMute(e.detail.value);
      const input = this.optionInputs.get(e.detail.key);
      if (input) { if (input.type === 'checkbox') input.checked = !!e.detail.value; else input.value = String(e.detail.value); }
      if (e.detail.key === 'flats') {
        this.syncTuningInfo();
        for (const o of tuningSel.options) { const t = TUNINGS.find((x) => x.id === o.value); if (t) o.textContent = `${t.name} — ${tuningLabel(t, { flats: e.detail.value })}`; }
      }
    });
    state.addEventListener('tuning', () => { tuningSel.value = state.tuning.id; this.syncTuningInfo(); });
    state.addEventListener('capo', () => { capoSel.value = String(state.capo); this.syncTuningInfo(); });
  }

  bindEngine() {
    const { engine } = this;
    engine.addEventListener('param', (e) => {
      const knob = this.knobs.get(e.detail.id);
      if (knob && Math.abs(knob.value - e.detail.value) > 1e-6) knob.set(e.detail.value);
    });
    engine.addEventListener('preset', () => {
      for (const [id, knob] of this.knobs) knob.set(engine.params[id]);
      this.syncPreset();
      this.syncPickup();
    });
    engine.addEventListener('pickup', () => this.syncPickup());
    engine.addEventListener('body', () => this.syncPickup());
  }

  syncPreset() {
    for (const b of this.root.querySelectorAll('.preset-btn')) {
      const on = b.dataset.preset === this.engine.presetId;
      b.classList.toggle('active', on);
      b.setAttribute('aria-pressed', String(on));
    }
  }

  syncPickup() {
    const acoustic = this.engine.body === 'acoustic';
    for (const b of this.pickupRow.querySelectorAll('.seg-btn')) {
      const on = Number(b.dataset.pickup) === this.engine.pickupPosition;
      b.classList.toggle('active', on && !acoustic);
      b.setAttribute('aria-pressed', String(on && !acoustic));
      b.disabled = acoustic;
    }
    this.pickupHint.hidden = !acoustic;
  }

  syncTuningInfo() {
    const { state } = this;
    const flats = state.options.flats;
    const parts = [];
    for (let s = 0; s < 6; s++) {
      const open = state.fretboard.noteAt(s, 0, { flats });
      const capo = state.capo ? state.fretboard.noteAt(s, state.capo, { flats }) : null;
      parts.push(`<span class="tn"><b>${6 - s}</b> ${open.name}${capo ? ` <i>→ ${capo.name}</i>` : ''}</span>`);
    }
    this.tuningInfo.innerHTML = parts.join('');
  }
}
