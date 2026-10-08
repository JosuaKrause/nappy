# spotted-osprey — Pelican diagonal comparison

The source sheets compare northeast and southeast anatomy in both pedal phases. Each column
is, from left to right: northeast A, northeast B, southeast A, southeast B. The top row is the
baseline; the middle row is this repair; the bottom row is the repair mirrored westward.
`comparison-1x.png` uses the native 40×44 sources. `comparison-6x.png` rasterizes those same
sources at six times native size. The gray background is a neutral sheet, not game ground.

These are source previews made with Godot 4.7.2's SVG parser, not runtime captures or approval.
The unchanged bicycle, canvas and bottom-center (20,44) anchor provide registration between
frames. The near wing follows the northeast body's side and the far wing is hidden by its
back. The southeast far eye is smaller, above the bill root. Knees point forward in both phases;
the far shins use the side-view family's darker orange to separate the legs.

The baseline is commit `420dcd96`. Current sources and collector are in the same commit as
these images; inspect that commit with `git log --diff-filter=A -- comparison-6x.png` from this
folder. Both source revisions are reachable through this pull request's durable head ref.

To rerender from the repository root with the repair checked out, use a fresh scratch folder:

```sh
pelican_out=$(mktemp -d)
mkdir -p "$pelican_out/project" "$pelican_out/baseline" "$pelican_out/render"
printf 'config_version=5\n' > "$pelican_out/project/project.godot"
for view in back_diagonal back_diagonal_b front_diagonal front_diagonal_b; do
    git show 420dcd96:art/events/pelican_cyclist_$view.svg > "$pelican_out/baseline/pelican_cyclist_$view.svg"
done
"$GODOT" --headless --path "$pelican_out/project" --script \
    "$PWD/docs/evidence/pelican-diagonals-2026-10-07/render.gd" -- \
    "$pelican_out/baseline" "$PWD/art/events" "$pelican_out/render"
```

Retained: two sheets and the source renderer. Individual duplicate rasters and routine check
logs stay in job scratch. Runtime evidence is separate from what these source sheets establish.
