/**
 * Application bootstrap: wires state, audio engine, canvas, interaction and
 * the panels together.
 */
import { AppState } from './state.js';
import { GuitarAudioEngine, PRESETS } from './audio/engine.js';
import { GuitarCanvas } from './ui/guitar-canvas.js';
import { Player } from './ui/interaction.js';
import { ControlPanel } from './ui/controls.js';
import { LearningPanel } from './ui/learning-panel.js';

function boot() {
  const query = new URLSearchParams(location.search);
  const state = new AppState();
  // ?audio=script forces the main-thread audio backend (what a phone on plain http gets).
  const engine = new GuitarAudioEngine({ forceScriptBackend: query.get('audio') === 'script' });
  const canvasEl = document.getElementById('guitar');
  const canvas = new GuitarCanvas(canvasEl, state, { navCanvas: document.getElementById('neck-nav') });
  const player = new Player({ canvas, state, engine });
  player.attach();

  const controls = new ControlPanel(document.getElementById('controls'), { engine, state, player });
  const learning = new LearningPanel(document.getElementById('learning'), { state, player, engine });

  // Start overlay (browsers require a gesture before audio can play).
  const overlay = document.getElementById('start-overlay');
  const powerLed = document.getElementById('power-led');
  const powerOn = () => {
    powerLed.classList.add('on');
    if (!overlay.isConnected) return;
    overlay.classList.add('hidden');
    overlay.setAttribute('inert', '');
    setTimeout(() => overlay.remove(), 600);
  };
  const start = async () => {
    try {
      await engine.init();
      await engine.resume();
    } catch (err) {
      console.error('Audio failed to start', err);
      document.getElementById('start-error').textContent = `Audio could not start: ${err.message}. Tap to try again.`;
      return;
    }
    powerOn();
  };
  overlay.addEventListener('click', start);
  overlay.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); start(); } });
  player.onAudioStart = powerOn;
  engine.addEventListener('ready', powerOn);

  // Keep the keyboard for playing: a panel button or menu that was operated with
  // the pointer gives focus back, so Space strums instead of re-pressing it.
  // (Keyboard users keep normal focus behaviour: detail is 0 for key activation.)
  document.addEventListener('click', (e) => {
    const button = e.target.closest && e.target.closest('button');
    if (button && e.detail > 0 && !button.closest('dialog')) button.blur();
  });
  document.addEventListener('change', (e) => { if (e.target.tagName === 'SELECT') e.target.blur(); });

  // Level meter
  const meter = document.getElementById('level-meter');
  let smooth = 0;
  const meterLoop = () => {
    const level = engine.getLevel();
    smooth = Math.max(level, smooth * 0.9);
    const pct = Math.min(100, Math.pow(smooth * 2.2, 0.6) * 100);
    meter.style.setProperty('--level', `${pct.toFixed(1)}%`);
    meter.classList.toggle('hot', pct > 85);
    requestAnimationFrame(meterLoop);
  };
  requestAnimationFrame(meterLoop);

  // Resize handling
  const stage = document.getElementById('stage');
  const fitStage = () => {
    stage.classList.toggle('vertical', canvas.resolveOrientation() === 'vertical');
    canvas.resize();
  };

  // Stage toolbar: quick strum / mute, and the full-screen play mode
  document.getElementById('tool-strum-down').addEventListener('click', () => player.strum('down'));
  document.getElementById('tool-strum-up').addEventListener('click', () => player.strum('up'));
  document.getElementById('tool-mute').addEventListener('click', () => player.releaseEverything());
  const stagePreset = document.getElementById('stage-preset');
  for (const p of PRESETS) stagePreset.append(new Option(p.name, p.id));
  stagePreset.value = engine.presetId;
  stagePreset.addEventListener('change', () => { player.ensureAudio(); engine.setPreset(stagePreset.value); });
  engine.addEventListener('preset', () => { stagePreset.value = engine.presetId; });

  const playBtn = document.getElementById('play-mode-btn');
  let usedFullscreenApi = false;
  const setPlayMode = (on, { fullscreen = true } = {}) => {
    document.body.classList.toggle('play-mode', on);
    playBtn.setAttribute('aria-pressed', String(on));
    playBtn.innerHTML = on ? '✕<span> Exit</span>' : '⤢<span> Full screen</span>';
    playBtn.title = on ? 'Back to the controls' : 'Fill the screen with the fretboard';
    // Where the browser supports it (iPad, Android, desktop) also hide its own chrome.
    const root = document.documentElement;
    const request = root.requestFullscreen || root.webkitRequestFullscreen;
    const exit = document.exitFullscreen || document.webkitExitFullscreen;
    const active = document.fullscreenElement || document.webkitFullscreenElement;
    try {
      if (on && fullscreen && request && !active) { const p = request.call(root); usedFullscreenApi = true; if (p && p.catch) p.catch(() => { usedFullscreenApi = false; }); }
      else if (!on && exit && active) { const p = exit.call(document); if (p && p.catch) p.catch(() => {}); }
    } catch { /* play mode works without the Fullscreen API (iPhone) */ }
    if (on) window.scrollTo(0, 0);
    fitStage();
  };
  playBtn.addEventListener('click', () => setPlayMode(!document.body.classList.contains('play-mode')));
  const onFullscreenChange = () => {
    const active = document.fullscreenElement || document.webkitFullscreenElement;
    if (!active && usedFullscreenApi && document.body.classList.contains('play-mode')) { usedFullscreenApi = false; setPlayMode(false, { fullscreen: false }); }
    else fitStage();
  };
  document.addEventListener('fullscreenchange', onFullscreenChange);
  document.addEventListener('webkitfullscreenchange', onFullscreenChange);
  // A phone held sideways has no room for anything but the neck: start in play mode.
  const phoneLandscape = () => window.matchMedia('(pointer: coarse) and (orientation: landscape) and (max-height: 520px)').matches;
  engine.addEventListener('ready', () => { if (phoneLandscape() && !document.body.classList.contains('play-mode')) setPlayMode(true, { fullscreen: false }); });

  // iOS: pinch gestures would zoom the page under the player's fingers.
  document.addEventListener('gesturestart', (e) => e.preventDefault());
  // If the system interrupted the audio (a call, switching apps), any touch brings it back.
  for (const type of ['pointerup', 'touchend', 'click', 'keydown']) {
    document.addEventListener(type, () => { if (engine.ready) engine.resume(); }, { passive: true });
  }
  document.addEventListener('visibilitychange', () => { if (!document.hidden && engine.ready) engine.resume(); });
  // Re-layout is cheap but re-rendering the static layer is not; debounce window resizes.
  let resizeTimer = 0;
  const fitStageDebounced = () => { clearTimeout(resizeTimer); resizeTimer = setTimeout(fitStage, 120); };
  window.addEventListener('resize', fitStageDebounced);
  window.addEventListener('orientationchange', fitStageDebounced);
  state.addEventListener('option', (e) => { if (e.detail.key === 'orientation' || e.detail.key === 'view') fitStage(); });
  fitStage();

  // Help dialog
  const help = document.getElementById('help');
  document.getElementById('help-btn').addEventListener('click', () => help.showModal());
  help.addEventListener('click', (e) => { if (e.target === help) help.close(); });

  // When served by tools/serve.mjs: show the address to open on a phone or tablet.
  fetch('__lan.json').then((r) => (r.ok ? r.json() : null)).then((info) => {
    const hint = document.getElementById('lan-hint');
    if (!hint || !info || !info.urls || !info.urls.length) return;
    const local = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
    if (local) hint.innerHTML = `On the same Wi-Fi, open <b>${info.urls[0]}</b> on the device.`;
  }).catch(() => {});

  // Offline support / installability (only possible on https or localhost).
  if ('serviceWorker' in navigator && window.isSecureContext && !query.has('nosw')) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }

  // Debug / test hooks (used by the end-to-end tests)
  window.__guitar = { state, engine, canvas, player, controls, learning, setPlayMode };
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
