class_name Sitting
extends Node
## What one sitting at the game keeps across the scene reloads a run makes: the held restart,
## the day-14 hand-over to the escape, a normal run carried on to its checkpoint and a free
## recipe's lost section played again (`main._reload_the_scene()` is the one place any of them
## happens). `reload_current_scene()` frees `main` and every node under it, so nothing a boot
## builds can hold a fact the next boot needs; this node is the one owner of those facts, and of
## nothing else. Process memory only, never saved itself: a page opened again starts a sitting
## with none of it, and only the run comes back, from the save its first boot reads
## (`GameSave.try_resume()`).
##
## **Not an autoload**, and nothing fetches it. `main`, the composition root, takes the one the
## boot before it parked at the tree's root, or builds one as its own child on the sitting's first
## boot, and hands it to whoever needs it through their setup: the title (`TitleScreen.use_sitting()`,
## the restart guard), the frame recorder (`FrameRecorder.setup()`, its one file) and the save
## symbol (`SaveIndicator.outlive_the_scene()` and `carried()`, its home). Before every reload
## `main` parks it at the tree's root, which a reload leaves alone. A test hands its boots a node of
## its own to stand for the root (`main.use_sitting_home()`), so the boot that stands for the
## reload takes the sitting the one before parked there, rather than the test setting and
## resetting statics.
##
## **It holds the run** (a `RunState`), which `main` takes off it once a boot (`take_the_run()`)
## and hands down: the day-14 hand-over and a run carried to its checkpoint keep it across their
## reloads, and a held restart hands it a fresh run (`main._restart_run()`, through `use_run()`),
## which the boot after starts (`RunState.start_run()`). A test hands a sitting the run it built
## (`use_run()`) before handing the sitting on.
##
## **It is the home of the save too** (`GameSave`, a child node `main` makes on the first boot and
## finds there after): the web flush's page-side objects, the operation ids and the file's path
## outlive the reload that frees `main`. It names no save, for the reason it names no symbol.
## The run log (`Telemetry`) and the page counter (`VisitCounter`) are children of it the same way,
## so the log a run is writing and the counter's count of the run outlive the reload too; it names
## neither.
##
## **It is the home of a save symbol that outlives its scene**: `SaveIndicator.outlive_the_scene()`
## reparents a symbol that is up under this node, and the next boot's `SaveIndicator.carried()`
## finds it here. It names no symbol itself, since it sits below the view that draws one.

## The name `main` gives it, and what the next boot looks for on the tree's root.
const NODE_NAME := "Sitting"

## The run this sitting plays (`RunState`): the seed, the calendar, the nerves and the
## resistance's progress. `main` takes it once a boot (`take_the_run()`) and hands it to every
## reader it builds, so it outlives each reload exactly as long as the sitting does. Null until
## handed one (`use_run()`) or asked for one.
var _run: RunState

## Set by `main` just before a reload that carries a normal run on from its checkpoint
## (`mark_the_run_carried_over()`, from `main._carry_the_run_into_the_next_boot()`), and asked
## (`carries_the_run_over()`) and spent (`spend_the_carry()`) by the boot that follows, which
## then puts the run back from memory rather than reading the save.
var _carry_the_run_over := false

## The title's last answer this sitting, in the words `--controls` takes (`"tap"`,
## `"joystick-left"`, `"joystick-right"`; `ControlsMode.word_for()` writes one and
## `ControlsMode.from_word()` and `side_from_word()` read it), or `""` before any title answered.
## The two boots that open no title of their own, the hand-over to the escape and a run carried
## on from its checkpoint, take it instead of the configured word *(2026-10-10, the player:
## "permanently for the sitting")*. Every other boot's title asks again.
var _controls_word := ""

## The instant `main._restart_run()` last asked for a scene reload, or `-INF` before the first one
## this sitting. The title's restart guard measures a press against it, so a stray press crossing
## the reload does not start a run — see `TitleScreen._begin()`.
var _restarted_at_msec := -INF

## Where a desktop frame record is written, chosen by the first recorder to save one this sitting
## and kept, so every scene exit rewrites the same file and a restart does not start a second.
## `""` until then.
var _frame_record_path := ""

## Where the desktop frame record is written, `""` until the first save.
func frame_record_file() -> String:
	return _frame_record_path

## Keeps `path` as where the desktop frame record is written, for every scene exit after this one.
func keep_frame_record_file(path: String) -> void:
	_frame_record_path = path

## The instant the held restart's reload was last asked for, `-INF` before the first.
func restart_requested_at_msec() -> float:
	return _restarted_at_msec

## The frame record's timing: the null sink or the `FrameRecord` `use_frame_timing()` handed in.
func kept_frame_timing() -> FrameTiming:
	return _frame_timing

## Where the frame record is kept, handed to every system that is timed: the null sink until `main`
## replaces it with a `FrameRecord` for a run that asks for one (`--frame-record`, `?framerecord=1`).
## The record and its ledger live here so a recording spans a scene reload, as the path above does.
var _frame_timing := FrameTiming.new()

## Hands the sitting the frame record `timing` to keep, as `main` does for a run that asks for one.
func use_frame_timing(timing: FrameTiming) -> void:
	_frame_timing = timing

## The ground's composition recipe, read from disk by the first city built this sitting and held
## here after, so a reload and every day's repaint compose from the same read (`GroundRecipe`).
## Not a fact a reload carries about the run, but one per process, and this node outlives the
## reload that frees `main`.
var _ground_recipe := GroundRecipe.new()

## The ground's composition recipe this sitting holds, which `main` hands to every city it builds.
func ground_recipe() -> GroundRecipe:
	return _ground_recipe

## The baked atlas pages and which of them are held (`AtlasLibrary`): one library per process,
## held here so the pages a boot holds for the process, and the loading moments it claimed, outlive
## the reload that frees `main`, and a held restart reads no page from disk again. `main` hands it
## to everything that acquires a group or draws a region.
var _atlas := AtlasLibrary.new()

## The baked atlas pages this sitting holds, which `main` hands to everything that draws.
func atlas() -> AtlasLibrary:
	return _atlas

## Hands the sitting the library to hold in place of its own: the game keeps the one it makes, and
## a test hands in a recording one to see who asks it for a page.
func use_atlas(library: AtlasLibrary) -> void:
	_atlas = library

## The run this sitting plays: the one it holds, or, when it holds none yet (a sitting's first
## boot), a fresh one of its own, held so it is parked across every reload with the sitting. Its
## seed is not yet chosen: the boot that takes it starts it (`RunState.start_run()`) or puts a
## saved one back.
func take_the_run() -> RunState:
	if not _run:
		_run = RunState.new()
	return _run

## Hands the sitting `run` to hold from now on: a held restart's fresh run (`main._restart_run()`),
## which the boot after the reload starts, or the run a test built.
func use_run(run: RunState) -> void:
	_run = run

## Marks the run as carried on from its checkpoint into the next boot, which then puts it back from
## memory rather than reading the save (`main._carry_the_run_into_the_next_boot()`).
func mark_the_run_carried_over() -> void:
	_carry_the_run_over = true

## Whether the boot before this one carried the run on from its checkpoint and the carry is not
## spent yet.
func carries_the_run_over() -> bool:
	return _carry_the_run_over

## Spends the carry: the boot that took the run from memory has it, and the boot after reads the
## save again.
func spend_the_carry() -> void:
	_carry_the_run_over = false

## The title's last answer this sitting, in the words `--controls` takes, or `""` before any title
## answered.
func controls_word() -> String:
	return _controls_word

## Keeps `word` as the title's answer for the boots that open no title of their own.
func keep_controls_word(word: String) -> void:
	_controls_word = word

## Stamps the held restart's reload — see `_restarted_at_msec`.
func note_restart_requested() -> void:
	_restarted_at_msec = Time.get_ticks_msec()
