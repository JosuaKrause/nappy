class_name BriefPresser
extends RefCounted
## What a dev rig's scripted input (`RouteRig`, `BuildingWalker`) does when the run flow raises an
## escape section's brief (`RunFlow.brief_opened`): answers it with the continue a tap and a key both
## end in (`main._on_summary_continued()`, which takes the `RunFlow.Mode` the screen was raised in),
## the way a person would. A key cannot be sent as an input event: a rig run has every real binding
## erased (`RigLock`). Configured with the sections it answers, so the two rigs share this one press.
## A day's brief (`Section.NONE`) is never answered, and neither is the retry brief of a section
## already pressed once: a loss stops the rig there and the retry is a person's.

var _sections: Array
var _continue: Callable
## The sections whose first brief has been pressed.
var _pressed: Dictionary = {}

## `sections` are the escape sections whose first brief this presses.
func _init(sections: Array) -> void:
	_sections = sections

## What a continue on a screen does, handed by `main`.
func use_continue(continue_from: Callable) -> void:
	_continue = continue_from

## Answers the brief `spec` raised, one frame after the flow opens it, since `main` shows the screen
## right after and a frame signal ticks while the tree is paused behind it. `tree` times the frame.
func press(tree: SceneTree, spec: DaySpec) -> void:
	if not _sections.has(spec.section) or _continue.is_null() or _pressed.has(spec.section):
		return
	_pressed[spec.section] = true
	await tree.process_frame
	_continue.call(RunFlow.Mode.BRIEF)
