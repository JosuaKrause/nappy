extends RefCounted
## `ResistanceHappenings`, what the resistance's story puts in the street besides the task, checked
## with no city: the happenings are handed a stand-in for the day's events (`FakeEventManager`) and
## for the fronts the story changes (`FakeCityFronts`), as `ResistanceDirector.setup()` hands them
## the city's, and a run of the suite's own.
##
## The map is a generated one (`CityGenerator.generate()`), handed as data: the raid stands at her
## building, which only a generated map has (a home, its doorstep and the street in front of it). No
## siting is handed, which the happenings read as none (`setup()`), so what holds the raid back here
## is her distance from her door alone; the view's own refusal is checked with the city's siting in
## `tests/test_resistance_placement_kinds.gd`, as is the real door's picture once sealed.

const SEED := 4242
## The seed of the suite's own run.
const RUN_SEED := 2
const STEP := 1.0 / 60.0

func run(t) -> void:
	_test_the_raid_seals_her_street_door(t)

## Her street door: ordinary at day 10's start, sealed the moment the raid actually arrives, out
## of her sight (PLAYTEST-131), and the scar it leaves is what every later day and a reloaded save
## read it from (`City._sync_home_door()`).
func _test_the_raid_seals_her_street_door(t) -> void:
	var map := CityGenerator.generate(SEED)
	var run_state := RunState.new()
	run_state.start_run(RUN_SEED)
	run_state.header.day = ResistanceHappenings.NEIGHBOR_DAY
	var events := FakeEventManager.new()
	var fronts := FakeCityFronts.new()
	var happenings := ResistanceHappenings.new()
	happenings.setup(map, run_state, events, DayStreets.new(), fronts, null, null)
	happenings.start_day(ResistanceHappenings.NEIGHBOR_DAY)
	t.check(fronts.seals() == 0, "the door is ordinary at day 10's start")
	var door := map.doorstep_world_position()
	happenings.tick(STEP, door + Vector2(0.0, Tuning.OUT_OF_SIGHT + 64.0), Vector2.ZERO)
	t.check(fronts.seals() == 1, "and sealed the moment the raid arrives, out of her sight")
	var sealed := false
	for scar in run_state.attempt_spend.scars:
		if String(scar["id"]) == City.SEALED_DOOR_SCAR:
			sealed = true
	t.check(sealed, "which leaves a scar for every later day to read")
	events.free()
