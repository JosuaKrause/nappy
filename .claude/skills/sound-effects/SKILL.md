---
name: sound-effects
description: Reproducibly author original synthesized sound auditions and their audio assets. Load before editing a sound recipe or generated audio file; runtime installation remains separate.
---

# Original sound-effects authoring

An audition is a reproducible proposal, not runtime approval. Keep its generator, listening files,
review page and provenance together; do not add it to `project.godot`, `src/` or runtime asset paths
until the player separately asks for integration.

## The recipe is the source

- Build sounds from original oscillators, seeded noise, envelopes and filters. Do not use recordings,
  downloaded sounds, sample libraries or pretrained audio output unless the player changes that
  constraint.
- Keep the editable generator under `tools/` and run it through the locked `uv` environment. Give
  every random source a deterministic seed. Record the exact rebuild command and seed beside the
  audition.
- Record the sample rate, channels, encoding, processing chain, durations, levels and SHA-256 hashes
  in a machine-readable manifest. Include a frozen copy of the exact generator in each pass and
  name that copy, rather than the evolving tracked tool, in the pass's rebuild command.
- Reuse the current audition folder and filenames for revisions on the open PR; overwriting them
  is allowed. Update the frozen recipe, manifest, page and ZIP together, and refresh the PR's
  commit-pinned links. Keep downloads reasonably small; extra pass folders are not required.

The current lab rebuilds with:

```sh
uv run python tools/synthesize-sfx.py \
  --output docs/evidence/copper-lark-sound-lab-2026-09-26-pass-4 \
  --seed 260926 \
  --selection subtle-revision
```

It writes 48 kHz mono PCM16 WAVs, a local A/B page, an ordered comparison and a portable ZIP. It
does not play audio. Keep the generator's defaults, README and manifest aligned when that behavior
changes.

## Make the comparison honest

Use a documented level strategy across an A/B set. Leave headroom, fade file boundaries, reject
clipped or silent files and keep piercing energy restrained. Equal RMS is useful only when the
audition asks for an unbiased style comparison. When the listening direction itself establishes a
level hierarchy, preserve it: the current lab keeps pass 3 at its submitted level, targets -31 dBFS
RMS for subtler steps and -38 dBFS RMS for wheels that should sit below them, all with a 0.70 peak
ceiling. These targets are audition proposals, not approved runtime mix values.

Establish recognition and implied weight before exploring style or polish. When a listener cannot
tell what a sound represents, focus the revision on the named defect. Keep an earlier take in the
current comparison only when it helps judge that revision. Broad noise is not forbidden, but a rolling mechanism needs discrete
contact or mechanical detail if a broad wash reads as water, and a light step should not be carried
by a heavy low thump.

Automated checks can establish format, non-silence, headroom, clean boundaries, file references and
deterministic rebuilds in the pinned environment. They cannot establish realism, comfort, fit or
preference. Make no listening claim unless someone actually listened. Do not promise cross-platform
bit-identical audio without measuring it; standard-library floating-point math can vary by platform.

## Runtime remains visually fair

Installing an approved sound is a later game change. Audio may reinforce a warning, but the visual
cue must remain sufficient by itself: a player with sound off must be able to make the same route
decision.
