class_name Sitting
extends Node
## What one sitting at the game keeps across the scene reloads a run makes: the held restart, the
## day-14 hand-over to the escape, a normal run carried on to its checkpoint and a free recipe's
## lost section played again (`main._reload_the_scene()` is the one place any of them happens).
## `reload_current_scene()` frees `main` and every node under it, so nothing a boot builds can
## hold a fact the next boot needs; this node is the one owner of those facts, and of nothing
## else. Process memory only, never saved: a page opened again starts a sitting with none of it.
##
## **Not an autoload**, and nothing fetches it. `main`, the composition root, takes the one the
## boot before it parked at the tree's root, or builds one as its own child on the sitting's first
## boot, and hands it to whoever needs it through their setup: the title (`TitleScreen.use_sitting()`,
## the restart guard), the frame recorder (`FrameRecorder.setup()`, its one file) and the save
## symbol (`SaveIndicator.outlive_the_scene()` and `carried()`, its home). Before every reload
## `main` parks it at the tree's root, which a reload leaves alone. A test hands its boots a node of
## its own to stand for the root (`main.use_sitting_home()`), so the boot that stands for the
## reload takes the sitting the one before parked there, rather than the test setting and
## resetting statics; a test driving a `main` off the tree hands it one (`main.use_sitting()`).
##
## **It is the home of the save too** (`GameSave`, a child node `main` makes on the first boot and
## finds there after): the web flush's page-side objects, the operation ids and the file's path
## outlive the reload that frees `main`. It names no save, for the reason it names no symbol.
##
## **It is the home of a save symbol that outlives its scene**: `SaveIndicator.outlive_the_scene()`
## reparents a symbol that is up under this node, and the next boot's `SaveIndicator.carried()`
## finds it here. It names no symbol itself, since it sits below the view that draws one.

## The name `main` gives it, and what the next boot looks for on the tree's root.
const NODE_NAME := "Sitting"

## Set by `main` just before a reload that carries a normal run on from its checkpoint, and read
## and cleared by the boot that follows, which then puts the run back from memory rather than
## reading the save (`main._carry_the_run_into_the_next_boot()`).
var carry_the_run_over := false

## The title's last answer this sitting, in the words `--controls` takes (`"tap"`,
## `"joystick-left"`, `"joystick-right"`; `ControlsMode.word_for()` writes one and
## `ControlsMode.from_word()` and `side_from_word()` read it), or `""` before any title answered.
## The two boots that open no title of their own, the hand-over to the escape and a run carried
## on from its checkpoint, take it instead of the configured word *(2026-10-10, the player:
## "permanently for the sitting")*. Every other boot's title asks again.
var controls_word := ""

## The instant `main._restart_run()` last asked for a scene reload, or `-INF` before the first one
## this sitting. The title's restart guard measures a press against it, so a stray press crossing
## the reload does not start a run — see `TitleScreen._begin()`.
var restarted_at_msec := -INF

## Where a desktop frame record is written, chosen by the first recorder to save one this sitting
## and kept, so every scene exit rewrites the same file and a restart does not start a second.
## `""` until then.
var frame_record_path := ""

## The ground's composition recipe, read from disk by the first city built this sitting and held
## here after, so a reload and every day's repaint compose from the same read (`GroundRecipe`).
## Not a fact a reload carries about the run, but one per process, and this node outlives the
## reload that frees `main`.
var ground_recipe := GroundRecipe.new()

## Stamps the held restart's reload — see `restarted_at_msec`.
func note_restart_requested() -> void:
	restarted_at_msec = Time.get_ticks_msec()
