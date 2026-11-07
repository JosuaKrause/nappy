extends RefCounted
## `WalkEvents`, the walk's events read through one object while she walks: its plans in the order
## they stream, every plan but the one being placed, the doors and the day's calm areas, checked
## here once on rows built by hand. Everything that reads the walk is handed it, or a stand-in with
## the answers set (`tests/fake_walk_events.gd`).

func run(t) -> void:
	_test_a_plan_placed_while_she_walks_joins_the_walk(t)
	_test_everything_but_leaves_out_the_plan_being_placed(t)
	_test_clearing_forgets_the_walk(t)

func _row(id: String, at: Vector2) -> EventScheduler.Planned:
	return EventScheduler.Planned.new(EventCatalogue.by_id(id), at)

func _test_a_plan_placed_while_she_walks_joins_the_walk(t) -> void:
	var first := _row("busker", Vector2(64, 64))
	var walk := WalkEvents.new()
	walk.take([first] as Array[EventScheduler.Planned])
	var mast := _row("loudspeaker", Vector2(320, 320))
	walk.add(mast)
	t.check(walk.plans() == ([first, mast] as Array[EventScheduler.Planned]),
			"a plan placed while she walks streams after every plan already in the walk")

func _test_everything_but_leaves_out_the_plan_being_placed(t) -> void:
	var a := _row("busker", Vector2(64, 64))
	var b := _row("roadblock", Vector2(320, 64))
	var c := _row("cafe_tables", Vector2(640, 64))
	var walk := WalkEvents.new()
	walk.take([a, b, c] as Array[EventScheduler.Planned])
	t.check(walk.everything_but(b) == ([a, c] as Array[EventScheduler.Planned]),
			"a plan being moved is not spaced against its own old body")
	t.check(walk.everything_but() == ([a, b, c] as Array[EventScheduler.Planned]),
			"and with nothing left out it is the whole walk, in order")
	var elsewhere := _row("skip", Vector2(960, 64))
	t.check(walk.everything_but(elsewhere) == ([a, b, c] as Array[EventScheduler.Planned]),
			"a plan not yet in the walk (a place from her route's bag) leaves nothing out")

func _test_clearing_forgets_the_walk(t) -> void:
	var walk := WalkEvents.new()
	walk.take([_row("busker", Vector2(64, 64))] as Array[EventScheduler.Planned], CalmAreas.new(),
			PackedVector2Array([Vector2(640, 64)]))
	walk.clear()
	t.check(walk.plans().is_empty() and walk.calm() == null and walk.doors().is_empty(),
			"a cleared walk holds nothing of the last one")
