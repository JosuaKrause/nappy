extends RefCounted
## What walking past a car crash costs, measured rather than derived — the number
## `Tuning.CAR_ACCIDENT_INTENSITY` is set from.
##
## The crash is solid only where its two cars are, so its picture's own gaps are ground she can
## walk. This walks every one of those gaps at `Tuning.WALK_SPEED`, straight across the sealed
## street, and prints what the pass puts on the meter: the field integrated along the line less the
## walking decay, the same arithmetic `tests/test_crowd.gd` prices a main-road crossing with.
##
## **The cheapest line is the one that matters.** A guarantee about a price is a guarantee about
## the price she can actually get, so the figure to set the constant against is the minimum over
## the open lanes, not their mean — and the lanes differ, because the far edge of a pavement is
## further from the band's own spine than its middle is.
##
## Run it with `tools/test.sh probes/m118_crash_gap.gd`.

const SEEDS := 6
const BASE_SEED := 118118
const STEP := 1.0 / 60.0
## Lateral sampling across the street, in px — fine enough to find the edge of a gap.
const LANE_STEP := 2.0

func run(t) -> void:
	var worst_pass := INF
	var best_pass := 0.0
	var lanes_found := 0
	for i in SEEDS:
		var map := CityGenerator.generate(BASE_SEED + i * 97)
		for vertical in [false, true]:
			var at := _a_street_of(map, vertical)
			if at == Vector2.INF:
				continue
			var instance := _accident_at(map, at)
			var half: float = instance.def.obstructs_radius
			var open := _open_lanes(instance, half)
			lanes_found += open.size()
			var costs := PackedFloat32Array()
			for offset in open:
				costs.append(_pass_cost(instance, offset))
			var lo := INF
			var hi := 0.0
			for cost in costs:
				lo = minf(lo, cost)
				hi = maxf(hi, cost)
			worst_pass = minf(worst_pass, lo)
			best_pass = maxf(best_pass, hi)
			print("seed %d %s street: %d open lanes over %.0fpx, pass costs %.1f..%.1f of %d"
					% [map.seed_used, "east-west" if vertical else "north-south", open.size(),
					2.0 * half, lo, hi, int(Tuning.METER_MAX)])
			print("    gaps (px from the scene centre): %s" % [_gap_spans(open)])
			instance.free()
	print("CHEAPEST pass %.1f, dearest %.1f, of a %d meter (half is %.0f); intensity %.1f"
			% [worst_pass, best_pass, int(Tuning.METER_MAX), Tuning.METER_MAX / 2.0,
			Tuning.CAR_ACCIDENT_INTENSITY])
	# The two figures `docs/EVENTS.md`'s cost table carries for this row, computed the way every
	# other row in it is: the field integrated along a straight line through the centre, at each
	# pace, less that pace's own decay. The crash is the one row where running is the cheaper of
	# the two — see that table's own note.
	var crash := EventCatalogue.by_id("car_accident")
	var mean := crash.mean_emission_along_the_line()
	print("COST TABLE car_accident: walk %+.1f, run %+.1f"
			% [crash.walk_through_cost(),
			(mean - Tuning.EXCITEMENT_DECAY_RUNNING + Tuning.EXCITEMENT_FROM_RUNNING)
			* (crash.outer_radius * 2.0 / Tuning.RUN_SPEED)])
	t.check(lanes_found > 0, "there were gaps to walk (%d)" % lanes_found)

# ------------------------------------------------------------------------ rigs ---

## A tile on a real street of the asked-for axis, as a world point. `Vector2.INF` when this city
## has none, which no generated city actually is.
func _a_street_of(map: CityMap, vertical: bool) -> Vector2:
	for segment in StreetNetwork.segments():
		if not map.has_street(segment.key()):
			continue
		if segment.horizontal != vertical:
			continue
		var centre := map.tile_rect_to_world(segment.tile_rect()).get_center()
		if EventInstance._spread_is_vertical(map, centre) == vertical:
			return centre
	return Vector2.INF

## A live crash, past its own telegraph so the field is at the rate the catalogue states rather
## than the damped one a telegraph holds it to. Never added to the tree: nothing here needs a
## collision body, and `contribution_at()` is a pure query.
func _accident_at(map: CityMap, at: Vector2) -> EventInstance:
	var instance := EventInstance.new()
	instance.setup(EventCatalogue.by_id("car_accident"), at, PackedVector2Array(), Vector2.RIGHT, map)
	instance.age = 10.0
	return instance

## Every lateral offset along the scene's own spread axis she can actually walk through: her centre
## clear of every car body by her own `PLAYER_BODY_RADIUS`, and her body inside the street.
func _open_lanes(instance: EventInstance, half: float) -> PackedFloat32Array:
	var open := PackedFloat32Array()
	var centres := instance.solid_part_centres()
	var shapes := instance.solid_part_shapes()
	var vertical := instance.solid_axis() == Vector2.DOWN
	var offset := -half + Tuning.PLAYER_BODY_RADIUS
	while offset <= half - Tuning.PLAYER_BODY_RADIUS:
		var blocked := false
		for i in centres.size():
			var along: float = (centres[i] - instance.global_position).y if vertical \
					else (centres[i] - instance.global_position).x
			if absf(offset - along) < shapes[i].reach() + Tuning.PLAYER_BODY_RADIUS:
				blocked = true
		if not blocked:
			open.append(offset)
		offset += LANE_STEP
	return open

## What one straight crossing of the sealed street costs, walked at `WALK_SPEED` from outside the
## field to outside it again: the crash's own emission less the walking decay, integrated over the
## time it takes. `offset` is how far along the spread axis the line runs.
func _pass_cost(instance: EventInstance, offset: float) -> float:
	var vertical := instance.solid_axis() == Vector2.DOWN
	var across := Vector2.RIGHT if vertical else Vector2.DOWN
	var along := Vector2.DOWN if vertical else Vector2.RIGHT
	var reach: float = instance.def.field_reach() + 8.0
	var walker: Vector2 = instance.global_position + along * offset - across * reach
	var paid := 0.0
	var travelled := 0.0
	while travelled < reach * 2.0:
		walker += across * Tuning.WALK_SPEED * STEP
		travelled += Tuning.WALK_SPEED * STEP
		paid += (instance.contribution_at(walker) - Tuning.EXCITEMENT_DECAY_WALKING) * STEP
	return paid

## The open lanes as readable spans, so a run says where the gaps are rather than how many samples
## fell in them.
func _gap_spans(open: PackedFloat32Array) -> String:
	if open.is_empty():
		return "none"
	var spans: Array[String] = []
	var from: float = open[0]
	var last: float = open[0]
	for i in range(1, open.size()):
		if open[i] - last > LANE_STEP * 1.5:
			spans.append("%.0f..%.0f" % [from, last])
			from = open[i]
		last = open[i]
	spans.append("%.0f..%.0f" % [from, last])
	return ", ".join(spans)
