@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## Nobody in a day's crowd is ever inside a body the day's real plan stood in the street.
##
## **A combined suite, for a guarantee that spans three modules**: the event manager's plan fills
## `CityMap.obstructed_tiles` (`EventManager`'s wiring), the city starts the day, and the crowd walks
## round what stands there. A suite of the crowd (`test_crowd_bodies.gd`) puts a body on the map by
## hand and asks what the crowd does; whether the plan puts the right tiles there is only seen by
## planning a real day on a real city, which is what this suite does, over three seeds. Its check of
## where a crash is sited (every crashed car's middle on ground the record holds) is the event
## manager's own answer and moves to the events' suites with their conversion (`src/events/` and its
## tests are another agent's now).

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_nobody_ever_stands_in_a_body_on_a_real_day(t)

## Nobody is ever inside a body's own footprint, over a day's real crowd on a day's real plan,
## across several seeds. The property the whole item is for, asked the way
## `crowd_rig.gd`'s hard-seal test asks its own: a count of frames, and the count is zero.
##
## **Stated over the record rather than over the catalogue**, because the record is what the crowd
## reads: a seed whose day happened to place nothing solid would pass vacuously, so the tile count
## is checked as well.
##
## **A crash's two cars are asked about separately, off the catalogue rather than off the record,
## and the sentence they hold is the siting's.** The cars are in the record like every other body,
## so the tile count above already keeps the crowd off the tiles they stand on; what this second
## count holds is that a crash is only ever sited on a street that is sealed — every agent ever
## found within one of its cars is on ground held for the day, never on open street it could have
## strolled in from. Vacuity is guarded the same way: the number of car bodies the days actually
## placed is checked.
##
## **Stated as *reaches* rather than *stands in*, and the difference is the crash's own geometry.**
## A car body is a 14px disc centred on the carriageway and it reaches a few pixels over the kerb,
## so a walker on the nearest pavement lane can be inside its radius while standing on a tile whose
## middle it does not cover — which is a walker beside a wreck rather than a walker in one. Held
## ground is the line this draws instead, because that is the property the siting owns.
func _test_nobody_ever_stands_in_a_body_on_a_real_day(t) -> void:
	var cars_seen := 0
	for city_seed: int in [4242, 24757, 91117]:
		var map := CityGenerator.generate(city_seed)
		var city: City = RunCity.with_own_run(CITY_SCENE, city_seed)
		t.add_child(city)
		city.build(map)
		for day: int in [1, 6]:
			var state := CityState.new()
			state.begin_day(map.block_plans, day)
			var closures := RandomNumberGenerator.new()
			closures.seed = hash("bodies-closures:%d:%d" % [city_seed, day])
			city.start_day(state, day, closures)
			var events := RandomNumberGenerator.new()
			events.seed = hash("bodies-events:%d:%d" % [city_seed, day])
			var consumed: Array[String] = []
			city.events.start_day(DaySpec.for_day(day), events, consumed)
			t.check(map.obstructed_tiles.size() > 0,
					"seed %d day %d stands solid bodies somewhere to be asked about (%d tiles)"
					% [city_seed, day, map.obstructed_tiles.size()])

			var at := map.doorstep_world_position()
			var crowd_rng := RandomNumberGenerator.new()
			crowd_rng.seed = hash("bodies-crowd:%d:%d" % [city_seed, day])
			city.crowd.start_day(day, crowd_rng, at)
			city.crowd.set_gates(city.streets().region_plan().gates)
			var cars := _car_bodies(map, city.events)
			cars_seen += cars.size()
			# The cars as an instance stands them are where the record put them: the middle of
			# each is on ground the day marked as a body.
			var off_the_record := 0
			for car: Array in cars:
				if not map.is_obstructed(map.world_to_tile(car[0])):
					off_the_record += 1
			t.check(off_the_record == 0,
					"seed %d day %d: every crashed car's middle is on ground the record holds (%d are not)"
					% [city_seed, day, off_the_record])
			var inside := 0
			var in_a_car := 0
			var reached_a_car := 0
			for frame in int(round(20.0 / STEP)):
				city.crowd.set_focus(at)
				city.crowd.step(STEP)
				for agent in city.crowd.agents():
					if map.is_obstructed(map.world_to_tile(agent.position)):
						inside += 1
					for car: Array in cars:
						if agent.position.distance_to(car[0]) < float(car[1]):
							in_a_car += 1
							if not map.is_held_at(map.world_to_tile(agent.position)):
								reached_a_car += 1
			t.check(inside == 0,
					"seed %d day %d: nobody in the crowd ever stands inside a solid body "
					% [city_seed, day] + "(%d agent-frames they did)" % inside)
			t.check(reached_a_car == 0,
					"seed %d day %d: nobody in the crowd ever reaches a crashed car across open "
					% [city_seed, day] + "ground (%d agent-frames of %d inside a car were on "
					% [reached_a_car, in_a_car] + "ground the crowd is not held off, over %d cars)"
					% cars.size())
		city.free()
	t.check(cars_seen > 0, "these days stood crashed cars somewhere at all (%d)" % cars_seen)

## Every crashed car standing on the day `events` has planned, as `[centre, radius]` pairs — the
## rows that declare `EventDef.solid_parts`, each piece placed the way
## `EventSpawner.obstructed_footprint()` places it. Read off the **plan** rather than off the live
## instances for the reason the record is: a plan covers the whole map and an instance only exists
## near the player.
func _car_bodies(map: CityMap, events: EventManager) -> Array:
	var bodies := []
	for plan in events.plans():
		if not plan.is_placed() or plan.def == null or plan.def.solid_parts.is_empty():
			continue
		# The instance the spawner would make for the plan: where it stands and which way its
		# pieces are laid out are what it decides when it is set up.
		var sited := EventInstance.new()
		sited.setup(plan.def, plan.position, PackedVector2Array(), plan.facing, map)
		var placed := sited.position
		var vertical := sited.runs_vertically()
		sited.free()
		for piece in plan.def.parts():
			var offset := piece.offset_for(vertical)
			var centre := placed + (Vector2(0.0, offset) if vertical else Vector2(offset, 0.0))
			bodies.append([centre, piece.shape.reach()])
	return bodies
