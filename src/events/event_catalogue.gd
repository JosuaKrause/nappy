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
		_playground(),
		_cat_dash(),
		_homeless_yeller(),
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
