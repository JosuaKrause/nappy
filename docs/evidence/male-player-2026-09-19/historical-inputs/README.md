# Original registration SVG inputs

This folder preserves the five original registration SVG inputs independently of the editable
runtime fallbacks. Their hashes match the original `registration.json` record.
`sources.json` maps their original runtime paths to the
frozen files and repeats those hashes; the renderer rejects a mapped file whose bytes differ.

`../historical-registration.json` binds the unchanged original registration config to this
mapping. It also records the hashes of the current registration and renderer scripts, so the
historical command continues to validate every input instead of treating the new support code as
an unverified exception.

To reproduce the original source renders, registration, and static contact sheet from the
repository root, choose fresh output directories:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/male-player-2026-09-19/render-sources.gd -- \
  --source-map res://docs/evidence/male-player-2026-09-19/historical-inputs/sources.json \
  --output-dir /tmp/male-player-historical-source
diff -r docs/evidence/male-player-2026-09-19/source /tmp/male-player-historical-source

uv run python docs/evidence/male-player-2026-09-19/prepare.py \
  --render-dir /tmp/male-player-historical-source \
  --output-dir /tmp/male-player-historical-inputs
diff -r --exclude=inputs.json docs/evidence/male-player-2026-09-19/inputs /tmp/male-player-historical-inputs

uv run python docs/evidence/male-player-2026-09-19/register.py register \
  --config docs/evidence/male-player-2026-09-19/registration.json \
  --historical-inputs docs/evidence/male-player-2026-09-19/historical-registration.json \
  --output-dir /tmp/male-player-historical-registration
diff -r docs/evidence/male-player-2026-09-19/registered /tmp/male-player-historical-registration

uv run python docs/evidence/male-player-2026-09-19/register.py verify \
  --config docs/evidence/male-player-2026-09-19/registration.json \
  --historical-inputs docs/evidence/male-player-2026-09-19/historical-registration.json \
  --output-dir docs/evidence/male-player-2026-09-19/registered

uv run python docs/evidence/male-player-2026-09-19/contact.py \
  --registered-dir /tmp/male-player-historical-registration \
  --output-dir /tmp/male-player-historical-contact
diff -r docs/evidence/male-player-2026-09-19/contact /tmp/male-player-historical-contact
```

The static contact command hashes the supplied registered outputs and the pinned shared stroller
PNG. It does not read active father SVGs, so the historical registered output makes the original
contact review reproducible without a second exception.

`prepare.py` records the chosen render directory as the keys in `inputs.json`; a fresh output
therefore has the same PNG hashes but different path strings. Every rendered source PNG and every
assembled grid is byte-identical, as checked by the excluded-file diff above.
