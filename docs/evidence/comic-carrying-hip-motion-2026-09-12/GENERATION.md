# F — Hip motion · SVG source review

This draft covers SVG source review before illustrated generation. The frozen source family uses
the runtime's 24×46 front/back canvases and 26×46 side/diagonal canvases, all bottom-center
anchored. Runtime order is A, C, B, C at four equal 190 ms diagnostic phases; C is also the idle
pose. East-authored side and diagonal sources are mirrored horizontally for west.

The targeted correction changes the front A/C/B lower-body geometry and rear-diagonal A/B. Front A
leads with the screen-left leg, front B leads with the screen-right leg, and each connects that leg
from hip through knee to shoe with its own knee flexion, heel height and lower-coat rotation. Front
C plants both feet in the together pose. Both
rear-diagonal contacts use the NE projection: their leading endpoint is upper-right and their
trailing endpoint is lower-left while the leg ownership changes. The remaining source drawings
are frozen unchanged for family context.

`source/svg/` holds the exact reviewed SVG inputs. `source/source-manifest.json` records their
SHA-256 values, dimensions, anchor and the review font. `render-svg-sources.gd` rasterizes all 15
inputs at native size and 6× with Godot's SVG parser. `assemble-source-review.py` refuses changed
inputs, then writes per-view A/C/B strips, diagonal comparisons, four-phase eight-direction sheets
and GIFs. These are source previews, not generated PNGs or gameplay captures.

From the repository root:

```sh
./tools/check.sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
  --script docs/evidence/comic-carrying-hip-motion-2026-09-12/render-svg-sources.gd
uv run --project . \
  docs/evidence/comic-carrying-hip-motion-2026-09-12/assemble-source-review.py
```

The retained recipe uses Godot 4.7.2 stable (`ed1daf0bf`), uv 0.12.10, Python 3.14.7 and Pillow
12.3.0. Labels use `/System/Library/Fonts/SFNS.ttf` at SHA-256
`2bfd40dc72e6759e248f82a52a40d551338979fffc9b5c070e685b4b7ad19e66`.

Review `source/strips/front-acb-6x.png` for the three targeted front poses and
`source/diagonals-acb-6x.png` for the authored southeast/northeast axes. The complete runtime mirror
and loop review is `source/eight-direction-acbc-6x.gif`; its static counterpart shows all four
phases without relying on GIF playback.
