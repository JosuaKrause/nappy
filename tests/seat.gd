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
## **Freeing a seat gives back what the observers held before it.** A booted `main` hands the run to
## the observers (`VisitCounter.configure()`), which keep it after `main` is gone; `end()` frees the
## home and puts the observers back (`tests/booted_main.gd`), so none holds a run that is over.

const Boot := preload("res://tests/booted_main.gd")

var run: RunState
var home: Node
var sitting: Sitting
## What the observers held before this seat, put back by `end()`.
var observers := Boot.hold_observers()

## `prepare`, when given, is called with the unplayed run (a run to be played from a later day).
func _init(t, prepare := Callable()) -> void:
	run = RunState.new()
	if prepare.is_valid():
		prepare.call(run)
	home = Boot.home_playing(t, run)
	sitting = home.get_node(NodePath(Sitting.NODE_NAME)) as Sitting

## The real `main.tscn` booted over this seat under `words`, a save at `scratch_path` handed to it
## (no boot reaches the player's own save). The caller frees the boot (`Booted.free_all()`) before
## `end()`.
func boot(t, scratch_path: String, words: Array) -> Boot.Booted:
	var seat := self
	return await Boot.boot(t, scratch_path, Boot.config(words),
			func(unbooted: Node) -> void: unbooted.use_sitting_home(seat.home))

func end() -> void:
	home.free()
	Boot.give_back_observers(observers)
