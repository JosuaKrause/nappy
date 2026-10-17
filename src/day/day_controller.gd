class_name DayController
extends Node
## One day: the clock, the two phases, and the four ways a day can end.
##
## Owns no rules about *why* the baby is asleep or crying — it listens to EventBus and
## decides what that means for the day. See docs/DESIGN.md for the win/lose table.

signal day_finished(result: GameEnums.DayResult)

var phase := GameEnums.DayPhase.OVER
var time_remaining := 0.0
var time_total := 0.0
## Set when the day ends badly, for the summary screen to explain itself.
var failure_reason := ""
## The raw `reason` a hard fail carried — `EventBus.hard_fail_triggered`'s own string, "car_strike"
## or a catalogue id — kept beside `failure_reason`'s translated sentence so `main._on_day_finished()`
## can name what ended the day for `VisitCounter` without re-deriving it from the narrative text.
## "" off a hard fail, and reset every `start()` — never carried from a previous attempt.
var hard_fail_reason := ""

var _map: CityMap
var _player: Node2D
var _connected := false
## The whole second `day_time_changed` was last emitted for. `hud.gd`'s clock reads to the second
## (`"%d:%02d" % [int(remaining) / 60, int(remaining) % 60]`) and its urgency colour flips at the
## same integer boundary (`remaining < 60.0`, which changes exactly when `int(remaining)` drops
## from 60 to 59) — so re-emitting while this has not changed can only ever hand the HUD text and
## colour it would draw identically to what it drew last time. `-1` so the day's first frame,
## whatever `time_remaining` starts at, always counts as a change.
var _last_emitted_second := -1
## Set by `FinaleController` on its own clock only. The escape's label reads to the hundredth
## (`GameState.format_clock_hundredths()`), which changes on nearly every frame, so this clock
## tells the HUD on every frame rather than once a second. A day's controller leaves it false and
## keeps the once-a-second emission above. *(inbox #746 in woolly-penguin, the player: "escape clocke we can try
## 100s but it's not going to be much better? framerate is too low? all of this was on phone.")*
var emit_every_frame := false

func setup(map: CityMap, player: Node2D) -> void:
	_map = map
	_player = player
	if _connected:
		return
	_connected = true
	EventBus.return_phase_started.connect(_on_baby_asleep)
	EventBus.baby_state_changed.connect(_on_baby_state_changed)
	EventBus.hard_fail_triggered.connect(_on_hard_fail)

func start(length: float) -> void:
	time_total = length
	time_remaining = length
	phase = GameEnums.DayPhase.WALKING
	failure_reason = ""
	hard_fail_reason = ""
	_last_emitted_second = int(time_remaining)
	EventBus.day_time_changed.emit(time_remaining, time_total)

## 1.0 at dawn, 0.0 at dusk. Drives the light.
func fraction_remaining() -> float:
	if time_total <= 0.0:
		return 1.0
	return clampf(time_remaining / time_total, 0.0, 1.0)

func is_running() -> bool:
	return phase != GameEnums.DayPhase.OVER

func _process(delta: float) -> void:
	if not is_running():
		return

	# **`--invincible` stands the clock still, never only lets it run past dusk.** *(2026-09-11,
	# overturning the flag's own first build the same evening: "when invincible the timer should
	# never go down ... this is just noisy flashing of alarms and the day gets dark.")* Skipping
	# the countdown outright, rather than decrementing and clamping the result at zero, is what
	# keeps `fraction_remaining()` at wherever the day started — the earlier build let the light
	# run itself down to dusk and then held the number, which is the "day gets dark" the player
	# was overturning. `DevFlags.invincible()` is asked directly rather than through
	# `_ignores_loss()`, which answers a different question (does a *result* end the day) that a
	# clock which never reaches zero never gets to ask.
	if not DevFlags.invincible():
		time_remaining -= delta
	var displayed := maxf(time_remaining, 0.0)
	# A day's label reads to the whole second and nothing finer, so a frame that has not crossed a
	# second boundary since the last emit would only hand the HUD the same text and the same
	# urgency colour it already drew — sixty avoidable emits (and, downstream, sixty format calls
	# and a `modulate` write) for the one that actually changes anything. The escape's clock
	# (`emit_every_frame`) reads to the hundredth and emits on every frame the countdown moves; a
	# frozen `--invincible` clock never reaches this line's emit twice, as before.
	var second := int(displayed)
	if emit_every_frame and not DevFlags.invincible():
		_last_emitted_second = second
		EventBus.day_time_changed.emit(displayed, time_total)
	elif second != _last_emitted_second:
		_last_emitted_second = second
		EventBus.day_time_changed.emit(displayed, time_total)
	if time_remaining <= 0.0:
		if _ignores_loss(GameEnums.DayResult.LOST_TIMEOUT):
			# Holds at zero rather than running arbitrarily negative, so the clock reads 0:00
			# instead of counting a day nothing is measuring any more. Unreachable in the
			# ordinary invincible run now that the countdown never moves, since it never reaches
			# zero to begin with; kept for a day started with no time left at all.
			time_remaining = 0.0
		else:
			failure_reason = Texts.DAY_LOST_DUSK
			_end(GameEnums.DayResult.LOST_TIMEOUT)
			return

	if phase == GameEnums.DayPhase.RETURNING and _is_home():
		_end(GameEnums.DayResult.WON)

func _is_home() -> bool:
	if not _map or not _player:
		return false
	return _map.tile_type_at_world(_player.global_position) == GameEnums.TileType.HOME

# ------------------------------------------------------------------- signals ---

func _on_baby_asleep() -> void:
	if phase == GameEnums.DayPhase.WALKING:
		_remember_the_calm_she_found()
		phase = GameEnums.DayPhase.RETURNING
		# Falling asleep on the doorstep should not need a lap of the block to register.
		if _is_home():
			_end(GameEnums.DayResult.WON)

## The one thing the city learns about how the player actually played, recorded at the only moment
## that means anything: where she was standing when the baby went under. It is what stops the same
## park being the answer two days running.
##
## It lives here rather than in `Baby`, and that is the invariant rather than a preference —
## the baby's entire interface to the world is three questions and none of them is about
## blocks. `DayController` is the class that already turns "she is asleep" into what it means
## for the day, so it is where "and this is the park she used" belongs too.
##
## Only calm ground counts. Falling asleep on a pavement is a different day and does not spend
## a park.
func _remember_the_calm_she_found() -> void:
	if not _map or not _player:
		return
	var here := _player.global_position
	if not Tile.is_calm(_map.tile_type_at_world(here)):
		return
	GameState.remember_where_she_settled(_map.block_at(here))

func _on_baby_state_changed(state: GameEnums.BabyState) -> void:
	if not is_running():
		return
	match state:
		GameEnums.BabyState.CRYING:
			if _ignores_loss(GameEnums.DayResult.LOST_CRYING):
				return
			failure_reason = Texts.DAY_LOST_CRYING
			_end(GameEnums.DayResult.LOST_CRYING)
		GameEnums.BabyState.AWAKE:
			# Woken on the way home: back to walking her down again.
			if phase == GameEnums.DayPhase.RETURNING:
				phase = GameEnums.DayPhase.WALKING

func _on_hard_fail(reason: String) -> void:
	if not is_running():
		return
	if _ignores_loss(GameEnums.DayResult.LOST_HARD_FAIL):
		return
	failure_reason = Texts.HARD_FAIL_TEXT.get(reason, Texts.DAY_LOST_DEFAULT)
	hard_fail_reason = reason
	_end(GameEnums.DayResult.LOST_HARD_FAIL)

## The one place all three losing paths ask before ending the day, so `--invincible` cannot drift
## between them. Never suppresses `WON`: a won day still ends normally, so she can still walk home
## asleep and the summary still shows. See `DevFlags.invincible()`.
func _ignores_loss(result: GameEnums.DayResult) -> bool:
	return result != GameEnums.DayResult.WON and DevFlags.invincible()

func _end(result: GameEnums.DayResult) -> void:
	if not is_running():
		return
	phase = GameEnums.DayPhase.OVER
	day_finished.emit(result)
