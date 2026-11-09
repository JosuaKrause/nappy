@warning_ignore_start("untyped_declaration")
extends RefCounted
## The real-Main lifecycle for the task recipes (`task-*.json`).
## What it checks is `tests/scene_recipe_lifecycle.gd`'s header; split by theme so that no suite
## runs two minutes serial.

const LIFECYCLE := preload("res://tests/scene_recipe_lifecycle.gd")

func run(t) -> void:
	await LIFECYCLE.new().lifecycle(t, LIFECYCLE.PREFIX_TASK)
