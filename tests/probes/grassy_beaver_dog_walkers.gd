extends RefCounted
## Measurement probe for grassy-beaver's dog walkers on the tutorial route (a day one that teaches):
## **is lesson (3)'s dog walker met on its street on the way to the park, and the second rigged dog
## walker met before her door on the walk home?** Not a suite: it prints rather than asserts, over
## more seeds than `tests/test_tutorial_dog_walkers.gd` holds (`SEEDS`: the city suites' and
## `EXTRA` more). Run by name:
##
##     tools/test.sh probes/grassy_beaver_dog_walkers.gd   (prints DOG_WALKERS lines)
##
## The walk is `tests/tutorial_walk_rig.gd`'s, once for each camera of `AHEADS`: as in play, then
## fixed distances ahead of her along her facing. Each line says, for each dog walker met, where she
## was when it came nearest, how near that was, and whether the director sent it; only a sent one
## counts toward the totals.

const Rig := preload("res://tests/tutorial_walk_rig.gd")
## Seeds walked past the city suites' own, the ones `tests/probes/grassy_beaver_lessons.gd` counts.
const EXTRA := 120
## The cameras walked: as in play, then 23, 31 and 46 px ahead of her (46 the whole look-ahead,
## `Stroller.CAMERA_LOOK_AHEAD`, with no smoothing lag).
const AHEADS: Array[float] = [Rig.AS_IN_PLAY, 23.0, 31.0, 46.0]

func run(t: TestRunner) -> void:
	var seeds := Rig.seeds()
	for i in range(1, EXTRA + 1):
		seeds.append(i)
	for ahead in AHEADS:
		_walk_all(t, seeds, ahead)
	t.check(true, "a probe asserts nothing")

static func _walk_all(t: TestRunner, seeds: Array[int], ahead: float) -> void:
	var camera := "as in play" if ahead == Rig.AS_IN_PLAY else "%.0fpx ahead" % ahead
	var first_on_its_street := 0
	var second_before_the_door := 0
	var walked := 0
	var missed: Array[String] = []
	for seed_value in seeds:
		var met := Rig.walk(t, seed_value, ahead)
		if met.is_empty():
			print("DOG_WALKERS %s seed %d: no tutorial route or no branch to its park"
					% [camera, seed_value])
			continue
		walked += 1
		var out_on_three := false
		var home := false
		var lines: Array[String] = []
		for seen: Dictionary in met:
			var sent := bool(seen.get("sent", false))
			lines.append("%s nearest %.0fpx%s" % [seen["where"], float(seen["nearest"]),
					"" if sent else " (not sent)"])
			out_on_three = out_on_three or (sent and seen["where"] == Rig.OUT_ON_THREE)
			home = home or (sent and seen["where"] == Rig.HOME)
		first_on_its_street += 1 if out_on_three else 0
		second_before_the_door += 1 if home else 0
		if not (out_on_three and home):
			missed.append(str(seed_value))
		print("DOG_WALKERS %s seed %d: %s" % [camera, seed_value, lines])
	print("DOG_WALKERS %s walks=%d first met on lesson (3)'s street=%d second met before her door=%d; not both: %s"
			% [camera, walked, first_on_its_street, second_before_the_door, missed])
