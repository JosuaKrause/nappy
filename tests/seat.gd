extends RefCounted
## **What one test plays**: a `RunState` made fresh for it and the sitting that holds it, parked in a
## node of the test's own standing for the tree's root (`Boot.home_playing()`). A boot taken with
## `boot()` takes that sitting, so the game plays the run the test made and hands it down, and the
## sitting's library is the one every boot over this seat builds on and outlives each of them.
## A helper, not a suite: the runner loads only `test_*.gd`.
##
## The suites that boot `main` over a run of their own share it (`test_main.gd`,
## `test_boot_handing.gd`, `test_atlas_loading.gd`), so none holds a copy.
##
## **Freeing a seat frees the observers its boots handed the run to.** A booted `main` keeps the
## run log and the page counter under the sitting (`tests/booted_main.gd`), so `end()`, which frees
## the home, frees them with it.

const Boot := preload("res://tests/booted_main.gd")

var run: RunState
var home: Node
var sitting: Sitting

## `prepare`, when given, is called with the unplayed run (a run to be played from a later day).
func _init(t, prepare := Callable()) -> void:
	run = RunState.new()
	if prepare.is_valid():
		prepare.call(run)
	home = Boot.home_playing(t, run)
	sitting = home.get_node(NodePath(Sitting.NODE_NAME)) as Sitting

## The real `main.tscn` booted over this seat under `words`, a save at `scratch_path` handed to it
## (no boot reaches the player's own save), and `run_log` when given (`main.use_run_log()`), which
## the caller frees; without one the boot writes the sitting's own. The caller frees the boot
## (`Booted.free_all()`) before `end()`.
func boot(t, scratch_path: String, words: Array, run_log: Telemetry = null) -> Boot.Booted:
	var seat := self
	return await Boot.boot(t, scratch_path, Boot.config(words),
			func(unbooted: Node) -> void:
				unbooted.use_sitting_home(seat.home)
				if run_log:
					unbooted.use_run_log(run_log))

func end() -> void:
	home.free()
