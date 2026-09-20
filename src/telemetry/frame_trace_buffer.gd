class_name FrameTraceBuffer
extends RefCounted
## Bounded raw callback samples. No clock, world reads, sorting or disk work during capture.
## An interval belongs to its ending callback; both endpoint IDs survive in adjacent rows.

const CAPACITY := 36000
const COLUMNS := ["post_draw_usec", "process_frame", "draw_frame", "interval_usec",
	"physics_frame", "draw_calls", "render_objects", "primitives", "live_events",
	"event_identity_sum", "crowd_agents", "picture_loads", "atlases_collected",
	"nodes", "objects", "orphan_nodes", "player_x_millipx", "player_y_millipx",
	"day", "readout_on", "graph_on", "telemetry_on"]

var count := 0
var dropped := 0
var _capacity: int
var _values := PackedInt64Array()
var _previous_usec := -1

func _init(capacity: int = CAPACITY) -> void:
	_capacity = clampi(capacity, 1, CAPACITY)
	_values.resize(_capacity * COLUMNS.size())

## Pauses and title screens break the interval: resuming must not manufacture a slow frame.
func break_interval() -> void:
	_previous_usec = -1

func append(timestamp_usec: int, process_frame: int, draw_frame: int,
		counters: PackedInt64Array) -> void:
	assert(counters.size() == COLUMNS.size() - 4)
	if count == _capacity:
		dropped += 1
		return
	var offset := count * COLUMNS.size()
	_values[offset] = timestamp_usec
	_values[offset + 1] = process_frame
	_values[offset + 2] = draw_frame
	_values[offset + 3] = timestamp_usec - _previous_usec if _previous_usec >= 0 else 0
	for i in counters.size():
		_values[offset + 4 + i] = counters[i]
	_previous_usec = timestamp_usec
	count += 1

## Called only after capture. Nearest-rank percentiles and strict budget exceedances operate
## on retained positive intervals, excluding the anchor at the start of every segment.
func report(refresh_hz: float) -> Dictionary:
	var rows: Array = []
	var intervals: Array[int] = []
	for i in count:
		var offset := i * COLUMNS.size()
		rows.append(Array(_values.slice(offset, offset + COLUMNS.size())))
		if _values[offset + 3] > 0:
			intervals.append(_values[offset + 3])
	intervals.sort()
	var summary := {"intervals": intervals.size(), "p50_ms": 0.0, "p95_ms": 0.0,
		"p99_ms": 0.0, "max_ms": 0.0, "over_60hz_budget": 0, "over_30hz_budget": 0,
		"over_refresh_budget": 0, "refresh_budget_ms": 1000.0 / refresh_hz if refresh_hz > 0 else 0.0}
	if not intervals.is_empty():
		summary.p50_ms = _percentile(intervals, 0.5)
		summary.p95_ms = _percentile(intervals, 0.95)
		summary.p99_ms = _percentile(intervals, 0.99)
		summary.max_ms = intervals.back() / 1000.0
	for interval in intervals:
		if interval > 1000000.0 / 60.0:
			summary.over_60hz_budget += 1
		if interval > 1000000.0 / 30.0:
			summary.over_30hz_budget += 1
		if refresh_hz > 0 and interval > 1000000.0 / refresh_hz:
			summary.over_refresh_budget += 1
	return {"schema_version": 1, "capacity": _capacity, "retained": count,
		"dropped_after_capacity": dropped, "columns": COLUMNS, "samples": rows,
		"summary": summary}

func _percentile(sorted: Array[int], fraction: float) -> float:
	return sorted[ceili(sorted.size() * fraction) - 1] / 1000.0
