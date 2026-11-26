extends RefCounted
## **`FlashRhythm`, when the sky over the escape city lights up**: stepped by hand at the physics
## rate, as `BlastLight` steps it, and read through `light()`, what the city's light is lifted by.
## A flash is seen where the light starts to rise.

const TICK := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_never_more_than_three_flashes_in_a_second(t)
	_test_a_bang_lights_brighter_than_a_far_bomb(t)
	_test_a_bang_lights_at_once_or_within_the_gap(t)
	_test_a_seed_replays_the_same_night(t)

## **Safe for viewers**: over ten minutes of far flashes with a bang every few seconds at random,
## no second holds more than three flashes, and there were flashes to count.
func _test_never_more_than_three_flashes_in_a_second(t: TestRunner) -> void:
	var rhythm := FlashRhythm.new()
	rhythm.start_the_night(7)
	var bangs := RandomNumberGenerator.new()
	bangs.seed = 11
	var starts := _flash_starts(rhythm, 600.0, func() -> bool: return bangs.randf() < 0.004)
	var most := 0
	var first := 0
	for i in starts.size():
		while starts[i] - starts[first] >= 1.0:
			first += 1
		most = maxi(most, i - first + 1)
	t.check(starts.size() > 300, "there were flashes to count (%d)" % starts.size())
	t.check(most <= 3, "never more than three flashes in any one second (%d)" % most)

## A bang's flash reaches `FlashRhythm.NEAR_PEAK`; the far flashes alone never pass
## `FlashRhythm.DISTANT_PEAK`, which is fainter.
func _test_a_bang_lights_brighter_than_a_far_bomb(t: TestRunner) -> void:
	var far := FlashRhythm.new()
	far.start_the_night(3)
	var brightest_far := 0.0
	for i in roundi(60.0 / TICK):
		far.step(TICK)
		brightest_far = maxf(brightest_far, far.light())
	var near := FlashRhythm.new()
	near.flash_for_a_bang()
	var brightest_near := 0.0
	for i in roundi(1.0 / TICK):
		near.step(TICK)
		brightest_near = maxf(brightest_near, near.light())
	t.check(brightest_far > 0.0 and brightest_far <= FlashRhythm.DISTANT_PEAK + 0.001,
			"the far bombs light the sky faintly (%.2f)" % brightest_far)
	t.check(is_equal_approx(brightest_near, FlashRhythm.NEAR_PEAK) and brightest_near > brightest_far,
			"a bang lights it brightly (%.2f)" % brightest_near)
	t.check(near.light() == 0.0, "and the flash is over within a second")

## A bang with no flash before it lights at once; one straight after a flash lights once the gap
## after that flash's start has run, no later.
func _test_a_bang_lights_at_once_or_within_the_gap(t: TestRunner) -> void:
	var rhythm := FlashRhythm.new()
	rhythm.flash_for_a_bang()
	rhythm.step(TICK)
	var clock := TICK
	t.check(rhythm.light() > 0.0, "a bang with nothing before it lights at once")
	for i in 5:
		rhythm.step(TICK)
		clock += TICK
	t.check(rhythm.light() > 0.0, "the first flash is still lit when the second bang comes")
	rhythm.flash_for_a_bang()
	var rose_at := INF
	while clock < 1.0 and rose_at == INF:
		var was := rhythm.light()
		rhythm.step(TICK)
		clock += TICK
		if rhythm.light() > was + 0.0001:
			rose_at = clock
	t.check(rose_at >= FlashRhythm.LEAST_GAP - 0.001 and rose_at <= FlashRhythm.LEAST_GAP + TICK * 3.0,
			"a bang straight after a flash lights once the gap after its start has run (%.2fs)"
			% rose_at)

## Two nights from one seed light the sky the same, tick for tick; another seed does not.
func _test_a_seed_replays_the_same_night(t: TestRunner) -> void:
	var one := _night(5)
	var again := _night(5)
	var other := _night(6)
	t.check(one == again, "the same seed, the same night")
	t.check(one != other, "another seed, another night")

## The light of a night from `seed` over twenty seconds, a tick at a time.
func _night(seed: int) -> PackedFloat32Array:
	var rhythm := FlashRhythm.new()
	rhythm.start_the_night(seed)
	var lights := PackedFloat32Array()
	for i in roundi(20.0 / TICK):
		rhythm.step(TICK)
		lights.append(rhythm.light())
	return lights

## The seconds each flash is seen to start over `seconds` of `rhythm`, a bang told whenever
## `bang_now` answers true: where the light starts to rise after not rising.
func _flash_starts(rhythm: FlashRhythm, seconds: float, bang_now: Callable) -> PackedFloat32Array:
	var starts := PackedFloat32Array()
	var was := 0.0
	var rising := false
	var clock := 0.0
	for i in roundi(seconds / TICK):
		if bang_now.call():
			rhythm.flash_for_a_bang()
		rhythm.step(TICK)
		clock += TICK
		var now := rhythm.light()
		var rises := now > was + 0.0001
		if rises and not rising:
			starts.append(clock)
		rising = rises
		was = now
	return starts
