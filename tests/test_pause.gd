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

const SUMMARY := preload("res://scenes/ui/day_summary.tscn")
const PAUSE := preload("res://scenes/ui/pause_screen.tscn")
const TITLE := preload("res://scenes/ui/title_screen.tscn")

func run(t) -> void:
	var was_paused: bool = t.get_tree().paused
	_test_a_canvas_layer_is_always_visible(t)
	_test_the_pause_puts_back_what_it_found(t)
	_test_space_carries_on_from_every_screen(t)
	_test_the_pause_says_where_the_run_stands(t)
	_test_there_is_a_way_out_of_a_finished_run(t)
	_test_the_title_screen_does_not_stop_the_city(t)
	_test_the_title_quit_key_matches_the_platform(t)
	_test_the_pause_quit_key_matches_the_platform(t)
	_test_a_tap_advances_every_screen(t)
	_test_a_mouse_click_advances_every_screen(t)
	_test_the_title_hint_and_body_match_the_platform(t)
	_test_the_button_fill_states_are_distinguishable(t)
	_test_the_title_names_a_version(t)
	_test_mode_button_restart_hold_state_machine(t)
	_test_the_pause_hint_and_body_match_the_platform(t)
	_test_the_buttons_only_show_on_touch(t)
	_test_the_restart_button_is_a_hold(t)
	_test_a_touch_away_from_restart_still_carries_on(t)
	_test_the_summary_hint_matches_the_platform(t)
	_test_the_summary_restart_button_is_a_hold(t)
	_test_a_continue_press_flashes_before_it_is_acted_on(t)
	t.get_tree().paused = was_paused

## The trap, stated as an assertion so that reaching for `.visible` again fails loudly.
func _test_a_canvas_layer_is_always_visible(t) -> void:
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	t.check(not summary.is_showing(), "a fresh summary is not showing")
	t.check(summary.visible,
			"but its own `visible` is true anyway — asking it is how Esc broke for three milestones")
	summary.queue_free()

## Opening over the between-days summary is the case the first version refused outright, on the
## grounds that two things fighting over `get_tree().paused` is how a pause stops meaning anything.
## That is true, and the answer is to not fight: whatever was found is what goes back.
func _test_the_pause_puts_back_what_it_found(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
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
	pause.queue_free()

## **One verb, every screen.** *(M39, playtest 10 finding 6: "from pause space should also let you
## continue".)*
##
## The title screen and the between-days summary have both meant *carry on* by `space` since M38, and
## the pause was the one screen that did not take it — so a player learned the verb on two screens out
## of three and found it missing on the third. Asserted as the property rather than as the key, so a
## fourth screen that forgets it fails here: **from every screen the game can come to rest on, space
## carries on.**
func _test_space_carries_on_from_every_screen(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	t.get_tree().paused = false
	pause.open()
	pause._unhandled_input(_accept())
	t.check(resumed[0] == 1 and not pause.is_open(), "space carries on from the pause")
	t.check(not t.get_tree().paused, "and the day starts again")

	# Esc still works, because it is also the key that opened this and a toggle should untoggle.
	pause.open()
	pause._unhandled_input(_action("pause"))
	t.check(resumed[0] == 2 and not pause.is_open(), "and so does the key that opened it")
	t.get_tree().paused = false
	pause.queue_free()

## **A pause with the run on it.** *(M39, playtest 10 finding 7: "in the pause screen the day and
## nerves should show prominently as well".)*
##
## Both numbers live in the HUD, behind a screen that covers the HUD — and the pause is exactly when
## somebody stops to ask how far in they are and how much they can still get wrong. It is read at
## `open()` rather than kept in step with `EventBus`: a screen only ever looked at while the game is
## stopped cannot go stale, and a listener that has to stay correct across fourteen days will not.
func _test_the_pause_says_where_the_run_stands(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var day := GameState.day
	var nerves := GameState.nerves

	GameState.day = 7
	GameState.nerves = 3
	t.get_tree().paused = false
	pause.open()
	var line: String = pause._standing.text
	t.check(line.contains("7") and line.contains("3"),
			"the pause says which day it is and how many nerves are left ('%s')" % line)
	pause.close()

	# The last one reads as itself rather than as a number, because that is the one that changes
	# what a player does next.
	GameState.nerves = 1
	pause.open()
	t.check(pause._standing.text.contains("last nerve"),
			"and the last one says so ('%s')" % pause._standing.text)
	pause.close()

	GameState.day = day
	GameState.nerves = nerves
	t.get_tree().paused = false
	pause.queue_free()

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
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var restarts := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)

	pause._unhandled_input(_key(KEY_R))
	t.check(restarts[0] == 0, "a key the pause screen never saw does nothing")

	t.get_tree().paused = false
	pause.open()
	pause._unhandled_input(_key(KEY_R))
	t.check(restarts[0] == 1, "r on the pause screen asks for a new run")
	pause.close()
	pause.queue_free()

	# And the other end of the same dead end: the last screen of a run has a key on it.
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary.show_ending(GameEnums.Ending.BAD)
	t.check(summary.is_showing(), "the ending screen is up")
	var carried_on := [0]
	summary.continued.connect(func() -> void: carried_on[0] += 1)
	summary._unhandled_input(_accept())
	t.check(carried_on[0] == 1,
			"and space carries on from it, rather than leaving the run with no key on it at all")
	t.get_tree().paused = false
	summary.queue_free()

## The title screen is **not** a pause, and the difference is the whole of what is behind it.
## *(M38: "as title screen just use the home and street in front without player and let act I events
## play out.")* It shows and hides and owns two keys; deciding what keeps running is `main`'s, and a
## title screen that paused the tree itself would take that decision away from it.
func _test_the_title_screen_does_not_stop_the_city(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	t.check(not title.is_open(), "the title starts hidden")

	t.get_tree().paused = false
	title.open()
	t.check(title.is_open(), "opening it shows it")
	t.check(not t.get_tree().paused,
			"and it does not pause the tree itself — the city plays out behind it")

	var started := [0]
	var quit := [0]
	title.start_requested.connect(func() -> void: started[0] += 1)
	title.quit_requested.connect(func() -> void: quit[0] += 1)
	title._unhandled_input(_accept())
	t.check(started[0] == 1, "space begins the run")
	title._unhandled_input(_key(KEY_Q))
	t.check(quit[0] == 1, "and q leaves")

	title.close()
	title._unhandled_input(_accept())
	t.check(started[0] == 1, "a closed title screen answers nothing")
	title.queue_free()

## **"For the web version remove Q (quit) and its mentions since it doesn't have any effect. Only
## for the online version, for the local version Q needs to exist still."** `SceneTree.quit()` is
## a no-op on a Web export, so the hint and the key have to agree in both platform shapes rather
## than each asking `OS.has_feature("web")` on its own — `title._can_quit` is read once so a test
## can drive both. Both directions are checked: the key must fire where the hint offers it, and
## must emit nothing where the hint does not.
func _test_the_title_quit_key_matches_the_platform(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var quit := [0]
	title.quit_requested.connect(func() -> void: quit[0] += 1)

	title._can_quit = true
	title.open()
	t.check("q to quit" in title._hint.text, "the hint offers q where quitting works")
	title._unhandled_input(_key(KEY_Q))
	t.check(quit[0] == 1, "and the key does something there")

	title._can_quit = false
	title.open()
	t.check(not "q to quit" in title._hint.text,
			"and the hint drops it where quitting is impossible ('%s')" % title._hint.text)
	title._unhandled_input(_key(KEY_Q))
	t.check(quit[0] == 1, "pressing it there emits nothing at all")

	title.close()
	title.queue_free()

## The same agreement, one screen further in. Unlike the title, the pause screen's hint was never
## rebuilt on open — `_refresh_hint()` is what a test can call after flipping `_can_quit` to reach
## the shape `_ready()` would have produced on the other platform.
func _test_the_pause_quit_key_matches_the_platform(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var quit := [0]
	pause.quit_requested.connect(func() -> void: quit[0] += 1)
	t.get_tree().paused = false

	pause._can_quit = true
	pause._refresh_hint()
	pause.open()
	t.check("q to quit" in pause._hint.text, "the hint offers q where quitting works")
	pause._unhandled_input(_key(KEY_Q))
	t.check(quit[0] == 1, "and the key does something there")
	pause.close()

	pause._can_quit = false
	pause._refresh_hint()
	pause.open()
	t.check(not "q to quit" in pause._hint.text,
			"and the hint drops it where quitting is impossible ('%s')" % pause._hint.text)
	pause._unhandled_input(_key(KEY_Q))
	t.check(quit[0] == 1, "pressing it there emits nothing at all")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

## **The controls appear only where they are used, and every hint agrees with them** — a screen
## that says `space to begin` on a device with no space is the same defect `q to quit` was on the
## web. `title._touch` is read once so a test can drive both platform shapes, exactly as
## `_can_quit` already does for the quit key.
func _test_the_title_hint_and_body_match_the_platform(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	title._touch = false
	title._refresh_body()
	title.open()
	t.check("space to begin" in title._hint.text, "the keyboard hint says space")
	t.check("Arrows or WASD" in title._body.text, "and the body names the keys")

	title._touch = true
	title._refresh_body()
	title.open(true)
	t.check("tap to walk again" in title._hint.text,
			"the touch hint says tap ('%s')" % title._hint.text)
	t.check("Tap to walk" in title._body.text,
			"and the body names the tap rather than a control it does not draw ('%s')"
					% title._body.text)
	t.check(not "Shift" in title._body.text, "and drops the key it does not have")

	title.close()
	title.queue_free()

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
## one implementation of "held for about a second" instead of each keeping its own clock.
func _test_mode_button_restart_hold_state_machine(t) -> void:
	var button := ModeButton.new()
	button.symbol = ModeButton.Symbol.RESTART

	t.check(button.begin_hold(0), "nothing else holds it, so a first touch is accepted")
	t.check(not button.begin_hold(1), "a second finger cannot also start a hold on the same button")
	t.check(button.is_held_by(0), "the first touch is the one recorded")
	t.check(not button.is_held_by(1), "and no other index reads as held")

	t.check(not button.end_hold(1), "ending the wrong index changes nothing and answers false")
	t.check(button.is_held_by(0), "so the real hold is still live")

	button._held_since = Time.get_ticks_msec() / 1000.0
	t.check(not button.end_hold(0), "released immediately, it does not count as a completed hold")
	t.check(not button.is_held_by(0), "but the hold is over either way")

	t.check(button.begin_hold(0), "a fresh touch can start a new hold once the last one ended")
	button._held_since = Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
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

## The version line is the one thing on this screen not addressed to the player — see
## `TitleScreen.version_text()`, which prefers `Telemetry.source_version()` (the `git describe`
## form) and falls back to `application/config/version`, the setting
## `.github/workflows/deploy.yml` writes into an export before it is built. This repo always has a
## `.git` to ask, so the git branch is what is asserted directly; the fallback is checked by
## asserting the baked setting itself is present and shaped right, since forcing "no repository"
## from inside a test would mean stubbing `OS.execute`, which `source_version()` deliberately does
## not go through an overridable seam for.
func _test_the_title_names_a_version(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	title.open()

	t.check(title._version.text != "", "the title screen shows a version")
	t.check(title._version.text == Telemetry.source_version(),
			"and it is git's own answer where git can give one (got '%s')" % title._version.text)

	var baked: String = ProjectSettings.get_setting("application/config/version", "")
	t.check(baked != "", "and the baked setting TitleScreen falls back to actually exists")
	t.check(baked.begins_with("v"), "in the same vMAJOR.MINOR.PATCH shape tools/release.sh writes")

	title.close()
	title.queue_free()

## The same agreement, one screen further in.
func _test_the_pause_hint_and_body_match_the_platform(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	t.get_tree().paused = false

	pause._touch = false
	pause._refresh_body()
	pause._refresh_hint()
	pause.open()
	t.check("space or esc to carry on" in pause._hint.text, "the keyboard hint names both keys")
	t.check("r to start again" in pause._hint.text, "and the restart key")
	t.check("Arrows or WASD" in pause._body.text, "and the body names the keys")
	pause.close()

	# `_can_quit` is fixed to `false` here so this assertion is only about `_touch` — the two
	# platform questions are independent and `_test_the_pause_quit_key_matches_the_platform`
	# already covers `q to quit` composing correctly on top of either shape.
	pause._touch = true
	pause._can_quit = false
	pause._refresh_body()
	pause._refresh_hint()
	pause._refresh_buttons()
	pause.open()
	t.check(pause._hint.text == "",
			"the touch hint says nothing at all — the buttons say it now ('%s')" % pause._hint.text)
	t.check("Tap to walk" in pause._body.text,
			"and the body names the tap rather than a control it does not draw")
	t.check(pause._buttons.visible, "and the continue/restart pair is what shows instead")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

## *(2026-09-06, playtest 26 finding 4 and playtest 27 finding 4: a restart control asked for on
## the pause screen and re-asked once the touch buttons existed but this one still had none.)* A
## keyboard never sees the buttons — `space`/`esc`/`r` already read as controls there — so the pair
## is touch-only, the same split `_refresh_hint()` makes for its own sentence.
func _test_the_buttons_only_show_on_touch(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	t.get_tree().paused = false

	pause._touch = false
	pause._refresh_buttons()
	t.check(not pause._buttons.visible, "a keyboard gets no buttons")

	pause._touch = true
	pause._refresh_buttons()
	t.check(pause._buttons.visible, "and a touch device gets both")

	t.get_tree().paused = false
	pause.queue_free()

## **The trap this milestone's own design names**: a touch anywhere already means *carry on*, so a
## press that lands on the restart button has to be caught before that catch-all or it would both
## start a hold and immediately close the screen underneath it. Driven through `_unhandled_input`
## directly with events shaped at the restart button's own `catch_rect()` centre, the same way
## every other touch test in this file drives a real propagated-looking event rather than calling
## the hold logic by name.
func _test_the_restart_button_is_a_hold(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var restarts := [0]
	pause.restart_requested.connect(func() -> void: restarts[0] += 1)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	pause._touch = true
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	# `Container` sorting is deferred a frame, so a rect read straight after `open()` is still
	# (0, 0) — not what a played frame would ever see, and not what this test is about. The rect
	# is set directly so the hit test is exercised against a known shape rather than against
	# whichever position happens to have landed by the time this line runs.
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)

	var at: Vector2 = pause._restart_button.catch_rect().get_center()
	pause._unhandled_input(_touch_at(at, true))
	t.check(pause._restart_button.is_held_by(0), "landing on the restart button starts a hold")
	t.check(resumed[0] == 0, "and does not also read as carrying on")
	t.check(pause.is_open(), "the screen stays open while the hold is tracked")

	# Released early: no restart, and the screen still has not read it as carrying on either —
	# the catch-all never saw this touch at all, on either its press or its release.
	pause._unhandled_input(_touch_at(at, false))
	t.check(restarts[0] == 0, "letting go early cancels rather than restarting")
	t.check(resumed[0] == 0, "and still does not carry on")
	t.check(not pause._restart_button.is_held_by(0), "and the hold's own state is cleared either way")

	# Held the full duration this time, backdating the start so the test does not sleep.
	pause._unhandled_input(_touch_at(at, true))
	pause._restart_button._held_since = Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	pause._unhandled_input(_touch_at(at, false))
	t.check(restarts[0] == 1, "held the full duration, it fires")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

## A touch that lands away from the restart button is not this button's business at all — the
## catch-all below still reads it as carrying on, exactly as any other tap on this screen already
## does.
func _test_a_touch_away_from_restart_still_carries_on(t) -> void:
	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)

	pause._touch = true
	pause._refresh_buttons()
	t.get_tree().paused = false
	pause.open()
	# See `_test_the_restart_button_is_a_hold` for why the rect is set directly rather than read
	# straight after `open()`.
	pause._restart_button.position = Vector2(500.0, 400.0)
	pause._restart_button.size = Vector2(92.0, 108.0)

	pause._unhandled_input(_touch_at(Vector2(20.0, 20.0), true))
	t.check(resumed[0] == 1, "a touch nowhere near the restart button still carries on")

	t.get_tree().paused = false
	pause.queue_free()

func _touch_at(position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = 0
	return event

## The between-days summary and the ending it leads to both say `space` today and `tap` on a touch
## device, the same agreement the title and the pause hints keep.
func _test_the_summary_hint_matches_the_platform(t) -> void:
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)

	summary._touch = false
	summary.show_day(1, GameEnums.DayResult.WON, "", 5)
	t.check("space to go on" in summary._hint.text, "the keyboard hint says space")

	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	t.check(summary._hint.text == "", "the touch hint says nothing — the buttons say it now")
	t.check(summary._buttons.visible, "and the continue/restart pair is what shows instead")

	summary.show_ending(GameEnums.Ending.GOOD)
	t.check(summary._hint.text == "", "and the ending screen agrees too ('%s')" % summary._hint.text)
	t.check(summary._buttons.visible, "carrying the same pair of buttons")

	t.get_tree().paused = false
	summary.queue_free()

## The day summary's own restart button, the second half of M76's item 2 — the pause screen's own
## version is `_test_the_restart_button_is_a_hold`, and the two share every line of the state
## machine through `ModeButton.begin_hold()`/`end_hold()`, so only the wiring differs here.
func _test_the_summary_restart_button_is_a_hold(t) -> void:
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	var restarts := [0]
	summary.restart_requested.connect(func() -> void: restarts[0] += 1)
	var continued := [0]
	summary.continued.connect(func() -> void: continued[0] += 1)

	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.LOST_TIMEOUT, "", 3)
	# See `_test_the_restart_button_is_a_hold` for why the rect is set directly rather than read
	# straight after showing — `Container` sorting is a frame behind either way.
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)

	var at: Vector2 = summary._restart_button.catch_rect().get_center()
	summary._unhandled_input(_touch_at(at, true))
	t.check(summary._restart_button.is_held_by(0), "landing on the restart button starts a hold")
	t.check(continued[0] == 0, "and does not also read as continuing")

	summary._restart_button._held_since = Time.get_ticks_msec() / 1000.0 - ModeButton.RESTART_HOLD_SECONDS
	summary._unhandled_input(_touch_at(at, false))
	t.check(restarts[0] == 1, "held the full duration, it fires")
	t.check(continued[0] == 0, "and still never reads as continuing")

	# A touch elsewhere on the same screen still means continue, exactly as before this button
	# existed — acknowledged two frames ahead of itself, see `_test_a_tap_advances_every_screen`
	# for why both are emitted manually rather than awaited, and why it is two and not one.
	summary.show_day(2, GameEnums.DayResult.WON, "", 3)
	summary._unhandled_input(_touch_at(Vector2(20.0, 20.0), true))
	t.check(continued[0] == 0, "not yet — the press is acknowledged first")
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(continued[0] == 1, "a touch away from the restart button still continues")

	t.get_tree().paused = false
	summary.queue_free()

## **The ordering fix 2 exists for**, asserted directly rather than only screenshotted: the
## continue button's own resting colour changes the instant a tap lands, stays changed across the
## one frame boundary that renders it, and only reverts — together with the day actually starting —
## on the second. A version that awaited `process_frame` once, which the first draft of this fix
## did, would already show the reverted colour and `carried_on == 1` after the *first* `emit()`
## here, since `SceneTree.process_frame` fires before the frame it names is drawn rather than after
## — see `DaySummary._acknowledge_and_continue()`'s own doc for how that was found.
func _test_a_continue_press_flashes_before_it_is_acted_on(t) -> void:
	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary._touch = true
	summary.show_day(1, GameEnums.DayResult.WON, "", 5)
	# See `_test_the_restart_button_is_a_hold` for why the rect is set directly rather than read
	# straight after showing — a stale, pre-layout rect at the origin would otherwise swallow the
	# (20, 20) touch below as a restart-button press instead of letting it reach the catch-all.
	summary._restart_button.position = Vector2(500.0, 400.0)
	summary._restart_button.size = Vector2(92.0, 108.0)
	var carried_on := [0]
	summary.continued.connect(func() -> void: carried_on[0] += 1)

	var resting: Color = (summary._continue_button.get_theme_stylebox("normal") as StyleBoxFlat) \
			.bg_color
	summary._unhandled_input(_touch_at(Vector2(20.0, 20.0), true))
	var flashed: Color = (summary._continue_button.get_theme_stylebox("normal") as StyleBoxFlat) \
			.bg_color
	t.check(flashed != resting,
			"the continue button's resting colour changes the instant any tap continues")
	t.check(carried_on[0] == 0, "and the day has not actually started yet")

	t.get_tree().process_frame.emit()
	t.check((summary._continue_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
				== flashed,
			"the flash is still showing after the first frame boundary")
	t.check(carried_on[0] == 0, "and still has not started")

	t.get_tree().process_frame.emit()
	t.check((summary._continue_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color
				== resting,
			"and only clears once the second frame boundary has passed")
	t.check(carried_on[0] == 1, "which is also when the day actually starts")

	t.get_tree().paused = false
	summary.queue_free()

## **Every screen advances on a tap** — a phone has no `space`, and nothing before this fired
## anything for a touch at all. Checked on all three screens the game can come to rest on, the same
## shape `_test_space_carries_on_from_every_screen` already checks for the key, and a release is
## checked to do nothing so a finger lifted off elsewhere cannot be read as a dismissal.
func _test_a_tap_advances_every_screen(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var started := [0]
	title.start_requested.connect(func() -> void: started[0] += 1)
	title.open()
	title._unhandled_input(_touch(false))
	t.check(started[0] == 0, "lifting a finger does nothing on the title")
	title._unhandled_input(_touch(true))
	t.check(started[0] == 1, "and pressing one starts the run, once a flag has already answered")
	title.close()
	title.queue_free()

	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	t.get_tree().paused = false
	pause.open()
	pause._unhandled_input(_touch(true))
	t.check(resumed[0] == 1 and not pause.is_open(), "and a tap carries on from the pause")
	t.get_tree().paused = false
	pause.queue_free()

	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary.show_day(1, GameEnums.DayResult.WON, "", 5)
	var carried_on := [0]
	summary.continued.connect(func() -> void: carried_on[0] += 1)
	summary._unhandled_input(_touch(true))
	# A touch continue is acknowledged two frames before it fires — see
	# `DaySummary._acknowledge_and_continue()` for why it is two `process_frame`s rather than one:
	# the signal fires *before* the frame it names is drawn, so the second is what actually lands
	# after the draw that happens between them. Emitted manually rather than awaited: `run_tests.gd`
	# calls every suite synchronously, so an `await` in a test would return control before the rest
	# of the test ran.
	t.check(carried_on[0] == 0, "the press is acknowledged before it is acted on")
	t.get_tree().process_frame.emit()
	t.get_tree().process_frame.emit()
	t.check(carried_on[0] == 1, "and a tap goes on from the between-days summary")
	t.get_tree().paused = false
	summary.queue_free()

## **Every screen advances on a left click too, on every build.** *(2026-09-06, on a laptop: "I
## still need to press space even in mouse mode".)* This overturns each screen's own earlier
## reason for reading only the raw touch — a stray desktop mouse press was a real risk when no
## scheme invited the mouse; the pointer scheme now reads a click everywhere, so a laptop player is
## expected to click and every screen has to accept the one they send.
func _test_a_mouse_click_advances_every_screen(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var started := [0]
	title.start_requested.connect(func() -> void: started[0] += 1)
	title.open()
	var release := _left_click()
	release.pressed = false
	title._unhandled_input(release)
	t.check(started[0] == 0, "releasing a click does nothing on the title")
	title._unhandled_input(_left_click())
	t.check(started[0] == 1, "and pressing one starts the run, once a flag has already answered")
	title.close()
	title.queue_free()

	var pause: PauseScreen = PAUSE.instantiate()
	t.add_child(pause)
	var resumed := [0]
	pause.resumed.connect(func() -> void: resumed[0] += 1)
	t.get_tree().paused = false
	pause.open()
	pause._unhandled_input(_left_click())
	t.check(resumed[0] == 1 and not pause.is_open(), "and a click carries on from the pause")
	t.get_tree().paused = false
	pause.queue_free()

	var summary: CanvasLayer = SUMMARY.instantiate()
	t.add_child(summary)
	summary.show_day(1, GameEnums.DayResult.WON, "", 5)
	var carried_on := [0]
	summary.continued.connect(func() -> void: carried_on[0] += 1)
	summary._unhandled_input(_left_click())
	t.check(carried_on[0] == 1, "and a click goes on from the between-days summary")
	t.get_tree().paused = false
	summary.queue_free()

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
	var event := InputEventScreenTouch.new()
	event.pressed = pressed
	return event

## A left mouse click, pressed. Godot's own GUI routing keeps a click away from
## `_unhandled_input()` whenever it actually lands on a `Button`, so every click this helper builds
## behaves as one that missed both — which `_unhandled_input()` now reads as nothing at all.
func _left_click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	return event
