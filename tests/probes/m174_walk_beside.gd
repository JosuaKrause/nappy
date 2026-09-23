extends RefCounted
## Measurement probe for M174, "the man shouting costs nothing to walk beside": the net rate the
## bar rises while walking beside a row, inside its own `inner_radius`, averaged over its own
## rhythm. Not a suite — prints numbers rather than asserting relationships — so it lives under
## `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m174_walk_beside.gd
##
## `PLAYTEST-112` took this measurement of `homeless_yeller` by hand: intensity at arm's length,
## averaged over the pulse, less the walking decay. This is the same arithmetic run over every row
## that is a place she can stand beside, so the three named rows (`homeless_yeller`, `loose_dog`,
## `dog_walker`) can be checked against the target and every other row can be surveyed for the
## same defect without anybody hand-computing forty of them.
##
## **The field.** `EventDef.emission_at()` at exactly `inner_radius` from the centre — the same
## function `walk_through_cost()` integrates, so a flock's spread and a core are already accounted
## for and nothing here recomputes a falloff of its own.
##
## **The rhythm.** `current_intensity()`'s pulse envelope is `0.25 + 0.75·(0.5 − 0.5·cos(phase))`,
## whose mean over one full period is exactly `0.625` regardless of `pulse_period` — the cosine
## term integrates to zero — so no row's own period needs walking through frame by frame. A row
## with no pulse emits at its full peak throughout, mean `1.0`.
##
## **The ground.** `Tuning.EXCITEMENT_DECAY_WALKING` at multiplier `1.0` — an ordinary pavement,
## `City._ground_decay_multiplier()`'s fallback — because that is where all three named rows are
## placed (`SIDEWALK`/`SQUARE`, none of calm, alley, precinct or main road).
##
## **What is excluded**, and why none of it is "a place to stand beside": zero-intensity rows
## (nothing to receive), the two free lists `tests/test_events.gd`
## already names (`_SCENERY`, priced at zero on purpose; the detainers, priced through their own
## capture rather than a field), anything `AHEAD_OF_PLAYER` (three seconds of cat, never a place),
## and anything that pursues or waits to (the encounter is a chase, not a walk beside a field).

const PULSE_MEAN := 0.625

## Ids priced at zero on purpose — `tests/test_events.gd`'s own list, so a row deliberately given
## no field is not reported as a defect here.
const _SCENERY := ["burnt_shell", "poster_crew", "poster_crew_square"]
## Ids priced through their own capture rather than a field — see the **balance** skill,
## "Two short lists hold every row that is allowed to be free."
const _DETAINERS := ["chatting_mother", "checkpoint_hut", "checkpoint_post"]

func run(t) -> void:
	print("\n== walk-beside net rate, at inner_radius, averaged over the pulse ==")
	print("decay compared: old 3.5/s (pre-M117, computed here, no code change), today %.1f/s"
			% Tuning.EXCITEMENT_DECAY_WALKING)
	print("%-22s %8s %10s %10s %10s %10s" % [
			"id", "rate/s", "awake@3.5", "awake@6.0", "asleep@3.5", "asleep@6.0"])
	var flagged: Array = []
	for def in EventCatalogue.all():
		if not _walkable_beside(def):
			continue
		var rate := _mean_rate_at_inner_radius(def)
		var awake_old := rate - 3.5
		var awake_now := rate - Tuning.EXCITEMENT_DECAY_WALKING
		var asleep_old := rate * Tuning.SLEEPING_SENSITIVITY - 3.5
		var asleep_now := rate * Tuning.SLEEPING_SENSITIVITY - Tuning.EXCITEMENT_DECAY_WALKING
		print("%-22s %8.2f %10.2f %10.2f %10.2f %10.2f"
				% [def.id, rate, awake_old, awake_now, asleep_old, asleep_now])
		if awake_now <= 0.0:
			flagged.append(def.id)
	print("\n== rows at or below zero net awake, today's decay (%.1f/s) ==" % Tuning.EXCITEMENT_DECAY_WALKING)
	if flagged.is_empty():
		print("  none")
	else:
		for id in flagged:
			print("  %s" % id)
	t.check(true, "zz_m174 walk-beside probe ran")

func _walkable_beside(def: EventDef) -> bool:
	if def.intensity <= 0.0:
		return false
	if def.id in _SCENERY or def.id in _DETAINERS:
		return false
	if def.pursues or def.pursues_within > 0.0:
		return false
	if def.spawn_mode == EventDef.SpawnMode.AHEAD_OF_PLAYER:
		return false
	return true

func _mean_rate_at_inner_radius(def: EventDef) -> float:
	var base: float = def.emission_at(Vector2(def.inner_radius, 0.0))
	if def.pulse_period > 0.0:
		return base * PULSE_MEAN
	return base
