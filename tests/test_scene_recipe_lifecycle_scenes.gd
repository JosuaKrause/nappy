@warning_ignore_start("untyped_declaration")
extends RefCounted
## The real-Main lifecycle for the other recipes (the fire truck, the power station, the station door corner, the tear slide) and the later-day power station hall.
## What it checks is `tests/scene_recipe_lifecycle.gd`'s header; split by theme so that no suite
## runs two minutes serial.

const LIFECYCLE := preload("res://tests/scene_recipe_lifecycle.gd")

func run(t) -> void:
	await LIFECYCLE.new().lifecycle(t, LIFECYCLE.PREFIX_OTHER)
