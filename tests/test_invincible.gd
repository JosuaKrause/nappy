extends RefCounted
## `--invincible`, M100 "An invincible mode for playtesting": `DevFlags`' own parsing of the flag,
## and that `DayController._ignores_loss()` is the single predicate all three losing paths consult,
## so a lost day under the flag stays running and a won day still ends.
##
## `DevFlags.invincible()` reads the real command line — the same one `run_tests.gd` itself reads
## to pick which suites run — so a test cannot drive it through actual argv. `DevFlags`'s own
## `_invincible_override` is the seam this suite uses instead: set immediately before exercising
## the flag and cleared straight back to `null` after, or it leaks into every suite run afterwards.

const SEED := 4242
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")

var _map: CityMap
var _player: Node2D
var _day: DayController
var _results: Array[GameEnums.DayResult] = []

func run(t) -> void:
	_test_invincible_from_args(t)
	_test_invincible_from_query(t)
	_test_crying_does_not_end_the_day_under_invincible(t)
	_test_hard_fail_does_not_end_the_day_under_invincible(t)
	_test_timeout_holds_the_clock_at_zero_under_invincible(t)
	_test_a_won_day_still_ends_under_invincible(t)
	_test_the_three_losses_still_end_the_day_with_the_flag_off(t)
	_test_the_hud_names_the_mode_when_invincible(t)
	_test_the_run_log_notes_the_flag_once_per_day(t)

# ------------------------------------------------------------ DevFlags parsing ---

func _test_invincible_from_args(t) -> void:
	t.check(not DevFlags._invincible_from_args(PackedStringArray()),
		"no command-line modifier leaves the day mortal")
	t.check(not DevFlags._invincible_from_args(PackedStringArray(["--invincible=1"])),
		"the explicit command-line spelling is a bare --invincible flag")
	t.check(DevFlags._invincible_from_args(PackedStringArray(["--invincible"])),
		"--invincible selects the mode")

func _test_invincible_from_query(t) -> void:
	t.check(not DevFlags._invincible_from_query(""),
		"an absent URL parameter leaves the day mortal")
	t.check(not DevFlags._invincible_from_query("?invincible=0"),
		"invincible=0 leaves the day mortal")
	t.check(not DevFlags._invincible_from_query("?seed=1&invincible=yes"),
		"only the documented URL value selects the mode")
	t.check(DevFlags._invincible_from_query("?invincible=1"),
		"?invincible=1 selects the mode")
	t.check(DevFlags._invincible_from_query("?seed=1&invincible=1&day=2"),
		"the invincible parameter is found among other URL parameters")

# ---------------------------------------------------------------------- rig ---

func _build(t) -> void:
	if not _map:
		_map = CityGenerator.generate(SEED)
	_results = []
	_player = Node2D.new()
	t.add_child(_player)
	_player.global_position = _map.tile_to_world(
		Vector2i(Tuning.STREET_WIDTH / 2, Tuning.STREET_WIDTH / 2))
	_day = DayController.new()
	t.add_child(_day)
	_day.set_process(false)
	_day.setup(_map, _player)
	_day.day_finished.connect(func(result: GameEnums.DayResult) -> void: _results.append(result))

func _teardown() -> void:
	_day.free()
	_player.free()

# ---------------------------------------------------------------- day loop ---

func _test_crying_does_not_end_the_day_under_invincible(t) -> void:
	_build(t)
	_day.start(300.0)
	DevFlags._invincible_override = true
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	t.check(_results.is_empty(), "crying does not end the day under --invincible")
	t.check(_day.is_running(), "the day is still running")
	t.check(_day.failure_reason == "", "nothing set a failure reason — nothing has failed")
	DevFlags._invincible_override = null
	_teardown()

func _test_hard_fail_does_not_end_the_day_under_invincible(t) -> void:
	_build(t)
	_day.start(300.0)
	DevFlags._invincible_override = true
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(_results.is_empty(), "a hard fail does not end the day under --invincible")
	t.check(_day.is_running(), "the day is still running")
	DevFlags._invincible_override = null
	_teardown()

func _test_timeout_holds_the_clock_at_zero_under_invincible(t) -> void:
	_build(t)
	_day.start(10.0)
	DevFlags._invincible_override = true
	_day._process(9.0)
	t.check(_results.is_empty(), "the day is still running before dusk")
	_day._process(5.0)
	t.check(_results.is_empty(), "dusk does not end the day under --invincible")
	t.check(_day.is_running(), "the day is still running")
	t.close_to(_day.time_remaining, 0.0, "the clock holds at zero rather than going negative", 0.001)
	_day._process(5.0)
	t.close_to(_day.time_remaining, 0.0, "and stays there", 0.001)
	DevFlags._invincible_override = null
	_teardown()

func _test_a_won_day_still_ends_under_invincible(t) -> void:
	_build(t)
	_day.start(300.0)
	DevFlags._invincible_override = true
	_player.global_position = _map.home_world_position()
	EventBus.return_phase_started.emit()
	t.check(_results == [GameEnums.DayResult.WON], "a won day still ends under --invincible")
	DevFlags._invincible_override = null
	_teardown()

## Both an explicit `false` and the default (unset) override must leave the ordinary behaviour
## alone, so the predicate's off branch is exercised rather than just its default pass-through.
func _test_the_three_losses_still_end_the_day_with_the_flag_off(t) -> void:
	DevFlags._invincible_override = false
	_build(t)
	_day.start(300.0)
	EventBus.baby_state_changed.emit(GameEnums.BabyState.CRYING)
	t.check(_results == [GameEnums.DayResult.LOST_CRYING],
		"crying still loses the day with the flag off")
	_teardown()

	_build(t)
	_day.start(300.0)
	EventBus.hard_fail_triggered.emit("abduction")
	t.check(_results == [GameEnums.DayResult.LOST_HARD_FAIL],
		"a hard fail still loses the day with the flag off")
	_teardown()

	_build(t)
	_day.start(10.0)
	_day._process(11.0)
	t.check(_results == [GameEnums.DayResult.LOST_TIMEOUT],
		"dusk still loses the day with the flag off")
	_teardown()
	DevFlags._invincible_override = null

# -------------------------------------------------------------------- HUD ---

func _test_the_hud_names_the_mode_when_invincible(t) -> void:
	var hud: CanvasLayer = HUD_SCENE.instantiate()
	t.add_child(hud)
	hud.set_process(false)
	hud._debug = true

	DevFlags._invincible_override = true
	hud._refresh_header()
	t.check(hud._header.text.contains("INVINCIBLE"),
		"the debug header names the mode so no capture from this run reads as a real one")

	DevFlags._invincible_override = false
	hud._refresh_header()
	t.check(not hud._header.text.contains("INVINCIBLE"), "and drops it once the flag is off")

	DevFlags._invincible_override = null
	hud.free()

# --------------------------------------------------------------- telemetry ---

func _test_the_run_log_notes_the_flag_once_per_day(t) -> void:
	Telemetry.begin_memory_log()

	DevFlags._invincible_override = true
	Telemetry.begin_day(1, 1, SEED, SEED, 144.0)
	var on_lines := Telemetry.current_log().lines.duplicate()

	DevFlags._invincible_override = false
	Telemetry.begin_day(2, 1, SEED, SEED, 144.0)
	var off_lines := Telemetry.current_log().lines.duplicate()

	DevFlags._invincible_override = null
	Telemetry.end_run()

	# The header line is the last one `begin_day` wrote before the next call — noted the same
	# way the seed is, once when the day opens, never as a per-frame entry.
	t.check(on_lines[on_lines.size() - 1].contains("invincible"),
		"the day header notes the flag the way it notes the seed (got '%s')"
		% on_lines[on_lines.size() - 1])
	t.check(not off_lines[off_lines.size() - 1].contains("invincible"),
		"and says nothing on a day played with the flag off (got '%s')"
		% off_lines[off_lines.size() - 1])
