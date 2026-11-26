class_name HintWatch
extends Node
## **Asks the hints' watchers every tick and puts the winner in the bubble over her**
## (`ThoughtBubble`): "a bubble over the mother holding an icon, no words", a few times per lesson
## at the moment it applies (curly-moose #819). One bubble at a time, the watchers' order being the
## priority (`SimulationBuilder` lists them): a hint that loses is neither shown nor counted, so it
## keeps its shows for a moment it wins, and **a higher hint that comes to apply replaces a lower one
## that is up**. **The exclamation mark wins over every bubble**: while it is up the bubble waits,
## since the mark is the only cue that gives an instruction about danger (**cues**). A show is
## counted in the run's `HintLedger` and said in the run log.
##
## **Each walk begins afresh** (`begin_walk()`, from the day director with the walk's tutorial
## route): every watcher is armed again and a bubble the last walk left up comes down, so a retried
## day is taught again and nothing of yesterday's route is asked about today. **The bubble is the
## watch's**, handed to it (`setup()`), stood over her while the watch has her and freed with the
## watch.

## How long a bubble that does not hold stays up, in seconds.
const SHOW_SECONDS := 4.0

var _ledger: HintLedger
var _watchers: Array[HintWatcher] = []
var _trace := RunTrace.new()
var _player: Stroller = null
var _bubble: ThoughtBubble = null
var _showing: HintWatcher = null
var _show_seconds := SHOW_SECONDS
var _left := 0.0

## Hands the watch the run's trace its shows are said in.
func equip(trace: RunTrace) -> void:
	_trace = trace

## Hands the watch the ledger it counts in, the watchers it asks, highest priority first, the
## bubble it draws in, and how long a bubble that does not hold stays up.
func setup(ledger: HintLedger, watchers: Array[HintWatcher], bubble: ThoughtBubble,
		show_seconds := SHOW_SECONDS) -> void:
	_ledger = ledger
	_watchers = watchers
	_bubble = bubble
	_show_seconds = show_seconds

## Starts a walk: every watcher armed afresh with the walk's tutorial route (null for none), and
## the bubble down. The day director calls it at each walk's start, a retry included.
func begin_walk(route: TutorialRoute) -> void:
	for watcher in _watchers:
		watcher.begin_walk(route)
	_take_down()

## Hands the watch her, and stands the bubble over her head. Called each time she walks the world;
## the same her again changes nothing.
func use_player(player: Stroller) -> void:
	_player = player
	if _bubble == null or player == null:
		return
	var parent := _bubble.get_parent()
	if parent == player:
		return
	if parent != null:
		parent.remove_child(_bubble)
	player.add_child(_bubble)

func _exit_tree() -> void:
	if is_instance_valid(_bubble):
		_bubble.queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_bubble) and not _bubble.is_inside_tree():
		_bubble.free()

func _physics_process(delta: float) -> void:
	if _player == null or _bubble == null:
		return
	var frame := HintFrame.new(_player.global_position, _player.facing_direction(), delta)
	var winner := _asked_in_order(frame)
	if _player.alert_level() != Stroller.Alert.NONE:
		_bubble.take_down()
		return
	if _showing != null and (winner == null or _rank(winner) >= _rank(_showing)):
		_keep_showing(frame, delta)
		return
	if winner != null:
		_put_up(winner, frame)

## The first watcher whose hint applies this tick and has shows left, or null. Every watcher is
## asked each tick, so a watcher that tracks the moment (the time she has been off the route) keeps
## its own count.
func _asked_in_order(frame: HintFrame) -> HintWatcher:
	var winner: HintWatcher = null
	for watcher in _watchers:
		var applies := watcher.asks(frame)
		if applies and winner == null and _has_shows_left(watcher):
			winner = watcher
	return winner

func _rank(watcher: HintWatcher) -> int:
	return _watchers.find(watcher)

func _has_shows_left(watcher: HintWatcher) -> bool:
	return watcher.every_time() or _ledger.has_shows_left(
			HintKind.id_of(watcher.kind()), Tuning.HINT_SHOWS_PER_LESSON)

func _put_up(watcher: HintWatcher, frame: HintFrame) -> void:
	var id := HintKind.id_of(watcher.kind())
	var shows := _ledger.record_show(id)
	watcher.shown()
	_showing = watcher
	_left = _show_seconds
	_bubble.put_up(watcher.kind(), watcher.direction(frame))
	_trace.note("cue", "thought bubble: %s (show %d)" % [id, shows])

func _keep_showing(frame: HintFrame, delta: float) -> void:
	var done := false
	if _showing.holds_while_true():
		done = not _showing.still_applies(frame)
	else:
		_left -= delta
		done = _left <= 0.0
	if done:
		_take_down()
		return
	_bubble.put_up(_showing.kind(), _showing.direction(frame))

func _take_down() -> void:
	_showing = null
	if is_instance_valid(_bubble):
		_bubble.take_down()
