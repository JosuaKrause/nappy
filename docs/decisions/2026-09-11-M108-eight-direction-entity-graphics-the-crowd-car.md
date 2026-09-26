## M108 — Eight-direction entity graphics · the crowd car, built 2026-09-11

The crowd half of the vehicle item, built once M111 had given a car a continuous heading. Four
agent commits on `feature/eight-direction-crowd-cars`, reviewed here. **The same table as the
walker's.** `CrowdAgent.CAR_VIEW_BY_SECTOR` is the walker's sector-to-view table verbatim, body
and trim dictionaries keyed by view name replace the two-slot end/side arrays, and the sector
advances through `EightDirection.update()` on `velocity()` with `CAR_IDLE_SPEED` (5px/s, well
under the 20px/s a strike needs) holding a stopped car's last view. Because `heading()` is the
arc's tangent mid-turn, the picture runs side, diagonal, end through a turn with no code of its
own; a test drives a synthetic arc through `CarTurn.heading_at()` to prove both diagonals appear.

**Registration was the work.** The old end view was a foreshortened top-down picture whose height
was the car's along-track length, shifted by half its height to centre the footprint; the prepared
front, back and diagonal views are standing elevations, bottom-centre grounded. So
`_car_body_anchor()` now answers per view: the side view stays at the node, since its width is
already the along-track length `draw_standing` centres; front and back sit `CAR_STRIKE_HALF_LENGTH`
(26px) south of the node, the strike box's own south edge, since the canvas's bottom is the car's
south end; the diagonals sit at the box's south corner rotated 45° onto the screen,
(26 + 14) / √2 ≈ 28.28px, plus the 2px gap `facings.csv` records between the diagonal canvas's
alpha and its edge — a documented literal, since a GDScript constant cannot call `sqrt()`, checked
back against the `Tuning` constants by the test rather than trusted. **The shadow can no longer be
resized by a picture**: `_car_shadow_shape()` read its along and across lengths off whichever
textures sat in the old arrays, and those numbers are now `CAR_SHADOW_ALONG` (52) and
`CAR_SHADOW_ACROSS` (30), unchanged in value. **The shadow turns with the car**: `_travel_axis()`
returns `heading()`, so the capsule and the debug view's shadow layer rotate through the arc; the
bounding-box layer already read the heading. `GroundShape`, the strike box and every radius are
untouched, and `car_end_{body,trim}.svg` is now unbound and says so in `GRAPHICS.md`.

**Tests**: `tests/test_car_views.gd` — the table, body-trim pairing, a stopped car holding its
view, no reset needed on a fresh axis, the halo tracing `_draw_body`, SVG fallback, the synthetic
arc sweeping both diagonals, and the analytic footprint check that derives each view's anchor from
the strike constants and asserts the node inside the drawn rectangle for all eight sectors.
`tests/test_crowd.gd`'s end-on footprint test now asserts the same agreement for the standing views.
**Evidence**: two captures under `docs/evidence/m108-crowd-cars-2026-09-11/` showing back and side
views with box and shadow centred on the body. **Not caught**: a car mid-turn — six windowed tries,
and a turn is two seconds in a rig whose day ends while the mother stands still; the queue's
vehicle bullet carries the capture and names the probe that would take it. **Open to overturn**:
the idle speed's value and the diagonal anchor's 2px allowance.
