/**
 * Tone presets. Every value is a plain control-panel setting so a preset is
 * nothing more than a starting point the user can tweak.
 */
export const PRESETS = Object.freeze([
  {
    id: 'clean',
    name: 'Clean',
    description: 'Glassy clean amp, neck/middle pickups, a touch of room reverb.',
    params: { volume: 0.8, tone: 0.72, gain: 0.12, distortion: 0.04, reverb: 0.28, delay: 0.0, chorus: 0.0 },
    pickup: 4,
    body: 'electric',
  },
  {
    id: 'overdrive',
    name: 'Overdrive',
    description: 'Warm, touch-sensitive tube break-up.',
    // Driven just into break-up: a soft pick stays cleaner and quieter than a hard one.
    params: { volume: 0.78, tone: 0.62, gain: 0.2, distortion: 0.16, reverb: 0.18, delay: 0.0, chorus: 0.0 },
    pickup: 2,
    body: 'electric',
  },
  {
    id: 'distortion',
    name: 'Distortion',
    description: 'High-gain rhythm and lead tone on the bridge pickup.',
    params: { volume: 0.72, tone: 0.55, gain: 0.85, distortion: 0.88, reverb: 0.12, delay: 0.0, chorus: 0.0 },
    pickup: 1,
    body: 'electric',
  },
  {
    id: 'acoustic',
    name: 'Acoustic',
    description: 'Brighter strings and a resonant wooden body instead of magnetic pickups.',
    params: { volume: 0.85, tone: 0.9, gain: 0.0, distortion: 0.0, reverb: 0.34, delay: 0.0, chorus: 0.0 },
    pickup: 3,
    body: 'acoustic',
  },
  {
    id: 'chorus',
    name: 'Chorus Clean',
    description: 'Shimmering 80s clean with chorus and a dotted-eighth delay.',
    params: { volume: 0.8, tone: 0.78, gain: 0.1, distortion: 0.02, reverb: 0.3, delay: 0.3, chorus: 0.6 },
    pickup: 4,
    body: 'electric',
  },
  {
    id: 'lead',
    name: 'Lead',
    description: 'Singing lead tone with delay and reverb.',
    params: { volume: 0.72, tone: 0.6, gain: 0.7, distortion: 0.7, reverb: 0.3, delay: 0.35, chorus: 0.0 },
    pickup: 5,
    body: 'electric',
  },
]);

export function getPreset(id) {
  const p = PRESETS.find((x) => x.id === id);
  if (!p) throw new Error(`Unknown preset: ${id}`);
  return p;
}
