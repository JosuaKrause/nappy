extends RefCounted
## **What the suites that boot the real `scenes/main.tscn` share**: the boot, waited on with real
## frames until the game shows her in her world, and the parts of the booted game found by the names
## and classes `main` gives them, so a suite reads no member of `main` itself. A helper, not a suite:
## the runner loads only `test_*.gd`.
##
## **Why the scene tree rather than queries on `main`.** `main` is the composition root: it hands
## every observer, the route rig and the scene recipes what each needs, and no game class reads
## anything back off it, so a query there, or a ready signal, would be heard by tests alone, which
## is not a seam. What `main` builds is in the tree under the names it gives (`City`, `Interior`,
## `Day`, `Resistance`, the stroller's `Stroller` and her `Baby`, the screens' own scene roots),
## which is what a suite finds here; the screens are pressed through the viewport as a player
## presses them (`tests/ui_screens.gd`).
##
## **When a boot has finished** is read off the tree as well: she is built after the canvas warm-up
## the boot holds for (`main._warm_the_canvas_shaders()`, two drawn frames, none for a scene
## recipe), and everything after her is built in the same frame, so once a frame has passed with
## her standing in a world the boot has finished, whichever path it took. No frame count is assumed.
##
## **No boot reaches the player's save.** `boot()` hands every `main` a save at a scratch path
## (`main.use_save()`), whatever configuration it boots under.

const UI := preload("res://tests/ui_screens.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const DaySummaryScript := preload("res://src/ui/day_summary.gd")

## How many real frames a boot may take before a suite stops waiting: the canvas warm-up holds a
## boot for two, so this is many times what any boot needs, and only a boot that never finishes
## (an authored scene that did not stand) reaches it.
const BOOT_FRAMES := 30

## A booted `main` and the scratch save it was handed. `free_all()` frees both and removes the
## scratch file.
class Booted:
	var main: Node2D
	var save: GameSave
	var path := ""

	func free_all() -> void:
		var tree := main.get_tree() if main.is_inside_tree() else null
		if tree:
			tree.paused = false
		main.free()
		save.free()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## The real `main.tscn`, handed `config` (none: the process's own) and a save at `scratch_path`,
## put under `t` and waited on, real frames passing, until she stands in a world (see this file's
## doc). `before` is called with the unbooted `main` before it enters the tree, for whatever else
## the suite hands it (`use_reload()`, `use_sitting_home()`). A boot that has not finished within
## `BOOT_FRAMES` fails `t`'s check and is returned as it stands.
static func boot(t, scratch_path: String, config: RunConfig = null,
		before := Callable()) -> Booted:
	var booted := Booted.new()
	booted.path = scratch_path
	booted.save = GameSave.new(scratch_path)
	booted.main = MAIN_SCENE.instantiate()
	booted.main.use_save(booted.save)
	if config:
		booted.main.configure(config)
	if before.is_valid():
		before.call(booted.main)
	t.add_child(booted.main)
	await until_booted(t, booted.main)
	return booted

## Lets real frames pass until `main`'s boot has finished: a frame has passed with her in a world.
## Fails `t`'s check after `BOOT_FRAMES`.
static func until_booted(t, main: Node) -> void:
	var frames := 0
	while frames < BOOT_FRAMES:
		await t.get_tree().process_frame
		frames += 1
		if player(main) != null:
			return
	t.check(false, "the boot finished within %d frames" % BOOT_FRAMES)

## A debug build's configuration from command-line `words`, unsaved and uncounted.
static func config(words: Array) -> RunConfig:
	var given := PackedStringArray(["--no-save", "--no-telemetry"])
	given.append_array(PackedStringArray(words))
	return RunConfig.parse(given, "", true)

# ------------------------------------------------------------------- the booted game ---

## The city she walks, or null before there is one (the escape's building).
static func city(main: Node) -> City:
	return main.get_node_or_null("City") as City

## The escape's building, or null on a boot that built none.
static func interior(main: Node) -> InteriorScene:
	return main.get_node_or_null("Interior") as InteriorScene

## The day's clock.
static func day(main: Node) -> DayController:
	return main.get_node_or_null("Day") as DayController

## The resistance, or null in the escape.
static func resistance(main: Node) -> ResistanceDirector:
	return main.get_node_or_null("Resistance") as ResistanceDirector

## Her, in whichever world she stands: on its entities layer, the node both worlds name `Entities`
## (`WorldMap.add_entity()`), read by path since a suite asks every tick.
static func player(main: Node) -> Stroller:
	for world_name in ["City", "Interior"]:
		var her := main.get_node_or_null(world_name + "/Entities/Stroller") as Stroller
		if her:
			return her
	return null

## The baby she carries.
static func baby(main: Node) -> Baby:
	var her := player(main)
	return her.get_node("Baby") as Baby if her else null

static func summary(main: Node) -> DaySummaryScript:
	return main.get_node_or_null("DaySummary") as DaySummaryScript

static func title(main: Node) -> TitleScreen:
	return main.get_node_or_null("TitleScreen") as TitleScreen

static func pause(main: Node) -> PauseScreen:
	return main.get_node_or_null("PauseScreen") as PauseScreen

static func hud(main: Node) -> CanvasLayer:
	return main.get_node_or_null("Hud") as CanvasLayer

## The on-screen controls, on the layer `main` builds for them.
static func touch_controls(main: Node) -> TouchControls:
	return main.find_child("TouchControls", true, false).find_child("TouchControls", false, false) \
			as TouchControls

# ------------------------------------------------------------------------ pressing ---

## A press on the title's button `button_name` ("Left", "Tap", "Right"), pushed through the
## viewport where the layout draws it, with the frames the tap's acknowledgement takes.
static func press_title(t, main: Node, button_name := "Tap") -> void:
	var screen := title(main)
	await UI.frames(t)
	UI.push(screen, UI.touch_at(UI.centre(UI.button(screen, button_name)), true))
	await UI.frames(t)

## A press on the summary's continue button (a brief, a day's end, an outcome screen), the way the
## title's is pressed.
static func press_continue(t, main: Node) -> void:
	var screen := summary(main)
	await UI.frames(t)
	UI.push(screen, UI.touch_at(UI.centre(UI.button(screen, "Continue")), true))
	await UI.frames(t)
