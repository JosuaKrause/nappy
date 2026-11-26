class_name HintWatch
extends Node
## **Asks the hints' watchers every tick and puts the winner in the bubble over her**
## (`ThoughtBubble`): "a bubble over the mother holding an icon, no words", a few times per lesson
## at the moment it applies (curly-moose #819). One bubble at a time, the watchers' order being the
## priority (`SimulationBuilder` lists them): a hint that loses is neither shown nor counted, so it
## keeps its shows for a moment it wins. **The exclamation mark wins over every bubble**: while it is
## up the bubble waits, since the mark is the only cue that gives an instruction about danger
## (**cues**). A show is counted in the run's `HintLedger` and said in the run log.

## How long a bubble that does not hold stays up, in seconds.
const SHOW_SECONDS := 4.0

var _ledger: HintLedger
var _watchers: Array[HintWatcher] = []
var _trace := RunTrace.new()
var _atlas: AtlasLibrary = null
var _player: Stroller = null
var _bubble: ThoughtBubble = null
var _showing: HintWatcher = null
var _left := 0.0

## Hands the watch the run's trace and the baked pages the bubble draws from.
func equip(trace: RunTrace, atlas: AtlasLibrary) -> void:
	_trace = trace
	_atlas = atlas

## Hands the watch the ledger it counts in and the watchers it asks, highest priority first.
func setup(ledger: HintLedger, watchers: Array[HintWatcher]) -> void:
	_ledger = ledger
	_watchers = watchers

## Hands the watch her, and puts the bubble over her head. Called once she walks the world.
func use_player(player: Stroller) -> void:
	_player = player
	if player == null:
		return
	_bubble = ThoughtBubble.new()
	_bubble.name = "ThoughtBubble"
	_bubble.use_atlas(_atlas)
	player.add_child(_bubble)

func _physics_process(delta: float) -> void:
	if _player == null or _bubble == null:
		return
	var frame := HintFrame.new(_player.global_position, _player.facing_direction(), delta)
	var winner := _asked_in_order(frame)
	if _player.alert_level() != Stroller.Alert.NONE:
		_bubble.take_down()
		return
	if _showing != null:
		_keep_showing(frame, delta)
		return
	if winner != null and _has_shows_left(winner):
		_put_up(winner, frame)

## The first watcher whose hint applies this tick, or null. Every watcher is asked each tick, so a
## watcher that tracks the moment (the time she has been off the route) keeps its own count.
func _asked_in_order(frame: HintFrame) -> HintWatcher:
	var winner: HintWatcher = null
	for watcher in _watchers:
		var applies := watcher.asks(frame)
		if applies and winner == null and _has_shows_left(watcher):
			winner = watcher
	return winner

func _has_shows_left(watcher: HintWatcher) -> bool:
	return watcher.every_time() or _ledger.has_shows_left(
			HintKind.id_of(watcher.kind()), Tuning.HINT_SHOWS_PER_LESSON)

func _put_up(watcher: HintWatcher, frame: HintFrame) -> void:
	var id := HintKind.id_of(watcher.kind())
	var shows := _ledger.record_show(id)
	watcher.shown()
	_showing = watcher
	_left = SHOW_SECONDS
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
		_bubble.take_down()
		_showing = null
		return
	_bubble.put_up(_showing.kind(), _showing.direction(frame))
