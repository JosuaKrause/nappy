class_name FrameLedger
extends RefCounted
## Every frame's time by system, for the last few minutes of play, in preallocated storage — the
## arithmetic half of the per-system frame record, with every timestamp handed in so a test can
## drive a frame without a clock. `FrameRecord` is the switch the game's entry points call;
## `FrameRecorder` is the node that marks the engine's phases and gets the record off the device.
##
## **A frame runs from one frame's first callback to the next one's**, and its time is spent in
## `FrameRecord`'s buckets, one at a time: `switch_to()` charges the time since the last switch to
## the bucket that was running and starts the next. So the buckets of a closed frame add up to
## its length exactly, with whatever no named system claimed left in the phases' own rests.
##
## **A slow frame is one that ran into the next refresh**: longer than one and a half display
## budgets. On a display that waits for the refresh a frame lasts one budget or two, never in
## between, so the half budget of slack keeps the ordinary jitter of a frame that made it from
## being counted, while every frame that missed its refresh is.
##
## Nothing here allocates per frame, prints, or touches the world: a closed frame is copied into
## a ring of `PackedInt64Array` rows, the oldest overwritten once it is full, so the record always
## holds the most recent `capacity` frames of play.

## About five minutes at 60 frames a second.
const CAPACITY := 18000

## Per-frame counters, after the buckets in a row. The scenery jobs are counted by kind as the
## queue ran them; the guard preparations (the synchronous ones a region or item needs before it
## can be seen) are counted apart, whatever their kind.
const PHYSICS_STEPS := 0
const TIMER_CALLS := 1
const SCENERY_UPDATES := 2
const SCENERY_OVER_BUDGET := 3
const JOBS_GROUND := 4
const JOBS_BUILDING := 5
const JOBS_PROP := 6
const JOBS_SHADOW := 7
const JOBS_DECAL := 8
const GUARD_PREPARATIONS := 9
const DRAWN := 10
const DRAW_CALLS := 11
const RENDER_OBJECTS := 12
const PRIMITIVES := 13
const CROWD_AGENTS := 14
const LIVE_EVENTS := 15
const PLAYER_X := 16
const PLAYER_Y := 17
const DAY := 18
const PROCESS_FRAME := 19
const COUNTER_NAMES: Array[String] = ["physics_steps", "timer_calls", "scenery_updates",
	"scenery_over_budget_usec", "jobs_ground", "jobs_building", "jobs_prop", "jobs_shadow",
	"jobs_decal", "guard_preparations", "drawn", "draw_calls", "render_objects", "primitives",
	"crowd_agents", "live_events", "player_x", "player_y", "day", "process_frame"]

## A row: when the frame started, how long it ran, whether it was slow, then one column per
## bucket and one per counter.
const START := 0
const FRAME := 1
const SLOW := 2
const FIRST_BUCKET := 3
const FIRST_COUNTER := FIRST_BUCKET + 9
const WIDTH := FIRST_COUNTER + 20

enum Phase { NONE, IN_FRAME, AFTER_PROCESS, AFTER_DRAW }

var capacity: int
## Frames longer than this are slow.
var slow_after_usec: int
## Frames kept, at most `capacity`.
var count := 0
## Frames kept and then overwritten by newer ones.
var overwritten := 0
## Slow frames among every frame ever kept, overwritten ones included.
var slow_frames := 0
## Whether the open frame is to be kept when it closes. `FrameRecorder` sets it each frame, so a
## paused game, the title and the summary are timed (the phases stay in step) but not kept.
var keep := false
## The last kept slow frame's row, meaningful once `slow_frames` is above zero. Copied into
## place rather than sliced, so a slow frame allocates nothing either.
var last_slow := PackedInt64Array()

var _rows := PackedInt64Array()
var _next := 0
var _spent := PackedInt64Array()
var _counters := PackedInt64Array()
var _current := FrameRecord.PROCESS_REST
var _since := 0
var _frame_start := -1
var _phase := Phase.NONE
var _readout := ""
var _readout_for := -1

func _init(rows: int = CAPACITY, slow_after: int = 25000) -> void:
	capacity = clampi(rows, 1, CAPACITY)
	slow_after_usec = slow_after
	assert(WIDTH == columns().size(), "FrameLedger.WIDTH must match its columns")
	_rows.resize(capacity * WIDTH)
	_spent.resize(FrameRecord.BUCKET_NAMES.size())
	_counters.resize(COUNTER_NAMES.size())
	last_slow.resize(WIDTH)

static func columns() -> Array[String]:
	var names: Array[String] = ["start_usec", "frame_usec", "slow"]
	for bucket in FrameRecord.BUCKET_NAMES:
		names.append(bucket + "_usec")
	names.append_array(COUNTER_NAMES)
	return names

# ------------------------------------------------------------------ the clock ---

## Charges the time since the last switch to the bucket that was running, starts `bucket`, and
## answers the bucket that was running.
func switch_to(bucket: int, now: int) -> int:
	_spent[_current] += now - _since
	_since = now
	var previous := _current
	_current = bucket
	return previous

## `switch_to()`, counted as one timed entry point: how many there were in a frame is what the
## record's own cost scales with.
func enter(bucket: int, now: int) -> int:
	_counters[TIMER_CALLS] += 1
	return switch_to(bucket, now)

func add(counter: int, amount: int) -> void:
	_counters[counter] += amount

func set_counter(counter: int, value: int) -> void:
	_counters[counter] = value

# ----------------------------------------------------------------- the phases ---

## The first physics callback of a step. The first one after the process step begins a frame.
func physics_step(now: int) -> void:
	if _phase != Phase.IN_FRAME:
		_begin_frame(now)
	_counters[PHYSICS_STEPS] += 1
	switch_to(FrameRecord.PHYSICS_REST, now)

## The first process callback. Begins a frame if no physics step did.
func process_start(now: int) -> void:
	if _phase != Phase.IN_FRAME:
		_begin_frame(now)
	switch_to(FrameRecord.PROCESS_REST, now)

## The last process callback: what follows is drawing.
func process_end(now: int) -> void:
	switch_to(FrameRecord.DRAW, now)
	_phase = Phase.AFTER_PROCESS

## The renderer's post-draw callback: what follows is waiting. A headless run draws nothing and
## never calls this, so its whole span after process is `draw`, and its `drawn` column is 0.
func drawn(now: int) -> void:
	if _phase != Phase.AFTER_PROCESS:
		return
	switch_to(FrameRecord.WAIT, now)
	_counters[DRAWN] = 1
	_phase = Phase.AFTER_DRAW

func _begin_frame(now: int) -> void:
	if _frame_start >= 0:
		switch_to(_current, now)
		if keep:
			_keep_frame(now - _frame_start)
	_spent.fill(0)
	_counters.fill(0)
	keep = false
	_frame_start = now
	_since = now
	_phase = Phase.IN_FRAME

func _keep_frame(length: int) -> void:
	var offset := _next * WIDTH
	var slow := length > slow_after_usec
	_rows[offset + START] = _frame_start
	_rows[offset + FRAME] = length
	_rows[offset + SLOW] = 1 if slow else 0
	for i in _spent.size():
		_rows[offset + FIRST_BUCKET + i] = _spent[i]
	for i in _counters.size():
		_rows[offset + FIRST_COUNTER + i] = _counters[i]
	if slow:
		slow_frames += 1
		for i in WIDTH:
			last_slow[i] = _rows[offset + i]
	_next = (_next + 1) % capacity
	if count == capacity:
		overwritten += 1
	else:
		count += 1

# ------------------------------------------------------------------- reading ---

## The kept frames, oldest first, one `PackedInt64Array` row each.
func rows() -> Array[PackedInt64Array]:
	var first := 0 if count < capacity else _next
	var out: Array[PackedInt64Array] = []
	for i in count:
		var offset := ((first + i) % capacity) * WIDTH
		out.append(_rows.slice(offset, offset + WIDTH))
	return out

## A row's `n` largest costs, largest first, as `[bucket name, microseconds]` pairs. `wait` is
## not a cost and is never among them.
static func top_costs(row: PackedInt64Array, n: int = 3) -> Array:
	var costs: Array = []
	for i in FrameRecord.BUCKET_NAMES.size():
		if i != FrameRecord.WAIT:
			costs.append([FrameRecord.BUCKET_NAMES[i], row[FIRST_BUCKET + i]])
	costs.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	return costs.slice(0, n)

## The readout's line: the last slow frame's length and its three largest costs, in ms. Built
## once per slow frame rather than once per frame the readout asks.
func readout_line() -> String:
	if slow_frames == 0:
		return "slow        none yet"
	if _readout_for != slow_frames:
		var parts: Array[String] = []
		for cost: Array in top_costs(last_slow):
			parts.append("%s %.1f" % [cost[0], cost[1] / 1000.0])
		_readout = "slow %5.1f ms  %s" % [last_slow[FRAME] / 1000.0, "  ".join(parts)]
		_readout_for = slow_frames
	return _readout

## The record as one dictionary for a file: the rows, their column names, and a summary that
## answers the question the record exists for — in the slow frames, which system was largest.
func report() -> Dictionary:
	var kept := rows()
	var lengths: Array[int] = []
	var all_spent := PackedInt64Array()
	all_spent.resize(FrameRecord.BUCKET_NAMES.size())
	var slow_spent := all_spent.duplicate()
	var largest := {}
	var slow_kept := 0
	var json_rows: Array = []
	for row in kept:
		json_rows.append(Array(row))
		lengths.append(row[FRAME])
		for i in all_spent.size():
			all_spent[i] += row[FIRST_BUCKET + i]
		if row[SLOW] == 1:
			slow_kept += 1
			for i in slow_spent.size():
				slow_spent[i] += row[FIRST_BUCKET + i]
			var name: String = top_costs(row, 1)[0][0]
			largest[name] = int(largest.get(name, 0)) + 1
	lengths.sort()
	var mean_all := {}
	var mean_slow := {}
	for i in all_spent.size():
		var bucket := FrameRecord.BUCKET_NAMES[i]
		mean_all[bucket] = all_spent[i] / 1000.0 / maxi(1, kept.size())
		mean_slow[bucket] = slow_spent[i] / 1000.0 / maxi(1, slow_kept)
	var summary := {"frames": kept.size(), "slow_frames": slow_kept,
		"slow_after_ms": slow_after_usec / 1000.0,
		"frame_p50_ms": _percentile(lengths, 0.5), "frame_p95_ms": _percentile(lengths, 0.95),
		"frame_p99_ms": _percentile(lengths, 0.99),
		"frame_max_ms": lengths.back() / 1000.0 if not lengths.is_empty() else 0.0,
		"mean_ms_per_frame": mean_all, "mean_ms_per_slow_frame": mean_slow,
		"largest_cost_in_slow_frames": largest}
	return {"capacity": capacity, "retained": kept.size(), "overwritten": overwritten,
		"slow_frames_ever": slow_frames, "columns": columns(), "rows": json_rows,
		"summary": summary}

static func _percentile(sorted: Array[int], fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	return sorted[ceili(sorted.size() * fraction) - 1] / 1000.0
