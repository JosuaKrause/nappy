# D walking rollout

This evidence assembles the registered D carrying pixels into the eight directions selected by
D's gameplay drawing path. The static sheet shows each direction's two-frame loop as
`A → B → A → B`; the GIF shows the same loop in place at 190 ms per frame. The A and B PNGs are
the individual GIF frames for inspection.

The static sheet is titled **D — Matched proportions** and labeled **Source-frame walking
rollout** so its status is explicit at a glance.

The source files are the ten PNGs in `../registered/rig/`, with the exact SHA-256 values recorded
in `manifest.json`. Each source is enlarged by exactly 6× with nearest-neighbor sampling. The
quiet slate background is added only for review, and all sprites share the registered ground
baseline. West-facing sectors use the runtime mirror convention: SW, W, and NW mirror their
front-diagonal, side, and back-diagonal source views respectively.

The timing follows D's preserved source behavior: `_walk_phase += velocity.length() * delta * 0.09`
(the requested walking-speed shorthand is `92*dt*.09`) and stepping selects B when
`sin(_walk_phase * 2.0) > 0.0`. The GIF is a source animation preview in place; it does not claim
gameplay travel or approval. It deliberately exposes D's known insufficient stride and does not
use E's independent four-phase loop (three unique poses).

`assemble_rollout.py` is the reproducible recipe. Run it from the repository checkout with:

```sh
UV_CACHE_DIR=/tmp/nappy-uv uv run python \
  docs/evidence/comic-carrying-redraw-2026-09-12/rollout/assemble_rollout.py
```

The checked run uses CPython 3.14.7 and Pillow 12.3.0 from the repository lock via `uv`.
Labels use macOS SFNS (`/System/Library/Fonts/SFNS.ttf`), falling back to Helvetica or Pillow's
built-in font when those system fonts are unavailable. The images are regenerated from the frozen
registered inputs; no generative or runtime asset is read.
