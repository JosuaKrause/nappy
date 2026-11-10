@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## `WalkEvents`, the walk's events read through one object while she walks: its plans in the order
## they stream, every plan but the one being placed, the doors and the day's calm areas, checked
## here once on rows built by hand, with what stands inside an area and the day's locations it was
## handed. Everything that reads the walk is handed it, or a stand-in with
## the answers set (`tests/fake_walk_events.gd`).

func run(t) -> void:
	_test_a_plan_placed_while_she_walks_joins_the_walk(t)
	_test_everything_but_leaves_out_the_plan_being_placed(t)
	_test_clearing_forgets_the_walk(t)
	_test_a_point_is_clear_of_the_walk_past_each_plans_clearance(t)
	_test_what_stands_inside_an_area(t)
	_test_the_walk_holds_the_days_locations(t)

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

## **Whether a point stands clear of the walk's events** (`is_clear_at()`, what the park cordon keeps
## its last gap clear of): inside a body's clearance is not clear, past it is; a spent plan, one not
## placed, and one inside the ground left out are not asked.
func _test_a_point_is_clear_of_the_walk_past_each_plans_clearance(t) -> void:
	var her := 14.0
	var block := _row("barricade", Vector2(320, 320))
	var reach := block.clearance(her)
	var walk := WalkEvents.new()
	walk.take([block] as Array[EventScheduler.Planned])
	t.check(not walk.is_clear_at(block.placed_at() + Vector2(reach - 2.0, 0), her),
			"a point inside a barricade's clearance is not clear of the walk")
	t.check(walk.is_clear_at(block.placed_at() + Vector2(reach + 2.0, 0), her),
			"and a point just past it is")
	var near := block.placed_at() + Vector2(reach * 0.5, 0)
	t.check(walk.is_clear_at(near, her, Rect2(block.placed_at() - Vector2(8, 8), Vector2(16, 16))),
			"a plan inside the ground left out is not asked")
	block.spend()
	t.check(walk.is_clear_at(near, her), "nor is a plan spent for the day")
	var unplaced := _row("barricade", Vector2.INF)
	walk.take([unplaced] as Array[EventScheduler.Planned])
	t.check(walk.is_clear_at(near, her), "nor one the day never placed")

## **What stands inside an area** (`placed_within()`, what a section holds for day 13's swap): the
## walk's placed, unspent plans standing in it, and not one outside it, one spent, or one never placed.
func _test_what_stands_inside_an_area(t) -> void:
	var inside := _row("busker", Vector2(100, 100))
	var outside := _row("cafe_tables", Vector2(400, 100))
	var spent := _row("cafe_tables", Vector2(120, 120))
	spent.spend()
	var unplaced := _row("cat_dash", Vector2.INF)
	var walk := WalkEvents.new()
	walk.take([inside, outside, spent, unplaced] as Array[EventScheduler.Planned])
	t.check(walk.placed_within(Rect2(64, 64, 128, 128)) == ([inside] as Array[EventScheduler.Planned]),
			"what stands inside an area is the placed, unspent plans standing in it")

## **The day's locations it was handed** (`locations()`), and none once it forgets the walk.
func _test_the_walk_holds_the_days_locations(t) -> void:
	var locations := DayLocations.new()
	var walk := WalkEvents.new()
	walk.take([] as Array[EventScheduler.Planned], null, PackedVector2Array(), null, locations)
	t.check(walk.locations() == locations, "the walk answers the day's locations it was handed")
	walk.clear()
	t.check(walk.locations() == null, "and none once it forgets the walk")
