extends RefCounted
## PROBE (measuring only): one crowd car driving south at a vehicle that steps into its lane and parks
## there (test_crowd_yields.gd's `_drive_at_a_vehicle`, restated), traced each 0.5 s; prints TURN_JSON.
const CITY_SCENE := preload("res://scenes/world/city.tscn")
const RIG := preload("res://tests/test_crowd_bodies.gd")
const SEED := 4242
const STEP := 1.0 / 60.0
var _rig = RIG.new()

func run(t) -> void:
	var map := CityGenerator.generate(SEED)
	var city: City = RunCity.of_the_run(CITY_SCENE)
	t.add_child(city)
	city.build(map)
	var length := 2 * CityMap.period() + Tuning.STREET_WIDTH
	var run_at: Vector2i = _rig._a_straight_run(map, length)
	var block := Vector2i(-1, -1)
	for along in range(run_at.y, run_at.y + length):
		if posmod(along, CityMap.period()) == Tuning.STREET_WIDTH \
				and along + Tuning.BLOCK_SIZE + Tuning.STREET_WIDTH + 3 <= run_at.y + length:
			block = Vector2i(run_at.x, along)
			break
	var tile := float(Tuning.TILE_SIZE)
	var corridor := block.x
	city.crowd.start_day(1, _rng(), Vector2.ZERO)
	city.crowd.clear()
	var lane: int = CrowdLanes.road_lane(true, 1.0)
	var car: CrowdAgent = _rig._agent_on(city, map, CrowdAgent.Kind.CAR, corridor, lane,
			(float(block.y) + 1.5) * tile, 1.0)
	var at := Vector2(CrowdLanes.lane_centre(corridor, lane), (float(block.y + Tuning.BLOCK_SIZE) - 0.5) * tile)
	var figure := MoveProposal.new()
	figure.radius = EventCatalogue.by_id("police_patrol").shape.reach()
	if "stood_round" in figure:
		figure.stood_round = true
	if "parked" in figure:
		figure.parked = true
	map.moves.join(figure, at + Vector2(6.0, 0.0))
	var trace: Array = []
	var turned_at := -1.0
	var overlapping := 0
	for frame in int(round(12.0 / STEP)):
		if frame == 2:
			figure.place(at)
		city.crowd.set_focus(at)
		city.crowd.step(STEP)
		var s := float(frame) * STEP
		var turned: bool = car._corridor != corridor or not car._vertical or car._direction < 0.0
		if turned and turned_at < 0.0:
			turned_at = s
		var d := (at - car.position).length()
		if d < car.shape.radius + figure.radius - 0.5:
			overlapping += 1
		if frame % 30 == 0:
			trace.append({"t": snappedf(s, 0.01), "y": snappedf(car.position.y, 0.1), "x": snappedf(car.position.x, 0.1),
					"speed": snappedf(car.speed(), 0.1), "dir": car._direction, "vertical": car._vertical,
					"turning": car.is_turning(), "dist_to_figure": snappedf(d, 0.1)})
	print("TURN_JSON " + JSON.stringify({"turned_at": turned_at, "overlap_frames": overlapping,
			"figure_y": at.y, "trace": trace}))
	city.free()
	t.check(true, "ran")

func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("crowd-yields:%d:%d" % [SEED, 1])
	return rng
