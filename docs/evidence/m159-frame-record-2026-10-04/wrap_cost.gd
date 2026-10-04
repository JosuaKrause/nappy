extends SceneTree
## What each shape of the frame record's timing wrap costs per call, against the body called
## inline, with the record off and then on. Run headless from the repository root:
##   godot --headless --path . --script "$PWD/docs/evidence/m159-frame-record-2026-10-04/wrap_cost.gd"
## Each shape is called CALLS times through a method call, as the engine calls `_process`, and
## the whole set is repeated ROUNDS times in rotated order; the per-round medians are printed.

const CALLS := 1000000
const ROUNDS := 7

class Inline:
	var acc := 0.0
	func tick(delta: float) -> void:
		acc += delta

## The branch as reviewed: a static read on the class, then the moved body called.
class StaticReadAndCall:
	var acc := 0.0
	func tick(delta: float) -> void:
		if FrameRecord.on:
			var outer := FrameRecord.enter(FrameRecord.CROWD)
			_body(delta)
			FrameRecord.leave(outer)
		else:
			_body(delta)
	func _body(delta: float) -> void:
		acc += delta

## A member copy of the switch, then the moved body called.
class MemberReadAndCall:
	var acc := 0.0
	var _timed := false
	func tick(delta: float) -> void:
		if _timed:
			var outer := FrameRecord.enter(FrameRecord.CROWD)
			_body(delta)
			FrameRecord.leave(outer)
		else:
			_body(delta)
	func _body(delta: float) -> void:
		acc += delta

## The static read, the body left inline: the timed path calls the method again.
class StaticReadInline:
	var acc := 0.0
	var _inside := false
	func tick(delta: float) -> void:
		if FrameRecord.on and not _inside:
			var outer := FrameRecord.enter(FrameRecord.CROWD)
			_inside = true
			tick(delta)
			_inside = false
			FrameRecord.leave(outer)
			return
		acc += delta

## A member copy of the switch, the body left inline: the timed path calls the method again.
class MemberReadInline:
	var acc := 0.0
	var _timed := false
	var _inside := false
	func tick(delta: float) -> void:
		if _timed and not _inside:
			var outer := FrameRecord.enter(FrameRecord.CROWD)
			_inside = true
			tick(delta)
			_inside = false
			FrameRecord.leave(outer)
			return
		acc += delta

func _initialize() -> void:
	FrameRecord.on = false
	_measure("off")
	# The same shapes with the record running, into a scratch ledger as the recorder's own
	# calibration does: a member copy taken now reads true.
	FrameRecord.start(FrameLedger.new(1))
	_measure("on")
	FrameRecord.stop()
	quit()

func _measure(state: String) -> void:
	var member_call := MemberReadAndCall.new()
	member_call._timed = FrameRecord.on
	var member_inline := MemberReadInline.new()
	member_inline._timed = FrameRecord.on
	var shapes: Array = [["inline", Inline.new()], ["static read + call", StaticReadAndCall.new()],
		["member read + call", member_call],
		["static read, body inline", StaticReadInline.new()],
		["member read, body inline", member_inline]]
	var times := {}
	for shape in shapes:
		times[shape[0]] = []
	for round_index in ROUNDS:
		for offset in shapes.size():
			var shape: Array = shapes[(round_index + offset) % shapes.size()]
			var target: Object = shape[1]
			var started := Time.get_ticks_usec()
			for _i in CALLS:
				target.tick(0.016)
			times[shape[0]].append(float(Time.get_ticks_usec() - started) * 1000.0 / CALLS)
	var base := _median(times["inline"])
	print("wrap cost with the record %s, ns per call (median of %d rounds of %d calls)" % [
		state, ROUNDS, CALLS])
	for shape in shapes:
		var median := _median(times[shape[0]])
		print("  %-26s %7.1f ns   %+6.1f ns over inline" % [shape[0], median, median - base])

func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]
