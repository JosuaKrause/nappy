## M61 — One shape per object · the shape, the shadow and the body, built 2026-09-10

The datum and two of its three consumers, on `feature/one-shape-per-object`; the field is still a
point falloff and stays in `TODO.md` under M61. Four agent commits and one merge, reviewed here.

**What a shape is, and why it is not the rectangle the entry asked for.** `GroundShape`
(`src/ground_shape.gd`) is a spine plus a rounding radius: a point (a disc), a segment along the
object's own X (a capsule), and — for a building's footprint alone — a rectangle. The entry as it
stood on the morning of 2026-09-10 said *"we can restrict bounding boxes to be rectangles which then
defines the shadow and minkowski influences as stretched rounded rectangles"*, and the brief this
was built from predated that sentence: it was written from the entry as it was the day before,
because the session started on a `main` that PR #73 had not yet reached. Put to the player with the
capsule slice already built and green, the answer was *"I said rectangle because it's easier. If
you can do more complex things to it that way"* — so **asked for rectangles · overturned to the
point, segment and rectangle datum on 2026-09-10**, in those words. A rectangle is kept only where
nothing else describes the object: `Building.shape = GroundShape.rect(footprint * 0.5)`, from
which its `RectangleShape2D` is now built rather than sized separately.

**Every spread stands on a capsule of the same reach as the disc it replaces, with a fixed 24px
half-thickness** (`GroundShape.BAND_RADIUS`; `band(reach)` derives the segment, and a reach at or
under 24 stays a point). The number holds two guarantees at once, and both are asserted in
`tests/test_shapes.gd`: a 48px-thick band on a 64px pavement band leaves 8px a side, under her 14px
body, so every pavement a band blocked as a disc is still blocked; and a capsule of a given reach
lies inside the disc of that reach, so every reachability guarantee stated over `obstructs_radius`
holds by inclusion. `obstructs_radius` is kept as the number every planner reads and is
`shape.reach()` by construction — `EventDef.solid(shape)` sets both, `validate()` refuses a row
whose two disagree, and a row with a look and no shape fails boot.

**The axis is the load-bearing fact for the seals.** A hard seal's bodies are spaced so circles of
`obstructs_radius` cover the street kerb to kerb; with a capsule that is only true if its spine lies
across the street. `_spread_is_vertical()` already lays a spread along local Y on an east–west
street and local X on a north–south one — across the street either way — and
`_test_a_hard_seal_capsule_spans_the_street_not_the_kerb` now states it: a `barricade` built at a
hard-seal position on each street orientation has `_solid_axis()` perpendicular to the street (dot
product 0.0 on both) and a `CapsuleShape2D` rotated to match.

**The rows' shapes, as built.** Segments (half-length, radius 24, reach): `roadblock` 36/60,
`barricade` 38/62, `protest` 31/55, `fallen_tree`, `car_accident`, `burst_water_main` and
`collapsed_frontage` 72/96, `burnt_shell` 12/36, `construction` and `scaffolding` 8/32,
`firefight` 6/30, `market_stall` and `moving_van` 4/28. Points at their old `obstructs_radius`:
`cafe_tables` 24 (a 48px frontage has no spine to be a capsule about), `delivery_van` and
`abduction` 22, `night_raid` 44, `burning_building` 30, `ice_cream_van` and `burnt_out_car` 24,
`reversing_lorry` 28, `busker`, `leaf_blower` and `poster_crew` 11, the three checkpoint rows 32.
Points at their old hand-picked shadow radius for the rows that obstruct nothing: `fire_truck` and
`military_convoy` 26, `police_patrol` 19, `chatting_mother` 14, `charging_dog` 13, `cyclist` 12,
`homeless_yeller`, `loose_dog` and `alley_robbery` 9, `dog_walker` 8, `cat_dash` 7, and a nominal
5 on `pigeon_flock`, whose birds each cast their own. Off the catalogue: a walker `point(7)`, a
car a capsule read off its own two textures (reach 26, across 15 — never smaller than the
`CAR_STRIKE_HALF_LENGTH` 26 by `CAR_STRIKE_HALF_WIDTH` 14 strike box, which a test holds, on the
player's *"lethal != noise"*), she `point(9)` and the pram `point(12)`, a tree `point(0.28 ×
width)`, the bollard `point(0.4 × width)`, the swing frame a capsule from its texture, a building
its footprint. The traffic light and the closure marker keep a point literal with a comment saying
so. The car, the walker, she and the pram have no body, as before.

**The shadow.** `assets/props/shadow.svg` is gone. A point shadow is the same `2r × 0.8r` ellipse
it always was, drawn as a circle under a Y scale of 0.4 (`GroundShape.SHADOW_SQUASH`, the oblique
view's own foreshortening of a contact shadow); a segment's is the spine swept with that ellipse —
the convex hull of the two end ellipses — rotated on the ground plane unsquashed, since tiles are
square; a rectangle's is its four corners rotated and then squashed. The halo still skips it.
Evidence: `docs/evidence/shot-2026-09-10-seed4242-m61-shape-before.png` and `-after.png`, a
`construction` band and a passing car on seed 4242, day 2.

**A bug found on the way, and the reason `shape` is copied by hand.** `Resource.duplicate()` copies
only properties with storage usage, and a plain `var` typed as a `RefCounted` has none, so both
`EventDef.at_heat()` and `SealPlanner.sealed_variant()` silently dropped the shape from every
derived row until `check.sh` failed on a seal candidate with *"Nonexistent function 'draw_shadow'
in base 'Nil'"*. Both now assign `shape` across explicitly; `test_shapes.gd` checks every heated
copy at every level and every seal candidate's sealed variant.

**Merged with main mid-build.** Main's PR #75 wrapped every drawn texture in
`TextureResolver.resolve()` for the PNG-first presentation, including the old shadow texture in
`Sprites.draw_shadow()` and `_draw_wide_scene()`'s vertical fallback; this branch had removed that
texture, so its side stands in both conflicts and there was nothing left to resolve. The transfer
set carries no shadow PNG, so nothing is orphaned. Main's `tests/test_visuals.gd` used `shadow.svg`
as "an SVG with no PNG transfer"; it uses the bollard now.

**Choices open to overturn, made where the design was silent.** `pigeon_flock`'s nominal point
exists only to satisfy "a row with a look has a shape". `checkpoint_post`'s shape is the
checkpoint's 32px body rather than the guard figure's 8px, so its shadow grew. Per-part shadows —
the dog on its lead, the abduction's victim, the guard beside the hut — keep their own point
literal, since a two-body composite has no single shape to be either body. `GroundShape.Kind` is
a real enum rather than the sign of `half_length`. The capsule hull is not antialiased because
`draw_colored_polygon` has no flag for it.

**Built before M104, the debug view, against the entry's own order**, on the player's instruction
that M61 was the next task; the entry's reason for the order — that the derivations cannot be
checked by a rig alone — stands for the field half, and the shadows and bodies here are checked by
eye once the layers exist.
