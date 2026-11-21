# calm-lemur — Fable's verdicts on polite-tapir's six merged designs · 2026-11-21

**What was asked.** The entry calm-lemur: once Fable's quota was back, Fable looks over the designs Opus wrote in its
place while it was out (inbox #1571 in teal-quail); the player asked for it on 2026-11-21 (inbox #1610). Three Fable
agents judged polite-tapir's six merged pull requests, each against the design review item it answered, the Opus
design, the merged code on main and its record, and wrote each change wanted as a design. Shown the verdicts, the
player: "yes, fables complaints are valid. get the fix and then let fable review again".

**Verdicts.**

- **#1564, the city's ways out are a data type (`CityExit`): stands.** One enum was answering two questions and was
  split on that line; the record's three open points (the name and place, `name_of()`, the `Piece` rename) stand.
- **#1570, the map interface's world half split off `WorldMap`: stands, one change.** The building's navigator is
  built inside `EventManager.setup_world()`, the one production path where the simulation builds its own world-layer
  service, and `EventWorld.navigator()` silently replaces a handed navigator whose map differs: filed as snowy-lynx.
  The record's open point "the building's events build their own navigator" is overturned by it.
- **#1548, the beats become rigged marbles in the units ahead of her: stands, two changes.** A mark's rigged row on
  days 6 and 7 comes from no bag, through a second call chain, where the player named the chained bag: filed as
  golden-moose. The fact that a beat stands on a location is stored three times: filed as gray-pelican.
- **#1567, the run log is handed the edge's badges (`EdgeBadges`): stands, one change.** A badge travels as an untyped
  dictionary whose contract is only a doc comment: filed as tiny-quail.
- **#1568, the tree pictures are a data class (`TreePictures`): stands, one change.** Three tree sizes are still
  restated outside it (`City.MIN_TREE_SPACING`, `Prop._draw_tree()`, and a street tree's size held by a test that
  builds a whole city): filed as spry-quail.
- **#1569, `DrawnView` stands in the world beside `VisibleView`: stands, one change.** The crowd is handed the drawn
  box while an event's look fetches it through a static reaching from its node to the viewport, the only place the
  simulation reaches a viewport: filed as minty-newt.

**Noted, not filed:** `name_of(-1)` answers "bridge" for no way out taken; a comment over `City._spine_centre_x()` is
no longer true; `draw_in()`'s comment says null is fine where a spawning manager needs a world; `WorldContext`'s first
sentence names only the baby's role; sunny-osprey's title says "the map's one navigator"; `field-reads.md` lists the
city's navigator as a field `main.gd` reads; the 983 ms worst frame on day 3 that #1548's design promised to remove
was 937 ms after (an input for polite-plover, the remaining slow frames); the 0.28 a tree's ground reaches is both its
shadow and the ground kept clear of events, which the shadow entries silver-egret and plaid-chipmunk should split;
`SceneryResidency._camera_view()` derives the drawn box on its own.
