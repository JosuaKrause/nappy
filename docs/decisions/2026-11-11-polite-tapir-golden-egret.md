# polite-tapir — Her line is followed from a junction box onto the sidewalk she walks, and one sidewalk of each of her routes' streets stays open (placement step 2, the street rules) · 2026-11-16

**The ask.** Placement step 2 of `placement-by-construction.md`, the street rules: a rule that follows her line the way
the free-line probe does, from the crossing onto her sidewalk, for every row that lands near her route, which the player
accepted as option C of the free-line-density question (inbox #1461); and that one sidewalk of a street stays walkable
past the drawn events where a street needs one, which the player's own correction of inbox #1465 limits to the streets
that already require it. This is the pull request #1476, the first of the step's two parts (part B of the Fable design,
the street rules); part A, the dog walker, the patrol and the convoy sent just ahead of her, is #1477 (its own record).

**Read as** (the orchestrator's readings, each open to the player's correction):

- Option C's "her line" includes the home street, which the route tree does not carry (a door is not a route). The
  free-line probe (`tests/probes/m129_zero_cost_line.gd`) already starts the line in the home and takes the home street,
  both sidewalks, as ground.
- The correction of inbox #1465 makes no street newly required to keep a walkable sidewalk. Where a rule already
  requires one, the draw makes sure of it by construction; today those streets are her routes' own streets and the
  escape's walk, which keeps its own rule. The streets beside the routes and off them keep PLAYTEST-17's blocking events
  all over. So the one-sidewalk rule covers the streets a route runs along and nothing else.
- A roadblock on her routes' streets is asked by the one-sidewalk rule like any body. The words behind it were said of
  the escape's roadblocks (inbox #747 in woolly-penguin); that they hold on an ordinary day's route is the orchestrator's
  reading.
- A roadblock's band is its body at every heat, as the escape reads the same hunting roadblock (`WalkGround`): the
  orchestrator's pick on the board question `heated-roadblock-body`, open to the player. The record downy-llama holds what
  the player then decided about the roadblock's width.

## What was built

- **`RouteLineRule`** (`src/events/street_rules/route_line_rule.gd`) replaces `RouteJunctionsRule`, which is gone, not kept
  beside it. Each junction box her routes cross is flooded together with the sidewalks she walks to it and from it. The
  ground is the box's open tiles, the walked sidewalk of each route street that meets the box, and the off-street tiles a
  route runs along beside the box or a walked sidewalk (an alley's mouth, a park cut); where a pacing row stands, that
  street's far sidewalk is added, since the man shouting is passed on the far side (PLAYTEST-71). A tile is free where no
  standing row that counts against the line denies it. A candidate is refused unless one flood from the first arm's far
  end reaches a tile of the box, every other arm's far end and a tile of every mouth. A box with nothing to start from
  must keep one free tile.
- **The home street is an arm of its two boxes**, with both sidewalks taken as walked, whether or not a route crosses the
  box. `Corridor.street_it_starts_in()` carries the tree's home street (`RouteTree.street_it_starts_in()`, null for an
  empty tree), so the rule needs no tree. The city skill's doorstep exemption from the route-redundancy guarantee is
  untouched: nothing that counts distinct routes asks the corridor for the home street.
- **`OneSidewalkOpenRule`** (`src/events/street_rules/one_sidewalk_open_rule.gd`) keeps one sidewalk of each street a route
  runs along open past the bodies drawn on it, from both directions (a body in the box at a street's end that reaches the
  street's last open sidewalk is refused as well). A street a closure, a seal or the wall already closes refuses nothing.
  There is no setting for which streets it covers.
- **A roadblock is read at its band** (60px, the sidewalk on its own side and the road) at every heat, in one function,
  `_closing_radius()`, keyed on `EventDef.spans_the_street()` and no row's id. From heat 4 its hunting copy answers its 86px
  lethal inner disc as `blocking_radius()`, which would take both sidewalks and so refuse every route-street roadblock by
  itself. The alley robbery's and the charging dog's pursuits, which have no body, stay read at their lethal disc, which
  takes one sidewalk.
- **`StreetInvalidation`** composes both rules for a walk with a corridor and no `WalkGround`; the escape keeps its own,
  stricter rule. `EventPlan.walks_a_beat()` is new and `denies()` asks it; `RouteSidewalkRule.is_a_carriageway_tile()` is
  public so the line rule takes a street's ground the same way; `Corridor.of()` copies the tree's home street;
  `RouteGroundRule` and `RouteSidewalkRule` stay as they were.
- **A measurement member**: `StreetInvalidation.refusals()` counts how many times each rule refused a candidate, by rule
  class name, printed by `tests/probes/walk_rows.gd` as `WL day rule count`, kept in `tools/test_only_members.txt` as a count
  of work done.
- Docs: `docs/EVENTS.md`, `docs/CITY.md` (a new section, "A street of her routes keeps one sidewalk past its bodies"),
  `docs/ARCHITECTURE.md`, `docs/MECHANICS.md` and the city skill; `tools/layer_map.py` lists the two rules as street rules.

## Measured

Heat 0, base `0296c814f` against `5a944841c`. The later commits change nothing a heat-0 day reads.

- **The free-line probe** (6 cities, days 1, 5, 9, 13): routes keeping a zero-cost line went from 289 of 299 to 299 of 299;
  the reviewer's twelve other cities gave 591 of 591. Pacing rows read over their whole beat went from 176 to 182 of 299.
- **What the day places** (`tests/probes/placement_rows.gd`, 18 cities, days 1 to 14): 50,879 rows placed on the base, 50,784
  on the branch (on the route 12,862 to 12,823). The thinning sits where the design predicted: wide rows near route
  corners, and the man shouting (1,571 to 1,520). Nothing was fitted. Roadblocks per day for days 7 to 14 are the base's.
- **The walk** (`tests/probes/walk_rows.gd`): route tiles cut off from home 0 on both; streets of a route with both
  sidewalks closed by bodies 1 of 17,490 on the base and 0 of 17,492 on the branch; route-adjacent and off-route streets
  unchanged (223 of 5,398 and 107 of 6,888), since the rule does not cover them. One unit's draw cost is within the runners'
  noise (CI's per-suite times 2.8% over the merge base's).
- **Refusals by the dawn's judge**, summed over days 1 to 14: `RouteLineRule` 41,716, `OneSidewalkOpenRule` 7,
  `RouteGroundRule` 108, `RouteSidewalkRule` 3,652, `PacingOpeningRule` 4. On her routes' streets the line rule refuses
  nearly every pair first.
- **Heat 4** (18 cities): route-street roadblocks 12, 10 and 5 on days 9, 10 and 11 with the band read; the same with the
  rule left out; 0, 0 and 0 with the lethal disc read as the body. Day 13's roadblocks (353 over 18 cities, the base's
  number) all stand beside the routes, which the rule does not cover.
- The `FP escape` and `FP building` lines of `placement_fingerprint.gd` and the output of `escape_roadblock_spacing.gd` are
  identical to the base.
- Every test fails with its line removed: 22 mutations, each applied alone and its suite run (the line rule's flood, its
  mouths, the home street as an arm, the corridor's copy of the home street, the roadblock's exemption and band, the
  streets covered, the composition in `StreetInvalidation` for the day and for the escape).

## Rejected, and the forks the first build brought back

- **A setting, `OneSidewalkOpenRule.COVERS`, for which streets the rule covers** (`NEAR_THE_ROUTES` or `EVERY_STREET`):
  deleted after the player's correction of inbox #1465, since a setting would have one value.
- **Reducing the rule to a roadblock check**: a pursuer (the alley robbery, the charging dog) does not count against the
  line, since it follows her rather than holding a tile, yet it stands as a body; a pursuer on one sidewalk with a
  roadblock or a second pursuer on the other closes a route's street with every line rule satisfied (seed 90303, day 9, a
  robbery then a roadblock). A roadblock-only check would still let a robbery drawn after a roadblock close the street.
- **Exempting a row that spans the street** (the first build): a roadblock placed second closed a street's last sidewalk. The
  exemption is deleted.
- **The home street as no arm** (the first build): a man shouting on a street beside the home street put a lens over the
  whole mouth where a route's ground opens onto it (seed 129323, day 1); with the home street an arm, that spot is refused.
- **Reading the hunting roadblock at its lethal disc**: with the roadblock as one of her routes' bodies it refuses every
  route-street roadblock at heat 4 (the table above). Kept as the alternative the board question offers.
- **Judging two wide rows at the two ends of one walked sidewalk together**: left open, as option C's condition says,
  to be closed only if the probe shows free lines lost. It shows none.

## Choices where the design was silent (each open to overturn)

The flood must always reach a tile of the box, not only with one route street, so the old rule's guarantee holds where two
streets join without passing through it. A mouth is an off-street route tile next to the box or a walked sidewalk, never
next to a far sidewalk, and mouths are grouped four-connected. A pacing row stands on a street where it was placed or where
a corner of its beat lies. A far end is the outermost open non-carriageway column away from the box. The off-street cost half
is tied to the existing setting (`counts_the_streets` off, the day's judge), with no new flag. The one-sidewalk rule reaches
the streets any tile of whose rect lies within the body's bounding square, with her radius on the body, and asks those on her
routes. The home street's two boxes are pieces even where no route crosses one, which costs three men shouting over 18 cities
and 14 days against the first build.

## Review

The first review (changes requested) found the description describing an earlier head, the heat-4 roadblock reading, and a
queue sentence; the second found one doc sentence the fix made untrue (`docs/EVENTS.md` said a hard-fail event counts by its
lethal disc); the third approved the docs-and-comments commit. The reviewer's own heat-4 run on twelve other cities agreed
with the description (route-street roadblocks 5, 8 and 11 on days 9, 10 and 11, and 0 of 834, 763 and 767 route streets with
both sidewalks closed).

## What stays open

Step 2's three route rows sent ahead of her, which #1477 builds and the record `polite-tapir-tall-ibis` finishes.
