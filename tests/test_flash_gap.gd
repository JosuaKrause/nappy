extends RefCounted
## **`FlashGap`, the least time between two flashes' starts**: plain state on a clock the case
## steps, so it is built as it is.

func run(t: TestRunner) -> void:
	_test_a_flash_waits_for_the_gap(t)
	_test_no_second_holds_a_fourth(t)

## The first flash may begin at once; the next not before `LEAST_GAP` has passed since it began.
func _test_a_flash_waits_for_the_gap(t: TestRunner) -> void:
	var gap := FlashGap.new()
	t.check(gap.may_begin(), "before any flash, one may begin")
	gap.begin()
	gap.step(FlashGap.LEAST_GAP * 0.5)
	t.check(not gap.may_begin(), "half the gap after it began, the next may not")
	gap.step(FlashGap.LEAST_GAP * 0.5)
	t.check(gap.may_begin(), "the whole gap after it began, it may")

## Beginning every flash the gap allows, on a 60Hz tick for a minute: no window of a second holds
## more than three starts.
func _test_no_second_holds_a_fourth(t: TestRunner) -> void:
	var gap := FlashGap.new()
	var tick := 1.0 / 60.0
	var starts: Array[float] = []
	for i in 3600:
		gap.step(tick)
		if gap.may_begin():
			gap.begin()
			starts.append(i * tick)
	var most := 0
	for i in starts.size():
		var within := 0
		for j in range(i, starts.size()):
			if starts[j] - starts[i] < 1.0:
				within += 1
		most = maxi(most, within)
	t.check(starts.size() > 100 and most <= 3,
			"at most three flashes begin in any second (%d at most, %d in all)" % [most, starts.size()])
