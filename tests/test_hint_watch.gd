extends RefCounted
## `HintWatch`: asks the watchers it is handed and puts the winner up, counted, one at a time, a
## higher one replacing a lower one, and not while the exclamation mark is over her; a walk's start
## takes the bubble down and re-arms every watcher. Watchers are fakes that answer on cue and the
## bubble is a fake that records what it is told; frames pass for real (the watch ticks in physics).
##
## **She is the real stroller scene**, for a stated reason: the watch reads her own position,
## facing and alert (`facing_direction()`, `alert_level()`), and the mark over her is raised the
## way the game raises it, through `Stroller.warn()` and `stand_down()`. A fake would be a second
## copy of the stroller's alert levels for the watch to agree with.

## A watcher that applies while `start()`ed, holding its bubble while it applies when `holds`,
## and counts the walks it was handed.
class _Cue extends HintWatcher:
	var _kind := HintKind.Kind.WAY_TO_PARK
	var _applies := true
	var _every_time := false
	var _holds := false
	var _walks: Array[TutorialRoute] = []

	func _init(the_kind: HintKind.Kind, applies := true, every := false, holds := false) -> void:
		_kind = the_kind
		_applies = applies
		_every_time = every
		_holds = holds

	func start() -> void:
		_applies = true

	func stop() -> void:
		_applies = false

	func walks() -> Array[TutorialRoute]:
		return _walks

	## Overrides HintWatcher.kind.
	func kind() -> HintKind.Kind:
		return _kind

	## Overrides HintWatcher.every_time.
	func every_time() -> bool:
		return _every_time

	## Overrides HintWatcher.begin_walk.
	func begin_walk(route: TutorialRoute) -> void:
		_walks.append(route)

	## Overrides HintWatcher.asks.
	func asks(_frame: HintFrame) -> bool:
		return _applies

	## Overrides HintWatcher.holds_while_true.
	func holds_while_true() -> bool:
		return _holds

	## Overrides HintWatcher.still_applies.
	func still_applies(_frame: HintFrame) -> bool:
		return _applies

## A bubble that records what it is told to show and draws nothing.
class _Bubble extends ThoughtBubble:
	var _shown_now := false
	var _told: Array[HintKind.Kind] = []

	func is_shown_now() -> bool:
		return _shown_now

	func kinds() -> Array[HintKind.Kind]:
		return _told

	## Overrides ThoughtBubble._enter_tree.
	func _enter_tree() -> void:
		pass

	## Overrides ThoughtBubble._exit_tree.
	func _exit_tree() -> void:
		pass

	## Overrides ThoughtBubble.put_up.
	func put_up(kind: HintKind.Kind, _direction: Vector2) -> void:
		if not _shown_now or _told.back() != kind:
			_told.append(kind)
		_shown_now = true

	## Overrides ThoughtBubble.take_down.
	func take_down() -> void:
		_shown_now = false

func run(t: TestRunner) -> void:
	await _test_the_first_watcher_to_apply_wins_and_is_counted_once(t)
	await _test_a_higher_hint_replaces_a_lower_one_that_is_shown_now(t)
	await _test_an_every_time_hint_shows_past_the_lessons_limit(t)
	await _test_a_lesson_hint_stops_at_its_limit(t)
	await _test_a_timed_bubble_goes_after_its_show(t)
	await _test_the_exclamation_mark_wins_the_column(t)
	await _test_a_walk_starts_afresh(t)
	await _test_the_bubble_is_the_watchs_and_stands_over_her_once(t)

func _watch(t: TestRunner, watchers: Array[HintWatcher], lines: Array[String], bubble: _Bubble,
		show_seconds := HintWatch.SHOW_SECONDS) -> HintWatch:
	var watch := HintWatch.new()
	watch.name = "HintWatch"
	watch.equip(RunTrace.new(func(kind: String, text: String) -> void:
			lines.append("%s %s" % [kind, text])))
	watch.setup(HintLedger.new(), watchers, bubble, show_seconds)
	t.add_child(watch)
	return watch

func _her(t: TestRunner) -> Stroller:
	var packed: PackedScene = load("res://scenes/player/stroller.tscn")
	var her: Stroller = packed.instantiate()
	her.name = "Her"
	t.add_child(her)
	return her

func _frames(t: TestRunner, count: int) -> void:
	for i in count:
		await t.get_tree().physics_frame

func _finish(her: Stroller, watch: HintWatch) -> void:
	watch.free()
	her.free()

func _test_the_first_watcher_to_apply_wins_and_is_counted_once(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var first := _Cue.new(HintKind.Kind.USE_ZEBRA)
	var second := _Cue.new(HintKind.Kind.WAY_TO_PARK)
	var watch := _watch(t, [first, second] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 5)
	t.check(lines.size() == 1 and "use_zebra" in lines[0],
			"one bubble, the higher watcher's, said once in the run log (%s)" % [lines])
	var zebra: Array[HintKind.Kind] = [HintKind.Kind.USE_ZEBRA]
	t.check(bubble.is_shown_now() and bubble.kinds() == zebra, "and it is the one up")
	_finish(her, watch)

func _test_a_higher_hint_replaces_a_lower_one_that_is_shown_now(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var higher := _Cue.new(HintKind.Kind.BACK_TO_ROUTE, false, true, true)
	var lower := _Cue.new(HintKind.Kind.USE_ZEBRA)
	var watch := _watch(t, [higher, lower] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 3)
	higher.start()
	await _frames(t, 3)
	var in_turn: Array[HintKind.Kind] = [HintKind.Kind.USE_ZEBRA, HintKind.Kind.BACK_TO_ROUTE]
	t.check(bubble.kinds() == in_turn and lines.size() == 2,
			"the higher hint, coming to apply while the lower is up, takes the bubble (%s)" % [lines])
	_finish(her, watch)

func _shown_in_turn(t: TestRunner, cue: _Cue, times: int) -> void:
	for i in times:
		cue.start()
		await _frames(t, 2)
		cue.stop()
		await _frames(t, 2)

func _test_an_every_time_hint_shows_past_the_lessons_limit(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var cue := _Cue.new(HintKind.Kind.BACK_TO_ROUTE, false, true, true)
	var watch := _watch(t, [cue] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	var times := Tuning.HINT_SHOWS_PER_LESSON + 2
	await _shown_in_turn(t, cue, times)
	t.check(lines.size() == times, "every one of its %d moments is shown and said (%s)" % [times, lines])
	t.check(not bubble.is_shown_now(), "a held bubble comes down once its moment is over")
	_finish(her, watch)

func _test_a_lesson_hint_stops_at_its_limit(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var cue := _Cue.new(HintKind.Kind.TURN_BACK, false, false, true)
	var watch := _watch(t, [cue] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	await _shown_in_turn(t, cue, Tuning.HINT_SHOWS_PER_LESSON + 2)
	t.check(lines.size() == Tuning.HINT_SHOWS_PER_LESSON,
			"a lesson's bubble shows its few times and no more (%s)" % [lines])
	_finish(her, watch)

func _test_a_timed_bubble_goes_after_its_show(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var cue := _Cue.new(HintKind.Kind.WALK_WIDE)
	var watch := _watch(t, [cue] as Array[HintWatcher], lines, bubble, 0.1)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 2)
	cue.stop()
	await _frames(t, 1)
	t.check(bubble.is_shown_now(), "a timed bubble stays up after its moment has passed")
	await _frames(t, 12)
	t.check(not bubble.is_shown_now() and lines.size() == 1, "and goes once its show has run (%s)" % [lines])
	_finish(her, watch)

func _test_the_exclamation_mark_wins_the_column(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var watch := _watch(t, [_Cue.new(HintKind.Kind.WALK_WIDE)] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	her.warn(Stroller.Alert.SOON, 5.0)
	watch.use_player(her)
	await _frames(t, 4)
	t.check(lines.is_empty() and not bubble.is_shown_now(),
			"while the mark is up no bubble goes up, and none is counted")
	her.stand_down(&"")
	await _frames(t, 3)
	t.check(lines.size() == 1 and bubble.is_shown_now(), "once the mark is down the bubble that waited goes up")
	_finish(her, watch)

func _test_a_walk_starts_afresh(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var cue := _Cue.new(HintKind.Kind.WAY_TO_PARK)
	var watch := _watch(t, [cue] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 3)
	cue.stop()
	var route := TutorialRoute.new(null, StreetNetwork.Segment.new(Vector2i.ZERO, true),
			[] as Array[StreetNetwork.Segment], [] as Array[Vector2i], Vector2i.ZERO, Rect2i())
	watch.begin_walk(route)
	t.check(not bubble.is_shown_now(), "a walk's start takes down the bubble the last walk left up")
	var handed: Array[TutorialRoute] = [route]
	t.check(cue.walks() == handed, "and hands every watcher the walk's route")
	await _frames(t, 3)
	t.check(not bubble.is_shown_now() and lines.size() == 1, "and nothing of the last walk goes up again")
	_finish(her, watch)

func _test_the_bubble_is_the_watchs_and_stands_over_her_once(t: TestRunner) -> void:
	var lines: Array[String] = []
	var bubble := _Bubble.new()
	var watch := _watch(t, [] as Array[HintWatcher], lines, bubble)
	var her := _her(t)
	watch.use_player(her)
	watch.use_player(her)
	t.check(bubble.get_parent() == her and her.get_children().filter(
			func(child: Node) -> bool: return child is ThoughtBubble).size() == 1,
			"handed her twice, the watch stands its one bubble over her once")
	watch.free()
	await t.get_tree().process_frame
	t.check(not is_instance_valid(bubble), "and the bubble goes with the watch, not with her")
	her.free()
