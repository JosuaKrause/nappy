extends RefCounted
## Measurement probe for the one-radius charger (inbox #788 in minty-lemur): every charger that waits for her, warns
## while she is inside its one radius and charges once its warning has run with her still inside.
## For each, at several warning times, four walks on the real `EventInstance` at 60Hz on open
## ground, her speed changing at `Tuning.ACCELERATION` as hers does. Not a suite: it prints rather
## than asserts. Run by name:
##
##     tools/test.sh probes/charger_warning.gd      (prints WARNING lines)
##
## She walks in at `Tuning.WALK_SPEED` from outside his radius (a roadblock's guard steps out to his
## post on the line between the band and her). The walks, from the frame his warning starts:
##
## - **back**: she turns `REACTION` later and runs back out. Fair if he never charges.
## - **stand**: she stops and stands where she is. Fair if he charges and catches her.
## - **bait**: she stops, stands until he charges, and runs back `REACTION` after his charge. Fair
##   if she gets away (his closest is printed against his catch).
## - **on**: she keeps walking in. Fair if he charges and catches her.

const STEP := 1.0 / 60.0
## Her reaction to his warning starting, or to his charge, in seconds.
const REACTION := 0.3
const TIMES: Array[float] = [1.0, 1.5, 2.0, 2.5, 3.0]

func run(t) -> void:
	for def in _waiting_chargers():
		for warns_for in TIMES:
			var copy := def.duplicate() as EventDef
			copy.shape = def.shape
			copy.solid_parts = def.solid_parts
			copy.pursuit = def.pursuit.duplicate() as PursuitSpec
			copy.pursuit.warns_for = warns_for
			var said: Array[String] = []
			for walk in ["back", "stand", "bait", "on"]:
				var r := _walk(t, copy, walk)
				said.append("%s: %s%s" % [walk,
						"caught" if r["caught"] else ("charged, got away" if r["charged"]
						else "never charged"),
						", closest %.0fpx" % r["closest"] if r["charged"] else ""])
			print("WARNING %s (radius %.0fpx, catch %.0fpx) warns %.1fs | %s" % [def.id,
					def.notice_within(), def.lethal_reach(), warns_for, " | ".join(said)])

## Every row that waits for her, warns by its one radius and pursues her, once each.
static func _waiting_chargers() -> Array[EventDef]:
	var rows: Array[EventDef] = []
	var seen := {}
	for row in EventCatalogue.all():
		for level in range(0, Tuning.RESISTANCE_GOAL + 1):
			for day in range(1, Tuning.RUN_LENGTH_DAYS + 1):
				var def := EventScheduler._for_day(EventCatalogue.heated(row, level), day)
				if def.pursuit == null or def.notice_within() <= 0.0 or def.starts_by(PursuitSpec.Start.SETS_OFF_BESIDE_HER) \
						or def.starts_by(PursuitSpec.Start.ARRIVES_CHASING):
					continue
				var key := "%s|%.2f|%.2f" % [def.id, def.notice_within(), def.chase_speed()]
				if not seen.has(key):
					seen[key] = true
					rows.append(def)
	return rows

## One walk; `{"charged", "caught", "closest"}`, the closest measured from his charge on.
static func _walk(t, def: EventDef, walk: String) -> Dictionary:
	var instance := EventInstance.new()
	instance.setup(def, Vector2.ZERO)
	t.add_child(instance)
	instance.set_process(false)
	instance.look.attach_nodes()
	var her := Vector2(0.0, def.notice_within() + 20.0)
	# Positive is away from him, along +y.
	var speed := -Tuning.WALK_SPEED
	var warned_at := INF
	var charged_at := INF
	var elapsed := 0.0
	var result := {"charged": false, "caught": false, "closest": INF}
	while elapsed < 20.0 and not instance.is_leaving and not instance.gave_up:
		var wanted := -Tuning.WALK_SPEED
		if warned_at != INF:
			match walk:
				"back":
					if elapsed - warned_at >= REACTION:
						wanted = Tuning.RUN_SPEED
				"stand":
					wanted = 0.0
				"bait":
					wanted = 0.0
					if charged_at != INF and elapsed - charged_at >= REACTION:
						wanted = Tuning.RUN_SPEED
		speed = move_toward(speed, wanted, Tuning.ACCELERATION * STEP)
		her.y += speed * STEP
		instance.player_at = her
		instance.player_running = speed > Tuning.WALK_SPEED
		instance.step(STEP)
		elapsed += STEP
		if warned_at == INF and not instance.is_waiting():
			warned_at = elapsed
		if charged_at == INF and instance.is_chasing():
			charged_at = elapsed
			result["charged"] = true
		if charged_at != INF:
			result["closest"] = minf(float(result["closest"]),
					instance.global_position.distance_to(her))
		if instance.is_lethal_at(her):
			result["caught"] = true
			break
		if walk == "back" and warned_at != INF and instance.is_waiting() and her.y > def.notice_within() + 60.0:
			break
	instance.free()
	return result
