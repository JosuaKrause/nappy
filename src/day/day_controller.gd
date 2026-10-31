class_name DayController
extends Node
## One day: the clock, the two phases, and the four ways a day can end.
##
## Owns no rules about *why* the baby is asleep or crying — it listens to EventBus and
## decides what that means for the day. See docs/DESIGN.md for the win/lose table.
##
## **Every day the run walks is one of these, the escape's two sections included** *(minty-lemur
## #785: "the escape is just like a normal day with some special settings")*. What a day is — its
## goal, its clock's precision — is the `DaySpec` it is handed (`spec`), so the building's service
## exit and the city's two ways out are goals of this clock exactly as her front door is, and a
## lost section ends here through the same three losing paths a day does.

signal day_finished(result: GameEnums.DayResult)

## What this day is: its goal and its clock. Handed in by whoever starts the day, before `start()`;
## an ordinary day until then.
var spec := DaySpec.new()
## Which way out a `DaySpec.Goal.CITY_EDGE` day was won by, as a `CityEdge.Kind`, or `-1` until one
## is reached. Reset by every `start()`.
var exit_reached := -1

var phase := GameEnums.DayPhase.OVER
var time_remaining := 0.0
var time_total := 0.0
## Set when the day ends badly, for the summary screen to explain itself.
var failure_reason := ""
## The raw `reason` a hard fail carried — `EventBus.hard_fail_triggered`'s own string, "car_strike"
## or a catalogue id — kept beside `failure_reason`'s translated sentence so `DayDirector.finish_day()`
## can name what ended the day for `VisitCounter` without re-deriving it from the narrative text.
## "" off a hard fail, and reset every `start()` — never carried from a previous attempt.
var hard_fail_reason := ""

var _map: CityMap
var _player: Node2D
## The run she settles in, which is told where she found her calm
## (`RunState.remember_where_she_settled()`), handed in by `setup()`.
var _run: RunState
var _connected := false
## The whole second `day_time_changed` was last emitted for. `hud.gd`'s clock reads to the second
## (`"%d:%02d" % [int(remaining) / 60, int(remaining) % 60]`) and its urgency colour flips at the
## same integer boundary (`remaining < 60.0`, which changes exactly when `int(remaining)` drops
## from 60 to 59) — so re-emitting while this has not changed can only ever hand the HUD text and
## colour it would draw identically to what it drew last time. `-1` so the day's first tick,
## whatever `time_remaining` starts at, always counts as a change.
var _last_emitted_second := -1
## `--invincible`, handed in by whoever builds the day: nothing but a win ends it and its clock
## stands still. See `tick()` and `_ignores_loss()`.
var invincible := false

func setup(map: CityMap, player: Node2D, run: RunState) -> void:
	_map = map
	_player = player
	_run = run
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
	exit_reached = -1
	_last_emitted_second = int(time_remaining)
	EventBus.day_time_changed.emit(time_remaining, time_total)

## 1.0 at dawn, 0.0 at dusk. Drives the light.
func fraction_remaining() -> float:
	if time_total <= 0.0:
		return 1.0
	return clampf(time_remaining / time_total, 0.0, 1.0)

func is_running() -> bool:
	return phase != GameEnums.DayPhase.OVER

## **One tick of the day's clock**, run by `main` on every physics tick the walk stepped, the same
## tick its play time counts (`main._physics_process()`): the countdown, what the HUD is told of it,
## dusk, and whether she has reached the day's goal. **Frame locked** (inbox #866 in minty-dolphin):
## it counts the ticks the walk stepped, never a drawn frame's length, so a lag spike slows the
## clock with the game instead of running it on, and two machines walking the same day read the same
## time; nothing counts behind a pause, a screen or a load. `delta` is the tick's length.
func tick(delta: float) -> void:
	if not is_running():
		return

	# **`invincible` stands the clock still, never only lets it run past dusk** (2026-09-11, the
	# player: "when invincible the timer should never go down ... this is just noisy flashing of
	# alarms and the day gets dark"). Skipping the countdown outright, rather than decrementing and
	# clamping at zero, keeps `fraction_remaining()` at wherever the day started, so the light
	# never runs down. Read directly rather than through `_ignores_loss()`, which answers a
	# different question (does a *result* end the day) that a clock which never reaches zero never
	# gets to ask.
	if not invincible:
		time_remaining -= delta
	var displayed := maxf(time_remaining, 0.0)
	# A day's label reads to the whole second and nothing finer, so a tick that has not crossed a
	# second boundary since the last emit would only hand the HUD the same text and the same
	# urgency colour it already drew — thirty avoidable emits (and, downstream, thirty format calls
	# and a `modulate` write) for the one that actually changes anything. A clock that reads to the
	# hundredth (`DaySpec.clock_hundredths`, the escape's) emits on every tick the countdown moves,
	# and between ticks on every drawn frame (`_process()`), since its label changes on nearly every
	# one *(inbox #746 in woolly-penguin, the player:
	# "escape clocke we can try 100s but it's not going to be much better? framerate is too low? all
	# of this was on phone.")*; a frozen `invincible` clock never reaches this line's emit twice.
	var second := int(displayed)
	if spec.clock_hundredths and not invincible:
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

	if _reached_the_goal():
		_end(GameEnums.DayResult.WON)

## **A drawn frame only shows the escape's hundredths**: between two ticks, a clock that reads to the
## hundredth (`DaySpec.clock_hundredths`) is told the tick's countdown advanced by how far the frame
## is into the next tick (`Engine.get_physics_interpolation_fraction()`), so its label moves on every
## drawn frame as smoothly as the world it is drawn over, never past where the next tick will put it.
## It changes nothing: the countdown, dusk and the goal are the tick's. A frozen `invincible` clock,
## a day's whole-second clock and a day that is over are told nothing here.
func _process(_delta: float) -> void:
	if not spec.clock_hundredths or invincible or not is_running():
		return
	var into_the_tick := Engine.get_physics_interpolation_fraction() \
			/ Engine.physics_ticks_per_second
	EventBus.day_time_changed.emit(maxf(time_remaining - into_the_tick, 0.0), time_total)

## Whether she is standing on the day's goal this tick — `spec.goal`: her front door with the baby
## asleep, or one of the city's two ways out however the baby is. The building's service exit is
## never reached by position here; the building says when she is through it (`reach_the_exit()`).
func _reached_the_goal() -> bool:
	match spec.goal:
		DaySpec.Goal.HOME:
			return phase == GameEnums.DayPhase.RETURNING and _is_home()
		DaySpec.Goal.CITY_EDGE:
			return _reached_an_exit()
	return false

## Whether she has reached the tunnel mouth or the bridge deck — within `Tuning.FINALE_EXIT_REACH`
## of the last walkable tile of the spine at either end (`spec.exits`), past her body and under two
## tiles — and which, kept in `exit_reached`.
func _reached_an_exit() -> bool:
	if not _player:
		return false
	for kind: int in spec.exits:
		if _player.global_position.distance_to(spec.exits[kind]) <= Tuning.FINALE_EXIT_REACH:
			exit_reached = kind
			return true
	return false

## The building's service exit, reached: its fade has covered the screen
## (`InteriorScene.exit_requested`), and on a `DaySpec.Goal.SERVICE_EXIT` day that is the win.
func reach_the_exit() -> void:
	if spec.goal == DaySpec.Goal.SERVICE_EXIT and is_running():
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
		if spec.goal == DaySpec.Goal.HOME and _is_home():
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
	_run.remember_where_she_settled(_map.block_at(here))

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

## The one place all three losing paths ask before ending the day, so `invincible` cannot drift
## between them. Never suppresses `WON`: a won day still ends normally, so she can still walk home
## asleep and the summary still shows.
func _ignores_loss(result: GameEnums.DayResult) -> bool:
	return result != GameEnums.DayResult.WON and invincible

func _end(result: GameEnums.DayResult) -> void:
	if not is_running():
		return
	phase = GameEnums.DayPhase.OVER
	day_finished.emit(result)
