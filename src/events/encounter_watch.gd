class_name EncounterWatch
extends RefCounted
## Counts her encounters with the day's events, and her bouts of running, for the page's counter —
## the telemetry half of `EventManager`, which owns one and asks it once a physics frame. *(misty-
## newt, the player: "I want to establish two things -- how frequent do certain events actually
## appear and are players avoiding them or ignoring them?" — "mostly I'm interested in the ratio of
## interacted/seen".)*
##
## **It only watches.** It reads where things are, what they have landed on her and whether she is
## running, and says so on `EventBus` — `encounter_seen`, `encounter_influenced`, `run_bout_began` —
## which `VisitCounter` turns into `nappy-day-N-seen-<event>`, `nappy-day-N-influenced-<event>` (or
## `influenced-unseen-<event>`) and `nappy-day-N-ran`. No roll, no write to anything an event, the
## baby or the player reads, so the day plays the same with nobody listening.
##
## **What she can see is `VisibleView.visible_share()`**: the view, less the two bottom corners the
## joystick scheme's rings and run buttons cover, which count in the tap scheme.
##
## **An encounter is one instance's time on screen.** It opens the first frame any of what is drawn
## for the instance is visible (`EventInstance.drawn_box()`), or the instance
## lands something on her from off screen; it stays open while either goes on; and it is over once
## the instance has been neither for `Tuning.ENCOUNTER_GAP` — so coming back sooner is the same
## encounter, and later a new one. Every instance is its own: a different yeller is a different
## encounter. A planned event streamed out and back in is a new instance, which changes nothing,
## because it streams out only past `Tuning.EVENT_STREAM_RADIUS`, far longer than the gap away.
##
## Within one encounter:
##
## - **seen** at most once, the first frame `Tuning.ENCOUNTER_SEEN_SHARE` of its drawn box is
##   visible. A row that draws nothing of its own has nothing to be seen and is never seen.
## - **influenced** at most once, the first frame the encounter is meaningful, for every row alike:
##   `Tuning.ENCOUNTER_INFLUENCE_POINTS` landed on her within the encounter
##   (`EventInstance.landed_ever`, since `landed()` keeps only the halo's window), or it chasing her
##   (`EventInstance.is_chasing()`), or her inside its lethal reach or its hold, whichever comes first.
##   *(Inbox #577, the player: "let's count chases and catches as influenced always".)* A row that
##   can do none of the three — a fallen tree, a skip — is seen and never influenced.
##   An influence before the encounter is seen waits: it goes out as influenced the moment the
##   instance is seen, or as influenced-unseen once the encounter is over without it, so influenced
##   ÷ seen counts only what she could see.
##
## **A bout of running** begins the first frame she runs (`Stroller.run_excess_ratio()` above 0, the
## test `EventManager` already makes) after `Tuning.RUN_BOUT_GAP` or more without running, or the
## first time in a day.
##
## **Cheap by construction**: one pass over the live instances, arithmetic on two rectangles each, a
## record made once per instance the first time it is present and nothing allocated on a frame
## otherwise. The open encounters are a short list of their own, so an encounter can be closed after
## its instance has gone.

## One instance's encounters. Kept on the instance (`EventInstance.encounter`) so finding it costs
## nothing, and on `_open` while an encounter is open, so it can be closed after the instance is gone.
class Record:
	var instance: Object
	## `EventInstance.logged_name()`, kept so an encounter can be named once its instance is freed.
	var name := ""
	var open := false
	## The watch's clock the last frame the instance was on screen or landed on her.
	var last_present := -INF
	## The watch's frame the instance was last looked at — a record not looked at this frame belongs
	## to an instance that is no longer live.
	var last_frame := -1
	## `EventInstance.landed_ever` when the current encounter opened, and the last frame.
	var landed_at_open := 0.0
	var landed_last := 0.0
	var seen := false
	var influenced := false
	## Influenced before it was seen: sent when it is seen, or as unseen when the encounter is over.
	var influence_waiting := false

var _clock := 0.0
var _frame := 0
var _open: Array[Record] = []
var _running := false
var _ran_last := -INF

## The day the signals carry. Set by `EventManager.start_day()`; an influence still waiting when the
## next day starts goes out under the day it happened on.
var day := 0

## One frame. `view` is the world the camera shows, `joystick` whether the joystick scheme's
## controls cover its bottom corners, `her` where she stands, `running` whether she is running.
func tick(delta: float, instances: Array[EventInstance], view: Rect2, joystick: bool,
		her: Vector2, running: bool) -> void:
	_clock += delta
	_frame += 1
	for instance in instances:
		_look_at(instance, view, joystick, her)
	_close_what_is_over()
	_watch_the_running(running)

## Ends the day's watch: every open encounter is over, and the clock, the records' list and the
## running start again with the next day.
func end_day() -> void:
	for record in _open:
		_close(record)
	_open.clear()
	_clock = 0.0
	_running = false
	_ran_last = -INF

func _look_at(instance: EventInstance, view: Rect2, joystick: bool, her: Vector2) -> void:
	var box := instance.drawn_box()
	var world := Rect2(box.position + instance.global_position, box.size)
	var share := VisibleView.visible_share(world, view, joystick)
	var in_view := share > 0.0
	var record := instance.encounter
	var landing := record != null and instance.landed_ever > record.landed_last
	if record == null:
		if not in_view and instance.landed_ever <= 0.0:
			return
		record = Record.new()
		record.instance = instance
		record.name = instance.logged_name()
		instance.encounter = record
		landing = instance.landed_ever > 0.0
	record.last_frame = _frame
	if in_view or landing:
		if not record.open:
			_open_an_encounter(record)
		record.last_present = _clock
	if not record.open:
		record.landed_last = instance.landed_ever
		return
	if not record.seen and share >= Tuning.ENCOUNTER_SEEN_SHARE:
		record.seen = true
		EventBus.encounter_seen.emit(day, record.name)
		if record.influence_waiting:
			record.influence_waiting = false
			EventBus.encounter_influenced.emit(day, record.name, true)
	if not record.influenced and _is_meaningful(instance, record, her):
		record.influenced = true
		if record.seen:
			EventBus.encounter_influenced.emit(day, record.name, true)
		else:
			record.influence_waiting = true
	record.landed_last = instance.landed_ever

## Opens a new encounter on `record`: nothing seen or influenced yet, and its landing counted from
## what the instance had landed before this frame, so a landing that opens it is part of it.
func _open_an_encounter(record: Record) -> void:
	record.open = true
	record.seen = false
	record.influenced = false
	record.influence_waiting = false
	record.landed_at_open = record.landed_last
	_open.append(record)

## The meaningful-encounter test — see the class doc. The same three ways in for every row: what a
## row cannot do (land anything, chase, reach or hold her) simply never happens.
static func _is_meaningful(instance: EventInstance, record: Record, her: Vector2) -> bool:
	var def := instance.def
	if instance.landed_ever - record.landed_at_open >= Tuning.ENCOUNTER_INFLUENCE_POINTS:
		return true
	if instance.is_chasing():
		return true
	var reach := 0.0
	if def.hard_fail:
		reach = def.lethal_reach()
	if def.detain_seconds > 0.0:
		reach = maxf(reach, def.detain_distance())
	return reach > 0.0 and instance.global_position.distance_to(her) <= reach

## Closes every open encounter whose instance has gone, or has been away for the gap. Removal swaps
## the last record in, so the list never shifts.
func _close_what_is_over() -> void:
	var i := 0
	while i < _open.size():
		var record := _open[i]
		var gone := record.last_frame != _frame or not is_instance_valid(record.instance)
		if gone or _clock - record.last_present >= Tuning.ENCOUNTER_GAP:
			_close(record)
			_open[i] = _open[_open.size() - 1]
			_open.pop_back()
		else:
			i += 1

func _close(record: Record) -> void:
	record.open = false
	if record.influence_waiting:
		record.influence_waiting = false
		EventBus.encounter_influenced.emit(day, record.name, false)

func _watch_the_running(running: bool) -> void:
	if running and not _running and _clock - _ran_last >= Tuning.RUN_BOUT_GAP:
		EventBus.run_bout_began.emit(day)
	_running = running
	if running:
		_ran_last = _clock
