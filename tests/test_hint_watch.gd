extends RefCounted
## `HintWatch`: asks the watchers it is handed and puts the winner up, counted once, one at a time,
## and not while the exclamation mark is over her. Watchers are fakes that answer on cue; she is the
## stroller scene; frames pass for real (the watch ticks in physics).

## A watcher that applies while `applies` holds, and counts how often it was told it was shown.
class _Cue extends HintWatcher:
	var _kind := HintKind.Kind.WAY_TO_PARK
	var _applies := true
	var _every_time := false

	func _init(the_kind: HintKind.Kind, every := false) -> void:
		_kind = the_kind
		_every_time = every

	func stop() -> void:
		_applies = false

	## Overrides HintWatcher.kind.
	func kind() -> HintKind.Kind:
		return _kind

	## Overrides HintWatcher.every_time.
	func every_time() -> bool:
		return _every_time

	## Overrides HintWatcher.asks.
	func asks(_frame: HintFrame) -> bool:
		return _applies

func run(t: TestRunner) -> void:
	await _test_the_first_watcher_to_apply_wins_and_is_counted_once(t)
	await _test_an_every_time_hint_has_no_limit(t)
	await _test_the_exclamation_mark_wins_the_column(t)

func _watch(t: TestRunner, watchers: Array[HintWatcher], lines: Array[String]) -> HintWatch:
	var watch := HintWatch.new()
	watch.name = "HintWatch"
	watch.equip(RunTrace.new(func(kind: String, text: String) -> void:
			lines.append("%s %s" % [kind, text])), AtlasLibrary.new())
	watch.setup(HintLedger.new(), watchers)
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
	var first := _Cue.new(HintKind.Kind.USE_ZEBRA)
	var second := _Cue.new(HintKind.Kind.WAY_TO_PARK)
	var watch := _watch(t, [first, second] as Array[HintWatcher], lines)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 5)
	t.check(lines.size() == 1 and "use_zebra" in lines[0],
			"one bubble, the higher watcher's, said once in the run log (%s)" % [lines])
	_finish(her, watch)

func _test_an_every_time_hint_has_no_limit(t: TestRunner) -> void:
	var lines: Array[String] = []
	var cue := _Cue.new(HintKind.Kind.BACK_TO_ROUTE, true)
	var watch := _watch(t, [cue] as Array[HintWatcher], lines)
	var her := _her(t)
	watch.use_player(her)
	await _frames(t, 3)
	cue.stop()
	t.check(lines.size() == 1, "it is up once while it applies")
	_finish(her, watch)

func _test_the_exclamation_mark_wins_the_column(t: TestRunner) -> void:
	var lines: Array[String] = []
	var watch := _watch(t, [_Cue.new(HintKind.Kind.WALK_WIDE)] as Array[HintWatcher], lines)
	var her := _her(t)
	her.warn(Stroller.Alert.SOON, 5.0)
	watch.use_player(her)
	await _frames(t, 4)
	t.check(lines.is_empty(), "while the mark is up no bubble goes up, and none is counted")
	her.stand_down(&"")
	await _frames(t, 3)
	t.check(lines.size() == 1, "once the mark is down the bubble that waited goes up")
	_finish(her, watch)
