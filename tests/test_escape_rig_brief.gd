extends RefCounted
## M204, `--start-escape` with a capture rig's flag: the escape's building brief is pressed for a
## rig that is not a `--route` walker, so a bare `--walk` is not held behind a brief that nobody
## answers (a still taken that way showed the brief over a motionless game). Driven through the real
## `main.tscn` (`tests/booted_main.gd`), booted as `--start-escape --walk north` is.

const Boot := preload("res://tests/booted_main.gd")
const UI := preload("res://tests/ui_screens.gd")
const _SCRATCH_SAVE := "user://test_escape_rig_brief_scratch.json"

func run(t) -> void:
	var booted: Boot.Booted = await Boot.boot(t, _SCRATCH_SAVE,
			Boot.config(["--start-escape", "--walk", "north"]))
	for i in 4:
		await UI.frames(t)
	var screen := Boot.summary(booted.main)
	t.check(screen != null and not screen.is_showing(),
			"the escape's brief has been pressed for the rig, not left standing")
	t.check(not booted.main.get_tree().paused, "so the tree is running behind it")
	t.check(Boot.interior(booted.main) != null, "in the building")
	Input.action_release("move_up")
	booted.free_all()
