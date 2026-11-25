# brisk-koala — The busker's strum, a café sitter's lean, a poster crew's brush and a firefight's flashes redraw only what moves · 2026-11-25

The audit the player's guarantee asked for after the four scenery cases (sunny-lynx: a sprite with
only partial motion keeps its stationary pixels in a static drawing and composites the moving parts
separately), as an optimization with its measurement (PLAYTEST-86). Evidence:
`docs/evidence/brisk-koala-figure-parts-2026-11-25/`.

**Which pixels move, read off the frame pairs rather than assumed.** Compared element by element:
the busker's strum changes only the arm, in all five views; a café sitter's lean moves only the
upper body, the lap stays; a poster crew's paste changes two spans (the brush arm, and the sheet
with the arm that holds it), and only its back view has a second frame at all.

**Built.**
- `tools/split-scenes.py` splits those eleven pictures as it already split the pipe and crash
  scenes: cropped `_static_*` and `_motion_*` SVG spans under `art/events/`, the parts table
  `src/events/data/event_scenery_parts.gd` and the atlas list. Every recombined frame matches its
  full picture within one alpha level and about two colour levels (the parity sheets).
- `EventScenery` can mirror a figure about its feet. The busker and a crew stand their figure as
  layers on the event (`FigureLook`), over the shadow the event draws; a café table's slice holds
  its sitter's layers and draws the table on a new front node (`SpreadLook.Front`) over the sitter,
  so painter order is kept. The three idle animations left the picture key, so a swap redraws only
  the moving layer; the basement steam keeps its swap in the key, since the whole cloud moves.
- Moving layers turn to their frame only while the event is in the drawn box, which also stops the
  crash's and burst main's layers flipping off screen.
- **The firefight's muzzle flashes moved to each gunman's slice front**, redrawn on every drawn
  frame (`RankLook._update_scenery()`, `Slice.redraw_front()`), and the firefight left
  `EventLook._picture_never_settles()`: its gunmen and shadow now wait for the key. The flashes
  are drawn by the same calls in the same order as before.
- The halo and badge still use the complete pictures.
- **The danger caret over a busker or a crew is drawn on a node of the look's own, put in after the
  figure's layers** (`FigureLook`), as a café's table stands over its sitter. Drawn on the event's
  own canvas it was under them, and between the busker's beats (his field pulses every 7 s) the
  shrunken chevron's tip reached about 3 px into his head. It now stands over the figure as it
  did over the whole picture on `main`; `tests/test_event_carets.gd` holds the order.

**Measured.** `tests/probes/brisk_koala_idle_redraws.gd`, run on `main` (`c051a7de8`) and the
branch, counts the `_draw()` calls of every canvas an event stands. Over ten seconds of its clock:
the busker's event redraws 40 times on `main`, laying 40 pictures, and none on the branch, where a
moving layer redraws 40 times; a crew's front view, whose frames are one picture, went from 25 to
nothing; a café's event and slices (6 and 12, 24 pictures) went to none, its moving layers 12; the
firefight's event and slices (600 and 1200, 1200 gunman pictures) went to none, its fronts 1200
with two circles each. The frame record (`run.sh`, three alternating rounds, headless and
windowed, days 1 and 4, seed 67, load average 2.0 to 4.1, no other engine running at any start)
shows whole-frame medians within the spread of each revision's own runs (windowed day 1 3452 →
3493 µs, day 4 3669 → 3635) and the events' and scenery's `_draw()` calls per frame halved
windowed (0.4 → 0.2): the work removed is small against a frame on those days, and shows in the
counts rather than in frame time.

**Not split, with the reason measured.**
- **The burning building**: every flame changes height on every frame (`sin(age × 9)` per flame),
  so the event's canvas redraws every frame whatever is split. The smoke is the only part still
  between its swaps, one picture in six on open ground (600 of 3600 over ten seconds), on one
  instance on day 3. Moving it to a node of its own would keep five sixths of the work and add a
  canvas.
- **The loudspeaker mast's lamp**: the mast redraws twice a broadcast cycle (two redraws, five
  pictures in 22 seconds). Nothing to remove.

**Looked at in the game.** Stills on `main` and the branch at the same seed and spot (`ingame/` in
the evidence folder) of a busker on a square, a café on an east–west street and one on a
north–south street show the same picture: the parts on the figure's feet, each sitter under its
table, the shadow under the figure. Not in a game still: a busker facing west, which the game never
sites (he stands on a park or a square, which has no sidewalk side to turn him, so
`PlanBuilder.build()` leaves him facing east), whose mirror the suites hold; and a poster crew seen
from behind, sited from her walk (`WalkSiting`), which neither `--spawn event:poster_crew`, a scene
recipe nor the seed-67 walk on day 4 put on screen.

**Open, the builder's choice for the reviewer and the player.** A café table is five canvas items
instead of one (its slice, the sitter's scenery node, that node's static and moving layers, and
the front), a busker five more than before (the scenery node, three layers and the caret's node)
and a crew seen from behind seven: a little renderer cost per item against not rebuilding the
table or the figure on every swap. The renderer's draw calls stayed within two.
