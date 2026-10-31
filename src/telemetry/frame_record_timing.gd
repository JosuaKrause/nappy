class_name FrameRecordTiming
extends CrowdTiming
## The crowd's sink for the frame record: what `CrowdTiming` is in a game that records. Charges the
## crowd's time to `FrameRecord.CROWD` and its draws to `FrameLedger.DRAWS_CROWD`, exactly as the
## crowd did when it read the record's statics itself, so the record's per-system names and draw
## counts are unchanged. Handed to the city by `main._new_city()`; the crowd never names this class.

func running() -> bool:
	return FrameRecord.on

func enter() -> int:
	return FrameRecord.enter(FrameRecord.CROWD)

func leave(previous: int) -> void:
	FrameRecord.leave(previous)

func drew() -> void:
	FrameRecord.drew(FrameLedger.DRAWS_CROWD)
