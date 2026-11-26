extends RefCounted
## Measurement probe for grassy-beaver's dog walkers on the tutorial route (a day one that teaches):
## **is lesson (3)'s dog walker met on its street on the way to the park, and the second rigged dog
## walker met before her door on the walk home?** Not a suite: it prints rather than asserts, over
## more seeds than `tests/test_tutorial_dog_walkers.gd` holds (`SEEDS`: the city suites' and
## `EXTRA` more). Run by name:
##
##     tools/test.sh probes/grassy_beaver_dog_walkers.gd   (prints DOG_WALKERS lines)
##
## The walk is `tests/tutorial_walk_rig.gd`'s. Each line says, for each dog walker met, where she was
## when it came nearest and how near that was.

const Rig := preload("res://tests/tutorial_walk_rig.gd")
## Seeds walked past the city suites' own, the ones `tests/probes/grassy_beaver_lessons.gd` counts.
const EXTRA := 120

func run(t: TestRunner) -> void:
	var seeds := Rig.seeds()
	for i in range(1, EXTRA + 1):
		seeds.append(i)
	var first_on_its_street := 0
	var second_before_the_door := 0
	var walked := 0
	var missed: Array[String] = []
	for seed_value in seeds:
		var met := Rig.walk(t, seed_value)
		if met.is_empty():
			print("DOG_WALKERS seed %d: no tutorial route or no branch to its park" % seed_value)
			continue
		walked += 1
		var out_on_three := false
		var home := false
		var lines: Array[String] = []
		for seen: Dictionary in met:
			lines.append("%s nearest %.0fpx" % [seen["where"], float(seen["nearest"])])
			out_on_three = out_on_three or seen["where"] == Rig.OUT_ON_THREE
			home = home or seen["where"] == Rig.HOME
		first_on_its_street += 1 if out_on_three else 0
		second_before_the_door += 1 if home else 0
		if not (out_on_three and home):
			missed.append(str(seed_value))
		print("DOG_WALKERS seed %d: %s" % [seed_value, lines])
	print("DOG_WALKERS walks=%d first met on lesson (3)'s street=%d second met before her door=%d; not both: %s"
			% [walked, first_on_its_street, second_before_the_door, missed])
	t.check(true, "a probe asserts nothing")
