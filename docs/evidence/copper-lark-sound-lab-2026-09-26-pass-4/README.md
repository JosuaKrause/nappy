# Copper lark sound lab

This folder is a listening audition. It is not installed in the game and makes no claim that the
sounds are realistic or approved. Every sound comes from the tracked Python recipe: oscillators,
seeded noise, envelopes and simple filters, with no recordings, downloads, sample libraries or
pretrained audio.

Open `index.html` for the focused controls. A is the byte-preserved pass-3 grounded take and B is the quieter pass-4 proposal. `comparison.wav` plays this order, with 0.45 seconds between A and B and
1.0 second between subjects:

1. `footsteps-pass-3-grounded.wav`
2. `footsteps-subtle-grounded.wav`
3. `stroller-wheels-pass-3-grounded.wav`
4. `stroller-wheels-quieter-grounded.wav`

## Rebuild

This pass carries its frozen generator inside the ZIP as `recipe/synthesize-sfx.py`. After extracting
the ZIP, run that copy through the repository's locked Python 3.14 environment into a scratch folder:

```sh
uv run python /path/to/extracted/recipe/synthesize-sfx.py   --output /path/to/rebuilt-pass   --seed 260926   --selection subtle-revision
```

The frozen recipe writes files only; it does not play audio. Rebuilding into scratch keeps the
submitted pass intact.

## Format and level

All WAVs are 48 kHz, mono, signed PCM16. The pass-3 WAVs are byte-identical to the submitted pass 3 and retain its -22.5 dBFS RMS target. The new footsteps target -31.0 dBFS RMS with a softer compressed contact; the new stroller wheels target -38.0 dBFS RMS with restrained mechanism ticks. Both retain the 0.70 peak ceiling. The comparison preserves those levels.
This is not a perceptual loudness match, so listen at a comfortable device volume.

`manifest.json` records the seed, recipe chain, duration, measured peak and RMS, file hashes and
the frozen generator hash. The current pass is rebuilt twice and compared byte for byte in the
pinned environment before submission. Floating-point math implementations can differ across
operating systems, so this is not a blanket promise of cross-platform bit identity.
