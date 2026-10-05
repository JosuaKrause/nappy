extends SceneTree
## What the `_draw()` counter costs per call with the record off and on, against the same body
## without it. Run headless from the repository root:
##   godot --headless --path . --script "$PWD/docs/evidence/m159-draw-split-2026-10-04/drew_cost.gd"
## Each shape is called CALLS times through a method call, as the engine calls `_draw`, and the
## set is repeated ROUNDS times in rotated order; the per-round nanoseconds a call are printed with
## their median. A loop's own cost (the shape `plain`) is in every figure, so read the differences.

const CALLS := 2000000
const ROUNDS := 7

class Plain:
	var acc := 0.0
	func draw(delta: float) -> void:
		acc += delta

class Counted:
	var acc := 0.0
	func draw(delta: float) -> void:
		if FrameRecord.on:
			FrameRecord.drew(FrameLedger.DRAWS_CROWD)
		acc += delta

func _init() -> void:
	var plain := Plain.new()
	var counted := Counted.new()
	FrameRecord.on = false
	var shapes := ["plain", "counted, record off", "counted, record on"]
	var results := {}
	for shape in shapes:
		results[shape] = []
	for round_index in ROUNDS:
		for step in shapes.size():
			var shape: String = shapes[(step + round_index) % shapes.size()]
			if shape == "counted, record on":
				FrameRecord.on = true
				FrameRecord.ledger = FrameLedger.new()
			else:
				FrameRecord.on = false
			var started := Time.get_ticks_usec()
			if shape == "plain":
				for i in CALLS:
					plain.draw(0.5)
			else:
				for i in CALLS:
					counted.draw(0.5)
			var elapsed := Time.get_ticks_usec() - started
			results[shape].append(elapsed * 1000.0 / CALLS)
	FrameRecord.on = false
	for shape in shapes:
		var values: Array = results[shape]
		var sorted := values.duplicate()
		sorted.sort()
		print("%-22s median %6.1f ns a call   rounds %s" % [shape, sorted[sorted.size() / 2],
				", ".join(values.map(func(v: float) -> String: return "%.1f" % v))])
	quit()
