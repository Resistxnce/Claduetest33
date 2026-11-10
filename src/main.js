/**
 * Application bootstrap: wires state, audio engine, canvas, interaction and
 * the panels together.
 */
import { AppState } from './state.js';
import { GuitarAudioEngine, PRESETS, isIOS } from './audio/engine.js';
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
  // Until the amp is on, the overlay is the only thing to operate: it has the focus and the page behind it is inert.
  const behind = [document.querySelector('.topbar'), document.querySelector('main')].filter(Boolean);
  for (const node of behind) node.setAttribute('inert', '');
  overlay.focus({ preventScroll: true });
  // The LED and the hint tell the truth about the sound: lit only while the audio clock runs.
  const soundHint = document.getElementById('sound-hint');
  let hintTimer = 0;
  const syncSound = () => {
    const running = engine.running;
    powerLed.classList.toggle('on', running);
    clearTimeout(hintTimer);
    if (!engine.ready || running || document.hidden) { soundHint.hidden = true; return; }
    // Brief pauses (the moment between a tap and the clock starting) are not worth a message.
    hintTimer = setTimeout(() => {
      if (!engine.ready || engine.running || document.hidden) return;
      soundHint.textContent = engine.stalled ? 'Sound has stopped — tap here to restart it' : 'Sound is paused — tap here to turn it back on';
      soundHint.hidden = false;
    }, 700);
  };
  const wakeSound = () => {
    if (!engine.ready && !engine.stalled) return;
    if (engine.stalled) engine.restart().then(syncSound, syncSound);
    else engine.resume().then(syncSound, syncSound);
  };
  soundHint.addEventListener('click', wakeSound);
  engine.addEventListener('state', syncSound);
  engine.addEventListener('ready', syncSound);
  const powerOn = () => {
    syncSound();
    for (const node of behind) node.removeAttribute('inert');
    if (!overlay.isConnected || overlay.classList.contains('hidden')) return;
    // Give the keyboard back to the instrument straight away (Space strums while the overlay fades).
    if (overlay.contains(document.activeElement)) document.activeElement.blur();
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
      document.getElementById('start-error').textContent = err.permanent
        ? `Sound cannot start here: ${err.message}.`
        : `Audio could not start: ${err.message}. Tap to try again.`;
      return;
    }
    powerOn();
  };
  overlay.addEventListener('click', start);
  overlay.addEventListener('keydown', (e) => {
    if (overlay.classList.contains('hidden')) return;
    if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); start(); }
  });
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
  // Hold: fingers stay down after the touch lifts (chord shapes, barre chords on a phone).
  const holdBtn = document.getElementById('tool-hold');
  const syncHold = () => {
    const on = !!state.options.holdFingers;
    holdBtn.setAttribute('aria-pressed', String(on));
    holdBtn.classList.toggle('active', on);
  };
  holdBtn.addEventListener('click', () => state.setOption('holdFingers', !state.options.holdFingers));
  state.addEventListener('option', (e) => { if (e.detail.key === 'holdFingers') syncHold(); });
  syncHold();
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
    // Where it helps (Android, desktop) also hide the browser's own chrome. Not on iPhone/iPad:
    // Safari's full screen answers a few quick taps with a "you are typing in full screen"
    // alert that pauses the page, and a downward swipe (a strum!) leaves it. There the
    // CSS-only play mode fills the window, and "Add to Home Screen" removes the browser bars.
    const root = document.documentElement;
    const request = isIOS() ? null : (root.requestFullscreen || root.webkitRequestFullscreen);
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
  // If the system interrupted the audio (a call, switching apps), any touch brings it back —
  // and rebuilds it when it has stalled for good.
  for (const type of ['pointerup', 'touchend', 'click', 'keydown']) {
    document.addEventListener(type, wakeSound, { passive: true });
  }
  // Hidden: stop the audio clock (battery, and the lock screen loses its player). Back: start it
  // again and make sure the clock really moves (after backgrounding, iOS can leave it frozen).
  const comeBack = () => {
    if (document.hidden || !engine.ready) return;
    engine.resume().then(() => { syncSound(); return engine.checkHealth(); }).then(syncSound, syncSound);
  };
  document.addEventListener('visibilitychange', () => { if (document.hidden) { engine.suspend(); syncSound(); } else comeBack(); });
  window.addEventListener('pageshow', comeBack);
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
  let helpOpenedByPointer = false;
  const openHelp = (section, e) => {
    helpOpenedByPointer = !!e && e.detail > 0;
    if (typeof help.showModal === 'function') { if (!help.open) help.showModal(); }
    else { help.setAttribute('open', ''); help.classList.add('fallback'); } // no <dialog> (iOS before 15.4)
    if (section) section.scrollIntoView({ block: 'center' }); else help.scrollTop = 0;
  };
  document.getElementById('help-btn').addEventListener('click', (e) => openHelp(null, e));
  // Closing a dialog hands focus back to the button that opened it. After a click or tap that would
  // make Space re-open the help instead of strumming (keyboard users keep the usual focus return).
  help.addEventListener('close', () => {
    if (helpOpenedByPointer && document.activeElement && document.activeElement.closest('.topbar')) document.activeElement.blur();
  });
  help.addEventListener('click', (e) => {
    if (typeof help.close === 'function') { if (e.target === help) help.close(); return; }
    if (e.target.closest('button[value="close"]')) { e.preventDefault(); help.removeAttribute('open'); }
  });

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
    deviceBtn.addEventListener('click', (e) => openHelp(box, e));
  }).catch(() => {});

  // Offline support / installability (only possible on https or localhost).
  if ('serviceWorker' in navigator && window.isSecureContext && !query.has('nosw')) {
    navigator.serviceWorker.register('sw.js').catch(() => {});
  }

  // Debug / test hooks (used by the end-to-end tests)
  window.__guitar = { state, engine, canvas, player, controls, learning, setPlayMode };
  // The start-up watchdog in index.html may have said "still loading": the app is ready now.
  document.getElementById('start-error').textContent = '';
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
