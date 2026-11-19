class_name FakeWalkSiting
extends WalkSiting
## A stand-in for the day's siting (`WalkSiting`) whose answers a check sets, handed to the director
## (`EventDirector.start_day()`) so a check of what the director decides plans no day and grows no
## city. It records each look (`looks`, as `[at, heading]`), each plan asked (`asked`) and every call
## in order (`calls`), lays a plan at a place set for its row (`set_place()`) or answers false, and
## answers a set value to `still_ahead_of()`. The real siting's own logic is checked once, in
## `tests/test_walk_siting.gd`. A helper, not a suite: the runner loads only `test_*.gd`.

## Each look begun, as `[at, heading]`.
var looks: Array[Array] = []
## Every plan `lay_ahead()` or `lay_just_ahead()` was asked about, in order.
var asked: Array[EventPlan] = []
## Every call, in order: "begin_look", "lay_ahead", "lay_just_ahead", "end_look", "lay_among",
## "lay_off_her_path".
var calls: Array[String] = []

var _places := {}
var _still_ahead := true

func _init() -> void:
	super(null, null, FakeWalkEvents.new(), null, null, null, null)

## Sets where a plan of the row `id` is laid: `lay_ahead()` and `lay_just_ahead()` stand it at `at`.
## A row with none set is refused.
func set_place(id: String, at: Vector2) -> FakeWalkSiting:
	_places[id] = at
	return self

## Sets what `still_ahead_of()` answers.
func set_still_ahead(still_ahead: bool) -> FakeWalkSiting:
	_still_ahead = still_ahead
	return self

## Overrides WalkSiting.prepare.
func prepare(_def: EventDef) -> void:
	pass

## Overrides WalkSiting.begin_look.
func begin_look(at: Vector2, heading: Vector2) -> void:
	looks.append([at, heading])
	calls.append("begin_look")

## Overrides WalkSiting.end_look.
func end_look() -> void:
	calls.append("end_look")

## Overrides WalkSiting.lay_ahead.
func lay_ahead(plan: EventPlan) -> bool:
	asked.append(plan)
	calls.append("lay_ahead")
	return _lay_at_its_place(plan)

## Overrides WalkSiting.lay_just_ahead.
func lay_just_ahead(plan: EventPlan) -> bool:
	asked.append(plan)
	calls.append("lay_just_ahead")
	return _lay_at_its_place(plan)

## Overrides WalkSiting.lay_among.
func lay_among(plan: EventPlan, _offered: Array[Vector2i]) -> bool:
	calls.append("lay_among")
	return _lay_at_its_place(plan)

## Overrides WalkSiting.lay_off_her_path.
func lay_off_her_path(plan: EventPlan, _away_from: Vector2, _rng: RandomNumberGenerator) -> bool:
	calls.append("lay_off_her_path")
	return _lay_at_its_place(plan)

func _lay_at_its_place(plan: EventPlan) -> bool:
	if not _places.has(plan.row().id):
		return false
	plan.stand_where(EventPlan.new(plan.row(), _places[plan.row().id]))
	return true

## Overrides WalkSiting.still_ahead_of.
func still_ahead_of(_at: Vector2, _heading: Vector2, _position: Vector2) -> bool:
	return _still_ahead

## Overrides WalkSiting.waits.
func waits() -> Dictionary:
	return {}
