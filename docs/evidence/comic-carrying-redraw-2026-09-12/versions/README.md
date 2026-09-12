# Carrying redraw versions

- **A — Upright bundle** is the previous runtime family rejected by the player. Its raw atlas,
  registered PNG snapshots and provenance remain under `docs/evidence/comic-rig-2026-09-12/`.
- **B — Round silhouette** fixes the cradle but enlarges the mother's head and shortens her legs.
  `b/raw.png`, `b/prompt.txt` and `b/registered/` preserve it for human comparison only.
- **C — Alternating stride** makes the second gait more distinct but retains the enlarged head and
  short proportions. Its generation source, selected edit, both prompts and registered previews
  are under `c/` for human comparison only.
- **D — Matched proportions** preserves a localized edit of the adult pushing atlas with two gait
  frames. Its selected raw atlas, exact prompt, source inputs and previews live at the record's
  top level.

The current carrying family is [E — Clear strides](../../comic-carrying-strides-2026-09-12/GENERATION.md),
with three poses and a feet-together idle frame. The four-version comparison remains fixed.

B and C are evidence of human-visible alternatives. They are not style, identity or pose inputs
for D or for future artwork.

## Rebuild the A–D comparison

`make-comparison.py` rebuilds the saved `all-versions.png` sheet from the registered PNGs and
refuses to overwrite an existing destination. From the repository checkout, use a fresh path:

```sh
comparison_dir=$(mktemp -d)
UV_CACHE_DIR=/tmp/nappy-uv uv run python \
  docs/evidence/comic-carrying-redraw-2026-09-12/versions/make-comparison.py \
  "$comparison_dir/all-versions.png"
```

The reproducible run uses CPython 3.14.7 and Pillow 12.3.0 from the locked `uv` environment.
The script uses the macOS Arial fonts at `/System/Library/Fonts/Supplemental/Arial Bold.ttf` and
`Arial.ttf`; those system fonts are part of the rendering dependency. The regenerated output is
byte-identical to the checked-in `all-versions.png`.
