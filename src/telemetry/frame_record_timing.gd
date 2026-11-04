class_name FrameRecordTiming
extends CrowdTiming
## The crowd's sink for the frame record: what `CrowdTiming` is in a game that records. Charges the
## crowd's time to `FrameTiming.CROWD` and its draws to `FrameTiming.Draw.CROWD` on the record it
## is handed, so the record's per-system names and draw counts are as the crowd's own would be.
## Handed to the city by `main._new_city()`; the crowd never names this class.

var _record: FrameTiming

func _init(record: FrameTiming) -> void:
	_record = record

func running() -> bool:
	return _record.on

func enter() -> int:
	return _record.enter(FrameTiming.CROWD)

func leave(previous: int) -> void:
	_record.leave(previous)

func drew() -> void:
	_record.drew(FrameTiming.Draw.CROWD)
