extends RefCounted
## Measurement probe for baiting a waiting charger (inbox #788): for every charger that waits, warns
## by radius and charges once she is within his charge radius, the numbers his charge radius is
## derived from and how long she may take to turn once he charges. Not a suite: it prints rather
## than asserts. Run by name:
##
##     tools/test.sh probes/bait_radius.gd      (prints BAIT lines)
##
## **The walk is the bait.** She walks straight in at `Tuning.WALK_SPEED` from just outside his
## warning radius; the frame he charges she keeps walking in for `reaction` seconds, then turns and
## runs, accelerating at `Tuning.ACCELERATION` as she really does, until he gives up. The rig is the
## real `EventInstance` stepped at 60Hz on open ground; a roadblock's guard steps out to his post on
## the line between the band and her. The widest reaction she survives is reported (to 0.01s), with
## the closest he came at `Tuning.BAIT_REACTION`.

const STEP := 1.0 / 60.0

func run(t) -> void:
	var posts: Array[String] = []
	for vertical in [false, true]:
		for side in [-1, 1]:
			posts.append("%s" % EventInstance._guard_post_offset(vertical, side))
	print("BAIT a roadblock's posts from its band: %s; his raised hand %s" % [", ".join(posts),
			EventInstance.warning_guard_rect(false, Vector2.ZERO, Vector2(0.0, 100.0)).size])
	for def in _waiting_chargers():
		var instance := EventInstance.new()
		instance.setup(def, Vector2.ZERO)
		var charge := instance.charge_radius()
		instance.free()
		var window := -1.0
		for i in 101:
			var reaction := i * 0.01
			if _bait(t, def, reaction)["caught"]:
				break
			window = reaction
		var at_the_reaction := _bait(t, def, Tuning.BAIT_REACTION)
		print(("BAIT %s: speed %.0f, catch %.0f, warning %.0f, charge radius %.0f (stand-off %.0f), "
				+ "field %.0f; widest reaction survived %.2fs; at %.2fs closest %.1fpx, %s")
				% [def.id, def.pursue_speed, def.lethal_reach(), def.pursues_within, charge,
				Tuning.pursuit_standoff(def.pursue_speed, def.standoff_reach()),
				def.outer_radius, window, Tuning.BAIT_REACTION, at_the_reaction["closest"],
				"caught" if at_the_reaction["caught"] else "got away"])

## Every row that waits for her, warns by radius and charges by proximity, at every resistance
## level and on every day, once each: `tests/test_events_pursuit.gd`'s own enumeration, plus the
## escape's roadblock.
static func _waiting_chargers() -> Array[EventDef]:
	var rows: Array[EventDef] = []
	var seen := {}
	var candidates: Array[EventDef] = []
	for row in EventCatalogue.all():
		for level in range(0, Tuning.RESISTANCE_GOAL + 1):
			for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
				candidates.append(EventScheduler._for_day(EventCatalogue.heated(row, level), day))
	candidates.append(EventCatalogue.escape_roadblock())
	for def in candidates:
		if not def.pursues or def.pursues_within <= 0.0 or def.sets_off_beside_her \
				or def.arrives_chasing:
			continue
		var key := "%s|%.2f|%.2f|%.2f|%s" % [def.id, def.pursues_within, def.pursue_speed,
				def.lethal_reach(), def.far_guard_leaves]
		if seen.has(key):
			continue
		seen[key] = true
		rows.append(def)
	return rows

## She walks in along -y from just inside his warning radius (measured from where he notices her
## from: the band's centre for a roadblock), keeps walking `reaction` seconds after he charges, then
## turns and runs. `{"caught", "closest"}`.
static func _bait(t, def: EventDef, reaction: float) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	instance._attach_the_band()
	var her := Vector2(0.0, def.pursues_within + 20.0)
	var speed := -Tuning.WALK_SPEED
	var since := INF
	var result := {"caught": false, "closest": INF}
	var elapsed := 0.0
	while elapsed < 20.0 and not instance.is_leaving and not instance.gave_up:
		var wanted := -Tuning.WALK_SPEED
		if since != INF and since >= reaction:
			wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		her.y += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance._process(STEP)
		elapsed += STEP
		if since == INF and instance.is_chasing():
			since = 0.0
		elif since != INF:
			since += STEP
		if since != INF:
			result["closest"] = minf(float(result["closest"]),
					instance.global_position.distance_to(her))
		if instance.is_lethal_at(her):
			result["caught"] = true
			break
	instance.free()
	return result
