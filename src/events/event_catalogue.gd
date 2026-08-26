class_name EventCatalogue
extends RefCounted
## Every event in the game, defined in code. See docs/EVENTS.md for the full catalogue and
## the reasoning behind each one.
##
## M4 carries three events, chosen to exercise the whole system rather than to populate a
## day: a permanent ambient field, a short mobile burst, and a stationary pulsing source.
## M5 fills in the rest of Act I.

static var _all: Array[EventDef] = []

static func all() -> Array[EventDef]:
	if _all.is_empty():
		_all = _build()
		for def in _all:
			def.validate()
	return _all

static func by_id(id: String) -> EventDef:
	for def in all():
		if def.id == id:
			return def
	return null

## Every def that may appear on this day, in catalogue order.
static func available_on(day: int) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in all():
		if def.available_on(day):
			found.append(def)
	return found

static func of_kind(kind: GameEnums.EventKind, day: int) -> Array[EventDef]:
	var found: Array[EventDef] = []
	for def in available_on(day):
		if def.kind == kind:
			found.append(def)
	return found

static func _build() -> Array[EventDef]:
	return [
		# Act I - a nice neighbourhood.
		_playground(),
		_busy_road(),
		_cat_dash(),
		_dog_walker(),
		_delivery_van(),
		_homeless_yeller(),
		_busker(),
		_construction(),
		_fire_truck(),
		_burning_building(),
	]

## The reason parks are not a free win. Permanent, wide, and sitting in the middle of the
## calmest ground in the city.
static func _playground() -> EventDef:
	var def := EventDef.new()
	def.id = "playground"
	def.display_name = "Playground"
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.PLAYGROUND
	def.look = EventDef.Look.NONE  # The park's swing frame already draws it.
	def.intensity = 7.0
	# Sized so it dominates the middle of a park but leaves the far side genuinely calm —
	# a park block is 256px across, so a 200px reach would have swallowed the whole thing
	# and made every park useless rather than merely contested.
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 0.0
	def.pulse_period = 9.0
	return def

## The tutorial obstacle: visible crouching before it bolts, sharp while it crosses, gone
## a second later. Small radius, so walking one lane wide of it is enough.
static func _cat_dash() -> EventDef:
	var def := EventDef.new()
	def.id = "cat_dash"
	def.display_name = "Cat"
	def.look = EventDef.Look.ANIMAL
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 15.0
	def.inner_radius = 30.0
	def.outer_radius = 120.0
	def.duration = 1.4
	def.telegraph_time = 1.6
	def.mobile = true
	def.speed = 240.0
	def.weight = 3.0
	def.max_per_day = 3
	return def

## Stationary, loud, and *pulsing* — the intensity envelope means the counterplay is timing
## a pass between yells, which is a different skill from routing around a hazard.
static func _homeless_yeller() -> EventDef:
	var def := EventDef.new()
	def.id = "homeless_yeller"
	def.display_name = "Man shouting"
	def.look = EventDef.Look.PERSON
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 10.0
	def.inner_radius = 45.0
	def.outer_radius = 210.0
	def.telegraph_time = 2.6
	def.pulse_period = 5.0
	def.weight = 2.0
	def.max_per_day = 2
	return def

## Traffic noise along the two arterial corridors.
##
## Pitched deliberately just BELOW the 3.5/s walking decay, so a main road can never raise
## the meter on its own — it is not a hazard. What it does is cripple *recovery*: on a
## quiet street excitement drains at 3.5/s, on the arterial at 0.3/s. So the cost of the
## main road is not that it excites the baby, it is that you cannot calm her down while
## you are on it. Getting away from a cat means getting off the arterial too.
static func _busy_road() -> EventDef:
	var def := EventDef.new()
	def.id = "busy_road"
	def.display_name = "Traffic"
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.MAIN_ROAD
	def.look = EventDef.Look.NONE
	def.intensity = 3.2
	def.inner_radius = 34.0
	def.outer_radius = 130.0
	def.telegraph_time = 0.0
	return def

## Slow, small, and it barks. Easy to walk around; annoying when it wanders into the
## quiet street you had picked.
static func _dog_walker() -> EventDef:
	var def := EventDef.new()
	def.id = "dog_walker"
	def.display_name = "Dog walker"
	def.look = EventDef.Look.PERSON
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 7.0
	def.inner_radius = 32.0
	def.outer_radius = 130.0
	def.telegraph_time = 1.4
	def.pulse_period = 3.5
	def.mobile = true
	def.speed = 32.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 30
	def.weight = 3.0
	def.max_per_day = 3
	return def

## Parked, reversing, beeping. Constant and stationary — the plain obstacle the route
## planning is practised on.
static func _delivery_van() -> EventDef:
	var def := EventDef.new()
	def.id = "delivery_van"
	def.display_name = "Delivery van"
	def.look = EventDef.Look.VEHICLE
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 8.0
	def.inner_radius = 40.0
	def.outer_radius = 150.0
	def.telegraph_time = 1.3
	def.weight = 2.0
	def.max_per_day = 2
	return def

## A park spoiler, and a pleasant one. Nothing about it is threatening; it is simply
## interesting, which is the whole problem.
static func _busker() -> EventDef:
	var def := EventDef.new()
	def.id = "busker"
	def.display_name = "Busker"
	def.look = EventDef.Look.PERSON
	def.first_day = 2
	def.placement = [GameEnums.TileType.PARK, GameEnums.TileType.SQUARE]
	def.intensity = 9.0
	def.inner_radius = 45.0
	def.outer_radius = 190.0
	def.telegraph_time = 1.7
	def.pulse_period = 7.0
	def.weight = 2.0
	def.max_per_day = 2
	return def

## The only Act I event that is physically in the way. Blocking the sidewalk forces a
## reroute rather than merely inviting one — and since a street is sidewalk|road|sidewalk,
## the road is always still there, so it costs time and exposure, never the day.
static func _construction() -> EventDef:
	var def := EventDef.new()
	def.id = "construction"
	def.display_name = "Roadworks"
	def.look = EventDef.Look.OBJECT
	def.first_day = 2
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 11.0
	def.inner_radius = 46.0
	def.outer_radius = 200.0
	def.telegraph_time = 1.8
	def.obstructs_radius = 34.0
	def.weight = 1.5
	def.max_per_day = 2
	def.cost = 2
	return def

## The Act I finale. Audible from streets away, moving fast down an arterial road, and it
## leaves a fire burning where it stops. Long telegraph, because the whole point is that
## you hear it coming and have time to get off that street.
static func _fire_truck() -> EventDef:
	var def := EventDef.new()
	def.id = "fire_truck"
	def.display_name = "Fire engine"
	def.kind = GameEnums.EventKind.ONE_SHOT
	def.look = EventDef.Look.VEHICLE
	def.first_day = 3
	def.last_day = 3
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 26.0
	def.inner_radius = 70.0
	def.outer_radius = 340.0
	# A truck at 190px/s outruns a walk, so the fairness rule demands the FULL radius of
	# clearance, not just the falloff band: 340/92 = 3.7s.
	def.telegraph_time = 4.0
	def.mobile = true
	def.speed = 190.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 60
	def.spawns_on_finish = "burning_building"
	def.cost = 4
	return def

## Never scheduled directly — a SCRIPTED def with no day, spawned only where the fire
## engine stops. Burns for the rest of the day.
static func _burning_building() -> EventDef:
	var def := EventDef.new()
	def.id = "burning_building"
	def.display_name = "Burning building"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.FIRE
	def.intensity = 18.0
	def.inner_radius = 60.0
	def.outer_radius = 260.0
	def.telegraph_time = 2.2
	def.pulse_period = 3.0
	return def
