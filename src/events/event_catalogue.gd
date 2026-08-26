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
		_burnt_shell(),

		# Act II - notices.
		_police_patrol(),
		_poster_crew(),
		_loudspeaker(),
		_curfew_announce(),
		_checkpoint(),

		# Act III - vans.
		_quiet_road(),
		_abduction(),
		_alley_robbery(),
		_night_raid(),

		# Act IV - open.
		_military_convoy(),
		_barricade(),
		_protest(),
		_firefight(),
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
	# Hands over to `quiet_road` on day 8; the two must never overlap, or the arterials
	# would carry both bands at once.
	def.last_day = 7
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
	def.scar_id = "burnt_shell"
	return def

## What is left the next morning, and every morning after. Cordoned off, never repaired.
## Almost silent — it is not an obstacle, it is a reminder, and it is on the same corner on
## day 12 as it was on day 4.
static func _burnt_shell() -> EventDef:
	var def := EventDef.new()
	def.id = "burnt_shell"
	def.display_name = "Burnt-out building"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.OBJECT
	def.intensity = 2.5
	def.inner_radius = 30.0
	def.outer_radius = 90.0
	def.telegraph_time = 0.7
	return def

# ------------------------------------------------------- Act II: notices (4-7) ---

## Mobile, unhurried, and it stops. Not dangerous yet — the danger is that you start
## planning around it, which is the point.
static func _police_patrol() -> EventDef:
	var def := EventDef.new()
	def.id = "police_patrol"
	def.display_name = "Patrol"
	def.look = EventDef.Look.VEHICLE
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 10.0
	def.inner_radius = 44.0
	def.outer_radius = 185.0
	def.telegraph_time = 1.7
	def.mobile = true
	def.speed = 74.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 40
	def.weight = 3.0
	def.max_per_day = 3
	return def

## Cosmetic dread. Barely moves the meter; it is here so the walls change.
static func _poster_crew() -> EventDef:
	var def := EventDef.new()
	def.id = "poster_crew"
	def.display_name = "Poster crew"
	def.look = EventDef.Look.PERSON
	def.first_day = 4
	def.act_tag = 2
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.SQUARE]
	def.intensity = 5.0
	def.inner_radius = 30.0
	def.outer_radius = 110.0
	def.telegraph_time = 1.0
	def.weight = 2.5
	def.max_per_day = 3
	return def

## The masts switch on and there is nowhere in the city they do not reach. City-wide, so
## it has no edge to route around — the first event in the game the player cannot walk
## away from. Pitched under the walking decay: like the arterial, it does not raise the
## meter, it stops you clearing it.
static func _loudspeaker() -> EventDef:
	var def := EventDef.new()
	def.id = "loudspeaker"
	def.display_name = "Public address"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 5
	def.look = EventDef.Look.NONE
	def.act_tag = 2
	def.city_wide = true
	def.intensity = 2.4
	def.telegraph_time = 3.0
	def.pulse_period = 22.0
	def.cost = 0
	return def

## The curfew announcement itself. The mechanical bite is in Tuning.day_length, which
## shortens every day from 6 onward; this is the moment you are told.
static func _curfew_announce() -> EventDef:
	var def := EventDef.new()
	def.id = "curfew_announce"
	def.display_name = "Curfew announcement"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 6
	def.look = EventDef.Look.NONE
	def.act_tag = 2
	def.city_wide = true
	def.intensity = 6.0
	def.duration = 26.0
	def.telegraph_time = 2.0
	def.intensity_ramp = 0.2
	def.cost = 0
	return def

## Closes a street and is loud about it. The first event that takes a route away rather
## than making it expensive.
static func _checkpoint() -> EventDef:
	var def := EventDef.new()
	def.id = "checkpoint"
	def.display_name = "Checkpoint"
	def.look = EventDef.Look.OBJECT
	def.first_day = 7
	def.act_tag = 2
	def.placement = [GameEnums.TileType.ROAD, GameEnums.TileType.CROSSING]
	def.intensity = 13.0
	def.inner_radius = 52.0
	def.outer_radius = 215.0
	def.telegraph_time = 1.8
	def.obstructs_radius = 60.0
	def.weight = 2.0
	def.max_per_day = 3
	def.cost = 2
	return def

# --------------------------------------------------------- Act III: vans (8-11) ---

## The cruellest number in the game. From Act III the arterials are *quieter*, because
## there is nobody left going out on them. The city becomes an easier place to put a baby
## to sleep, and that is the horror.
static func _quiet_road() -> EventDef:
	var def := EventDef.new()
	def.id = "quiet_road"
	def.display_name = "Traffic"
	def.kind = GameEnums.EventKind.AMBIENT
	def.ambient_source = EventDef.AmbientSource.MAIN_ROAD
	def.look = EventDef.Look.NONE
	def.first_day = 8
	def.act_tag = 3
	def.intensity = 1.4
	def.inner_radius = 30.0
	def.outer_radius = 100.0
	def.telegraph_time = 0.0
	return def

## An unmarked van idles first — that idling IS the telegraph, and it runs long because
## the inner radius ends the day. Getting close does not excite the baby; it takes you.
static func _abduction() -> EventDef:
	var def := EventDef.new()
	def.id = "abduction"
	def.display_name = "Unmarked van"
	def.look = EventDef.Look.VEHICLE
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK, GameEnums.TileType.CROSSING]
	def.intensity = 20.0
	def.inner_radius = 54.0
	def.outer_radius = 250.0
	def.duration = 34.0
	# hard_fail doubles the required margin: (250-54)/92 * 2 = 4.26s.
	def.telegraph_time = 4.6
	def.hard_fail = true
	def.weight = 2.0
	def.max_per_day = 2
	def.cost = 3
	return def

## Alleys only, and deliberately tiny: the alley itself is the warning. You knew what an
## alley was when you turned into it. The radius is small enough that the fairness rule is
## satisfied by half a second, which is as close to "no warning" as the contract allows.
static func _alley_robbery() -> EventDef:
	var def := EventDef.new()
	def.id = "alley_robbery"
	def.display_name = "Robbery"
	def.look = EventDef.Look.PERSON
	def.first_day = 8
	def.act_tag = 3
	def.placement = [GameEnums.TileType.ALLEY]
	def.intensity = 16.0
	def.inner_radius = 22.0
	def.outer_radius = 42.0
	def.telegraph_time = 0.6
	def.hard_fail = true
	def.weight = 1.5
	def.max_per_day = 2
	def.cost = 2
	return def

## A building goes in the night. Enormous, static, and it closes the block.
static func _night_raid() -> EventDef:
	var def := EventDef.new()
	def.id = "night_raid"
	def.display_name = "Raid"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 10
	def.look = EventDef.Look.VEHICLE
	def.act_tag = 3
	def.placement = [GameEnums.TileType.SIDEWALK]
	def.intensity = 24.0
	def.inner_radius = 70.0
	def.outer_radius = 330.0
	def.telegraph_time = 3.0
	def.pulse_period = 6.0
	def.obstructs_radius = 44.0
	def.cost = 4
	return def

# ------------------------------------------------------------ Act IV: open (12+) ---

## Like the fire engine, but it does not leave a fire. It leaves a barricade, and the
## barricade is still there tomorrow.
static func _military_convoy() -> EventDef:
	var def := EventDef.new()
	def.id = "military_convoy"
	def.display_name = "Convoy"
	def.look = EventDef.Look.VEHICLE
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.ROAD]
	def.intensity = 22.0
	def.inner_radius = 76.0
	def.outer_radius = 300.0
	def.telegraph_time = 3.4
	def.mobile = true
	def.speed = 120.0
	def.path_mode = EventDef.PathMode.ALONG_STREET
	def.path_length_tiles = 50
	def.spawns_on_finish = "barricade"
	def.weight = 2.0
	def.cost = 4
	return def

## Left where a convoy stopped, and left there for the rest of the run.
static func _barricade() -> EventDef:
	var def := EventDef.new()
	def.id = "barricade"
	def.display_name = "Barricade"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 0
	def.look = EventDef.Look.OBJECT
	def.act_tag = 4
	def.intensity = 6.0
	def.inner_radius = 40.0
	def.outer_radius = 120.0
	def.telegraph_time = 0.9
	def.obstructs_radius = 62.0
	def.scar_id = "barricade"
	return def

## Grows while it is there — `intensity_ramp` takes it to 1.9x over its duration. A protest
## you could have walked past when you saw it is not one you can walk past two minutes later.
static func _protest() -> EventDef:
	var def := EventDef.new()
	def.id = "protest"
	def.display_name = "Protest"
	def.look = EventDef.Look.PERSON
	def.first_day = 12
	def.act_tag = 4
	def.placement = [GameEnums.TileType.SQUARE, GameEnums.TileType.CROSSING]
	def.intensity = 15.0
	def.inner_radius = 70.0
	def.outer_radius = 300.0
	def.duration = 150.0
	def.telegraph_time = 2.6
	def.intensity_ramp = 1.9
	def.pulse_period = 8.0
	def.weight = 2.5
	def.max_per_day = 2
	def.cost = 3
	return def

## The last thing in the catalogue and the worst. Static, extreme, lethal at the centre,
## and it shuts a district.
static func _firefight() -> EventDef:
	var def := EventDef.new()
	def.id = "firefight"
	def.display_name = "Firefight"
	def.kind = GameEnums.EventKind.SCRIPTED
	def.scripted_day = 13
	def.look = EventDef.Look.FIRE
	def.act_tag = 4
	def.placement = [GameEnums.TileType.CROSSING, GameEnums.TileType.SQUARE]
	def.intensity = 30.0
	def.inner_radius = 90.0
	def.outer_radius = 380.0
	# hard_fail: (380-90)/92 * 2 = 6.3s.
	def.telegraph_time = 6.5
	def.pulse_period = 2.5
	def.hard_fail = true
	def.cost = 5
	return def
