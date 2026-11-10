/**
 * Learning panel: "now playing" read-out with chord detection, chord library
 * with diagrams and finger positions, scale library, and note highlighting.
 */
import { CHORD_QUALITIES, chordName, detectChord, voicingBarres, voicingBaseFret } from '../theory/chords.js';
import { SCALES, scaleNoteNames } from '../theory/scales.js';
import { pitchClassName, pitchClass, describeNote } from '../theory/notes.js';
import { STRING_COUNT } from '../theory/fretboard.js';

const SVG_NS = 'http://www.w3.org/2000/svg';

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

function svgEl(tag, attrs = {}) {
  const node = document.createElementNS(SVG_NS, tag);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  return node;
}

/**
 * Render a chord diagram (nut at the top, low E on the left) as an SVG element.
 */
export function chordDiagram(voicing, { width = 104, height = 116, title = '' } = {}) {
  const svg = svgEl('svg', { viewBox: '0 0 104 116', width, height, class: 'chord-diagram', role: 'img', 'aria-label': title });
  const left = 26, right = 96, top = 26, bottom = 106; // room on the left for the "12fr" label
  const strings = STRING_COUNT, frets = 5;
  const sx = (s) => left + (right - left) * (s / (strings - 1));
  const fh = (bottom - top) / frets;
  const base = voicingBaseFret(voicing);
  // nut or base fret label
  if (base === 1) svg.append(svgEl('rect', { x: left - 1, y: top - 4, width: right - left + 2, height: 5, rx: 1, class: 'cd-nut' }));
  else {
    const t = svgEl('text', { x: left - 9, y: top + fh * 0.5 + 3.5, class: 'cd-base', 'text-anchor': 'end' });
    t.textContent = `${base}fr`;
    svg.append(t);
  }
  for (let f = 0; f <= frets; f++) svg.append(svgEl('line', { x1: left, x2: right, y1: top + f * fh, y2: top + f * fh, class: 'cd-fret' }));
  for (let s = 0; s < strings; s++) svg.append(svgEl('line', { x1: sx(s), x2: sx(s), y1: top, y2: bottom, class: 'cd-string' }));
  // barres
  for (const b of voicingBarres(voicing)) {
    const rel = b.fret - base;
    if (rel < 0 || rel >= frets) continue;
    const y = top + rel * fh + fh / 2;
    svg.append(svgEl('rect', { x: sx(b.from) - 7, y: y - 6, width: sx(b.to) - sx(b.from) + 14, height: 12, rx: 6, class: 'cd-barre' }));
  }
  voicing.frets.forEach((f, s) => {
    if (f < 0) {
      const t = svgEl('text', { x: sx(s), y: top - 9, class: 'cd-mute', 'text-anchor': 'middle' });
      t.textContent = '×';
      svg.append(t);
    } else if (f === 0) {
      svg.append(svgEl('circle', { cx: sx(s), cy: top - 12, r: 4, class: 'cd-open' }));
    } else {
      const rel = f - base;
      if (rel < 0 || rel >= frets) return;
      const y = top + rel * fh + fh / 2;
      svg.append(svgEl('circle', { cx: sx(s), cy: y, r: 7, class: 'cd-dot' }));
      if (voicing.fingers[s]) {
        const t = svgEl('text', { x: sx(s), y: y + 3.5, class: 'cd-finger', 'text-anchor': 'middle' });
        t.textContent = String(voicing.fingers[s]);
        svg.append(t);
      }
    }
  });
  return svg;
}

export class LearningPanel {
  /**
   * @param {HTMLElement} root
   * @param {object} o
   * @param {import('../state.js').AppState} o.state
   * @param {import('./interaction.js').Player} o.player
   * @param {import('../audio/engine.js').GuitarAudioEngine} o.engine
   */
  constructor(root, { state, player, engine }) {
    this.root = root;
    this.state = state;
    this.player = player;
    this.engine = engine;
    this.chordRoot = 0;
    this.chordQuality = 'maj';
    this.scaleRoot = 9;
    this.scaleId = 'minor-pentatonic';
    this.build();
    state.addEventListener('played', () => this.renderNowPlaying());
    state.addEventListener('ringing', () => this.renderNowPlaying());
    state.addEventListener('finger', () => this.renderNowPlaying());
    state.addEventListener('chord', () => { this.renderNowPlaying(); this.renderChordVoicings(); });
    state.addEventListener('tuning', () => { this.renderChordVoicings(); this.renderNowPlaying(); });
    state.addEventListener('capo', () => { this.renderChordVoicings(); this.renderNowPlaying(); });
    state.addEventListener('option', (e) => { if (e.detail.key === 'flats') { this.renderAll(); } });
    state.addEventListener('scale', () => this.renderScaleInfo());
    state.addEventListener('highlight', () => this.syncNoteButtons());
    this.tick = this.tick.bind(this);
    requestAnimationFrame(this.tick);
  }

  get flats() { return this.state.options.flats; }

  build() {
    const root = this.root;
    root.innerHTML = '';
    // Now playing
    this.nowPlaying = el('div', { class: 'now-playing', 'aria-live': 'polite' });
    root.append(el('section', { class: 'control-group' }, [el('h3', { text: 'Now playing' }), this.nowPlaying]));

    // Tabs
    const tabs = el('div', { class: 'tabs', role: 'tablist' });
    const panels = {};
    for (const [id, label] of [['chords', 'Chords'], ['scales', 'Scales'], ['notes', 'Notes']]) {
      const btn = el('button', { class: 'tab', type: 'button', role: 'tab', 'data-tab': id, text: label, onclick: () => this.showTab(id) });
      tabs.append(btn);
      panels[id] = el('div', { class: 'tab-panel', 'data-panel': id, role: 'tabpanel' });
    }
    this.tabs = tabs;
    this.panels = panels;
    root.append(el('section', { class: 'control-group learning' }, [tabs, panels.chords, panels.scales, panels.notes]));
    this.buildChords(panels.chords);
    this.buildScales(panels.scales);
    this.buildNotes(panels.notes);
    this.showTab('chords');
    this.renderNowPlaying();
  }

  showTab(id) {
    for (const b of this.tabs.querySelectorAll('.tab')) {
      const on = b.dataset.tab === id;
      b.classList.toggle('active', on);
      b.setAttribute('aria-selected', String(on));
    }
    for (const [pid, p] of Object.entries(this.panels)) p.hidden = pid !== id;
  }

  rootPicker(selected, onPick, { className = 'root-picker' } = {}) {
    const row = el('div', { class: className, role: 'group' });
    for (let pc = 0; pc < 12; pc++) {
      row.append(el('button', { class: `root-btn${pc === selected ? ' active' : ''}`, type: 'button', 'data-pc': pc, text: pitchClassName(pc, { flats: this.flats }), onclick: () => onPick(pc) }));
    }
    return row;
  }

  /* ---------------- chords ---------------- */

  buildChords(panel) {
    panel.innerHTML = '';
    this.chordRootRow = this.rootPicker(this.chordRoot, (pc) => { this.chordRoot = pc; this.selectChord(); });
    const qualitySel = el('select', { class: 'select', 'aria-label': 'Chord type', onchange: (e) => { this.chordQuality = e.target.value; this.selectChord(); } },
      CHORD_QUALITIES.map((q) => el('option', { value: q.id, text: `${q.name} (${q.symbol || 'maj'})` })));
    qualitySel.value = this.chordQuality;
    this.chordQualitySel = qualitySel;
    this.holdBtn = el('button', { class: 'btn', type: 'button', text: 'Hold chord', 'aria-pressed': 'false', title: 'Virtual fingers hold the chord so you can strum it', onclick: () => { if (this.state.chordVoicing || this.state.holdChord) this.state.setHoldChord(!this.state.holdChord); } });
    const strumBtn = el('button', { class: 'btn primary', type: 'button', text: '⬇ Strum chord', onclick: () => { if (!this.state.chordVoicing) return; if (!this.state.holdChord) this.state.setHoldChord(true); this.player.strum('down'); } });
    this.strumBtn = strumBtn;
    const clearBtn = el('button', { class: 'btn ghost', type: 'button', text: 'Clear', onclick: () => { this.state.setHoldChord(false); this.state.setChord(null); } });
    this.chordTitle = el('div', { class: 'chord-title' });
    this.voicingList = el('div', { class: 'voicing-list' });
    panel.append(
      this.chordRootRow,
      el('div', { class: 'inline-row wrap' }, [qualitySel, this.holdBtn, strumBtn, clearBtn]),
      this.chordTitle,
      this.voicingList,
      el('p', { class: 'hint-text', text: 'Pick a chord to see where the fingers go (numbers: 1 index, 2 middle, 3 ring, 4 pinky). "Hold chord" presses the shape for you so you can strum; your own fingers always take priority.' }),
    );
    this.renderChordVoicings();
  }

  selectChord() {
    this.state.setChord(this.chordRoot, this.chordQuality, 0);
    for (const b of this.chordRootRow.querySelectorAll('.root-btn')) b.classList.toggle('active', Number(b.dataset.pc) === this.chordRoot);
  }

  renderChordVoicings() {
    const chord = this.state.chord;
    const playable = !!(chord && chord.voicings.length);
    this.holdBtn.classList.toggle('active', this.state.holdChord);
    this.holdBtn.setAttribute('aria-pressed', String(this.state.holdChord));
    this.holdBtn.disabled = !playable;
    this.strumBtn.disabled = !playable;
    this.voicingList.innerHTML = '';
    if (!chord) {
      this.chordTitle.textContent = 'Select a root note and a chord type.';
      return;
    }
    const name = chordName(chord.rootPc, chord.quality, { flats: this.flats });
    const notes = [...new Set(CHORD_QUALITIES.find((q) => q.id === chord.quality).intervals.map((i) => pitchClassName(chord.rootPc + i, { flats: this.flats })))];
    const capo = this.state.capo;
    const extras = [];
    if (capo) extras.push(`${chordName(chord.rootPc - capo, chord.quality, { flats: this.flats })} shapes above the capo on fret ${capo}`);
    if (this.state.tuning.id !== 'standard') extras.push(`voicings generated for ${this.state.tuning.name} tuning`);
    this.chordTitle.innerHTML = `<b>${name}</b> <span class="muted">· ${notes.join(' – ')}${extras.map((x) => ` · ${x}`).join('')}</span>`;
    if (!playable) {
      this.voicingList.append(el('p', { class: 'hint-text', text: `No playable ${name} voicing was found in this tuning${capo ? ' with this capo' : ''}. Try another chord type, tuning or capo position.` }));
      return;
    }
    chord.voicings.forEach((v, i) => {
      const card = el('button', {
        class: `voicing-card${i === chord.index ? ' active' : ''}`, type: 'button', 'data-voicing': i,
        title: v.name || '', onclick: () => this.state.setChordVoicing(i),
      });
      card.append(chordDiagram(v, { title: `${name} ${v.name || ''}` }));
      const sounding = v.frets.map((f) => (f < 0 ? 'x' : String(f))).join(' ');
      card.append(el('div', { class: 'voicing-name', text: v.name || `Voicing ${i + 1}` }));
      card.append(el('div', { class: 'voicing-frets', text: capo ? `${sounding} (capo ${capo})` : sounding }));
      this.voicingList.append(card);
    });
  }

  /* ---------------- scales ---------------- */

  buildScales(panel) {
    panel.innerHTML = '';
    this.scaleRootRow = this.rootPicker(this.scaleRoot, (pc) => { this.scaleRoot = pc; this.applyScale(true); });
    const scaleSel = el('select', { class: 'select', 'aria-label': 'Scale', onchange: (e) => { this.scaleId = e.target.value; this.applyScale(true); } },
      SCALES.map((s) => el('option', { value: s.id, text: s.name })));
    scaleSel.value = this.scaleId;
    this.scaleSel = scaleSel;
    const showBtn = el('button', { class: 'btn primary', type: 'button', text: 'Show on fretboard', onclick: () => this.applyScale(true) });
    const hideBtn = el('button', { class: 'btn ghost', type: 'button', text: 'Hide', onclick: () => this.state.setScale(null) });
    const labelSel = el('select', { class: 'select small', 'aria-label': 'Scale labels', onchange: (e) => this.state.setOption('scaleLabels', e.target.value) },
      [el('option', { value: 'degrees', text: 'Show degrees' }), el('option', { value: 'names', text: 'Show note names' })]);
    this.scaleInfo = el('div', { class: 'scale-info' });
    panel.append(this.scaleRootRow, el('div', { class: 'inline-row wrap' }, [scaleSel, labelSel, showBtn, hideBtn]), this.scaleInfo);
    this.renderScaleInfo();
  }

  applyScale(show) {
    for (const b of this.scaleRootRow.querySelectorAll('.root-btn')) b.classList.toggle('active', Number(b.dataset.pc) === this.scaleRoot);
    if (show) this.state.setScale(this.scaleRoot, this.scaleId);
  }

  renderScaleInfo() {
    const sc = this.state.scale;
    if (!sc) {
      const scale = SCALES.find((s) => s.id === this.scaleId);
      this.scaleInfo.innerHTML = `<span class="muted">${pitchClassName(this.scaleRoot, { flats: this.flats })} ${scale.name}: ${scaleNoteNames(scale, this.scaleRoot, { flats: this.flats }).join(' – ')}</span>`;
      return;
    }
    const names = scaleNoteNames(sc.scale, sc.rootPc, { flats: this.flats });
    this.scaleInfo.innerHTML = `<b>${pitchClassName(sc.rootPc, { flats: this.flats })} ${sc.scale.name}</b> <span class="muted">· ${names.join(' – ')}</span><br><span class="legend"><i class="dot root"></i> root <i class="dot tone"></i> scale tone</span>`;
  }

  /* ---------------- notes ---------------- */

  buildNotes(panel) {
    panel.innerHTML = '';
    this.noteRow = this.rootPicker(-1, (pc) => this.state.setHighlight(this.state.highlightPc === pc ? null : pc), { className: 'root-picker notes' });
    panel.append(
      el('p', { class: 'hint-text', text: 'Highlight every place a note lives on the fretboard. Click again to clear.' }),
      this.noteRow,
      el('div', { class: 'inline-row' }, [el('button', { class: 'btn ghost', type: 'button', text: 'Clear highlight', onclick: () => this.state.setHighlight(null) })]),
      el('div', { class: 'keyboard-help' }, [
        el('h4', { text: 'Keyboard' }),
        el('ul', {}, [
          el('li', { html: '<kbd>1</kbd>–<kbd>6</kbd> pick string 1 (high E) … 6 (low E)' }),
          el('li', { html: '<kbd>Space</kbd> strum down · <kbd>Shift</kbd>+<kbd>Space</kbd> strum up' }),
          el('li', { html: '<kbd>M</kbd> hold for palm mute · <kbd>Esc</kbd> mute everything' }),
        ]),
      ]),
    );
  }

  syncNoteButtons() {
    for (const b of this.noteRow.querySelectorAll('.root-btn')) b.classList.toggle('active', Number(b.dataset.pc) === this.state.highlightPc);
  }

  renderAll() {
    this.buildChords(this.panels.chords);
    this.buildScales(this.panels.scales);
    this.buildNotes(this.panels.notes);
    this.syncNoteButtons();
    this.renderNowPlaying();
  }

  /* ---------------- now playing ---------------- */

  tick() {
    // Refresh when a ringing note fades out of the audible window.
    const audible = this.audibleCount();
    if (audible !== this.lastAudible) this.renderNowPlaying();
    requestAnimationFrame(this.tick);
  }

  /** Notes that are sounding right now, newest change last. */
  soundingNotes() {
    const st = this.state;
    const out = [];
    for (let s = 0; s < STRING_COUNT; s++) {
      const ring = st.ringing[s];
      if (ring && this.engine.isAudible(s)) out.push(ring);
    }
    return out.sort((a, b) => a.time - b.time);
  }

  audibleCount() {
    let n = 0;
    for (let s = 0; s < STRING_COUNT; s++) if (this.state.ringing[s] && this.engine.isAudible(s)) n++;
    return n;
  }

  renderNowPlaying() {
    const st = this.state;
    const flats = this.flats;
    const sounding = this.soundingNotes();
    this.lastAudible = sounding.length;
    // Names are derived from the pitch at render time so they follow the sharps/flats option.
    const named = (n) => ({ ...n, ...describeNote(n.midi, { flats }) });
    this.nowPlaying.classList.toggle('idle', sounding.length === 0);
    if (!sounding.length) {
      const held = [];
      for (let s = 0; s < STRING_COUNT; s++) if (st.fingerFret(s) !== null && st.noteOn(s)) held.push(st.noteOn(s));
      const last = st.recent.length ? named(st.recent[st.recent.length - 1]) : null;
      if (held.length) {
        this.nowPlaying.innerHTML = held.map((n) => `<span class="np-chip">${n.name}</span>`).join('') + '<span class="muted"> fretted — tap or strum to hear it</span>';
      } else if (last) {
        this.nowPlaying.innerHTML = `<span class="muted">Last played: <b>${last.name}</b> · ${last.frequency.toFixed(2)} Hz · string ${6 - last.string}, fret ${last.fret}</span>`;
      } else {
        this.nowPlaying.innerHTML = '<span class="muted">Tap any string at any fret to play it — sweep across the strings to strum.</span>';
      }
      return;
    }
    const latest = named(sounding[sounding.length - 1]);
    const byPitch = [...sounding].sort((a, b) => a.midi - b.midi).map(named);
    const pcs = new Set(byPitch.map((n) => pitchClass(n.midi)));
    const chord = pcs.size >= 2 ? detectChord(pcs, { bassPc: pitchClass(byPitch[0].midi), flats }) : null;
    const other = flats ? latest.sharpName : latest.flatName;
    const bent = latest.bend > 0.02 ? `<span>bent +${latest.bend.toFixed(1)} st</span>` : '';
    const main = `
      <div class="np-main">
        <div class="np-note">${latest.name}</div>
        <div class="np-details">
          ${other !== latest.name ? `<span>${other}</span>` : ''}
          <span>MIDI ${latest.midi}</span>
          <span>${latest.frequency.toFixed(2)} Hz</span>
          <span>string ${6 - latest.string} · fret ${latest.fret}</span>
          ${bent}
        </div>
      </div>`;
    const chips = byPitch.map((n) => `<span class="np-chip${n.string === latest.string ? ' latest' : ''}">${n.name}</span>`).join('');
    const chordHtml = chord ? `<div class="np-chord">Chord: <b>${chord.name}</b></div>` : (pcs.size >= 2 ? '<div class="np-chord muted">No chord match</div>' : '');
    this.nowPlaying.innerHTML = main + `<div class="np-ringing">${chips}</div>` + chordHtml;
  }
}
