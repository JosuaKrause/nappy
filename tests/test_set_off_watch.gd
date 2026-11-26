extends RefCounted
## **`SetOffWatch`, the places that set a row off**, with its world, its streaming and its board
## faked: the masked man's plan on open ground, her standing where each case puts her and the
## camera's view about her (`VisibleView.around()`), the board recording each warning it is asked
## to put up and putting it up only where the place answers one (`WarningBoard.warn_first()`'s own
## rule), the streaming saying the plan may come and recording each one it is asked to bring in.
## The plan, the row and the view are plain data, built as they are.
##
## Two rules no other suite reaches. **Walking into the place gives the copy set off at once, and
## a jump of more than a tile into it does not** (`SetOffWatch._walked_in()`): the stairwell's doors
## are a fade and a teleport that put her inside the place, and the at-once copy, with no badge time,
## is held to the fairness contract from the set-off distance alone. **Nothing comes while the place
## it starts at is in her sight**: no warning goes up then, and a warning whose place has come into
## sight when it runs out is withdrawn and put up again.

## Where the masked man's shaft has its foot, and where the escape city's explosion stands.
const START := Vector2(1000.0, 1000.0)

## The world the watch asks what she can see: the camera's view about her, told by the case.
class FakeWorld extends EventWorld:
	var _view := VisibleView.new()

	## The view about her standing at `her`, as the camera's would be with her at its centre.
	func look_from(her: Vector2) -> void:
		_view = VisibleView.around(her, null)

	## Overrides EventWorld.visible_view.
	func visible_view() -> VisibleView:
		return _view

## The streaming: every plan may come, and each one asked to come is recorded and comes.
class FakeStreaming extends EventStreaming:
	var _came: Array[EventPlan] = []

	func _init() -> void:
		super(EventWorld.new(EventSurroundings.new().reading(EventCatalogue.shipped())), null, null)

	## Overrides EventStreaming.may_set_off.
	func may_set_off(_plan: EventPlan) -> bool:
		return true

	## Overrides EventStreaming.set_off.
	func set_off(plan: EventPlan) -> bool:
		_came.append(plan)
		return true

	## The plans asked to come, in order.
	func came() -> Array[EventPlan]:
		return _came

## The board: records each row it is asked to warn of, and the place answer it was handed, and puts
## the warning up only where that answers a place for her (`PendingWarning.put_up()`), as the real
## board does.
class FakeBoard extends WarningBoard:
	var _rows: Array[EventDef] = []
	var _wheres: Array[Callable] = []
	var _up: Array[PendingWarning] = []

	func _init() -> void:
		super(EventWorld.new(EventSurroundings.new().reading(EventCatalogue.shipped())))

	## Overrides WarningBoard.warn_first.
	func warn_first(def: EventDef, her: Vector2, where: Callable,
			arrive: Callable) -> PendingWarning:
		_rows.append(def)
		_wheres.append(where)
		var warning := PendingWarning.new(def, where, arrive)
		if not warning.put_up(her):
			return null
		_up.append(warning)
		return warning

	## The rows it was asked to warn of, in order.
	func rows() -> Array[EventDef]:
		return _rows

	## The place answer of the latest warning asked for.
	func last_where() -> Callable:
		return _wheres.back()

	## Forgets every warning and answer it holds, which hold the watch's own callables: a case's end.
	func forget() -> void:
		_rows.clear()
		_wheres.clear()
		_up.clear()

	## The latest warning it put up, null for none.
	func last_up() -> PendingWarning:
		return _up.back() if not _up.is_empty() else null

## One watch over one plan a place sets off, the masked man's unless the case names another row,
## with its fakes.
class Rig extends RefCounted:
	var plan: EventPlan
	var world := FakeWorld.new()
	var streaming := FakeStreaming.new()
	var board := FakeBoard.new()
	var watch: SetOffWatch

	func _init(row_id := "masked_pursuer") -> void:
		plan = EventPlan.new(EventCatalogue.shipped().by_id(row_id), START)
		var walk := WalkEvents.new()
		walk.add(plan)
		watch = SetOffWatch.new(world, streaming, board, walk)

	## The case is over: the board lets go of the watch's callables, which hold the watch.
	func done() -> void:
		board.forget()
		watch.clear()

	## One tick with her standing at `her`, the camera's view about her.
	func tick(her: Vector2) -> void:
		world.look_from(her)
		watch.watch(her)

## Each case on a rig of its own, let go of when it is over.
func run(t: TestRunner) -> void:
	for case: Callable in [_test_walking_in_sets_him_off_at_once,
			_test_a_door_into_the_place_gives_his_badge_first,
			_test_inside_on_the_first_tick_gives_his_badge_first,
			_test_nothing_goes_up_while_the_foot_is_in_her_sight,
			_test_a_warning_withdrawn_in_her_sight_is_put_up_again]:
		var rig := Rig.new()
		case.call(t, rig)
		rig.done()
	for case: Callable in [_test_walking_into_an_explosions_place_gives_its_badge_first,
			_test_an_explosion_waits_while_its_crater_would_be_in_sight,
			_test_running_into_an_explosions_place_still_brings_its_bang,
			_test_an_explosions_badge_waits_while_a_run_could_bring_it_into_sight]:
		var rig := Rig.new("finale_explosion")
		case.call(t, rig)
		rig.done()

## **The escape city's explosion is never set off at once**: it comes all at once, so the badge is
## the whole of its notice, and walking into its place puts its badge up for its own time first
## (`EventDef.may_be_set_off_at_once()`), where the masked man's walk-in gives none.
func _test_walking_into_an_explosions_place_gives_its_badge_first(t: TestRunner, rig: Rig) -> void:
	var within := rig.plan.sets_off_within()
	rig.tick(START + Vector2(0.0, within + 10.0))
	t.check(rig.board.rows().is_empty(), "outside its place, nothing goes up")
	rig.tick(START + Vector2(0.0, within - 10.0))
	t.check(rig.board.rows().size() == 1
			and rig.board.rows()[0].warned_for() == rig.plan.row().warned_for()
			and rig.plan.row().warned_for() > 0.0,
			"walking in, its badge is up for its own %.2fs first" % rig.plan.row().warned_for())

## **Nothing it leaves comes into her view either**: with the explosion's own point just out of
## sight but the crater it would leave there reaching into her view, its place answers none; a
## crater's width further off, it answers the place (`EventFootprints.footprint_of()`).
func _test_an_explosion_waits_while_its_crater_would_be_in_sight(t: TestRunner, rig: Rig) -> void:
	var half_height := VisibleView.around(START, null).camera_view().size.y * 0.5
	var at_the_edge := START + Vector2(0.0, half_height + 8.0)
	rig.tick(at_the_edge)
	t.check(rig.board.rows().size() == 1, "inside its place, its warning is asked for")
	t.check(rig.board.last_where().call(at_the_edge) == Vector2.INF,
			"with its point out of sight and its crater reaching into her view, no place yet")
	var clear := START + Vector2(0.0, half_height + 120.0)
	rig.world.look_from(clear)
	t.check(rig.board.last_where().call(clear) == START,
			"with the crater wholly out of sight, it goes off where it stands")

## **A runner heading straight at an explosion along the screen's long axis still gets its bang**:
## from where its place sets it off, running the whole of its badge leaves the place and its crater
## out of her sight, so the badge runs out into the explosion going off rather than being withdrawn
## (`EventCatalogue.FINALE_EXPLOSION_SET_OFF_WITHIN`, minty-dolphin #852).
func _test_running_into_an_explosions_place_still_brings_its_bang(t: TestRunner, rig: Rig) -> void:
	var within := rig.plan.sets_off_within()
	var badge := rig.plan.row().warned_for()
	rig.tick(START + Vector2(within + 10.0, 0.0))
	rig.tick(START + Vector2(within - 10.0, 0.0))
	var up := rig.board.last_up()
	t.check(up != null, "running into its place, its badge goes up")
	if up == null:
		return
	var ran_to := START + Vector2(within - 10.0 - Tuning.RUN_SPEED * badge, 0.0)
	rig.world.look_from(ran_to)
	t.check(up.tick(badge + 0.01, ran_to) and not up.was_withdrawn()
			and rig.streaming.came() == [rig.plan],
			"run %.0fpx on through its %.1fs badge, it goes off (%.0fpx from her)"
			% [Tuning.RUN_SPEED * badge, badge, ran_to.distance_to(START)])

## **Its badge never goes up where it could come down with nothing after it**: arriving 450px from
## it, out of her sight but where a run for the whole badge would bring it into view, as a door
## could put her, nothing goes up; from twice as far, it does.
func _test_an_explosions_badge_waits_while_a_run_could_bring_it_into_sight(t: TestRunner,
		rig: Rig) -> void:
	var near := START + Vector2(450.0, 0.0)
	rig.tick(near)
	t.check(rig.board.rows().size() == 1 and rig.board.last_up() == null,
			"450px off along her street, out of sight, no badge goes up yet")
	rig.world.look_from(near)
	t.check(rig.board.last_where().call(near) == START,
			"though the place itself is out of her sight there")
	var far := START + Vector2(700.0, 0.0)
	rig.tick(far)
	t.check(rig.board.last_up() != null, "700px off, its badge goes up")

## Her step from just outside his place to just inside it, 20px, sets him off at once: the copy with
## no time alone (`EventDef.as_set_off_at_once()`), on the tick she reaches it, and he comes on that
## tick.
func _test_walking_in_sets_him_off_at_once(t: TestRunner, rig: Rig) -> void:
	var within := rig.plan.sets_off_within()
	rig.tick(START + Vector2(0.0, within + 10.0))
	t.check(rig.board.rows().is_empty(), "outside his place, nothing goes up")
	rig.tick(START + Vector2(0.0, within - 10.0))
	t.check(rig.board.rows().size() == 1, "walking in puts his warning up on that tick")
	if rig.board.rows().size() != 1:
		return
	t.check(rig.board.rows()[0].warned_for() == 0.0
			and rig.plan.row().warned_for() > 0.0,
			"with no time alone, the copy set off at once (%.2fs, the row's own %.2fs)"
			% [rig.board.rows()[0].warned_for(), rig.plan.row().warned_for()])

## A jump of more than a tile into his place, as a door's teleport makes, is no walk: the row's own
## badge time first.
func _test_a_door_into_the_place_gives_his_badge_first(t: TestRunner, rig: Rig) -> void:
	rig.tick(START + Vector2(0.0, 900.0))
	rig.tick(START + Vector2(0.0, 400.0))
	t.check(rig.board.rows().size() == 1
			and rig.board.rows()[0].warned_for() == rig.plan.row().warned_for(),
			"through a door, his warning is the row's own %.2fs first" % rig.plan.row().warned_for())

## Inside his place on the first tick the watch sees is no walk either: the row's own badge time.
func _test_inside_on_the_first_tick_gives_his_badge_first(t: TestRunner, rig: Rig) -> void:
	rig.tick(START + Vector2(0.0, 400.0))
	t.check(rig.board.rows().size() == 1
			and rig.board.rows()[0].warned_for() == rig.plan.row().warned_for(),
			"inside on the first tick, the row's own badge time too")

## With the foot of his shaft in her sight, the place answers none, so no warning is up and he is
## not counted as warned of: a step on to where it is out of her sight puts it up.
func _test_nothing_goes_up_while_the_foot_is_in_her_sight(t: TestRunner, rig: Rig) -> void:
	var near := START + Vector2(0.0, 150.0)
	rig.tick(near)
	t.check(rig.board.rows().size() == 1, "inside his place, his warning is asked for")
	t.check(rig.board.last_where().call(near) == Vector2.INF,
			"with the foot in her sight, it has no place to come from")
	var away := START + Vector2(0.0, 400.0)
	rig.tick(away)
	t.check(rig.board.rows().size() == 2, "nothing was up, so it is asked for again")
	t.check(rig.board.last_where().call(away) == START,
			"out of her sight, it comes from the foot of his shaft")
	rig.tick(away)
	t.check(rig.board.rows().size() == 2, "and once it is up, no second one beside it")

## His row's badge runs out with the foot of his shaft come into her sight: the warning is
## withdrawn and nothing comes, and the board's withdrawal (`PendingWarning.ask_again()`, which
## `WarningBoard.run()` calls) lets the watch put it up again; run out with the foot out of her
## sight, he comes. The warning is ticked as the board ticks it.
func _test_a_warning_withdrawn_in_her_sight_is_put_up_again(t: TestRunner, rig: Rig) -> void:
	var away := START + Vector2(0.0, 400.0)
	var near := START + Vector2(0.0, 150.0)
	var row_time := rig.plan.row().warned_for()
	rig.tick(START + Vector2(0.0, 900.0))
	rig.tick(away)
	var up := rig.board.last_up()
	t.check(up != null, "through a door, out of her sight, his badge is up")
	if up == null:
		return
	t.check(up.tick(row_time + 0.1, near) and up.was_withdrawn(),
			"run out with the foot in her sight, it is withdrawn")
	t.check(rig.streaming.came().is_empty(), "and he does not come")
	up.ask_again()
	rig.tick(away)
	var again := rig.board.last_up()
	t.check(rig.board.rows().size() == 2 and again != up, "withdrawn, it is put up again")
	t.check(again.tick(row_time + 0.1, away) and not again.was_withdrawn()
			and rig.streaming.came() == [rig.plan],
			"run out with the foot out of her sight, he comes")
