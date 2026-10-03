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
- Keep the editable generator under `tools/` (`tools/synthesize-sfx.py`) and run it through the
  locked `uv` environment. Give every random source a deterministic seed.
- No generated audio and no frozen copy of the generator lives in the tree: git history already
  holds every past version of `tools/synthesize-sfx.py`. The current pass gets one entry in
  `tools/sound-lab/passes.json` instead — its seed, its extra `--selection`/CLI args, and the
  SHA-256 of every WAV it writes. `tools/sound-lab.sh` builds it from the tracked
  `tools/synthesize-sfx.py` directly, through the locked environment, into git-ignored
  `build/sound-lab/<pass>/`, and refuses to serve anything whose hashes have drifted from what the
  recipe recorded — the reproducibility guarantee is enforced on every run, not just claimed in
  prose.
- `passes.json` names exactly one pass: the current proposal, with no pinned commit. A branch
  reaches `main` squashed, which would take a pin to one of its own commits with it, and a
  rejected pass is not worth keeping alive anyway — its findings stay in `DECISIONS.md`. Make a
  new pass by changing the generator's defaults or `passes.json`'s `args`, rebuilding with
  `tools/sound-lab.sh`, and listening; once it is worth keeping, overwrite `passes.json`'s
  `seed`/`args`/`label` and every hash with the new build's own. Live iteration on the generator
  before it is worth freezing this way is `uv run python tools/synthesize-sfx.py --output
  build/sound-lab/scratch --seed <n> --selection <name>` run directly, with no change to
  `passes.json` yet.

**Share a pass as the command to run, never a zip or a committed page.** Point at
`tools/sound-lab.sh`; `--lan` prints an address a phone on the same network can open, and
`--no-serve` builds and verifies without serving. Nobody downloads an `index.html` or a zip to
listen.

It writes 48 kHz mono PCM16 WAVs and a local A/B page, one clip playing at a time. Keep
`tools/sound-lab/passes.json`'s recorded hashes aligned with the generator whenever the pass
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

The release Web engine plays WAV without a profile change, but omits Ogg/Vorbis and MP3 decoders;
before adding either compressed format, follow
[Turning a module back on](../../../tools/web-template/README.md#turning-a-module-back-on).
