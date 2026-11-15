class_name WayConfirmation
extends RefCounted
## **Whether she can be sent to a place: it stands, with a way to it over drawn ground that
## nothing drawn later can reach.** A unit of the day's locations draws as she comes near it
## (`UnitDraw`), so ground may still be undrawn, and a body a unit draws there later could stand
## on a place fixed before it drew, or shut the way the place was found reachable by (`DayReach`).
## The answer goes **by where the place stands** (`a_way_stands()`), not by who fixed it:
##
## - **Inside the ground drawn round her**, the place stands as it is, with no search and nothing
##   drawn: her own paths reach it from where she stands without coming within `CLEAR` of an
##   undrawn unit (`drawn_round` says how far the nearest is). She walked to where she stands, and
##   the walk keeps the units round her drawn (`EventsAhead.draw_what_comes_near()`), so the way
##   she came has drawn too.
## - **Beyond it**, a way from home is confirmed, the ground drawn first and the place judged
##   against what it draws. Up to `PASSES` times: a shortest way from home to the place over the
##   ground open now (`DayReach.way_from_home()`), none refusing the place; the units round every
##   `STEP`th tile of the way and round the place itself drawn (`draws_round`, out to
##   `Tuning.EVENT_DRAW_AHEAD` each); and **a pass that draws no unit lets the place stand**, on
##   the way that pass walked. A pass that drew may have shut the way it walked, since whoever
##   draws tells the reach what now stands in the way (`DayReach.shut_more()`), so the next pass
##   walks the ground as it stands then: down another way where there is one, and to a refusal
##   where there is none.
##
## Either way no undrawn unit is left within `CLEAR` of the way, which is beyond the widest reach
## a placement rule asks (a lethal field of 270px), so nothing drawn later is judged against the
## way or the place, stands on either, or reaches either with its field.
##
## **A place beyond is asked of once more, after the pass that drew nothing** (`still_stands`, the
## caller's own question of the tile): whoever fixes a place asks whether anything stands on it
## before the units round it have drawn, and one of them may stand a body there that shuts no way
## (a café's tables on a sidewalk), so the answer from before the draw is not the one that holds.
## A place inside the ground drawn round her was asked against ground that had drawn.
##
## Handed what it reads, so a check hands it a street drawn by hand and a stand-in for the draw.
## Model: no node.

## How many times a way is walked and the ground round it drawn before the place is refused.
const PASSES := 8
## Every how many tiles of the way the units round it are drawn: every tile of the way is then
## within half this of one drawn round.
const STEP := 8
## **How far from a way that stands the nearest undrawn unit lies, at least**: 320px. A unit a
## pass leaves undrawn is more than `Tuning.EVENT_DRAW_AHEAD` (448px) from every `STEP`th tile of
## the way, each tile of which is within half a `STEP`, 128px, of one of those; and her own paths
## are walked only this far short of the nearest undrawn unit. Beyond the widest reach a placement
## rule asks (a lethal field of 270px).
const CLEAR := Tuning.EVENT_DRAW_AHEAD - STEP * Tuning.TILE_SIZE / 2.0

var _map: CityMap
var _reach: DayReach
var _draws_round: Callable
var _drawn_round: Callable

## `map` says where a tile is; `reach` is the walk's (`WalkEvents.reach()`); `draws_round` is
## `func(at: Vector2, reach: float) -> bool`, which draws every undrawn unit any part of which lies
## within `reach` of `at`, tells `reach` what they placed, and answers whether it drew any
## (`EventManager.draw_the_ground_round()`); `drawn_round` is `func(at: Vector2) -> float`, how far
## round `at` the ground has drawn, the distance to the nearest undrawn unit and `INF` with none
## left (`DayUnits.drawn_round()`).
func _init(map: CityMap, reach: DayReach, draws_round: Callable, drawn_round: Callable) -> void:
	_map = map
	_reach = reach
	_draws_round = draws_round
	_drawn_round = drawn_round

## **Whether she can be sent to the place at `tile`**, by where it stands: inside the ground drawn
## round `her`, where she stands, it stands as it is (`_her_own_way_stands()`); beyond it, or with
## `her` `Vector2.INF` (a place fixed before she is put down), a way from home is confirmed
## (`_a_way_from_home_stands()`). `still_stands` is `func(tile: Vector2i) -> bool`, whether the
## caller's place may still stand there, asked once the units round a place beyond have drawn.
## See the class comment.
func a_way_stands(tile: Vector2i, her: Vector2, still_stands: Callable) -> bool:
	return _her_own_way_stands(tile, her) or _a_way_from_home_stands(tile, still_stands)

## Whether the place at `tile` lies inside the ground drawn round `her`: her paths, walked from
## her own tile over the ground the reach leaves open (`DayReach.paths_within()`), reach it
## without coming within `CLEAR` of the nearest undrawn unit; a place only a way round through
## undrawn ground reaches is asked from home. With no unit left to draw every way is over drawn
## ground, so the place stands where it is reached from home, or is the tile she stands on. Draws
## nothing.
func _her_own_way_stands(tile: Vector2i, her: Vector2) -> bool:
	if her == Vector2.INF:
		return false
	var her_tile := _map.world_to_tile(her)
	var drawn: float = _drawn_round.call(her)
	if is_inf(drawn):
		return tile == her_tile or _reach.reaches(tile)
	if _map.tile_to_world(tile).distance_to(her) >= drawn - CLEAR:
		return false
	var from: Array[Vector2i] = [her_tile]
	return _reach.paths_within(_map, from, her, drawn - CLEAR).has(tile)

## Whether a way from home to the place at `tile` stands once the ground along it has drawn: the
## passes of the class comment, and `still_stands` asked after the one that drew nothing.
func _a_way_from_home_stands(tile: Vector2i, still_stands: Callable) -> bool:
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
