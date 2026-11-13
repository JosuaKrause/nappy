class_name DayEvents
extends RefCounted
## **What the day's events are, read through one object while dawn plans them**: the rows in the
## order they were placed, and the facts derived from them — which calm areas each spoils and
## whether one is a pursuit — kept in step with every row added.
##
## *(inbox #1156 in gray-dolphin: "have an object that contains the derived information -- don't rederive over
## and over again -- then pass that object around".)* `EventScheduler.build_day()` makes one per
## walk with `over()` and is its only writer; its passes and `DayPlanner` are handed it, and nothing reads the rows any other way. So a fact is worked out
## once, when the row arrives, and every question answers from the plan as it stands.
##
## **A calm area is spoiled for the day** when a row's field reaches its calm ground
## (`EventPlan.spoils()`): a park she can see is noisy and walk away from. That is a fact
## of the day's plan rather than of the city, because it changes with every day and as one day is
## planned, and the city's own `SPOILED` ground, which its arcs paint, is another thing.
##
## **A row is never changed once added**, in anything the facts are derived from (its def,
## position, path, `permanent`, whether it is placed), which is what keeps every answer true; a row
## handed to her walk is added already unplaced (`EventScheduler.owed_to_her_walk()`). **Never
## saved**: a load plans the day again from the run's saved inputs, and the same plan gives the same
## answers.
##
## **The constructor derives nothing**, so a test hands a consumer a stand-in that overrides the
## questions and the writes below and answers what the test set, with no city built.

var _calm: CalmAreas
var _rows: Array[EventPlan] = []
var _standing: Array[EventPlan] = []
## Calm block -> the rows spoiling it (`Array[EventPlan]`), in plan order.
var _spoilers := {}
var _pursuits := 0
## The day's locations, where a phase laid them out (`use_locations()`), or null.
var _locations: DayLocations = null
## The day's ground for a row, where the dawn made one (`use_ground()`), or null.
var _ground: RowGround = null

## **An empty plan over `calm`**, with `standing` the bodies planned before the catalogue: the day's
## seals and the region wall's own bodies, or the escape city's seals on its walk. They stand for the
## whole plan and are not its rows: none of them spoils a calm area, since they are the streets'
## rather than the day's noise.
static func over(calm: CalmAreas, standing: Array[EventPlan] = []) -> DayEvents:
	var events := DayEvents.new()
	events._calm = calm
	events._standing = standing.duplicate()
	for block in calm.blocks():
		events._spoilers[block] = [] as Array[EventPlan]
	return events

# ------------------------------------------------------------------- writes ---

## Adds `row` after every row already planned.
func add(row: EventPlan) -> void:
	_rows.append(row)
	_learn(row)

## Adds each of `rows`, in order.
func add_all(rows: Array[EventPlan]) -> void:
	for row in rows:
		add(row)

## Learns the facts `row`, the plan's last row, adds: each calm area it spoils keeps it after the
## rows already spoiling it, so a fact's rows are in plan order.
func _learn(row: EventPlan) -> void:
	for block: Vector2i in _spoilers:
		if row.spoils(_calm.ground_of(block)):
			(_spoilers[block] as Array[EventPlan]).append(row)
	if row.def.pursuit != null:
		_pursuits += 1

# ---------------------------------------------------------------- questions ---

## Every row, in the order placed: what the walk streams, and what a placement is spaced against.
func placements() -> Array[EventPlan]:
	return _rows.duplicate()

## How many rows there are.
func size() -> int:
	return _rows.size()

## The bodies handed in as standing for the whole plan (`over()`).
func standing() -> Array[EventPlan]:
	return _standing.duplicate()

## The rows whose field reaches `block`'s calm ground, in plan order. A playground, a scar the run
## left and a row not yet placed never count (`EventPlan.spoils()`).
func spoilers_of(block: Vector2i) -> Array[EventPlan]:
	var found: Array[EventPlan] = []
	found.assign(_spoilers.get(block, []))
	return found

## Whether any row's field reaches `block`'s calm ground.
func is_spoiled(block: Vector2i) -> bool:
	return not (_spoilers.get(block, []) as Array).is_empty()

## Whether any row is a pursuit.
func has_a_pursuit() -> bool:
	return _pursuits > 0

## Hands the plan the day's locations (`DayLocations`), as the roadblock phase lays them out, so the
## walk that starts from this plan is handed them too (`DayPlanner.Plan.locations()`).
func use_locations(locations: DayLocations) -> void:
	_locations = locations

## The day's locations, laid out at dawn on day 13 in this step of the placement, or null on a day
## that laid none out.
func locations() -> DayLocations:
	return _locations

## Hands the plan the day's ground for a row (`RowGround`), as the dawn makes it, so the walk that
## starts from this plan is handed the same one (`DayPlanner.Plan.ground()`) and what is sited
## while she walks asks the ground the day was planned on.
func use_ground(ground: RowGround) -> void:
	_ground = ground

## The day's ground for a row, as the dawn made it, or null for a plan no dawn of a day made.
func ground() -> RowGround:
	return _ground
