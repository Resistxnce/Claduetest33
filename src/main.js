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
  // Menus: only when chosen with the pointer/touch — stepping through a menu with the arrow keys keeps it focused.
  let pointerSelect = null;
  document.addEventListener('pointerdown', (e) => { pointerSelect = e.target.closest ? e.target.closest('select') : null; }, true);
  document.addEventListener('keydown', () => { pointerSelect = null; }, true);
  document.addEventListener('change', (e) => { if (e.target.tagName === 'SELECT' && e.target === pointerSelect) e.target.blur(); });

  // Level meter
  const meter = document.getElementById('level-meter');
  let smooth = 0;
  let meterRaf = 0;
  let lastSound = 0;
  const meterLoop = (now) => {
    meterRaf = 0;
    const level = engine.getLevel();
    smooth = Math.max(level, smooth * 0.9);
    if (smooth > 0.0008) lastSound = now;
    const awake = now - lastSound < 1500;
    const pct = awake ? Math.min(100, Math.pow(smooth * 2.2, 0.6) * 100) : 0;
    meter.style.setProperty('--level', `${pct.toFixed(1)}%`);
    meter.classList.toggle('hot', pct > 85);
    // After a moment of silence the loop stops; the next pluck wakes it.
    if (awake) meterRaf = requestAnimationFrame(meterLoop);
  };
  const wakeMeter = () => { lastSound = performance.now(); if (!meterRaf) meterRaf = requestAnimationFrame(meterLoop); };
  engine.addEventListener('pluck', wakeMeter);
  engine.addEventListener('ready', wakeMeter);

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
  // The canvas box can also change without a window resize (a scrollbar appearing, panels reflowing).
  if (typeof ResizeObserver !== 'undefined') {
    new ResizeObserver(() => {
      const box = canvasEl.getBoundingClientRect();
      if (Math.abs(box.width - canvas.cssW) > 0.5 || Math.abs(box.height - canvas.cssH) > 0.5) fitStageDebounced();
    }).observe(canvasEl);
  }
  state.addEventListener('option', (e) => { if (e.detail.key === 'orientation' || e.detail.key === 'view') fitStage(); });
  fitStage();

  // Help dialog
  const help = document.getElementById('help');
  // Open at the top (the dialog would otherwise scroll to its focused "Got it" button), or at a given section.
  const openHelp = (section) => {
    if (!help.open) help.showModal();
    if (section) section.scrollIntoView({ block: 'center' }); else help.scrollTop = 0;
  };
  document.getElementById('help-btn').addEventListener('click', () => openHelp());
  help.addEventListener('click', (e) => { if (e.target === help) help.close(); });

  // When served by tools/serve.mjs on a computer: show the address (and a QR code) to open on a phone or tablet.
  const devServer = document.querySelector('meta[name="guitar-dev-server"]');
  if (devServer) fetch('__lan.json').then((r) => (r.ok ? r.json() : null)).then(async (info) => {
    const box = document.getElementById('device-link');
    if (!box || !info || !Array.isArray(info.urls)) return;
    const local = ['localhost', '127.0.0.1', '[::1]'].includes(location.hostname);
    // Already on the phone/tablet itself: nothing to show.
    if (!local && window.matchMedia('(pointer: coarse)').matches) return;
    const url = local ? info.urls.find((u) => /^https?:\/\/[\w.\-:[\]]+\/$/.test(String(u))) : `${location.origin}/`;
    if (!url) return;
    document.getElementById('device-url').textContent = url;
    document.getElementById('device-note').textContent = info.https
      ? 'The certificate is self-signed: accept the browser warning once on the device.'
      : 'Tip: start the server with "npm run start:https" for lower-latency audio and offline install on the device.';
    const { qrToCanvas } = await import('./ui/qr.js');
    qrToCanvas(document.getElementById('device-qr'), url, { scale: 4, quiet: 3 });
    box.hidden = false;
    const deviceBtn = document.getElementById('device-btn');
    deviceBtn.hidden = false;
    deviceBtn.addEventListener('click', () => openHelp(box));
  }).catch(() => {});

  // Offline support / installability (only possible on https or localhost).
  if ('serviceWorker' in navigator && window.isSecureContext && !query.has('nosw')) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }

  // Debug / test hooks (used by the end-to-end tests)
  window.__guitar = { state, engine, canvas, player, controls, learning, setPlayMode };
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
