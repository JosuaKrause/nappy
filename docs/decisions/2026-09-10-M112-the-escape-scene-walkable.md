## M112 — The escape scene, walkable, built 2026-09-10

Asked for, built and redrawn twice in one day. *"as a good exercise we could build out the escape
scene (three floors over ground floor -- top floor is her apartment -- entrance -- basement --
double staircase left and right) without any events just as a special game entry ./tools/run.sh
--start-escape or similar to test out the walking and screen transitions and stair walking.
graphics are her holding the baby … can you do that right now … also create the svg needed for
this"* (playtest 54). Two agents, on `feature/the-escape-scene-build` and `-build-2`; the first
built the whole milestone against the entry's first layout, the second reworked it as the
player's sketches and three further decisions arrived (playtest 55). What M102, the finale, adds
on top is in its own entry; this is the building with nothing in it.

**The building is one map with seven parts on it, 64 tiles apart.** Three hallways (third,
second, first — the same layout each: a 14-tile hallway two rows deep, the north wall in
elevation with lamps, windows and the dead lift, locked apartment doors as thresholds on the
south edge, her own the one she starts in front of), two stairwells, the lobby and the basement,
each at its own origin on one `TileMapLayer` with unwalkable nothing between them; the camera at
zoom 2 sees 20 by 11 tiles, so no part is ever in view from another. **A door is a fade to black,
a teleport to just inside its counterpart, and a fade in** — *"instead of multiple maps have all
parts of the house on the same map with enough space inbetween and on transition fade to black,
teleport, then fade in again"* — so nothing is loaded or freed and there is no "current map",
only her position. The first build was seven separate maps joined by loads; its commit is kept in
the branch's history as the rejected shape.

**Two stairwells at opposite ends, not one shaft with a double staircase.** The sketch drew a
double staircase and both stair doors at the hallway's right end; the player reopened it — *"we
could have one stairway map only show one stairway … and have their doors at the opposing ends.
that way having a fire on the stairs forces you to enter a floor hallway and walk to the other
end"* — and accepted the orchestrator's reading that the lift stays in the hallway's north wall
and the lobby sketch's three notches already are left stairwell, right stairwell and basement:
*"okay, fine"*. Each stairwell is a plain switchback, eight rows per floor, one door per landing
on the hallway side offset one tile west of the landing so that passing a mid-floor landing on
the way down never opens that floor's door underfoot, and the lowest landing's door into the lobby
at the same end. Nine door pairs, each pointing back at the other, asserted by a test.

**A flight is diagonal and she walks it.** *"holding right or left on the switchback stairs moves
the player diagonally"*: the kit's flight tile drops one tile height over one tile width at 45°,
a flight of three tiles occupies a diagonal run, and while she stands on a flight tile
`Stroller._redirect_along_a_flight()` turns a sideways press into the slope's own direction —
`slope_dir_at`, a `Callable` the escape scene installs and the city never does — so key, tap and
joystick all walk the treads and never off them sideways. This closed the entry's own open
refinement (a constant height with a drop implied by the pictures) before it was walked.

**The stair kit.** `assets/interior/stair_flight_{e,w}.svg` (a four-step, 45° tread-and-riser
silhouette on a full 32×32 canvas, so a run repeats per tile), `stair_landing.svg` (the
stairwell floor's own checker plate with an inset frame), `stair_rail_{e,w,level}.svg` (45° and
level rail overlays with four balusters, drawn in front of her), `stair_newel.svg` (16×40, a post
at every landing), plus `wall_lamp.svg` (a wall tile rather than an overlay, the smaller fit for
the wall's one-texture-per-column drawing), `basement_debris.svg` and `rat.svg` (ground decals).
`stair_down.svg`, the prepared one-picture module, is archived under the rejected-graphics rules
as human-rejected: *"the inner stairs need to work as tiles and need to be walkable so they need
to be actually 2.5D and be separated in handrail and stair tiles and landings"*.

**What the build learned, kept in the code's docstrings.** Cross-script enums are not one type,
so every value crossing a file in `src/interior/` is an `int`. Two diagonal flight tiles touch at
a corner point, and a full-tile collision box on each flanking cell pinches that corner to zero
width, which no circular body crosses — she stood still on the first flight in the first burst,
with every headless test green, because no suite here drives collision-checked movement;
`InteriorMap._mark_diagonal_clearances()` frees both flanking cells of every diagonal adjacency
and a data-level test holds it. Camera limits smaller than the camera's own view pin the camera.
The exit returns to the title by pausing and opening it rather than reloading, since a reload
would re-read `--start-escape`. Escape mode opens a telemetry run log so bursts work.

**`--start-escape`** (debug only, `?escape=1` on the web) starts at her door; `--start-escape
stairwell:left|stairwell:right|lobby|basement|floor:2|floor:1` teleports to a part, which is
how the evidence was taken without walking. `Stroller.carrying` draws the prepared
`mother_carrying_*` frames facing for facing, no pram, the baby cue over the bundle; her
collision is unchanged. No `City`, events, crowd, day clock or debug layers exist in this mode.

**Choices open to overturn, made where the design was silent.** The door offset side (west of
every landing), the slot order and the 64-tile stride, the basement's exact jogs (three
brick-walled bands, right then left, entered by a two-tile flight), one `stairwell_door.svg` for
every door whatever it leads to, a newel at every landing including the mid-floor turns, facing
north on arrival, the exit's title-restart behaviour, no pause screen in this mode.

**Evidence**: `docs/evidence/m112-stairs-2026-09-10/` (the kit at native and 3×, one assembled
switchback) and `docs/evidence/m112-escape-2026-09-10/` (one capture per part and a burst of her
walking a flight, with the pinch defect and its fix written up in the README). **Nobody has
walked it**: whether a flight reads as descending, whether the fade-and-teleport reads as a door,
whether eight rows a floor reads as a stairwell and whether five floors is *"not excessively many"*
are the played questions.
