extends RefCounted
## Measurement probe for tall-osprey, "the robber's capture zone is too big": a rig that gives the
## alley robber's chase different answers, over several seeds, at several catch sizes. Not a suite:
## it prints rather than asserting, runs only by name, and is rerun the same way:
##
##     tools/test.sh probes/tall_osprey_catch.gd
##
## **The stand-off follows the catch**: `Tuning.pursuit_standoff(130, catch)` is `catch + 78`, so a
## smaller catch moves the lunge nearer by the same amount and the room between lunge and catch
## stays 78px whatever the catch. What a smaller catch changes is therefore small and comes only
## from the geometry after the lunge (`turn_at_notice` below); a held stand-off, which would widen
## that room, is not measured because it needs a change to `EventInstance._chase()`.
##
## The rig walks her along a line at the robber from outside his notice (`pursues_within` 140),
## and answers after a reaction time drawn per seed: `turns` runs away `reaction` seconds after
## the lunge (the chase begins), accelerating at `Tuning.ACCELERATION`. Other rigs: stands still,
## walks away, runs from the notice.

const STEP := 1.0 / 60.0
const SEEDS := 200
const CATCHES := [30.0, 28.0, 26.0, 24.0, 23.0, 22.0, 20.0, 18.0, 16.0]

func run(t) -> void:
	for catch_radius in CATCHES:
		_report(float(catch_radius))
	t.check(true, "tall_osprey_catch probe ran")

func _def(catch_radius: float) -> EventDef:
	var def := EventCatalogue.by_id("alley_robbery").duplicate() as EventDef
	def.inner_radius = catch_radius
	return def

func _report(catch_radius: float) -> void:
	var out := "catch %4.0f  standoff %5.1f |" % [catch_radius,
			Tuning.pursuit_standoff(130.0, catch_radius)]
	for mode in ["still", "walk_away", "run_at_notice", "turn_at_lunge", "turn_at_notice"]:
		var got_away := 0
		for seed_i in SEEDS:
			var rng := RandomNumberGenerator.new()
			rng.seed = 7000 + seed_i
			if not _caught(_def(catch_radius), mode, rng):
				got_away += 1
		out += " %s %2d/%d |" % [mode, got_away, SEEDS]
	print(out)

## One chase. She starts 170-230px out walking in (or still), the robber notices at 140.
func _caught(def: EventDef, mode: String, rng: RandomNumberGenerator) -> bool:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	var her := Vector2(rng.randf_range(170.0, 230.0), 0.0)
	var reaction := rng.randf_range(0.15, 0.75)
	var speed := -Tuning.WALK_SPEED
	var wanted := -Tuning.WALK_SPEED
	if mode == "still":
		speed = 0.0
		her.x = 130.0
		wanted = 0.0
	elif mode == "walk_away":
		her.x = 130.0
		speed = Tuning.WALK_SPEED
		wanted = Tuning.WALK_SPEED
	var elapsed := 0.0
	var since_notice := INF
	var since_lunge := INF
	var caught := false
	while elapsed < 14.0 and not instance.is_leaving and not instance.is_finished and not caught:
		if not instance.is_waiting() and since_notice == INF:
			since_notice = 0.0
		if not instance.is_waiting() and not instance.is_telegraphing() and since_lunge == INF:
			since_lunge = 0.0
		if mode == "run_at_notice" and since_notice != INF:
			wanted = Tuning.RUN_SPEED
		elif mode == "turn_at_lunge" and since_lunge != INF and since_lunge >= reaction:
			wanted = Tuning.RUN_SPEED
		elif mode == "turn_at_notice" and since_notice != INF and since_notice >= reaction:
			wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		her.x += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if since_notice != INF:
			since_notice += STEP
		if since_lunge != INF:
			since_lunge += STEP
		if instance.is_lethal_at(her):
			caught = true
	instance.free()
	return caught
