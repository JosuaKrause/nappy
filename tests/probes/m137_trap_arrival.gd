class_name M137TrapArrival
extends RefCounted
## Measurement probe for the "about one handover in five" figure quoted in
## `ResistanceDirector._draw_arrival_position()`'s own doc, the `docs/EVENTS.md` row for
## `robber_giving_chase`/`van_guard_giving_chase`, and PR #362's fork 2: how often the trap's
## start falls back to the along-her-street `beside_distance()` draw — a street that runs
## sideways, with no crossing street near enough for a clear run above or below — rather than the
## preferred above-or-below draw. Not a suite: it prints a rate rather than asserting one, so it
## lives under `tests/probes/`, where the runner never discovers it, and runs only by name:
##
##     tools/test.sh probes/m137_trap_arrival.gd
##
## **The rig.** A real city and `ResistanceDirector` per seed (`CityGenerator.generate(seed)`),
## carried to exactly the point a real handover reaches it: day 6's mark touched so the yeller
## perform is active (`_on_contact_completed(1)`, the shape `tests/test_resistance.gd`'s
## `_director_on_the_yeller_perform()` builds), day 7's mark touched so the van's perform is
## active (`_on_contact_completed(3)`, `_director_on_the_van_perform()`'s shape). From there
## `_draw_arrival_position()` — the same private call `_set_the_trap_on_her()` makes at the
## handover — is asked directly with the director's own `_rng`, so the draw is exactly the one a
## real handover would make on that seed, without spawning the event or writing to telemetry.
##
## Counted over `SEEDS_TO_SWEEP` seeds for each of the two rows, since one city says nothing
## about a rate — the whole reason the figure needed measuring rather than eyeballing.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEEDS_TO_SWEEP := 200

func run(t) -> void:
	print("\n== M137: how often the trap's start falls back to beside_distance() ==")
	print("| row | seeds | above/below, clear run | beside (fallback) | no clear run at all | no legal start |")
	print("|---|---|---|---|---|---|")
	_measure(t, "robber_giving_chase", 6, 1)
	_measure(t, "van_guard_giving_chase", 7, 3)

## `day`'s mark touched at `mark_step_index`, the same way the matching `_director_on_..._perform()`
## test helper reaches the perform step, then `SEEDS_TO_SWEEP` cities swept for `row_id`'s own draw.
func _measure(t, row_id: String, day: int, mark_step_index: int) -> void:
	var def := EventCatalogue.by_id(row_id)
	if not def:
		print("| %s | — | row not found |  |  |  |" % row_id)
		return
	var above_below := 0
	var beside := 0
	var no_clear_run := 0
	var no_legal_start := 0
	for seed_value in range(1, SEEDS_TO_SWEEP + 1):
		var city: City = CITY_SCENE.instantiate()
		t.add_child(city)
		city.build(CityGenerator.generate(seed_value))
		var director := ResistanceDirector.new()
		t.add_child(director)
		director.set_process(false)
		director.setup(city, city.map)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d:%d:%s" % [seed_value, day, "resistance"])
		director.start_day(day, rng, 300.0)
		director._on_contact_completed(mark_step_index)
		var her := director.contact_position()
		if her != Vector2.INF:
			var result: Array = director._draw_arrival_position(director._rng, her, def)
			var at: Vector2 = result[0]
			var clear: bool = result[1]
			var is_beside: bool = result[2]
			if at == Vector2.INF:
				no_legal_start += 1
			elif is_beside:
				beside += 1
			elif clear:
				above_below += 1
			else:
				no_clear_run += 1
		director.free()
		city.free()
	var total := above_below + beside + no_clear_run + no_legal_start
	print("| %s | %d | %d (%.1f%%) | %d (%.1f%%) | %d (%.1f%%) | %d (%.1f%%) |" % [
		row_id, total,
		above_below, 100.0 * above_below / maxf(total, 1),
		beside, 100.0 * beside / maxf(total, 1),
		no_clear_run, 100.0 * no_clear_run / maxf(total, 1),
		no_legal_start, 100.0 * no_legal_start / maxf(total, 1)])
