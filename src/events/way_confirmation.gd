class_name WayConfirmation
extends RefCounted
## **Whether a place fixed from her walk stands, with a way to it from home that nothing drawn
## later can reach.** A unit of the day's locations draws as she comes near it (`UnitDraw`), so the
## ground between home and a place fixed while she is elsewhere may still be undrawn, and a body a
## unit draws there later could shut the way the place was found reachable by (`DayReach`). So the
## ground is drawn first, and the place judged against what it draws.
##
## Up to `PASSES` times: a shortest way from home to the place over the ground open now
## (`DayReach.way_from_home()`), none refusing the place; the units round every `STEP`th tile of
## the way and round the place itself drawn (`draws_round`, out to `Tuning.EVENT_DRAW_AHEAD` each);
## and **a pass that draws no unit lets the place stand**, on the way that pass walked. A pass that
## drew may have shut the way it walked, since whoever draws tells the reach what now stands in
## the way (`DayReach.shut_more()`), so the next pass walks the ground as it stands then: down
## another way where there is one, and to a refusal where there is none.
##
## **The place is asked of once more, after the pass that drew nothing** (`still_stands`, the
## caller's own question of the tile): whoever fixes a place asks whether anything stands on it
## before the units round it have drawn, and one of them may stand a body there that shuts no way
## (a café's tables on a sidewalk), so the answer from before the draw is not the one that holds.
##
## Handed what it reads, so a check hands it a street drawn by hand and a stand-in for the draw.
## Model: no node.

## How many times a way is walked and the ground round it drawn before the place is refused.
const PASSES := 8
## Every how many tiles of the way the units round it are drawn: every tile of the way is then
## within half this, 128px, of one drawn round, so a unit a pass leaves undrawn, more than
## `Tuning.EVENT_DRAW_AHEAD` (448px) from each of those, lies more than 320px from the whole way,
## beyond the widest reach a placement rule asks (a lethal field of 270px).
const STEP := 8

var _map: CityMap
var _reach: DayReach
var _draws_round: Callable

## `map` says where a tile is; `reach` is the walk's (`WalkEvents.reach()`); `draws_round` is
## `func(at: Vector2, reach: float) -> bool`, which draws every undrawn unit any part of which lies
## within `reach` of `at`, tells `reach` what they placed, and answers whether it drew any
## (`EventManager.draw_the_ground_round()`).
func _init(map: CityMap, reach: DayReach, draws_round: Callable) -> void:
	_map = map
	_reach = reach
	_draws_round = draws_round

## Whether the place at `tile` stands. `still_stands` is `func(tile: Vector2i) -> bool`, whether
## the caller's place may still stand there, asked once the units round it have drawn. See the
## class comment.
func confirms(tile: Vector2i, still_stands: Callable) -> bool:
	for _pass in PASSES:
		var way := _reach.way_from_home(tile)
		if way.is_empty():
			return false
		var drew := false
		for k in range(0, way.size(), STEP):
			drew = _draws_round.call(_map.tile_to_world(way[k]), Tuning.EVENT_DRAW_AHEAD) or drew
		drew = _draws_round.call(_map.tile_to_world(tile), Tuning.EVENT_DRAW_AHEAD) or drew
		if not drew:
			return still_stands.call(tile)
	return false
