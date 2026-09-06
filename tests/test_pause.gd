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
	_test_the_title_hint_and_body_match_the_platform(t)
	_test_the_title_asks_when_nothing_forces_an_answer(t)
	_test_pressing_a_title_button_both_chooses_and_starts(t)
	_test_the_dropped_key_chooses_nothing(t)
	_test_an_arrow_key_chooses_the_stick(t)
	_test_a_pointer_press_away_from_the_buttons_does_nothing(t)
	_test_the_forced_controls_path_ignores_the_new_inputs(t)
	_test_the_title_hint_names_the_new_inputs(t)
	_test_the_title_buttons_carry_their_own_symbol(t)
	_test_the_title_buttons_are_sized_for_a_thumb(t)
	_test_the_title_captions_are_not_clickable(t)
	_test_the_title_captions_match_the_body_wording(t)
	_test_the_title_names_a_version(t)
	_test_the_pause_hint_and_body_match_the_platform(t)
	_test_the_summary_hint_matches_the_platform(t)
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
	title.start_requested.connect(func(_mode: ControlsMode.Mode) -> void: started[0] += 1)
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
	# This is the skip-the-question shape a `--controls` flag or a `?controls=` URL forces; a test
	# process forces neither, so it is set directly, the same way `_can_quit` and `_touch` already
	# are for their own platform questions.
	title._asking_controls = false

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
	t.check("Drag the stick" in title._body.text,
			"and the body names the stick and the run button ('%s')" % title._body.text)
	t.check(not "Shift" in title._body.text, "and drops the key it does not have")

	title.close()
	title.queue_free()

## *(2026-09-05, playtest 25 finding 3: "I like both control modes equally let the player choose on
## the title screen (instead of tap the screen to start have two buttons to choose from)".)* A
## test process forces neither `--controls` nor a `?controls=` URL, so a freshly instanced title
## always lands here — which is deliberately also the shape a fresh install shows, unless launched
## with a flag.
func _test_the_title_asks_when_nothing_forces_an_answer(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	t.check(title._asking_controls, "a title with no forcing flag asks the question")
	t.check(title._choice.visible and not title._body.visible,
			"and shows the two buttons instead of the one paragraph")
	title.queue_free()

## **One press, not a menu then a start.** Each button both names its own control scheme and starts
## the run in it, the same way the single hint used to before this milestone — there is no
## separate "confirm" step.
func _test_pressing_a_title_button_both_chooses_and_starts(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var chosen: Array = []
	title.start_requested.connect(func(mode: ControlsMode.Mode) -> void: chosen.append(mode))
	title.open()

	title._tap_button.pressed.emit()
	t.check(chosen == [ControlsMode.Mode.TAP], "pressing the tap button starts in tap mode")

	title._stick_button.pressed.emit()
	t.check(chosen == [ControlsMode.Mode.TAP, ControlsMode.Mode.STICK],
			"and the stick button starts in stick mode")

	title.close()
	title.queue_free()

## *(2026-09-06, playtest 26 finding 2: "on the local clicking should choose the tap and arrow
## keys should choose the controls ... t I'm not so sure since it's a move from keyboard to
## mouse".)* The player closed their own uncertainty by taking `T` out — no key selects the scheme
## played with a mouse, so the letter that used to reach the tap button now reaches nothing.
func _test_the_dropped_key_chooses_nothing(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var chosen: Array = []
	title.start_requested.connect(func(mode: ControlsMode.Mode) -> void: chosen.append(mode))
	title.open()

	title._unhandled_input(_key(KEY_T))
	t.check(chosen.is_empty(), "t no longer chooses anything")

	title.close()
	title.queue_free()

## An arrow key **is** the stick scheme on a desktop, so pressing one is a choice rather than
## something this screen ignores — see `_unhandled_input()`'s own doc. `ui_left` is checked as the
## representative of the four; `_is_arrow_key()` is the same one condition for all of them.
func _test_an_arrow_key_chooses_the_stick(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var chosen: Array = []
	title.start_requested.connect(func(mode: ControlsMode.Mode) -> void: chosen.append(mode))
	title.open()

	title._unhandled_input(_action("ui_left"))
	t.check(chosen == [ControlsMode.Mode.STICK], "an arrow key picks the stick")

	title.close()
	title.queue_free()

## *(2026-09-06, the player, asked directly about the touch fallback: "clicking anywhere else
## should do nothing".)* The two buttons are the only pointer route to a choice while asking: a
## left click that lands nowhere near either does nothing at all, not even the stick — the two
## earlier shapes (a click anywhere choosing tap, a touch anywhere falling back to the stick) are
## both withdrawn, since a pointer answering the question silently is exactly what two visible
## buttons exist to replace. This also covers a click landing on `_stick_caption`/`_tap_caption`:
## both set `mouse_filter = Control.MOUSE_FILTER_IGNORE` (see `TitleScreen._stick_caption`'s own
## doc), so a caption click reaches `_unhandled_input()` unconsumed exactly like one that lands on
## the bare scrim, and is the same event this test already sends.
func _test_a_pointer_press_away_from_the_buttons_does_nothing(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	var chosen: Array = []
	title.start_requested.connect(func(mode: ControlsMode.Mode) -> void: chosen.append(mode))
	title.open()

	title._unhandled_input(_left_click())
	t.check(chosen.is_empty(), "a left click away from the buttons does nothing")
	title._unhandled_input(_touch(true))
	t.check(chosen.is_empty(), "and neither does a bare touch, while the screen is still asking")

	title.close()
	title.queue_free()

## The one case a run started with a flag must not be asked again: an arrow key does nothing once
## `ControlsMode.is_forced()` has already answered the question, and the screen falls back to
## exactly the shape it had before this milestone — `ui_accept` still chooses whichever mode the
## flag fixed, and so, unchanged, does a bare touch: a flag-started web build (the deployed page's
## own `?controls=`) still has to be startable by touch, since nothing on it will ever ask.
func _test_the_forced_controls_path_ignores_the_new_inputs(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	title._asking_controls = false
	title._controls_mode = ControlsMode.Mode.TAP
	var chosen: Array = []
	title.start_requested.connect(func(mode: ControlsMode.Mode) -> void: chosen.append(mode))
	title.open()

	title._unhandled_input(_action("ui_left"))
	t.check(chosen.is_empty(), "an arrow key does nothing once a flag has already answered")
	title._unhandled_input(_accept())
	t.check(chosen == [ControlsMode.Mode.TAP],
			"space still starts the mode the flag fixed, unchanged")

	title.close()
	title.queue_free()

## *(2026-09-06, playtest 26 finding 2.)* The hint has to state the new shape rather than the
## dropped `"space or t to choose"`, in both the `_can_quit` and not-`_can_quit` shapes the `·`
## separator already composes — see `_test_the_title_quit_key_matches_the_platform` for why that
## suffix rule itself is unchanged. It no longer mentions clicking: with two visible buttons and no
## pointer fallback, "click the tap button" needs no hint at all.
func _test_the_title_hint_names_the_new_inputs(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	title._can_quit = true
	title.open()
	t.check(title._hint.text == "arrows or space for stick     ·     q to quit",
			"the hint names the keyboard route and keeps q where quitting works ('%s')"
					% title._hint.text)

	title._can_quit = false
	title.open()
	t.check(title._hint.text == "arrows or space for stick",
			"and drops the quit suffix where quitting is impossible ('%s')" % title._hint.text)

	title.close()
	title.queue_free()

## *(2026-09-06, playtest 26 finding 1: "the choice on the title screen is not at all obvious.
## those should be proper buttons".)* `ModeButton` is the reusable control both buttons draw
## themselves through — see its own class comment for why it is not a one-off in this scene — and
## each names a different mode with its own symbol and its own fill colour rather than sharing
## either.
func _test_the_title_buttons_carry_their_own_symbol(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	t.check(title._stick_button is ModeButton, "the stick button draws itself as a ModeButton")
	t.check(title._tap_button is ModeButton, "and so does the tap button")
	t.check((title._stick_button as ModeButton).symbol == ModeButton.Symbol.STICK,
			"the stick button carries the stick symbol")
	t.check((title._tap_button as ModeButton).symbol == ModeButton.Symbol.TAP,
			"and the tap button carries the tap symbol, not the same one")
	t.check((title._stick_button as ModeButton).fill_colour == Palette.MODE_STICK,
			"the stick button fills with Palette.MODE_STICK")
	t.check((title._tap_button as ModeButton).fill_colour == Palette.MODE_TAP,
			"and the tap button fills with Palette.MODE_TAP, a different colour")
	t.check(title._stick_button.flat,
			"flat turns off Godot's own theme, leaving ModeButton's _draw() the whole of its look")

	title.queue_free()

## *(2026-09-06, the player's own visual reference: circular buttons sized for a thumb.)*
## `TouchControls.PAUSE_CATCH_RADIUS` (46px) is the smallest of its three catch radii
## (`STICK_CATCH_RADIUS` 100px, `RUN_CATCH_RADIUS` 76px) — the least generous target a thumb is
## already asked to hit during a run. `ModeButton` is opened on the same phone, so its own minimum
## size must be at least that radius doubled, or the title screen would ask for a more precise
## touch than the game it leads into ever does.
func _test_the_title_buttons_are_sized_for_a_thumb(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	var floor_diameter: float = TouchControls.PAUSE_CATCH_RADIUS * 2.0
	t.check(title._stick_button.custom_minimum_size.x >= floor_diameter
				and title._stick_button.custom_minimum_size.y >= floor_diameter,
			"the stick button is at least as wide and tall as TouchControls' smallest catch target")
	t.check(title._tap_button.custom_minimum_size.x >= floor_diameter
				and title._tap_button.custom_minimum_size.y >= floor_diameter,
			"and so is the tap button")

	title.queue_free()

## *(2026-09-06: "remove the text (or put it under it without it being clickable)".)* The paragraph
## each button used to carry as its own `text` moved out to `_stick_caption`/`_tap_caption` — plain
## `Label`s beside rather than inside either `Button`, see `TitleScreen._stick_caption`'s own doc,
## so neither is a pressable control by construction (a `Label` is statically never a `BaseButton`).
## "Not clickable" is only true if a press actually falls through too, so `mouse_filter` is
## asserted directly rather than trusted from the scene.
func _test_the_title_captions_are_not_clickable(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	t.check(title._stick_caption.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"the stick caption lets a press fall through to whatever is behind it")
	t.check(title._tap_caption.mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"and so does the tap caption")

	title.queue_free()

## The captions carry the exact wording `_refresh_body()` gives a forced mode — see
## `_refresh_choice()`'s own doc for why the two must never say the choice differently depending on
## which path answered it.
func _test_the_title_captions_match_the_body_wording(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)

	title._touch = false
	title._refresh_choice()
	t.check("Arrows or WASD" in title._stick_caption.text,
			"the stick caption names the keys on a keyboard ('%s')" % title._stick_caption.text)
	t.check(title._tap_caption.text.begins_with("Tap to walk there"),
			"and the tap caption keeps its own wording ('%s')" % title._tap_caption.text)

	title._touch = true
	title._refresh_choice()
	t.check("Drag the stick" in title._stick_caption.text,
			"and the stick caption switches to the touch wording when _touch flips ('%s')"
					% title._stick_caption.text)

	title.queue_free()

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
	pause.open()
	t.check(pause._hint.text == "tap to carry on",
			"the touch hint says tap and drops the keys with no touch equivalent ('%s')"
					% pause._hint.text)
	t.check("Drag the stick" in pause._body.text, "and the body names the stick and run button")

	pause.close()
	t.get_tree().paused = false
	pause.queue_free()

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
	t.check("tap to try again" in summary._hint.text,
			"the touch hint says tap ('%s')" % summary._hint.text)

	summary.show_ending(GameEnums.Ending.GOOD)
	t.check(summary._hint.text == "tap to start again",
			"and the ending screen agrees too ('%s')" % summary._hint.text)

	t.get_tree().paused = false
	summary.queue_free()

## **Every screen advances on a tap**, handled as the touch event itself rather than as a
## synthetic mouse click — a phone has no `space`, and nothing before this fired anything for a
## touch at all. Checked on all three screens the game can come to rest on, the same shape
## `_test_space_carries_on_from_every_screen` already checks for the key, and a release is checked
## to do nothing so a finger lifted off the stick elsewhere cannot be read as a dismissal.
##
## The title only keeps this shape once a flag has already answered the controls question
## (`_asking_controls = false` here) — while still asking, a bare touch does nothing at all, see
## `_test_a_pointer_press_away_from_the_buttons_does_nothing()`, because the two buttons are the
## only pointer route to a choice and a stray tap must not silently pick one for a phone.
func _test_a_tap_advances_every_screen(t) -> void:
	var title: TitleScreen = TITLE.instantiate()
	t.add_child(title)
	title._asking_controls = false
	var started := [0]
	title.start_requested.connect(func(_mode: ControlsMode.Mode) -> void: started[0] += 1)
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
	t.check(carried_on[0] == 1, "and a tap goes on from the between-days summary")
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
