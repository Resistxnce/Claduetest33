/**
 * Application bootstrap: wires state, audio engine, canvas, interaction and
 * the panels together.
 */
import { AppState } from './state.js';
import { GuitarAudioEngine } from './audio/engine.js';
import { GuitarCanvas } from './ui/guitar-canvas.js';
import { Player } from './ui/interaction.js';
import { ControlPanel } from './ui/controls.js';
import { LearningPanel } from './ui/learning-panel.js';

function boot() {
  const state = new AppState();
  const engine = new GuitarAudioEngine();
  const canvasEl = document.getElementById('guitar');
  const canvas = new GuitarCanvas(canvasEl, state);
  const player = new Player({ canvas, state, engine });
  player.attach();

  const controls = new ControlPanel(document.getElementById('controls'), { engine, state, player });
  const learning = new LearningPanel(document.getElementById('learning'), { state, player, engine });

  // Keep the guitar's own knobs/selector in sync with the engine.
  const syncCanvasControls = () => canvas.setControls({ volume: engine.params.volume, tone: engine.params.tone, pickup: engine.pickupPosition });
  engine.addEventListener('param', syncCanvasControls);
  engine.addEventListener('preset', syncCanvasControls);
  engine.addEventListener('pickup', syncCanvasControls);
  syncCanvasControls();

  // Start overlay (browsers require a gesture before audio can play).
  const overlay = document.getElementById('start-overlay');
  const powerLed = document.getElementById('power-led');
  const start = async () => {
    try {
      await engine.init();
      await engine.resume();
    } catch (err) {
      console.error('Audio failed to start', err);
      document.getElementById('start-error').textContent = `Audio could not start: ${err.message}`;
      return;
    }
    overlay.classList.add('hidden');
    powerLed.classList.add('on');
    setTimeout(() => overlay.remove(), 600);
  };
  overlay.addEventListener('click', start);
  overlay.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') start(); });
  player.onAudioStart = () => { overlay.classList.add('hidden'); powerLed.classList.add('on'); };
  engine.addEventListener('ready', () => { powerLed.classList.add('on'); overlay.classList.add('hidden'); });

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
    const vertical = state.options.orientation === 'vertical' || (state.options.orientation === 'auto' && window.innerHeight > window.innerWidth && window.innerWidth < 760);
    stage.classList.toggle('vertical', vertical);
    canvas.resize();
  };
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

  // Debug / test hooks (used by the end-to-end tests)
  window.__guitar = { state, engine, canvas, player, controls, learning };
}

if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
