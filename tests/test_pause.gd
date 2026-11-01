extends RefCounted
## The pause and the title screen, which share this file because both are the game's ends: the
## title is where a run begins and where a finished one goes back to, and the pause is where a
## run in progress can be walked away from and returned to. Neither has anywhere else its own
## suite would naturally sit.
##
## **`Esc` did nothing from M33 until M36.** The guard in `main._unhandled_input` read
## `_summary.visible`, and `_summary` is a `CanvasLayer` whose `visible` is `true` from the moment
## it is added to the tree — what the summary hides and shows is the `Control` *inside* it. So the
## guard was satisfied on every frame of every day and the pause screen was never opened once.
##
## A green suite and a screenshot both passed it, and neither could have caught it: nothing in
## either of them has ever pressed a key. What is asserted here is therefore not "the pause works"
## — that is `--press pause`, in a real run, with a screenshot — but the two things underneath it
## that a unit test *can* hold: **the property that looks like the question is not the question**,
## and the pause puts back the paused state it found rather than assuming one.
##
## **Every screen is driven the way a player drives it.** An event is pushed through the viewport
## the screen is in (`UiScreens.push`), so it passes the GUI layer before the screen's unhandled
## pass; a button is found by the name the scene gives it and pressed where it is really drawn,
## after the frames a container needs to lay it out; the two-frame acknowledgement of a tap is
## waited out in real frames; and a hold of a full second is a `ModeButton` handed a clock that
## moves a second (`ModeButton.use_clock()`) rather than a second of waiting. The platform a screen
## runs on is handed in (`use_platform()`, `use_touch()`) before it enters the tree, and nothing is
## read from or written to a private member.

const UI := preload("res://tests/ui_screens.gd")
const SUMMARY := preload("res://scenes/ui/day_summary.tscn")
const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const TITLE := preload("res://scenes/ui/title_screen.tscn")
const TOUCH_CONTROLS := preload("res://scenes/ui/touch_controls.tscn")

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
	_test_a_canvas_layer_is_always_visible(t)
	_test_the_pause_puts_back_what_it_found(t)
	_test_space_carries_on_from_every_screen(t)
	_test_the_pause_says_where_the_run_stands(t)
	_test_there_is_a_way_out_of_a_finished_run(t)
	_test_a_press_soon_after_a_restart_is_swallowed_not_started(t)
	_test_the_title_screen_does_not_stop_the_city(t)
	_test_every_walking_key_begins_the_run(t)
	await _test_a_press_on_either_title_button_starts_a_run_in_that_mode(t)
	await _test_a_round_button_catches_its_old_square_and_five_percent_past_its_disc(t)
	await _test_a_real_touch_on_a_title_button_reaches_the_title_screen(t)
	_test_the_title_quit_key_matches_the_platform(t)
	_test_the_pause_quit_key_matches_the_platform(t)
	await _test_a_tap_advances_every_screen(t)
	await _test_a_mouse_click_advances_every_screen(t)
	_test_the_title_hint_and_body_match_the_platform(t)
	_test_the_title_names_the_mode_once_it_is_decided(t)
	_test_the_button_fill_states_are_distinguishable(t)
	_test_the_title_names_a_version(t)
	_test_mode_button_restart_hold_state_machine(t)
	await _test_the_restart_hold_drops_its_pressed_fill_once_the_sweep_starts(t)
	_test_mode_button_pressed_and_hovered_drive_the_stylebox(t)
	await _test_hover_lights_up_the_button_under_the_mouse(t)
	await _test_button_catches_and_hover_are_radial_when_rotated(t)
	_test_the_pause_hint_and_body_match_the_platform(t)
	_test_the_pause_body_names_the_run_button_in_the_joystick_scheme(t)
	_test_the_buttons_show_on_every_device(t)
	await _test_the_restart_button_is_a_hold(t)
	await _test_a_real_touch_on_the_continue_button_reaches_the_pause_screen(t)
	await _test_a_real_touch_hold_on_the_restart_button_fires_on_the_pause_screen(t)
	await _test_a_touch_away_from_restart_still_carries_on(t)
	await _test_pause_keeps_the_last_heading_through_the_dismiss_press(t)
	await _test_pause_stays_standing_through_the_dismiss_press(t)
	_test_the_summary_hint_matches_the_platform(t)
	_test_an_ending_has_no_continue_button(t)
	await _test_the_summary_restart_button_is_a_hold(t)
	await _test_a_real_touch_on_the_continue_button_reaches_the_summary(t)
	await _test_a_real_touch_hold_on_the_restart_button_fires_on_the_summary(t)
	await _test_a_continue_press_flashes_before_it_is_acted_on(t)
	t.get_tree().paused = was_paused

## A pause screen on a platform, in the tree and closed.
func _pause(t, touch := false, can_quit := true) -> PauseScreen:
	var pause: PauseScreen = PAUSE.instantiate()
	pause.use_run(GameState)
	pause.use_platform(touch, can_quit)
	t.add_child(pause)
	return pause

## A title screen on a platform, in the tree and closed. Its clock runs well past any restart the
## process stamped (the stamp is process-wide, and the guard test makes one), so only the guard
## test meets the guard.
func _title(t, touch := false, can_quit := true) -> TitleScreen:
	var title: TitleScreen = TITLE.instantiate()
	title.use_run(GameState)
	title.use_platform(touch, can_quit)
	title.use_clock(func() -> int: return Time.get_ticks_msec() + 100000)
	t.add_child(title)
	return title

## A between-days summary on a platform, in the tree and not yet showing.
func _summary(t, touch := false) -> CanvasLayer:
	var summary: CanvasLayer = SUMMARY.instantiate()
	summary.use_touch(touch)
	t.add_child(summary)
	return summary

## Shows an ordinary day's summary that ended as `result`.
func _show_day_over(summary: CanvasLayer, result: GameEnums.DayResult) -> void:
	summary.show_summary(SummaryModel.day_over(GameState, UI.ended(result)), RunFlow.Mode.DAY_OVER)

## A restart button whose hold is measured on a clock the test moves.
func _clocked(restart: ModeButton, clock: UI.FakeClock) -> void:
	restart.use_clock(clock.read)

func _test_button_catches_and_hover_are_radial_when_rotated(t) -> void:
	var window: Window = t.get_window()
	var old_size := window.size
	for rotated in [false, true]:
		window.size = Vector2i(720, 1280) if rotated else Vector2i(1280, 720)
		# The catch is the 122.7px square (half-side `radius` * 4/3) holding the 1.05 circle, so a
		# point just inside and just past the square's edge and its corner are the edges.
		var radius := ModeButton.RADIUS
		var half_square := radius * 4.0 / 3.0
		var offsets: Array[Vector2] = [Vector2.RIGHT * half_square * 0.999,
				Vector2.RIGHT * half_square * 1.001, Vector2.ONE * radius * 0.9,
				Vector2.ONE * half_square * 0.999, Vector2.ONE * half_square * 1.001]
		for kind: String in ["title", "pause", "summary"]:
			for offset: Vector2 in offsets:
				var expected := maxf(absf(offset.x), absf(offset.y)) < half_square
				var started := [0]
				var screen: Node
				var button: ModeButton
				if kind == "title":
					var title := _title(t, true)
					title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
							_side: ControlsMode.Side) -> void: started[0] += 1)
					screen = title
				elif kind == "pause":
					screen = _pause(t, true)
				else:
					screen = _summary(t, true)
				ScreenOrientation.apply_to_layer(screen, rotated)
				if kind == "title":
					screen.open()
					button = UI.button(screen, "Left")
				elif kind == "pause":
					screen.open()
					button = UI.button(screen, "Restart")
				else:
					_show_day_over(screen, GameEnums.DayResult.WON)
					button = UI.button(screen, "Restart")
				await UI.frames(t)
				var presented := ScreenOrientation.to_presented_space(
						UI.centre(button) + offset, rotated)
				UI.push(screen, UI.touch_at(presented, true))
				var caught: bool
				if kind == "title":
					await UI.frames(t)
					caught = started[0] == 1
				else:
					caught = button.is_held_by(0)
					if caught:
						UI.push(screen, UI.touch_at(Vector2.ZERO, false))
						t.check(not button.is_held(), "restart release outside the disc still ends its hold")
					# A press the button did not catch is a tap on the screen, which carries on.
					await UI.frames(t)
				t.check(caught == expected, "button press agrees with radial catch (%s, rotated %s, offset %s)"
						% [kind, rotated, offset])
				screen.free()
				t.get_tree().paused = false
	window.size = old_size
	# Hover is a mouse's, and a mouse is not a touch device, which is the only kind that rotates
	# (`ScreenOrientation.wants_rotation`): hover is read in the upright presentation alone.
	window.size = Vector2i(1280, 720)
	for kind: String in ["title", "pause", "summary"]:
		var screen: Node
		var button: ModeButton
		if kind == "title":
			screen = _title(t)
			screen.open()
			button = UI.button(screen, "Left")
		elif kind == "pause":
			screen = _pause(t)
			screen.open()
			button = UI.button(screen, "Restart")
		else:
			screen = _summary(t)
			_show_day_over(screen, GameEnums.DayResult.WON)
			button = UI.button(screen, "Restart")
		await UI.frames(t)
		var radius := ModeButton.RADIUS
		var half_square := radius * 4.0 / 3.0
		for offset: Vector2 in [Vector2.RIGHT * half_square * 0.999,
				Vector2.RIGHT * half_square * 1.001, Vector2.ONE * radius * 0.9,
				Vector2.ONE * half_square * 0.999, Vector2.ONE * half_square * 1.001]:
			var expected := maxf(absf(offset.x), absf(offset.y)) < half_square
			var motion := InputEventMouseMotion.new()
			motion.position = UI.centre(button) + offset
			UI.push(screen, motion)
			t.check((UI.fill(button) == Palette.BUTTON_HOVER) == expected,
					"%s hover follows the catch, including square corners (offset %s)" % [kind, offset])
		screen.free()
		t.get_tree().paused = false
	window.size = old_size

func _test_a_canvas_layer_is_always_visible(t) -> void:
	var summary := _summary(t)
	t.check(not summary.is_showing(), "a fresh summary is not showing")
	t.check(summary.visible,
			"but its own `visible` is true anyway — asking it is how Esc broke for three milestones")
	summary.free()

## Opening over the between-days summary is the case the first version refused outright, on the
## grounds that two things fighting over `get_tree().paused` is how a pause stops meaning anything.
## That is true, and the answer is to not fight: whatever was found is what goes back.
func _test_the_pause_puts_back_what_it_found(t) -> void:
	var pause := _pause(t)
	t.check(not pause.is_open(), "the pause starts closed")

	t.get_tree().paused = false
	pause.open()
	t.check(pause.is_open() and t.get_tree().paused, "opening it over the city pauses the tree")
	pause.close()
	t.check(not pause.is_open() and not t.get_tree().paused, "and closing it starts the day again")

	# Over something that has already stopped the world — the summary, the ending screen.
	t.get_tree().paused = true
	pause.open()
	t.check(t.get_tree().paused, "opening it over a stopped screen leaves the tree stopped")
	pause.close()
	t.check(t.get_tree().paused,
			"and closing it hands the screen underneath back its pause rather than resuming a day "
			+ "that had ended")
	t.get_tree().paused = false
	pause.free()

## **One verb, every screen.** *(M39, playtest 10 finding 6: "from pause space should also let you
## continue".)*
##
## The title screen and the between-days summary have both meant *carry on* by `space` since M38, and
## the pause was the one screen that did not take it — so a player learned the verb on two screens out
## of three and found it missing on the third. Asserted as the property rather than as the key, so a
## fourth screen that forgets it fails here: **from every screen the game can come to rest on, space
## carries on.**
func _test_space_carries_on_from_every_screen(t) -> void:
	var pause := _pause(t)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	t.get_tree().paused = false
	pause.open()
	UI.push(pause, _accept())
	t.check(resumed[0] == 1 and not pause.is_open(), "space carries on from the pause")
	t.check(not t.get_tree().paused, "and the day starts again")

	# Esc still works, because it is also the key that opened this and a toggle should untoggle.
	pause.open()
	UI.push(pause, _action("pause"))
	t.check(resumed[0] == 2 and not pause.is_open(), "and so does the key that opened it")
	t.get_tree().paused = false
	pause.free()

## **A pause with the run on it.** *(M39, playtest 10 finding 7: "in the pause screen the day and
## nerves should show prominently as well".)*
##
## Both numbers live in the HUD, behind a screen that covers the HUD — and the pause is exactly when
## somebody stops to ask how far in they are and how much they can still get wrong. It is read at
## `open()` rather than kept in step with `EventBus`: a screen only ever looked at while the game is
## stopped cannot go stale, and a listener that has to stay correct across fourteen days will not.
func _test_the_pause_says_where_the_run_stands(t) -> void:
	var pause := _pause(t)
	var standing := UI.control(pause, "Standing") as Label
	var day := GameState.header.day
	var nerves := GameState.header.nerves

	GameState.header.day = 7
	GameState.header.nerves = 3
	t.get_tree().paused = false
	pause.open()
	var line: String = standing.text
	t.check(line.contains("7") and line.contains("***"),
			"the pause says which day it is and how many nerves are left, as stars ('%s')" % line)
	t.check(line == SummaryModel.standing_line(GameState),
			"and the line is the summary model's own standing line, the one formatter")
	pause.close()

	# A single nerve is one star, drawn through the same `Texts.nerve_stars()` every other screen
	# reads the count through — never a digit and never the word.
	GameState.header.nerves = 1
	pause.open()
	t.check(standing.text.contains(Texts.nerve_stars(1)) and not standing.text.contains("1 nerve"),
			"and the last one is one star, not a number ('%s')" % standing.text)
	pause.close()

	GameState.header.day = day
	GameState.header.nerves = nerves
	t.get_tree().paused = false
	pause.free()

## **The dead end.** *(M38: "the lost screen doesn't allow for restarting the game — you can just
## cycle between pause screen and loss screen at that point.")*
##
## Four keys across two screens and none of them started a run: the ending said `esc to quit`, `Esc`
## opened the pause, and the pause offered `Esc` and `Q`. What is asserted is the property that was
## missing rather than the fix — **from every screen the game can come to rest on, some key starts a
## run** — so a later screen that forgets it fails here rather than in somebody's evening.
##
## The keys are pushed as real `InputEventKey`s, because that is what the two screens read and it is
## exactly the difference the M36 bug turned on. `--press key:r` is the same check in a real window.
func _test_there_is_a_way_out_of_a_finished_run(t) -> void:
	var pause := _pause(t)
	var restarts := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)

	UI.push(pause, _key(KEY_R))
	t.check(restarts[0] == 0, "a key the pause screen never saw does nothing")

	t.get_tree().paused = false
	pause.open()
	UI.push(pause, _key(KEY_R))
	t.check(restarts[0] == 1, "r on the pause screen asks for a new run")
	pause.close()
	pause.free()

	# And the other end of the same dead end: the last screen of a run has a key on it.
	var summary := _summary(t)
	summary.show_summary(SummaryModel.ending(GameState, GameEnums.Ending.BAD), RunFlow.Mode.ENDING)
	t.check(summary.is_showing(), "the ending screen is up")
	var carried_on := [0]
	summary.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)
	UI.push(summary, _accept())
	t.check(carried_on[0] == 1,
			"and space carries on from it, rather than leaving the run with no key on it at all")
	t.get_tree().paused = false
	summary.free()

## **A press within the guard window of a restart-triggered reload is swallowed, not started.**
## *(2026-09-07: "tapping on the game over screen often goes directly back to the game skipping the
## title screen".)* The restart is stamped on the title screen's class (`note_restart_requested()`)
## — the one place that survives the reload that frees the node under test itself — so the guard is
## driven through that call rather than through `main._restart_run()`, which cannot safely be
## called from a test: it defers a real `reload_current_scene()`, which nothing in this suite can
## afford to trigger. The window passing is a restart stamped further back than the guard is long.
func _test_a_press_soon_after_a_restart_is_swallowed_not_started(t) -> void:
	var title := _title(t)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open()

	# The title is handed a clock that runs ahead of the real one by whatever the test says.
	var ahead := [0]
	title.use_clock(func() -> int: return Time.get_ticks_msec() + ahead[0])
	TitleScreen.note_restart_requested()
	UI.push(title, _accept())
	t.check(started[0] == 0, "a press right after a restart-triggered reload does not start a run")

	ahead[0] = 10000 # well past the guard window
	UI.push(title, _accept())
	t.check(started[0] == 1, "and the same key works again once the guard window has passed")

	title.close()
	title.free()

## The title screen is **not** a pause, and the difference is the whole of what is behind it.
## *(M38: "as title screen just use the home and street in front without player and let act I events
## play out.")* It shows and hides and owns two keys; deciding what keeps running is `main`'s, and a
## title screen that paused the tree itself would take that decision away from it.
func _test_the_title_screen_does_not_stop_the_city(t) -> void:
	var title := _title(t)
	t.check(not title.is_open(), "the title starts hidden")

	t.get_tree().paused = false
	title.open()
	t.check(title.is_open(), "opening it shows it")
	t.check(not t.get_tree().paused,
			"and it does not pause the tree itself — the city plays out behind it")

	var started := [0]
	var quit := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.quit_requested.connect(func() -> void: quit[0] += 1)
	UI.push(title, _accept())
	t.check(started[0] == 1, "space begins the run")
	UI.push(title, _key(KEY_Q))
	t.check(quit[0] == 1, "and q leaves")

	title.close()
	UI.push(title, _accept())
	t.check(started[0] == 1, "a closed title screen answers nothing")
	title.free()

## **Every direction key begins a run too, in `Mode.TAP`.** *(2026-09-07: "awsd and arrows should
## start the game in addition to space", and "using awsd or arrow keys will start the game with tap
## mode".)* `WASD` and the arrows are bound to all four `move_*` actions, so a single `move_left`
## press stands in for the rest of them. Read as *the keyboard is a desktop and a desktop is a
## mouse* — a player pressing a direction key has told this screen nothing about a thumb either, the
## same reasoning that makes `TAP` the mouse mode at all.
func _test_every_walking_key_begins_the_run(t) -> void:
	var title := _title(t)
	var started_modes: Array[ControlsMode.Mode] = []
	var by_keys: Array[bool] = []
	title.start_requested.connect(func(mode: ControlsMode.Mode, by_key: bool,
			_side: ControlsMode.Side) -> void:
		started_modes.append(mode)
		by_keys.append(by_key))
	title.open()

	UI.push(title, _action("move_left"))
	t.check(started_modes.size() == 1, "a direction key begins the run exactly as space does")
	t.check(started_modes[0] == ControlsMode.Mode.TAP, "and always chooses tap, never joystick")
	t.check(by_keys == [true], "and says a key began it, so the counter reports keys, not tap")

	title.close()
	title.free()

## **A round button's catch holds both the 122.7px square it had before the 5% margin and the
## circle 5% past its drawn disc** *(2026-10-10, the player: "why does the button reach decrease
## anything??? the 5% should go over the visible size making the area *larger*!")*. The margin alone
## made it a 48.3px circle, about half the area. Pinned on the title's three buttons, which are the
## pause screen's and the summary's too (one `ModeButton`), at points in the old square's corner and
## just past its edge, in the button's own local frame so a rotated presentation does not matter.
func _test_a_round_button_catches_its_old_square_and_five_percent_past_its_disc(t) -> void:
	var title := _title(t)
	title.open()
	await UI.frames(t)
	for button: ModeButton in [UI.button(title, "Left"), UI.button(title, "Right"),
			UI.button(title, "Tap")]:
		var centre := button.size * 0.5
		var drawn := minf(button.size.x, button.size.y) * 0.5
		var half_square := ModeButton.RADIUS + ModeButton.RADIUS / 3.0
		var transform := button.get_global_transform()
		t.close_to(drawn, ModeButton.RADIUS, "the disc is drawn at %.0fpx" % ModeButton.RADIUS, 0.01)
		for local: Vector2 in [centre + Vector2(drawn * 1.05 - 0.5, 0.0),
				centre + Vector2(half_square - 0.5, 0.0), centre + Vector2(0.0, -(half_square - 0.5)),
				centre + Vector2(half_square - 0.5, half_square - 0.5),
				centre + Vector2(-(half_square - 0.5), half_square - 0.5)]:
			t.check(button.contains_design_point(transform * local),
					"%.1fpx right and %.1fpx down of the disc's centre is inside the catch"
					% [local.x - centre.x, local.y - centre.y])
		for local: Vector2 in [centre + Vector2(half_square + 0.5, 0.0),
				centre + Vector2(0.0, half_square + 0.5), centre + Vector2(-(half_square + 0.5), 0.0)]:
			t.check(not button.contains_design_point(transform * local),
					"%.1fpx past the old square's edge is outside it" % (half_square + 0.5 - ModeButton.RADIUS))
	title.close()
	title.free()

## **The buttons are the only pointer way in, and each answers the mode and side it names.**
## *(2026-09-07: "let's make the controls a player choice and bring back the two buttons ... that
## should also solve the issue with the missing title screen since the only way to start the game
## will be clicking on one of the buttons". 2026-10-10: "the joystick select buttons move to where
## the joystick buttons will be. selecting the left one will make the left side permanently
## joystick and the right side permanently run button ... vice versa on the right side. the tap to
## play button goes in the center between both.")* The discs are read where the real layout puts
## them, a frame or two after the screen opens: on the two focal points, and midway between them.
##
## Acknowledged two frames ahead of itself, the same as every other button that fires and closes
## its own screen — see `_test_a_tap_advances_every_screen` for why both frames are waited out.
func _test_a_press_on_either_title_button_starts_a_run_in_that_mode(t) -> void:
	var title := _title(t)
	var started: Array[Array] = []
	var by_keys: Array[bool] = []
	title.start_requested.connect(func(mode: ControlsMode.Mode, by_key: bool,
			side: ControlsMode.Side) -> void:
		started.append([mode, side])
		by_keys.append(by_key))
	title.open()
	await UI.frames(t)
	var expected := [
		[UI.button(title, "Left"), TouchControls.FOCUS_LEFT,
				[ControlsMode.Mode.JOYSTICK, ControlsMode.Side.LEFT], "left joystick"],
		[UI.button(title, "Right"), TouchControls.FOCUS_RIGHT,
				[ControlsMode.Mode.JOYSTICK, ControlsMode.Side.RIGHT], "right joystick"],
		[UI.button(title, "Tap"), (TouchControls.FOCUS_LEFT + TouchControls.FOCUS_RIGHT) * 0.5,
				[ControlsMode.Mode.TAP, ControlsMode.Side.LEFT], "tap"],
	]
	for row: Array in expected:
		var button: ModeButton = row[0]
		var centre := UI.centre(button)
		t.check(centre.distance_to(row[1]) < 0.5,
				"the %s button's disc is centred on %s (got %s)" % [row[3], row[1], centre])

	for row: Array in expected:
		var button: ModeButton = row[0]
		UI.push(title, UI.touch_at(UI.centre(button), true))
		t.check(started.size() < expected.find(row) + 1,
				"the %s press is acknowledged before it is acted on" % row[3])
		await UI.frames(t)
		t.check(started.size() == expected.find(row) + 1 and started.back() == row[2],
				"pressing the %s button starts a run as %s (got %s)" % [row[3], row[2], started])
	t.check(by_keys == [false, false, false], "a button press is never reported as a key")

	title.close()
	title.free()

## **The regression test playtest 29 finding 2 owes, the title screen's own half.** See
## `_test_a_real_touch_on_the_continue_button_reaches_the_pause_screen` for the full reasoning: an
## event handed straight to a screen's handler skips Godot's GUI layer, the one place that consumed
## a raw `InputEventScreenTouch` before `ModeButton._ready()` set `MOUSE_FILTER_IGNORE`, and
## `UI.push` goes through the viewport, so it is the one call that would fail here if that regressed.
func _test_a_real_touch_on_a_title_button_reaches_the_title_screen(t) -> void:
	var title := _title(t)
	var started_modes: Array[ControlsMode.Mode] = []
	var by_keys: Array[bool] = []
	title.start_requested.connect(func(mode: ControlsMode.Mode, by_key: bool,
			_side: ControlsMode.Side) -> void:
		started_modes.append(mode)
		by_keys.append(by_key))
	title.open()
	await UI.frames(t)

	UI.push(title, UI.touch_at(UI.centre(UI.button(title, "Left")), true))

	# Acknowledged two frames ahead of itself — see `_test_a_tap_advances_every_screen` for why.
	t.check(started_modes.is_empty(), "the press is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(started_modes == [ControlsMode.Mode.JOYSTICK],
			"a real touch pushed through the viewport on the joystick button's own rect reaches "
			+ "the screen (this fails if mouse_filter regresses to STOP)")
	t.check(by_keys == [false], "a real touch on a button is never reported as a key")

	title.close()
	title.free()

## **"For the web version remove Q (quit) and its mentions since it doesn't have any effect. Only
## for the online version, for the local version Q needs to exist still."** `SceneTree.quit()` is
## a no-op on a Web export, so whether the platform can quit gates whether the key does anything at
## all rather than each use asking `OS.has_feature("web")` on its own — handed in
## (`use_platform()`) so a test can drive both. *(Playtest 29 finding 4: "never should it be
## mentioned to the user" — the hint this test used to also check no longer names the key on either
## platform, so only the key's own effect is asserted here now.)*
func _test_the_title_quit_key_matches_the_platform(t) -> void:
	var title := _title(t, false, true)
	var quit := [0]
	title.quit_requested.connect(func() -> void: quit[0] += 1)

	title.open()
	UI.push(title, _key(KEY_Q))
	t.check(quit[0] == 1, "the key does something where quitting works")

	title.use_platform(false, false)
	title.open()
	UI.push(title, _key(KEY_Q))
	t.check(quit[0] == 1, "and pressing it where quitting is impossible emits nothing at all")

	title.close()
	title.free()

## The same agreement, one screen further in — see `_test_the_title_quit_key_matches_the_platform`
## for why only the key's own effect is asserted, not a hint that no longer names it.
func _test_the_pause_quit_key_matches_the_platform(t) -> void:
	var pause := _pause(t, false, true)
	var quit := [0]
	pause.quit_requested.connect(func() -> void: quit[0] += 1)
	t.get_tree().paused = false

	pause.open()
	UI.push(pause, _key(KEY_Q))
	t.check(quit[0] == 1, "the key does something where quitting works")
	pause.close()

	pause.use_platform(false, false)
	pause.open()
	UI.push(pause, _key(KEY_Q))
	t.check(quit[0] == 1, "and pressing it where quitting is impossible emits nothing at all")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## A title whose mode is already decided (a save brought back) names it, "Normal" or "Hard Mode",
## in place of the checkbox; a new game shows the checkbox and no name.
func _test_the_title_names_the_mode_once_it_is_decided(t) -> void:
	var title := _title(t)
	var was_hard: bool = GameState.hard_mode
	GameState.hard_mode = false
	title.open(false, false, true)
	t.check(title.mode_name_shown() == "Normal", "a decided Normal run is named 'Normal'")
	t.check(not title.hard_mode_shown(), "and the checkbox is not offered beside it")
	GameState.hard_mode = true
	title.open(false, false, true)
	t.check(title.mode_name_shown() == "Hard Mode", "a decided Hard Mode run is named 'Hard Mode'")
	title.open(false, true)
	t.check(title.mode_name_shown() == "", "a new game, where the mode is not decided, names none")
	t.check(title.hard_mode_shown(), "and offers the checkbox")
	title.open(true)
	t.check(title.mode_name_shown() == "" and not title.hard_mode_shown(),
			"a title with no run behind it shows neither")
	GameState.hard_mode = was_hard
	title.free()

## **The hint has to name the thing that actually works.** *(2026-09-07, on review: "a bare tap no
## longer begins anything ... the screen instructs the player to do the one thing that will not
## work".)* `tap to begin` was true when a bare press anywhere began a run; once only the two
## buttons do, `press a button` is what replaces it — still no key named, the same way `tap` never
## named one *(Playtest 29 finding 4: "in fact I said to remove the keyboard inputs altogether but
## I'm willing to compromise on letting them stay silently".)* Each caption says what its own
## button does rather than naming the mode — see `Texts.WALKING_LESSON_PAUSE`'s doc for why the teaching line itself does
## not change here at all (2026-09-07's M88 asked for the buttons back, not a new lesson).
func _test_the_title_hint_and_body_match_the_platform(t) -> void:
	var title := _title(t)
	var hint := UI.control(title, "Hint") as Label
	var body := UI.control(title, "Body") as Label

	title.open()
	t.check("press a button to begin" in hint.text,
			"the hint names the thing that actually works ('%s')" % hint.text)
	t.check("Tap to walk" in body.text,
			"and the body names the tap rather than a key ('%s')" % body.text)
	t.check(not "Shift" in body.text, "no key is named")
	t.check(not "q to quit" in hint.text, "and neither is q, even where it works")
	# *(2026-09-07: "the movement tutorial should just say 'Tap to walk' and 'Double tap to run'.
	# no mention of tapping her or 'that way'".)*
	t.check(body.text.begins_with("Tap to walk, double tap to run."),
			"and the body says two things and nothing else ('%s')" % body.text)
	t.check(not "that way" in body.text and not "tap her" in body.text,
			"no mention of tapping her or 'that way' — stopping still works, it just is not taught")
	t.check(UI.button(title, "Left").visible and UI.button(title, "Tap").visible
			and UI.button(title, "Right").visible,
			"all three buttons are on screen, the only pointer way to begin a run")
	# *(Playtest 34 finding 10: "call the modes 'On-screen Controls' and 'Tap to Go' no further
	# explanations".)* The captions under the buttons are the names and nothing else; the two
	# joystick buttons share theirs, since a button's place says its side.
	for caption_path: String in ["Root/Choice/LeftColumn/LeftCaption",
			"Root/Choice/RightColumn/RightCaption"]:
		var joystick_caption: Label = title.get_node(caption_path)
		t.check(joystick_caption.text == "On-screen Controls",
				"the joystick mode is named and not explained ('%s')" % joystick_caption.text)
	var tap_caption: Label = title.get_node("Root/Choice/TapColumn/TapCaption")
	t.check(tap_caption.text == "Tap to Go",
			"and the tap mode is named and not explained ('%s')" % tap_caption.text)

	title.open(true)
	t.check("press a button to walk again" in hint.text,
			"a returning run gets the same wording, naming the buttons again ('%s')" % hint.text)

	title.close()
	title.free()

## With one hue doing every button, hover and pressed are the only feedback left that a press
## registered at all — see `Palette.BUTTON_PRESSED`'s own doc — so the three states have to read as
## three states rather than two of them collapsing into the same shade.
func _test_the_button_fill_states_are_distinguishable(t) -> void:
	t.check(Palette.BUTTON_FILL != Palette.BUTTON_HOVER,
			"resting and hover are different shades")
	t.check(Palette.BUTTON_FILL != Palette.BUTTON_PRESSED,
			"resting and pressed are different shades")
	t.check(Palette.BUTTON_HOVER != Palette.BUTTON_PRESSED,
			"and hover and pressed are different from each other too")

## The state machine `PauseScreen` and `DaySummary` both drive through `begin_hold()`/
## `is_held_by()`/`end_hold()`/`cancel_hold()`, held here on `ModeButton` itself directly rather
## than only through a screen — see `ModeButton`'s own class comment for why the two screens share
## one implementation of "held for about a second" instead of each keeping its own clock. The
## button is handed a clock the test moves, so a hold of a full second is a clock a second on.
func _test_mode_button_restart_hold_state_machine(t) -> void:
	var clock := UI.FakeClock.new()
	var button := ModeButton.new()
	button.symbol = ModeButton.Symbol.RESTART
	_clocked(button, clock)

	t.check(button.begin_hold(0), "nothing else holds it, so a first touch is accepted")
	t.check(not button.begin_hold(1), "a second finger cannot also start a hold on the same button")
	t.check(button.is_held_by(0), "the first touch is the one recorded")
	t.check(not button.is_held_by(1), "and no other index reads as held")

	t.check(not button.end_hold(1), "ending the wrong index changes nothing and answers false")
	t.check(button.is_held_by(0), "so the real hold is still live")

	t.check(not button.end_hold(0), "released immediately, it does not count as a completed hold")
	t.check(not button.is_held_by(0), "but the hold is over either way")

	t.check(button.begin_hold(0), "a fresh touch can start a new hold once the last one ended")
	clock.now += ModeButton.RESTART_HOLD_SECONDS
	t.check(button.end_hold(0), "held the full duration, it counts")

	button.begin_hold(0)
	button.cancel_hold()
	t.check(not button.is_held_by(0), "cancel_hold lets go without completing it")
	t.close_to(button.hold_progress, 0.0, "and resets the fill back to empty")

	button.hold_progress = 5.0
	t.close_to(button.hold_progress, 1.0, "hold_progress clamps above 1")
	button.hold_progress = -2.0
	t.close_to(button.hold_progress, 0.0, "and below 0")

	button.free()

## **The fix playtest 35 finding 2 asks for.** *(2026-09-07: "the light up of the reset button
## conflicts with the bar filling up." Resolved by the player's own choice among three offered:
## "Pressed fill only until the hold starts".)* The pressed fill used to stay under the sweep for the
## whole second-long hold, and a pale sweep over a near-white fill had nothing to read against.
## `begin_hold()` still flashes pressed on contact — the acknowledgement every other button gives —
## but the button's own frame drops it the instant `hold_progress` moves past zero, the same moment
## it starts painting the sweep at all, leaving the sweep alone on the resting disc for the rest of
## the hold. Asserted on the stylebox directly, the same way
## `_test_mode_button_pressed_and_hovered_drive_the_stylebox` reads every other state transition,
## with a real frame let pass after the clock moves.
func _test_the_restart_hold_drops_its_pressed_fill_once_the_sweep_starts(t) -> void:
	var clock := UI.FakeClock.new()
	var button := ModeButton.new()
	button.symbol = ModeButton.Symbol.RESTART
	_clocked(button, clock)
	t.get_tree().paused = false
	t.add_child(button)

	button.begin_hold(0)
	t.check(UI.fill(button) == Palette.BUTTON_PRESSED,
			"the flash on contact is the same pressed fill any other button gives")

	clock.now += 0.1
	await UI.frames(t)
	t.check(button.hold_progress > 0.0, "the hold's own timer has started")
	t.check(UI.fill(button) != Palette.BUTTON_PRESSED,
			"and the pressed fill has already dropped back, leaving the sweep alone on the disc")

	button.cancel_hold()
	button.free()

## **The fix playtest 34 finding 1 asks for, asserted on the stylebox `Button` actually draws.**
## *(2026-09-07: "buttons still don't light up when pressed or hovered.")* `MOUSE_FILTER_IGNORE`
## means `Button`'s own hover/pressed draw state is never reached, so `force_pressed_look()` and
## `set_hovered()` write the `"normal"` stylebox directly instead — this reads it back the same way
## `_test_a_continue_press_flashes_before_it_is_acted_on` already does for the flash.
## `begin_hold()`/`end_hold()`/`cancel_hold()` route through the same two functions, so `RESTART`'s
## own timed hold is covered by the same assertions rather than a second set.
func _test_mode_button_pressed_and_hovered_drive_the_stylebox(t) -> void:
	var button := ModeButton.new()
	button.symbol = ModeButton.Symbol.CONTINUE

	var resting := Palette.BUTTON_FILL
	button.force_pressed_look()
	t.check(UI.fill(button) == Palette.BUTTON_PRESSED,
			"force_pressed_look() paints the pressed fill")
	button.clear_forced_press()
	t.check(UI.fill(button) == resting,
			"clear_forced_press() puts the resting fill back")

	button.set_hovered(true)
	t.check(UI.fill(button) == Palette.BUTTON_HOVER,
			"set_hovered(true) paints the hover fill")
	button.set_hovered(false)
	t.check(UI.fill(button) == resting,
			"and set_hovered(false) puts the resting fill back")

	button.set_hovered(true)
	button.force_pressed_look()
	t.check(UI.fill(button) == Palette.BUTTON_PRESSED,
			"pressed wins over hovered while both are true")
	button.clear_forced_press()
	t.check(UI.fill(button) == Palette.BUTTON_HOVER,
			"clearing the press falls back to hovered rather than straight to resting")

	button.begin_hold(0)
	t.check(UI.fill(button) == Palette.BUTTON_PRESSED,
			"begin_hold() paints the same pressed fill a real press does")
	button.end_hold(0)
	t.check(UI.fill(button) == Palette.BUTTON_HOVER,
			"end_hold() clears it back through the same hover-aware path")

	button.begin_hold(0)
	button.cancel_hold()
	t.check(UI.fill(button) == Palette.BUTTON_HOVER,
			"cancel_hold() clears it the same way")

	button.free()

## **Hover is new and answered from the same raw mouse motion the press already reads.**
## *(Playtest 34 finding 1: "buttons still don't light up when pressed or hovered." Hover is "a
## laptop's question" per the TODO's own note — there is no hover on a phone, and
## `MOUSE_FILTER_IGNORE` silences `mouse_entered`/`mouse_exited` the same way it silences a click.)*
## Checked on the title screen's own two buttons and the pause screen's continue button —
## `DaySummary` shares the identical hover shape and is not re-checked here.
func _test_hover_lights_up_the_button_under_the_mouse(t) -> void:
	var title := _title(t, false)
	title.open()
	await UI.frames(t)
	var left := UI.button(title, "Left")
	var tap := UI.button(title, "Tap")

	var over_joystick := InputEventMouseMotion.new()
	over_joystick.position = UI.centre(left)
	UI.push(title, over_joystick)
	t.check(UI.fill(left) == Palette.BUTTON_HOVER,
			"the mouse sitting over the joystick button lights it up")
	t.check(UI.fill(tap) != Palette.BUTTON_HOVER,
			"and not the other button, which the mouse is not over")

	var away := InputEventMouseMotion.new()
	away.position = Vector2(20.0, 20.0)
	UI.push(title, away)
	t.check(UI.fill(left) != Palette.BUTTON_HOVER,
			"and moving away turns it off again")

	title.close()
	title.free()

	var pause := _pause(t)
	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)
	var continue_button := UI.button(pause, "Continue")

	var over_continue := InputEventMouseMotion.new()
	over_continue.position = UI.centre(continue_button)
	UI.push(pause, over_continue)
	t.check(UI.fill(continue_button) == Palette.BUTTON_HOVER,
			"the same reading lights up the pause screen's own continue button")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## The version line is the one thing on this screen not addressed to the player — see
## `BuildInfo.version_text()`, which prefers `BuildInfo.source_version()` (the `git describe`
## form) and falls back to `application/config/version`, the setting `tools/export-web.sh` bakes
## into an export before it is built. This repo always has a `.git` to ask, so the git branch is
## what is asserted directly; the fallback is checked by asserting the baked setting itself is
## present and shaped right, since forcing "no repository" from inside a test would mean stubbing
## `OS.execute`, which `source_version()` deliberately does not go through an overridable seam for.
##
## The commit beside it is the same two steps — `commit_text()` over `BuildInfo.source_commit()`
## and `application/config/source_commit` — and `build_text()` is the two joined, which is what
## the "DEBUG MODE ON" note carries after its words, so the note is read back here as well.
func _test_the_title_names_a_version(t) -> void:
	var title := _title(t)
	title.open()
	var version := UI.control(title, "Version") as Label

	t.check(version.text != "", "the title screen shows a version")
	t.check(version.text == BuildInfo.source_version(),
			"and it is git's own answer where git can give one (got '%s')" % version.text)

	var baked: String = ProjectSettings.get_setting("application/config/version", "")
	t.check(baked != "", "and the baked setting TitleScreen falls back to actually exists")
	t.check(baked.begins_with("v"), "in the same vMAJOR.MINOR.PATCH shape tools/release.sh writes")

	var commit := BuildInfo.commit_text()
	t.check(commit == BuildInfo.source_commit(),
			"the commit is git's own answer where git can give one (got '%s')" % commit)
	t.check(commit.length() >= 7 and commit.is_valid_hex_number(),
			"and it is an abbreviated hash (got '%s')" % commit)
	var baked_commit: String = ProjectSettings.get_setting("application/config/source_commit", "")
	t.check(baked_commit != "", "and the baked setting commit_text falls back to actually exists")

	var build := BuildInfo.build_text()
	t.check(build.contains(BuildInfo.version_text()) and build.contains(commit),
			"the build stamp is the describe form and the commit together (got '%s')" % build)
	var note := DebugModeNote.new()
	t.add_child(note)
	var note_label: Label = note.get_node("Note")
	t.check(note_label.text.begins_with("DEBUG MODE ON") and note_label.text.contains(build),
			"the debug note says so and carries the stamp (got '%s')" % note_label.text)
	note.free()

	title.close()
	title.free()

## **One hint (always empty), one body, on every device.** *(Playtest 29 finding 4: "never should
## it be mentioned to the user".)* The platform used to choose between a keyboard body/hint and a
## touch one; now the body is the touch wording on both and the hint is always blank — the
## continue/restart pair says what a press does instead. `Esc`, `space`, `r` and `q` all keep
## working regardless (see `_test_there_is_a_way_out_of_a_finished_run` and the quit-key tests);
## only the sentences naming them are gone.
func _test_the_pause_hint_and_body_match_the_platform(t) -> void:
	var pause := _pause(t, false)
	t.get_tree().paused = false
	var hint := UI.control(pause, "Hint") as Label
	var body := UI.control(pause, "Body") as HelpText

	pause.open()
	t.check(hint.text == "",
			"the hint says nothing at all, even on a keyboard-and-mouse desktop ('%s')" % hint.text)
	t.check("Tap to walk" in body.line,
			"and the body names the tap rather than a key, even here ('%s')" % body.line)
	t.check(not "Shift" in body.line and not "Arrows" in body.line,
			"no key is named")
	# *(2026-09-07: "the movement tutorial should just say 'Tap to walk' and 'Double tap to run'.
	# no mention of tapping her or 'that way'".)*
	t.check(body.line.begins_with("Tap to walk, double tap to run."),
			"and the body says two things and nothing else ('%s')" % body.line)
	t.check(not "that way" in body.line and not "tap her" in body.line,
			"no mention of tapping her or 'that way' — stopping still works, it just is not taught")
	pause.close()

	pause.use_platform(true, true)
	pause.open()
	t.check(hint.text == "",
			"the touch hint says nothing either — the buttons say it now ('%s')" % hint.text)
	t.check("Tap to walk" in body.line,
			"and the body names the tap rather than a control it does not draw")
	t.check(UI.control(pause, "Buttons").visible, "and the continue/restart pair is what shows instead")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## *(2026-09-06, playtest 26 finding 4 and playtest 27 finding 4: a restart control asked for on
## the pause screen and re-asked once the touch buttons existed but this one still had none; then
## playtest 29 finding 1: "I specifically said that now all controls are treated the same across
## platforms so the buttons should show in *every* environment".)* The pair shows on every device —
## both pointer schemes work on every device now, and a press sets a direction on a
## keyboard-and-mouse desktop exactly as it does on a phone, so the same buttons are a control
## there too.
func _test_the_buttons_show_on_every_device(t) -> void:
	var desktop := _pause(t, false)
	t.check(UI.control(desktop, "Buttons").visible, "a keyboard-and-mouse desktop gets the buttons too")
	desktop.free()

	var phone := _pause(t, true)
	t.check(UI.control(phone, "Buttons").visible, "and so does a touch device")
	phone.free()
	t.get_tree().paused = false

## **The trap this milestone's own design names**: a touch anywhere already means *carry on*, so a
## press that lands on the restart button has to be caught before that catch-all or it would both
## start a hold and immediately close the screen underneath it. Driven with events shaped at the
## restart button's centre, where the layout really draws it, the same way every other touch test
## in this file drives a real propagated event rather than calling the hold logic by name.
func _test_the_restart_button_is_a_hold(t) -> void:
	var pause := _pause(t, true)
	var restarts := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	var clock := UI.FakeClock.new()
	var restart := UI.button(pause, "Restart")
	_clocked(restart, clock)

	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)

	var at := UI.centre(restart)
	UI.push(pause, UI.touch_at(at, true))
	t.check(restart.is_held_by(0), "landing on the restart button starts a hold")
	t.check(resumed[0] == 0, "and does not also read as carrying on")
	t.check(pause.is_open(), "the screen stays open while the hold is tracked")

	# Released early: no restart, and the screen still has not read it as carrying on either —
	# the catch-all never saw this touch at all, on either its press or its release.
	UI.push(pause, UI.touch_at(at, false))
	t.check(restarts[0] == 0, "letting go early cancels rather than restarting")
	t.check(resumed[0] == 0, "and still does not carry on")
	t.check(not restart.is_held_by(0), "and the hold's own state is cleared either way")

	# Held the full duration this time: the clock moves a second and a frame lets the button see it.
	# Firing is the button's own frame reaching full — *(Playtest 144: "The button only activated
	# when releasing though. It should trigger the moment it is full.")* — not this release; see
	# `tests/test_held_restart.gd`'s own real-engine-dispatch version of the same thing.
	UI.push(pause, UI.touch_at(at, true))
	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1, "the disc filling fires it, before any release")
	UI.push(pause, UI.touch_at(at, false))
	t.check(restarts[0] == 1, "and the release afterwards does not fire it again")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## **The regression test playtest 29 finding 2 owes.** A raw event handed straight to a screen's
## handler is exactly the one path that skips Godot's GUI layer — the layer that runs between
## `_input` and `_unhandled_input` and consumes a raw `InputEventScreenTouch` landing on a `Control`
## whose `mouse_filter` is the default `STOP`. That is what made every button on this screen
## unusable until `ModeButton._ready()` set `MOUSE_FILTER_IGNORE`. Every touch in this file is
## pushed through the viewport (`UI.push`), so it is a call that would fail here if `mouse_filter`
## regressed to `STOP`.
##
## **The `in_local_coords` flag is load-bearing.** Without it the viewport applies the window's own
## stretch transform to the event position, and a headless test window is not the 1280x720 design
## box every screen is authored against, so an untransformed push would land the touch somewhere
## else entirely and the test would pass for the wrong reason.
##
## The press position is the button's own real `get_global_rect().get_center()` after the layout
## frames, so this is asserting against the button's actual on-screen shape.
func _test_a_real_touch_on_the_continue_button_reaches_the_pause_screen(t) -> void:
	var pause := _pause(t, true)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)

	UI.push(pause, UI.touch_at(UI.centre(UI.button(pause, "Continue")), true))

	# Acknowledged two frames ahead of itself — it flashes the button first.
	t.check(resumed[0] == 0, "the press is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(resumed[0] == 1,
			"a real touch pushed through the viewport on the continue button's own rect reaches "
			+ "the screen (this fails if mouse_filter regresses to STOP)")
	t.check(not pause.is_open(), "and closes it, the same as any other press")

	t.get_tree().paused = false
	pause.free()

## The other half of the same regression: a hold has to survive the GUI layer on both its press
## and its matching release, not only its press — see the test above for why a pushed event is
## what exercises that layer at all.
func _test_a_real_touch_hold_on_the_restart_button_fires_on_the_pause_screen(t) -> void:
	var pause := _pause(t, true)
	var restarts := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	var clock := UI.FakeClock.new()
	var restart := UI.button(pause, "Restart")
	_clocked(restart, clock)

	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)

	var at := UI.centre(restart)
	UI.push(pause, UI.touch_at(at, true))
	t.check(restart.is_held_by(0),
			"a real touch pushed through the viewport on the restart button's own rect starts a "
			+ "hold (this fails if mouse_filter regresses to STOP)")

	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1,
			"held the full duration, the disc filling fires it through a real, GUI-routed event")

	UI.push(pause, UI.touch_at(at, false))
	t.check(restarts[0] == 1, "and the matching release, also GUI-routed, does not fire it again")

	pause.close()
	t.get_tree().paused = false
	pause.free()

## A touch that lands away from the restart button is not this button's business at all — the
## catch-all below still reads it as carrying on, exactly as any other tap on this screen already
## does.
func _test_a_touch_away_from_restart_still_carries_on(t) -> void:
	var pause := _pause(t, true)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)

	UI.push(pause, UI.touch_at(Vector2(20.0, 20.0), true))
	# Acknowledged two frames ahead of itself — it flashes the continue button first.
	await UI.frames(t)
	t.check(resumed[0] == 1, "a touch nowhere near the restart button still carries on")

	t.get_tree().paused = false
	pause.free()

## **"Pause can keep the last direction just don't overwrite it from the button press."**
## *(PLAYTEST-67, "The first press walks her".)* The leak: `TouchControls` used to arm its drag
## pointer for the very press that dismisses the pause screen, even though its own
## `get_tree().paused` guard already turned that same press into a no-op for the world — so a
## finger or a mouse button still down a frame or two later, once the pause screen's own two-frame
## acknowledge delay has actually unpaused the tree, delivers an ordinary
## `InputEventScreenDrag`/`InputEventMouseMotion` for the same pointer, and the controls read it as
## a fresh heading. A real touchscreen reports a point or two of drift from a finger that is not
## deliberately moving, which is why the report reads as *always* rather than *sometimes*.
## Reproduced here with a real `PauseScreen` and `TouchControls` sharing one viewport, the pair
## `main._ready()` actually wires together, rather than asserting against `TouchControls` alone:
## the bug is in how the two interact, not in either on its own. The dismissing press never being
## tracked is read from what the later drift does to her heading, which is what it was for.
func _test_pause_keeps_the_last_heading_through_the_dismiss_press(t) -> void:
	# She stands east of the pause screen's continue button, so a heading taken from a finger on
	# that button would point west, not along the heading she carried in.
	var rig := Node2D.new()
	rig.add_to_group("player")
	rig.global_position = Vector2(1100.0, 300.0)
	t.add_child(rig)
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.TAP)
	controls.set_direction(Vector2(1500.0, 300.0), false) # due east of her
	t.check(Input.is_action_pressed("move_right"), "walking east before the pause")

	var pause := _pause(t, true)
	pause.set_touch_controls(controls)
	pause.open()
	await UI.frames(t) # the transition into pause force-releases the held direction
	t.check(not Input.is_action_pressed("move_right"),
			"opening the pause lets go of the held direction, same as ever")

	var at := UI.centre(UI.button(pause, "Continue"))
	var touch := UI.touch_at(at, true)
	UI.push(pause, touch)

	await UI.frames(t)
	t.check(not pause.is_open(), "the press has closed the pause")

	# The same finger, still down, drifts a couple of pixels once the day is running again --
	# a real touch controller's own sensor noise, not a second, deliberate gesture.
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = at + Vector2(2.0, 1.0)
	UI.push(controls, drag)
	t.check(Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_left")
			and not Input.is_action_pressed("move_up") and not Input.is_action_pressed("move_down"),
			"the dismissing press itself is never tracked for a later drag, and she resumes east "
			+ "-- the heading she carried into the pause -- not a new one from the finger that "
			+ "dismissed it")

	UI.push(controls, UI.touch_at(drag.position, false))
	_release_moves()
	t.get_tree().paused = false
	pause.free()
	controls.free()
	rig.free()

## The other half of the same fix: a run that was never walking must not start walking from the
## press that dismisses the pause either.
func _test_pause_stays_standing_through_the_dismiss_press(t) -> void:
	var rig := Node2D.new()
	rig.add_to_group("player")
	rig.global_position = Vector2(1100.0, 300.0)
	t.add_child(rig)
	var controls: TouchControls = TOUCH_CONTROLS.instantiate()
	t.add_child(controls)
	controls.set_mode(ControlsMode.Mode.TAP)
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"standing before the pause")

	var pause := _pause(t, true)
	pause.set_touch_controls(controls)
	pause.open()
	await UI.frames(t)

	var at := UI.centre(UI.button(pause, "Continue"))
	UI.push(pause, UI.touch_at(at, true))
	await UI.frames(t)
	t.check(not pause.is_open(), "the press has closed the pause")

	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = at + Vector2(2.0, 1.0)
	UI.push(controls, drag)
	t.check(Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") == Vector2.ZERO,
			"and she still stands -- the finger that dismissed the pause is not her first heading")

	UI.push(controls, UI.touch_at(drag.position, false))
	_release_moves()
	t.get_tree().paused = false
	pause.free()
	controls.free()
	rig.free()

## Movement actions and `run` are global `Input` state, not scoped to this suite's own nodes --
## the new pause/`TouchControls` pair above is the first thing in this file to press one.
func _release_moves() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")
	Input.action_release(&"run")

## The between-days summary and the ending it leads to say nothing at all — the continue/restart
## pair says it instead, on every device. *(Playtest 29 finding 4: "never should it be mentioned
## to the user.")* `space` still carries on regardless of what the hint says.
func _test_the_summary_hint_matches_the_platform(t) -> void:
	var summary := _summary(t, false)
	var hint := UI.control(summary, "Hint") as Label

	_show_day_over(summary, GameEnums.DayResult.WON)
	t.check(hint.text == "",
			"the hint says nothing, even on a keyboard-and-mouse desktop ('%s')" % hint.text)
	summary.free()

	summary = _summary(t, true)
	hint = UI.control(summary, "Hint") as Label
	_show_day_over(summary, GameEnums.DayResult.LOST_TIMEOUT)
	t.check(hint.text == "", "the touch hint says nothing either — the buttons say it now")
	t.check(UI.control(summary, "Buttons").visible, "and the continue/restart pair is what shows instead")

	summary.show_summary(SummaryModel.ending(GameState, GameEnums.Ending.GOOD),
			RunFlow.Mode.ENDING)
	t.check(hint.text == "", "and the ending screen agrees too ('%s')" % hint.text)
	t.check(UI.control(summary, "Buttons").visible, "the row still shows, for the restart button")
	t.check(not UI.control(summary, "ContinueColumn").visible,
			"but not the continue button — see _test_an_ending_has_no_continue_button")

	t.get_tree().paused = false
	summary.free()

## *(Playtest 28 finding 4: "the game over screen cannot have a continue button".)* Every other
## screen this row appears on carries on into a day that still has one; an ending has none, and the
## button was drawn as *continue* while doing exactly what the catch-all underneath it already
## does — restart the run. The restart button stays, hold and all — *(2026-09-06, asked directly:
## "the restart button, hold and all")* — since a screen with no day left to protect still owes one
## interaction learned everywhere it is met.
func _test_an_ending_has_no_continue_button(t) -> void:
	var summary := _summary(t, true)
	var continue_column := UI.control(summary, "ContinueColumn")

	_show_day_over(summary, GameEnums.DayResult.WON)
	t.check(continue_column.visible, "an ordinary day summary still offers continue")

	summary.show_summary(SummaryModel.ending(GameState, GameEnums.Ending.BAD), RunFlow.Mode.ENDING)
	t.check(not continue_column.visible, "but the ending screen does not")
	t.check(UI.button(summary, "Restart").get_parent().visible,
			"the restart button stays, hold and all")

	# The row returns to its ordinary shape once a fresh run's own day summary shows — the flag
	# belongs to the screen currently up, not to whatever was up last.
	_show_day_over(summary, GameEnums.DayResult.WON)
	t.check(continue_column.visible,
			"and a later day summary is not left thinking it is still an ending")

	t.get_tree().paused = false
	summary.free()

## The day summary's own restart button, the second half of M76's item 2 — the pause screen's own
## version is `_test_the_restart_button_is_a_hold`, and the two share every line of the state
## machine through `ModeButton.begin_hold()`/`end_hold()`, so only the wiring differs here.
func _test_the_summary_restart_button_is_a_hold(t) -> void:
	var summary := _summary(t, true)
	var restarts := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	var continued := [0]
	summary.continued.connect(func(_raised_in: int) -> void: continued[0] += 1)
	var clock := UI.FakeClock.new()
	var restart := UI.button(summary, "Restart")
	_clocked(restart, clock)

	_show_day_over(summary, GameEnums.DayResult.LOST_TIMEOUT)
	await UI.frames(t)

	var at := UI.centre(restart)
	UI.push(summary, UI.touch_at(at, true))
	t.check(restart.is_held_by(0), "landing on the restart button starts a hold")
	t.check(continued[0] == 0, "and does not also read as continuing")

	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1, "the disc filling fires it, before any release")
	UI.push(summary, UI.touch_at(at, false))
	t.check(restarts[0] == 1, "and the release afterwards does not fire it again")
	t.check(continued[0] == 0, "and still never reads as continuing")

	# A touch elsewhere on the same screen still means continue, exactly as before this button
	# existed — acknowledged two frames ahead of itself, see `_test_a_tap_advances_every_screen`
	# for why both frames are waited out, and why it is two and not one.
	_show_day_over(summary, GameEnums.DayResult.WON)
	UI.push(summary, UI.touch_at(Vector2(20.0, 20.0), true))
	t.check(continued[0] == 0, "not yet — the press is acknowledged first")
	await UI.frames(t)
	t.check(continued[0] == 1, "a touch away from the restart button still continues")

	t.get_tree().paused = false
	summary.free()

## **The regression test playtest 29 finding 2 owes, the summary's own half.** See `PauseScreen`'s
## `_test_a_real_touch_on_the_continue_button_reaches_the_pause_screen` for the full reasoning:
## an event handed straight to a handler skips the GUI layer that consumed the raw touch before
## `ModeButton._ready()` set `MOUSE_FILTER_IGNORE`, and an event pushed through the viewport is the
## one that would fail here if that regressed.
func _test_a_real_touch_on_the_continue_button_reaches_the_summary(t) -> void:
	var summary := _summary(t, true)
	var carried_on := [0]
	summary.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)

	_show_day_over(summary, GameEnums.DayResult.WON)
	await UI.frames(t)

	UI.push(summary, UI.touch_at(UI.centre(UI.button(summary, "Continue")), true))

	# Acknowledged two frames ahead of itself — see `_test_a_tap_advances_every_screen` for why.
	t.check(carried_on[0] == 0, "the press is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(carried_on[0] == 1,
			"a real touch pushed through the viewport on the continue button's own rect reaches "
			+ "the screen (this fails if mouse_filter regresses to STOP)")

	t.get_tree().paused = false
	summary.free()

## The other half: a hold has to survive the GUI layer on both its press and its matching release.
func _test_a_real_touch_hold_on_the_restart_button_fires_on_the_summary(t) -> void:
	var summary := _summary(t, true)
	var restarts := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	var clock := UI.FakeClock.new()
	var restart := UI.button(summary, "Restart")
	_clocked(restart, clock)

	_show_day_over(summary, GameEnums.DayResult.LOST_TIMEOUT)
	await UI.frames(t)

	var at := UI.centre(restart)
	UI.push(summary, UI.touch_at(at, true))
	t.check(restart.is_held_by(0),
			"a real touch pushed through the viewport on the restart button's own rect starts a "
			+ "hold (this fails if mouse_filter regresses to STOP)")

	clock.now += ModeButton.RESTART_HOLD_SECONDS
	await UI.frames(t)
	t.check(restarts[0] == 1,
			"held the full duration, the disc filling fires it through a real, GUI-routed event")

	UI.push(summary, UI.touch_at(at, false))
	t.check(restarts[0] == 1, "and the matching release, also GUI-routed, does not fire it again")

	t.get_tree().paused = false
	summary.free()

## **The ordering fix 2 exists for**, asserted directly rather than only screenshotted: the
## continue button's own resting colour changes the instant a tap lands, stays changed across the
## one frame boundary that renders it, and only reverts — together with the day actually starting —
## on the second. A version that awaited `process_frame` once, which the first draft of this fix
## did, would already show the reverted colour and `carried_on == 1` after the *first* frame
## here, since `SceneTree.process_frame` fires before the frame it names is drawn rather than after
## — see `DaySummary._acknowledge_and_continue()`'s own doc for how that was found.
func _test_a_continue_press_flashes_before_it_is_acted_on(t) -> void:
	var summary := _summary(t, true)
	_show_day_over(summary, GameEnums.DayResult.WON)
	await UI.frames(t)
	var carried_on := [0]
	summary.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)
	var continue_button := UI.button(summary, "Continue")

	var resting := UI.fill(continue_button)
	UI.push(summary, UI.touch_at(Vector2(20.0, 20.0), true))
	var flashed := UI.fill(continue_button)
	t.check(flashed != resting,
			"the continue button's resting colour changes the instant any tap continues")
	t.check(carried_on[0] == 0, "and the day has not actually started yet")

	await UI.frames(t, 1)
	t.check(UI.fill(continue_button) == flashed,
			"the flash is still showing after the first frame boundary")
	t.check(carried_on[0] == 0, "and still has not started")

	await UI.frames(t, 1)
	t.check(UI.fill(continue_button) == resting,
			"and only clears once the second frame boundary has passed")
	t.check(carried_on[0] == 1, "which is also when the day actually starts")

	t.get_tree().paused = false
	summary.free()

## **A tap advances the pause and the summary** — a phone has no `space`, and nothing before this
## fired anything for a touch at all. Checked on both screens a tap may dismiss, the same shape
## `_test_space_carries_on_from_every_screen` already checks for the key, and a release is checked
## to do nothing so a finger lifted off elsewhere cannot be read as a dismissal.
##
## **The title screen is not a third case here any more.** *(2026-09-07: "the only way to start the
## game will be clicking on one of the buttons".)* A bare tap that lands on neither button does
## nothing at all — see `_test_a_press_on_either_title_button_starts_a_run_in_that_mode` for the
## case that does.
func _test_a_tap_advances_every_screen(t) -> void:
	var title := _title(t)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open()
	await UI.frames(t)
	UI.push(title, _touch(false))
	t.check(started[0] == 0, "lifting a finger does nothing on the title")
	UI.push(title, _touch(true))
	await UI.frames(t)
	t.check(started[0] == 0, "and neither does pressing one, since it lands on neither button")
	title.close()
	title.free()

	var pause := _pause(t)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)
	UI.push(pause, _touch(true))
	# A touch resume is acknowledged two frames before it fires — the continue button flashes, and
	# the signal fires *before* the frame it names is drawn, so the second is what actually lands
	# after the draw that happens between them. The frames are real ones: the suite's `run()` is a
	# coroutine the runner waits on.
	t.check(resumed[0] == 0, "the press is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(resumed[0] == 1 and not pause.is_open(), "and a tap carries on from the pause")
	t.get_tree().paused = false
	pause.free()

	var summary := _summary(t)
	_show_day_over(summary, GameEnums.DayResult.WON)
	await UI.frames(t)
	var carried_on := [0]
	summary.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)
	UI.push(summary, _touch(true))
	# A touch continue is acknowledged two frames before it fires, for the same reason.
	t.check(carried_on[0] == 0, "the press is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(carried_on[0] == 1, "and a tap goes on from the between-days summary")
	t.get_tree().paused = false
	summary.free()

## **The pause and the summary advance on a left click too, on every build.** *(2026-09-06, on a
## laptop: "I still need to press space even in mouse mode".)* This overturns each screen's own
## earlier reason for reading only the raw touch — a stray desktop mouse press was a real risk when
## no scheme invited the mouse; the pointer scheme now reads a click everywhere, so a laptop player
## is expected to click and both screens have to accept the one they send.
##
## **The title screen is not a third case here either** — see `_test_a_tap_advances_every_screen`'s
## own doc for why a bare click, same as a bare tap, now does nothing on this screen.
func _test_a_mouse_click_advances_every_screen(t) -> void:
	var title := _title(t)
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode, _by_key: bool,
			_side: ControlsMode.Side) -> void: started[0] += 1)
	title.open()
	await UI.frames(t)
	var release := _left_click()
	release.pressed = false
	UI.push(title, release)
	t.check(started[0] == 0, "releasing a click does nothing on the title")
	UI.push(title, _left_click())
	await UI.frames(t)
	t.check(started[0] == 0, "and neither does pressing one, since it lands on neither button")
	title.close()
	title.free()

	var pause := _pause(t)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	t.get_tree().paused = false
	pause.open()
	await UI.frames(t)
	UI.push(pause, _left_click())
	# Acknowledged two frames ahead of itself, same as a tap — see
	# `_test_a_tap_advances_every_screen` for why.
	t.check(resumed[0] == 0, "the click is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(resumed[0] == 1 and not pause.is_open(), "and a click carries on from the pause")
	t.get_tree().paused = false
	pause.free()

	var summary := _summary(t)
	_show_day_over(summary, GameEnums.DayResult.WON)
	await UI.frames(t)
	var carried_on := [0]
	summary.continued.connect(func(_raised_in: int) -> void: carried_on[0] += 1)
	UI.push(summary, _left_click())
	# A mouse click continue is acknowledged two frames ahead of itself too, like a tap.
	t.check(carried_on[0] == 0, "the click is acknowledged before it is acted on")
	await UI.frames(t)
	t.check(carried_on[0] == 1, "and a click goes on from the between-days summary")
	t.get_tree().paused = false
	summary.free()

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	return event

func _accept() -> InputEventAction:
	return _action("ui_accept")

func _action(name: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	return event

func _touch(pressed: bool) -> InputEventScreenTouch:
	return UI.touch_at(Vector2.ZERO, pressed)

## A left mouse click, pressed. Godot's own GUI routing keeps a click away from the unhandled pass
## whenever it actually lands on a `Button`, so every click this helper builds behaves as one that
## missed both — which the screens read as nothing at all.
func _left_click() -> InputEventMouseButton:
	return UI.mouse_at(Vector2.ZERO, true)

## The pause screen's run line shows the run button where the chosen scheme draws one (inbox #533),
## and is re-read on every open, since the title screen can choose the scheme after the screen was
## built.
func _test_the_pause_body_names_the_run_button_in_the_joystick_scheme(t) -> void:
	var controls: TouchControls = load("res://scenes/ui/touch_controls.tscn").instantiate()
	t.add_child(controls)
	var pause := _pause(t)
	var body := UI.control(pause, "Body") as HelpText
	pause.open()
	t.check(body.line.begins_with("Tap to walk, double tap to run."),
			"tap scheme: the body says double tap to run, got '%s'" % body.line)
	pause.close()
	controls.set_mode(ControlsMode.Mode.JOYSTICK)
	pause.open()
	t.check(body.line.begins_with("Tap to walk, hold {run} or double tap to run."),
			"joystick scheme: the body shows the run button, got '%s'" % body.line)
	pause.close()
	pause.free()
	controls.free()
