extends Telemetry
## **A run log for a suite that reads what was logged**: the note surface `RunSession`, the
## `TelemetryObserver` and every trace over its `note` write through, kept as a list of lines and
## written nowhere. A helper, not a suite: the runner loads only `test_*.gd`.
##
## What a note says, and when, is the writer's; how a line is laid out on disk, and the folders and
## pictures a run writes, are the real log's own, which `tests/test_telemetry.gd` tests against a
## scratch folder of its own. So this keeps a note as `"<clock> <kind> <text>"`, the clock to one
## decimal, and each section the run log heads as a line naming the call and its arguments, and it
## writes no file, folder or picture. A `TelemetryObserver` is typed against the run log and
## `main.use_run_log()` takes one, which is why this extends it rather than standing alone.
##
## **It is dormant until `begin_run()`, and its clock moves only inside a section**, as the real
## log's do: a note while no run is open is dropped, a section opens the clock at zero, and the
## clock stops when the section ends. The suite that makes one frees it.

## Every line kept since the log was made, in order.
var lines: Array[String] = []

var _open := false
var _section_open := false
var _now := 0.0

## A log keeping its lines in `into`, which a suite reading lines from more than one writer shares;
## none keeps them in `lines`.
func _init(into: Array[String] = []) -> void:
	lines = into

## Overrides Telemetry.begin_run.
func begin_run(_run_seed: int, _played := true) -> void:
	end_run()
	_open = true
	_now = 0.0

## Overrides Telemetry.end_run.
func end_run() -> void:
	_bursts.cancel("run ended")
	_open = false
	_section_open = false

## Overrides Telemetry.is_active.
func is_active() -> bool:
	return _open

## Overrides Telemetry.begin_day.
func begin_day(day: int, act: int, run_seed: int, city_seed: int, length: float) -> void:
	_open_a_section("begin_day %d %d %d %d %.1f" % [day, act, run_seed, city_seed, length])

## Overrides Telemetry.begin_section.
func begin_section(day: int, title: String, run_seed: int, length: float) -> void:
	_open_a_section("begin_section %d %s %d %.1f" % [day, title, run_seed, length])

func _open_a_section(line: String) -> void:
	if not _open:
		return
	_now = 0.0
	_section_open = true
	lines.append(line)

## Overrides Telemetry.end_day.
func end_day() -> void:
	_bursts.cancel("day ended")
	_section_open = false

## Overrides Telemetry.note.
func note(kind: String, text: String) -> void:
	if _open:
		lines.append("%.1f %s %s" % [_now, kind, text])

## Overrides Telemetry.set_clock.
func set_clock(seconds: float) -> void:
	if _section_open:
		_now = seconds

## Overrides Telemetry.restart_section_clock.
func restart_section_clock() -> void:
	if _section_open:
		_now = 0.0

## Overrides Telemetry.clock.
func clock() -> float:
	return _now

## The person's picture is the real log's to take; what is noted is the line beside it.
## Overrides Telemetry.snapshot_now.
func snapshot_now(context: String) -> void:
	note("shot", context)

## Overrides Telemetry.snapshot.
func snapshot(_kind: String) -> void:
	pass

## Overrides Telemetry.write_map.
func write_map(_map: CityMap, _day: int, _closures: Array[RoadClosure] = [],
		_tree: RouteTree = null, _plans: Array[EventScheduler.Planned] = [],
		_at_dusk := false, _trail: Array[Vector3] = [], _met: Dictionary = {},
		_corridor := true) -> void:
	pass
