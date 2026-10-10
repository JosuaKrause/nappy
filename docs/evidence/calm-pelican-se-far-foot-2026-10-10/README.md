# calm-pelican — The southeast pelican's far foot in the far leg's orange

The southeast pelican cyclist (`art/events/pelican_cyclist_front_diagonal.svg` and `_b.svg`, the
A and B pedal phases) drew its far foot in the near leg's orange, `#e0843a`, while its far shin and
every other view's far leg use the darker `#b8683a`. Both files now fill that foot with `#b8683a`;
nothing else in either drawing changes. The southwest pelican is the same two files mirrored.

- `se-far-foot-before-after-1x.png` — the eastern row of the pelican sheet (northeast, southeast and
  east, each in A and B), before above after, at the game's own source scale.
- `se-far-foot-before-after-6x.png` — the same row rasterized at 6×, each cell labeled.
- `se-far-foot-zoom.png` — both southeast feet cropped from the 6× sheets and enlarged four times
  more, nearest-neighbour: before on top, after beneath, A on the left and B on the right. The far
  foot is the one behind the frame's down tube, at the right of each crop; in B the wheel and tubes
  cover most of it.

Rendered with Godot 4.7.2's SVG parser through the pelican sheet renderer
`docs/evidence/pelican-diagonals-2026-10-07/current.gd`; `before_after.py` and `zoom.py` crop and
label its output with Pillow, without resampling the art except the zoom's nearest-neighbour
enlargement. The before sheet is the sources at `9d51380fbe2881720821e9b57db7f57e7b527016`, the
after sheet the sources at the commit that adds this folder. To reproduce from a checkout of either,
with `$GODOT` naming the engine and `$before` and `$after` naming the two checkouts:

```sh
work=$(mktemp -d)
mkdir -p "$work/project" "$work/before" "$work/after"
printf 'config_version=5\n' > "$work/project/project.godot"
for side in before after; do
    checkout=$before; [ "$side" = after ] && checkout=$after
    "$GODOT" --headless --path "$work/project" --script \
        "$after/docs/evidence/pelican-diagonals-2026-10-07/current.gd" -- \
        "$checkout/art/events" "$work/$side"
done
uv run python docs/evidence/calm-pelican-se-far-foot-2026-10-10/before_after.py \
    "$work/before" "$work/after" "$work"
uv run python docs/evidence/calm-pelican-se-far-foot-2026-10-10/zoom.py \
    "$work/before" "$work/after" "$work"
```
