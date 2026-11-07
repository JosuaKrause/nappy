extends RefCounted
## **What the run log says about the atlas pages while a test watches**: which pages were read from
## disk, in which loading moment, and which were dropped again. A helper, not a suite: the runner
## loads only `test_*.gd`.
##
## `AtlasLibrary.acquire()` writes one `texture` line when it reads a page from disk ("atlas page
## '<group>' loaded in the <moment>: ...") and `release()` one when the last reference drops it
## ("atlas page '<group>' released after ..."), per page and never per call: an acquire of a page
## already held reads nothing and writes nothing, and a release above the last frees nothing and
## writes nothing (`docs/TELEMETRY.md`, the `texture` kind). So a page's lines are its life as a
## reader of the log sees it, and what the atlas suites assert about a library's load and release
## discipline is asked of them: a consumer that took a page and never gave it back leaves no
## release line once it is freed, and two consumers sharing one page show one load and, only after
## the last of them is gone, one release.
##
## **Why the log and not the library's own counts**: nothing in the game reads a library's counts
## back, so a test that read them would be reading bookkeeping only it asks about (curly-rabbit
## #1095); the log is what the game itself writes for a reader. The lines name no library, so a test
## watches one library at a time: a library of its own, or the sitting's on a boot, which every node
## the boot builds draws from (`tests/test_atlas_loading.gd`).
##
## Making one points the library it watches at a recording trace of its own
## (`AtlasLibrary.trace_note`, a `RunTrace.recording()`'s `note`), so only the lines written from then
## on are read. A boot over the library's sitting points the library at the boot's own run log, so a
## suite that watches a boot hands it `boot_log()`, a recording fake (`tests/recording_log.gd`) that
## keeps its lines in the same list. `stop()` lets the library go and frees that log, which a test
## owes before it ends.

const RecordingLog := preload("res://tests/recording_log.gd")

var _lines: Array[String] = []
## Held here, since the library's `trace_note` is only a `Callable` over it.
var _trace := RunTrace.recording(_lines)
var _atlas: AtlasLibrary
var _boot_log: Telemetry

## Starts watching `atlas`.
func _init(atlas: AtlasLibrary) -> void:
	_atlas = atlas
	atlas.trace_note = _trace.note

## The run log to hand a boot over the watched library's sitting (`main.use_run_log()`): open, and
## keeping what the boot's trace writes beside the library's own lines.
func boot_log() -> Telemetry:
	if _boot_log == null:
		_boot_log = RecordingLog.new(_lines)
		_boot_log.begin_run(0)
	return _boot_log

## Stops the library writing here, and frees the boot's log if one was handed out.
func stop() -> void:
	_atlas.trace_note = Callable()
	if _boot_log:
		_boot_log.free()

## How many times `group`'s page has been read from disk since the watch began.
func loads(group: StringName) -> int:
	return _lines_about(group, " loaded in the ").size()

## How many times the last reference on `group` has dropped its page since the watch began.
func releases(group: StringName) -> int:
	return _lines_about(group, " released after ").size()

## Whether `group`'s page is held now, for a library that held nothing of it when the watch began:
## it was read more often than it was dropped.
func held(group: StringName) -> bool:
	return loads(group) > releases(group)

## The moment `group`'s page was last read from disk in (`AtlasLibrary.MOMENT_STARTUP` and its
## siblings), or `&""` if it has not been read since the watch began.
func last_moment(group: StringName) -> StringName:
	var found := _lines_about(group, " loaded in the ")
	if found.is_empty():
		return &""
	var line: String = found[found.size() - 1]
	var after := line.get_slice(" loaded in the ", 1)
	return StringName(after.get_slice(": ", 0))

## Every line about `group` carrying `marker`, in order.
func _lines_about(group: StringName, marker: String) -> Array[String]:
	var lead := "atlas page '%s'%s" % [group, marker]
	var found: Array[String] = []
	for line in _lines:
		if lead in line:
			found.append(line)
	return found
