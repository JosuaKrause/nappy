## M53 — The bollard · built 2026-09-08

The milestone's last piece, a drawing: a street that met a precinct simply ended flush against the
paving, which read as the road running out rather than as a street closed on purpose, while six
code comments and `docs/CITY.md` explained the precinct by a driver *"meeting a bollarded street"*.
Built by a sub-agent from a brief, with the player's leave to use **placeholder SVG graphics**
*(2026-09-08: "if you need to you can create svg placeholder graphics")*.

**A line of posts across the carriageway at each mouth, seen from above.** `assets/props/bollard.svg`
is a 12px post-head — rim, body, offset highlight — in the house style, not a post in elevation
turned on its side (the mistake M49 records for the fence). `Prop.Kind.BOLLARD` draws it through
`Sprites.draw_standing` with the ordinary shadow, feet-anchored so it y-sorts.

**Placement is geometry, not a roll.** `City.bollard_positions(map)` is static and stated over the
map alone: for each span in `CityMap.precinct_spans` one row on the first tile of paving and one on
the last, spread across the carriageway band only — the middle two tiles of the corridor — so the
pavements run past the posts and a pram walks through where a car does not. `BOLLARD_SPACING`
(14px) gives five posts on the 64px band; the count is derived from the cross-section rather than
fixed. `tests/test_generator.gd` holds it over the precinct test's seeds: two rows per span, every
post on a `PEDESTRIAN` tile of its own corridor and on the carriageway, and the tile one step past
each row not precinct.

**Chosen where the brief was silent, open to overturn:** the posts are rebuilt every `start_day`
beside the trees rather than once per run, because they need no seed and `_dress_blocks` stays the
one owner of every prop. The capture is
`docs/evidence/archive/session-captures/2026-09-08/rig-190124-seed4242-v0.7.0-2-g7f9cc02-dirty/bollards-precinct-mouth.png`
— seed 4242, day 1, the precinct's west mouth — and shows the five posts in a vertical line where
the open paving meets an ordinary crossroads, the pavement strips unbroken on either side.

**The bollards did not address the complaint, and the player said so the same day.** [PLAYTEST-37.md](../playtests/PLAYTEST-37.md):
*"the original complaint was that there is a zebra crossing at the edge of the precinct which
shouldn't be there"*, and *"we can keep the bollards but it doesn't address the complaint"*. The
2026-09-02 instruction — *all roads leading up to a precinct should be t-junctions at the edge* —
had been built for the junctions **inside** a span and not for the crossroads at either **end**,
which `CityMap.street_kind()` left ordinary because a span *"stops short of the crossroads"*, so
`CityGenerator._street_tile()` laid a zebra on the arm that led into the paving. Four findings
came in one conversation and were built as one rule, **a junction is made of the streets that
actually meet at it**, by the same sub-agent on the same branch:

- **A precinct's end is a T.** `street_kind()`'s `PEDESTRIAN` range widens by `SIDEWALK_WIDTH`
  at each end, reaching the crossroads' own road edge, so every reader — the tile layer,
  `is_driveable_at()`, the brick paint — sees the spur as precinct with no second definition. Read
  rather than assumed: only the precinct corridor's own road offsets in the box's precinct-side
  band change from `CROSSING` to `SIDEWALK`; the crossing street's own zebra depends on a different
  offset and stays. The bollards moved to the new first tile of paving. *Rejected:* calling
  `_seal_stub_crossings()` over the span and patching the paint separately, two definitions of
  one extent.
- **The border is T-junctions, except at the tunnel and the bridge.** *(2026-09-08: "the border of
  the city grid also should have t-junctions (except for tunnel and bridge)".)* A new
  `CityGenerator._seal_border_stubs()` runs after the streets are laid and turns any `CROSSING`
  within `SIDEWALK_WIDTH` of any edge into `SIDEWALK`, stated over *a side* rather than four
  hand-written rects (M49's own warning), with the spine's two exits read off the same edges
  `City._spawn_spine_exits` draws them on. No walkable tile moves.
- **The main road's crossings are the thin-line style on all four arms.** *(2026-09-08: "since all
  have traffic lights".)* `GroundTiles._crossing_variant`'s predicate is *either corridor at this
  tile is `MAIN`* rather than *the carriageway being crossed is*, the junction's property rather
  than the arm's; the orientation logic is unchanged and the `CROSSING_MAIN_W`/`_E` sprites, which
  existed and were never reachable, draw for the first time.
- **Out of bounds is blocked.** *(2026-09-08, on the branch: "it's now correctly t-junctions but
  the cars and people still go off the map".)* `CrowdAgent._cannot_go_on()` and
  `_stands_on_a_street()` refuse any out-of-bounds tile except a car on `main_road` crossing the
  north or south edge — never a walker, playtest 16 finding 3. Found by the first test run rather
  than by reading: `_recycle()`'s six-roll fallback could still drop a body out of bounds near a
  true edge (a car on 1088 of 1200 frames at the north edge), so a roll that fails placement is
  clamped onto the map's last row or column, and a fencepost — `world_size()` itself floors to an
  out-of-bounds tile — is clamped to one pixel inside. `tests/test_crowd.gd` holds it over seeds
  and frames. Built under a line-level fence into `src/crowd/`, since the halo milestone owned the
  rest of the file at the time.

The captures, whole run folders under `docs/evidence/archive/session-captures/2026-09-08/`: the
precinct's west mouth as a T with the posts on the paving's edge, the north border with its
top pavement unbroken, and a spine junction with dotted crossings on the side street too.

**What is open.** Whether five dots read as *closed on purpose* while walking; the asset is a
placeholder the graphics overhaul may redraw. And the border as a wall to the crowd has been
tested and not watched: bodies now turn or clamp at the boundary pavement rather than walking
into the mountain, and whether that reads as a city edge is a played question.
