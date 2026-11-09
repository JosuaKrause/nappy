extends RefCounted
## `EventScheduler.RuledOffer`, a ruled ground's offer a candidate at a time: each step builds and
## asks one of the row's tiles at the location, the first that stands clear is the offer at once,
## otherwise the one with the most room once every tile is asked, and the one kept is asked again on
## the last step when the walk gained a plan since it was asked. Run against a stand-in ground
## (`_Ground`) that answers each tile's room from a table and counts the walk's plans as the suite
## sets them: what a tile's room is belongs to the day's rules, checked in `tests/test_route_rules.gd`
## and the placement suites.
##
## - **A step asks one tile**: three tiles take three steps, one asked on each, and the offer is the
##   one with the most room.
## - **A tile that stands clear is the offer at once**: the steps stop at it.
## - **The one kept is asked again when the walk gained a plan**: refused now, the offer is nothing;
##   allowed now, it stands.
## - **And not when the walk did not**: nothing is asked again.

const ROW := "busker"

## A ruled ground whose tiles answer rooms from `rooms` (tile -> room, a tile not named not building)
## and whose walk counts `count` plans; records each tile asked and each asked again.
class _Ground extends EventScheduler.RuledLocationGround:
	var rooms := {}
	var room_again := 0.0
	var count := 0
	var asked: Array[Vector2i] = []
	var asked_again: Array[Vector2i] = []
	var built := {}

	func _init() -> void:
		super(1, 0, CityMap.new(), DayEvents.new(), null, null, null)

	## Overrides EventScheduler.RuledLocationGround.ask.
	func ask(def: EventDef, tile: Vector2i, _rng: RandomNumberGenerator,
			_role: GameEnums.BlockerRole) -> Array:
		asked.append(tile)
		if not rooms.has(tile):
			return []
		var plan := EventScheduler.Planned.new(def, Vector2(tile) * Tuning.TILE_SIZE)
		built[tile] = plan
		return [plan, rooms[tile]]

	## Overrides EventScheduler.RuledLocationGround.ask_again.
	func ask_again(_candidate: EventScheduler.Planned, tile: Vector2i,
			_role: GameEnums.BlockerRole) -> float:
		asked_again.append(tile)
		return room_again

	## Overrides EventScheduler.RuledLocationGround.judged_at.
	func judged_at() -> int:
		return count

func run(t) -> void:
	_test_a_step_asks_one_tile(t)
	_test_a_tile_that_stands_clear_is_the_offer_at_once(t)
	_test_the_one_kept_is_asked_again_when_the_walk_gained_a_plan(t)
	_test_and_not_when_the_walk_did_not(t)

const A := Vector2i(1, 0)
const B := Vector2i(2, 0)
const C := Vector2i(3, 0)

func _offer(ground: _Ground, fits: Array[Vector2i]) -> EventScheduler.RuledOffer:
	return EventScheduler.RuledOffer.new(ground, EventCatalogue.by_id(ROW), fits,
			RandomNumberGenerator.new(), GameEnums.BlockerRole.FRICTION)

func _test_a_step_asks_one_tile(t) -> void:
	var ground := _Ground.new()
	ground.rooms = {A: 10.0, B: 30.0, C: 20.0}
	var offer := _offer(ground, [A, B, C])
	var over: Array[bool] = []
	var asked_by_step: Array[int] = []
	for _i in 3:
		over.append(offer.step())
		asked_by_step.append(ground.asked.size())
	t.check(asked_by_step == ([1, 2, 3] as Array[int]), "each step asks one tile (%s)" % [asked_by_step])
	t.check(over == ([false, false, true] as Array[bool]), "and the offer is made on the third (%s)" % [over])
	t.check(offer.plan == ground.built[B], "the offer is the tile with the most room")

func _test_a_tile_that_stands_clear_is_the_offer_at_once(t) -> void:
	var ground := _Ground.new()
	ground.rooms = {A: 10.0, B: INF, C: 50.0}
	var offer := _offer(ground, [A, B, C])
	offer.step()
	var made := offer.step()
	t.check(made and offer.plan == ground.built[B] and ground.asked.size() == 2,
			"a tile that stands clear is the offer on its own step, and no tile after it is asked (%d asked)"
			% ground.asked.size())

func _test_the_one_kept_is_asked_again_when_the_walk_gained_a_plan(t) -> void:
	for allowed in [false, true]:
		var ground := _Ground.new()
		ground.rooms = {A: 30.0, B: 10.0}
		ground.room_again = 5.0 if allowed else -INF
		ground.count = 4
		var offer := _offer(ground, [A, B])
		offer.step()
		ground.count = 5
		offer.step()
		t.check(ground.asked_again == ([A] as Array[Vector2i]),
				"the tile kept is asked again once the walk gained a plan (%s)" % [ground.asked_again])
		if allowed:
			t.check(offer.plan == ground.built[A], "and, allowed now, it is the offer")
		else:
			t.check(offer.plan == null, "and, refused now, the offer is nothing")

func _test_and_not_when_the_walk_did_not(t) -> void:
	var ground := _Ground.new()
	ground.rooms = {A: 30.0, B: 10.0}
	ground.room_again = -INF
	ground.count = 4
	var offer := _offer(ground, [A, B])
	offer.step()
	offer.step()
	t.check(ground.asked_again.is_empty() and offer.plan == ground.built[A],
			"with the walk as it was, nothing is asked again and the tile kept is the offer")
