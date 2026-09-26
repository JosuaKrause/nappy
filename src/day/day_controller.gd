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
	# The label this feeds reads to the whole second and nothing finer, so a frame that has not
	# crossed a second boundary since the last emit would only hand the HUD the same text and the
	# same urgency colour it already drew — sixty avoidable emits (and, downstream, sixty format
	# calls and a `modulate` write) for the one that actually changes anything.
	var second := int(displayed)
	if second != _last_emitted_second:
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
			failure_reason = "Dusk. You are still out."
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
			failure_reason = "She started crying. There is no settling her now."
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
	failure_reason = _HARD_FAIL_TEXT.get(reason, "It went wrong.")
	_end(GameEnums.DayResult.LOST_HARD_FAIL)

## The one place all three losing paths ask before ending the day, so `--invincible` cannot drift
## between them. Never suppresses `WON`: a won day still ends normally, so she can still walk home
## asleep and the summary still shows. See `DevFlags.invincible()`.
func _ignores_loss(result: GameEnums.DayResult) -> bool:
	return result != GameEnums.DayResult.WON and DevFlags.invincible()

const _HARD_FAIL_TEXT := {
	"abduction": "The van door opened. Nobody saw where you went.",
	"alley_robbery": "They were waiting in the alley.",
	# The same man, sent after her by a handed-over task rather than met in an alley, so the line
	# is the alley robber's with the alley taken out of it.
	"robber_giving_chase": "They were waiting for you.",
	# The van's own guard, sent after her the same way — but he is the door's own man rather than
	# the alley's, so his line follows `door_guard`'s tone (a detention, not a killing) with the
	# package named as the reason, the same "what is lost is named, never dwelt on" rule.
	"van_guard_giving_chase": "He caught up with the package still on her. They took her in.",
	"firefight": "You walked into the middle of it.",
	# Not an event, and the only hard fail the player can walk into rather than be caught by.
	"car_strike": "It never slowed down. You were in the road.",
	# Act I's two, and they are deliberately the most ordinary sentences in this table:
	# the danger act I was missing is not sinister, it is a street.
	"cyclist": "The bell, and then the bike. She is screaming.",
	"reversing_lorry": "It never saw you. Nobody was looking behind it.",
	# The escape's own catch, on the stairs rather than the street — the same figure as
	# `roadblock`'s guard (`EventCatalogue`, `masked_pursuer`'s own doc), and the same tone rule
	# the rest of this table already keeps: what is lost is named, never dwelt on.
	"masked_pursuer": "He caught you on the stairs.",
	# The door's own guard, after she walked under a raised boom rather than through a hut: a
	# detention, not a death — *"She gets detained/imprisoned or whatever in that case"* — said as
	# plainly as the rest of the table, with the reason in the first half and the baby left out of
	# it, since the regime never puts her in narrative danger directly (docs/NARRATIVE.md, the
	# tone rules).
	"door_guard": "You went under the barrier. They took you in.",
}

func _end(result: GameEnums.DayResult) -> void:
	if not is_running():
		return
	phase = GameEnums.DayPhase.OVER
	day_finished.emit(result)
