class_name AtlasPhaseTrace
extends RefCounted
## Opt-in CPU spans for atlas work, collected on the main thread and exported after play.
## Worker spans arrive only after their task is joined. No GPU completion is measured here.

const CAPACITY := 4096
static var enabled := false
static var _rows: Array = []
static var _dropped := 0

static func reset(active: bool) -> void:
	enabled = active
	_rows.clear()
	_dropped = 0

static func record(group: String, phase: String, start_usec: int, end_usec: int,
		on_main_thread := true, process_frame := -1) -> void:
	if not enabled:
		return
	if _rows.size() >= CAPACITY:
		_dropped += 1
		return
	_rows.append([group, phase, start_usec, end_usec, on_main_thread,
		Engine.get_process_frames() if on_main_thread and process_frame < 0 else process_frame])

static func report() -> Dictionary:
	return {"capacity": CAPACITY, "dropped_after_capacity": _dropped,
		"columns": ["group", "phase", "start_usec", "end_usec", "on_main_thread",
			"process_frame"], "spans": _rows.duplicate(true),
		"clock": "Time.get_ticks_usec", "gpu_completion_measured": false}
