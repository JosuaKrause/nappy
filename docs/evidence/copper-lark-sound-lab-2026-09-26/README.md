# Copper lark sound lab

This folder is a listening audition. It is not installed in the game and makes no claim that the
sounds are realistic or approved. Every sound comes from the tracked Python recipe: oscillators,
seeded noise, envelopes and simple filters, with no recordings, downloads, sample libraries or
pretrained audio.

Open `index.html` for labeled A/B controls. The grounded treatment is A and the stylized treatment
is B. `comparison.wav` plays this order, with 0.45 seconds between A and B and 1.0 second between
subjects:

1. `footsteps-grounded.wav`
2. `footsteps-stylized.wav`
3. `stroller-wheels-grounded.wav`
4. `stroller-wheels-stylized.wav`
5. `car-horn-grounded.wav`
6. `car-horn-stylized.wav`
7. `loudspeaker-crackle-grounded.wav`
8. `loudspeaker-crackle-stylized.wav`

## Rebuild

This pass carries its frozen generator both beside this README and inside the ZIP as
`recipe/synthesize-sfx.py`. From the repository root, run that copy through the locked Python 3.14
environment into scratch:

```sh
uv run python docs/evidence/copper-lark-sound-lab-2026-09-26/recipe/synthesize-sfx.py \
  --output "${TMPDIR:-/tmp}/copper-lark-sound-lab-pass-1-rebuild" \
  --seed 260926
```

The frozen generator writes files only; it does not play audio. Rebuilding into scratch keeps the
submitted pass intact. The tracked `tools/synthesize-sfx.py` evolves with later passes and is not
the source for this one.

## Format and level

All WAVs are 48 kHz, mono, signed PCM16. Each individual audition and the comparison file is
DC-centered, faded over 12 ms at both boundaries and normalized to a 0.70 linear peak (about
-3.1 dBFS). Equal peak targets make A/B playback comparable while leaving mix headroom. They do
not make perceived loudness identical, so listen at a comfortable device volume.

`manifest.json` records the seed, recipe chain, duration, measured peak and RMS, file hashes and
the frozen generator hash. Compare a scratch rebuild's WAV hashes with that manifest; the current
repository tests cover the current pass rather than claiming that an evolving tool rebuilds this
archive. Floating-point math implementations can differ across operating systems, so this is not a
blanket promise of cross-platform bit identity.
