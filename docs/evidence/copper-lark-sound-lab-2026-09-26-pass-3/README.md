# Copper lark sound lab

This folder is a listening audition. It is not installed in the game and makes no claim that the
sounds are realistic or approved. Every sound comes from the tracked Python recipe: oscillators,
seeded noise, envelopes and simple filters, with no recordings, downloads, sample libraries or
pretrained audio.

Open `index.html` for the focused controls. A is the preserved old grounded take and B is its revised grounded take. `comparison.wav` plays this order, with 0.45 seconds between A and B and
1.0 second between subjects:

1. `footsteps-old-grounded.wav`
2. `footsteps-revised-grounded.wav`
3. `stroller-wheels-old-grounded.wav`
4. `stroller-wheels-revised-grounded.wav`

## Rebuild

This pass carries its frozen generator inside the ZIP as `recipe/synthesize-sfx.py`. After extracting
the ZIP, run that copy through the repository's locked Python 3.14 environment into a scratch folder:

```sh
uv run python /path/to/extracted/recipe/synthesize-sfx.py   --output /path/to/rebuilt-pass   --seed 260926   --selection grounded-revision
```

The frozen recipe writes files only; it does not play audio. Rebuilding into scratch keeps the
submitted pass intact.

## Format and level

All WAVs are 48 kHz, mono, signed PCM16. The revised WAVs are DC-centered, faded over 12 ms at both boundaries and set to -22.5 dBFS RMS unless their peak first reaches the 0.70 ceiling (about -3.1 dBFS). The OLD WAVs are byte-identical to pass 1 and retain its original 0.70 peak-only finishing stage. The comparison preserves those levels.
This is not a perceptual loudness match, so listen at a comfortable device volume.

`manifest.json` records the seed, recipe chain, duration, measured peak and RMS, file hashes and
the frozen generator hash. The current pass is rebuilt twice and compared byte for byte in the
pinned environment before submission. Floating-point math implementations can differ across
operating systems, so this is not a blanket promise of cross-platform bit identity.
