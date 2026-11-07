extends RefCounted
## Boot cost and memory of the real `scenes/main.tscn`, one boot per process, written to compare
## revisions (the parent of the nearby-scenery loading, the merge that brought it, today's main):
## it uses nothing newer than the scene and the tree, so the same file runs in each checkout.
## Headless, so it holds the CPU side only: no draw, no GPU memory, no frame tails.
##
## Run `tools/test.sh probes/scenery_startup.gd --no-save`; the flag is required, since an old
## revision's `main` takes the save it finds. Prints one `SCENERY_STARTUP {json}` line.

const BOOT_FRAMES := 30

func run(t) -> void:
	if not "--no-save" in OS.get_cmdline_user_args():
		t.check(false, "the probe is run with --no-save")
		return
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = scene.instantiate()
	var memory_before := OS.get_static_memory_usage()
	var started := Time.get_ticks_usec()
	t.add_child(main)
	var synchronous := Time.get_ticks_usec() - started
	var frames := 0
	while frames < BOOT_FRAMES:
		await t.get_tree().process_frame
		frames += 1
		if main.get_node_or_null("BootCamera") == null:
			break
	var booted := Time.get_ticks_usec() - started
	var memory_after := OS.get_static_memory_usage()
	# What the booted city holds: the nodes and objects it left in the tree.
	print("SCENERY_STARTUP " + JSON.stringify({
		"engine": Engine.get_version_info().string,
		"processor": OS.get_processor_name(),
		"synchronous_ready_usec": synchronous,
		"boot_usec": booted,
		"frames_waited": frames,
		"static_memory_before": memory_before,
		"static_memory_after": memory_after,
		"static_memory_delta": memory_after - memory_before,
		"peak_static_memory": OS.get_static_memory_peak_usage(),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resource_count": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
	}))
	t.get_tree().paused = false
	main.free()
