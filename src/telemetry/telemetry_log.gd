class_name TelemetryLog
extends RefCounted
## One run's log: an ordered list of lines, and the file they are written to.
##
## The shape is a chronological log, not a metrics dump — what happened and *in what order*,
## reconstructable by a human reading top to bottom with no tool. An aggregate can always be
## computed from an ordered log; the order can never be recovered from an aggregate, which is
## why nothing here counts anything. See docs/TELEMETRY.md.
##
## Every line is flushed as it is written. A run that ends in a crash, an Esc, or a closed
## window is exactly the run worth reading, and a buffered log of it would be empty.

## Timestamp in six columns, then the entry kind in eight, so the third column starts in the
## same place on every line and the log can be read down a column. Godot's `%` has no dynamic
## width, so the widths live here as a format string rather than as two constants.
const _LINE_FORMAT := "%6.1f  %-8s %s"

## Every line written this run, in order. Kept in memory as well as on disk so a test can
## assert on the log without a file, and so `lines_since()` can answer questions cheaply.
var lines: Array[String] = []
## Where it is being written, or "" for an in-memory log.
var path := ""

var _file: FileAccess

## `to_path` of "" keeps the log in memory only. That is what the tests use, and it is also
## the honest fallback when the user directory cannot be written to: losing the trace is
## never a reason to interrupt somebody's run.
func _init(to_path: String = "") -> void:
	if to_path == "":
		return
	_file = FileAccess.open(to_path, FileAccess.WRITE)
	if not _file:
		push_warning("telemetry: cannot write %s (%d)" % [to_path, FileAccess.get_open_error()])
		return
	path = to_path

## A line with no timestamp: the run preamble and each day's header. Blank `text` writes a
## blank line, which is the only separator the format has.
func header(text: String) -> void:
	_write(text)

## One thing that happened, at `at` seconds into the day.
##
## `kind` is the column a reader scans down — keep it short, lower case, and reuse the ones
## already in docs/TELEMETRY.md rather than inventing a synonym.
func note(at: float, kind: String, text: String) -> void:
	_write(_LINE_FORMAT % [at, kind, text])

func close() -> void:
	if _file:
		_file.close()
		_file = null

func _write(line: String) -> void:
	lines.append(line)
	if not _file:
		return
	_file.store_line(line)
	_file.flush()

# ------------------------------------------------------------------ formatting ---
# Shared by every writer, so a tile reads the same whichever system logged it.

static func tile(at: Vector2i) -> String:
	return "(%d,%d)" % [at.x, at.y]

## Which way something is pointing, in words. +y is south: the city is drawn from above.
static func compass(direction: Vector2) -> String:
	if direction.length_squared() < 0.0001:
		return "nowhere"
	if absf(direction.x) > absf(direction.y):
		return "east" if direction.x > 0.0 else "west"
	return "south" if direction.y > 0.0 else "north"

static func purpose(which: GameEnums.BlockPurpose) -> String:
	return GameEnums.BlockPurpose.keys()[which].to_lower()
