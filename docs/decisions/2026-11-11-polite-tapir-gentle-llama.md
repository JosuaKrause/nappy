# polite-tapir — The city edge's kinds: the way out of the city is CityExit, a data type, and CityEdge keeps its pieces · 2026-11-19

**What was asked.** polite-tapir's `standing-layer-breaks.md` holds the layer breaks
`tools/check_layers.py --list` prints; the player's words are that they are not forgotten (inbox #1268
in olive-ferret). This group is "the city edge's kinds". Fable's quota is out, and the player answered
"yes, continue with one fable task at a time and use opus for it" (grassy-bison #1560), so an Opus agent
designed and built it in Fable's place; the pull request (#1564) carries the `fable-only` label. It was
held unmerged for Fable's review of the design (entry grassy-ibis) until the player lifted that
hold while Fable's quota is out (inbox #1571 in teal-quail), and merged on its Opus review.

**What was built.** `CityEdge` (`src/city/city_edge.gd`, the world-layer node that draws where the
main road leaves the map) had one enum answering two questions: which way out of the city she takes,
and which piece of the edge a node draws. Because the first went through the drawing class,
`src/finale/finale_planner.gd` (model) named the world ten times and `src/ui/texts.gd` (data) twice.
The way out is now `CityExit` (`src/city/city_exit.gd`, placed in the data layer by its own entry in
`tools/layer_map.py`): `enum Kind { TUNNEL, BRIDGE }` and `name_of(kind)`, which returns the word the
plan's summary and the run log's won line each worked out with the same ternary. Every reader of the
way out names `CityExit.Kind`. `CityEdge` keeps its drawing and geometry; its enum is renamed
`Piece`, so that a lookup left on the old name fails at the parse instead of silently reading
`BRIDGE` as another value. No stored or logged value changes: the kind travels as an int nothing
keeps, and the run log writes the word. The twelve listed uses leave `tools/layer_map.py`'s list and
no break is added.

**Rejected.** Moving `CityEdge` to another layer (it is a drawing node, so the map is right); moving
the five-value enum to data unchanged (it puts the drawing's pieces into the type the texts key on); an
enum in `GameEnums` (no place for `name_of()`).

**Open to overturn (the designer's, and Fable's to judge):** the name `CityExit` and its place in
`src/city/`; `name_of()` on it; the rename of `CityEdge`'s enum to `Piece`.

**The item.** The group leaves `standing-layer-breaks.md`'s list; its sentence there said the kinds
were read by `main.gd`, the rigs and the run log, which sit above the world and were never breaks.
The two road-stub pieces `CityEdge.Piece.ROAD_EAST` and `ROAD_WEST` are reached by nothing; their
deletion is filed as the entry brisk-rabbit.
