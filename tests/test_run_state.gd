extends RefCounted
## The run's state kept in one registered list (`RunStateRegistry` of `RunSubState` parts) — see
## docs/ARCHITECTURE.md, "The run's state".
##
## **Save compatibility is held against a file main wrote.** `tests/fixtures/
## run_state_saved_by_main.json` is `GameSave.file_data()` of the run `run_state_scenario.gd`
## builds, and of the same run after a lost day, dumped on commit e1cc7c7f — the build that kept
## every field by hand in `GameState.save_snapshot()`/`restore_snapshot()`, the `_dawn_*` copies and
## `GameSave.run_data()` — by a throwaway probe that ran the scenario under `tools/test.sh`. The
## suite replays the scenario on this build and expects the same bytes (everything but the `build`
## string), loads the fixture and expects the same run back, and loses a day from the loaded run
## and expects the same give-back.
##
## **The fixture is the old-save check and stays as it is.** It is a save written before the parts
## existed, and what it proves is that such a save still loads and gives back the same. When the
## save format next changes on purpose, this fixture is not regenerated from the new build (that
## would erase what it proves): the comparisons that no longer hold are narrowed to the keys the
## fixture holds, and a new fixture is added for the new format with its own provenance line.
##
## `run()` puts back the run it found, so nothing leaks into the next suite.

const SCENARIO := preload("res://tests/fixtures/run_state_scenario.gd")
const FIXTURE_PATH := "res://tests/fixtures/run_state_saved_by_main.json"
const _SCRATCH_PATH := "user://test_run_state_scratch.json"

## An owner holding one part, for the check that a part left off the list is caught.
class FakeOwner:
	extends RefCounted
	var part := RunHeader.new()

func run(t) -> void:
	var baseline := GameSave.file_data(GameState, false)
	GameSave.set_path_override(_SCRATCH_PATH)
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))

	_test_the_scenario_writes_what_main_wrote(t, fixture)
	_test_a_loss_gives_back_what_main_gave_back(t, fixture)
	_test_a_save_written_by_main_loads_and_resumes(t, fixture)
	_test_a_lost_day_from_a_loaded_save_gives_back_what_main_gave_back(t, fixture)
	_test_the_registry_lists_every_part_the_state_declares(t)
	_test_a_part_left_off_the_list_is_caught(t)
	_test_every_part_gives_back_what_it_photographed(t)
	_test_every_part_declares_each_field_once_in_its_data(t)
	_test_every_part_round_trips_through_json(t)

	GameSave._clear_now()
	GameSave.set_path_override("")
	GameState.start_run(1)
	GameSave.restore_run_data(GameState.run_parts, baseline)
	GameState.calendar.hard_mode = false
	GameState.calendar.checkpoint = {}

## Everything the file holds but the build that wrote it.
func _without_build(file: Dictionary) -> Dictionary:
	var kept := file.duplicate(true)
	kept.erase("build")
	return kept

func _test_the_scenario_writes_what_main_wrote(t, fixture: Dictionary) -> void:
	SCENARIO.build()
	var written: Dictionary = SCENARIO.written()
	t.check(_without_build(written) == _without_build(fixture["written"]),
			"the scenario's save is the file main wrote, key for key (%s)"
			% _first_difference(_without_build(written), _without_build(fixture["written"])))
	t.check(int(written["format_version"]) == GameSave.FORMAT_VERSION,
			"and the format version is the one the fixture was written in")

func _test_a_loss_gives_back_what_main_gave_back(t, fixture: Dictionary) -> void:
	SCENARIO.build()
	var after: Dictionary = SCENARIO.after_a_loss()
	t.check(_without_build(after) == _without_build(fixture["after_a_loss"]),
			"a lost day on the scenario leaves the file main's give-back left (%s)"
			% _first_difference(_without_build(after), _without_build(fixture["after_a_loss"])))

func _test_a_save_written_by_main_loads_and_resumes(t, fixture: Dictionary) -> void:
	GameState.start_run(5)
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture["written"]))
	file.close()
	var resume := GameSave._read_now(GameState)
	t.check(resume.get("day_under_way", false) == true, "main's save resumes, a day under way")
	t.check(_without_build(SCENARIO.written()) == _without_build(fixture["written"]),
			"and the run it gives back writes the same file again (%s)" % _first_difference(
			_without_build(SCENARIO.written()), _without_build(fixture["written"])))

func _test_a_lost_day_from_a_loaded_save_gives_back_what_main_gave_back(t, fixture: Dictionary) -> void:
	GameState.start_run(5)
	var file := FileAccess.open(_SCRATCH_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(fixture["written"]))
	file.close()
	GameSave._read_now(GameState)
	var after: Dictionary = SCENARIO.after_a_loss()
	t.check(_without_build(after) == _without_build(fixture["after_a_loss"]),
			"a day lost after resuming main's save gives back what main's did (%s)"
			% _first_difference(_without_build(after), _without_build(fixture["after_a_loss"])))

## The name of the first top-level or state key two files differ at, for a failure to say where.
func _first_difference(a: Dictionary, b: Dictionary) -> String:
	for key: String in a:
		if not b.has(key) or a[key] != b[key]:
			if key == "state" and b.has(key):
				return "state." + _first_difference(a[key], b[key])
			return key
	for key: String in b:
		if not a.has(key):
			return "missing " + key
	return "same"

## Every part `GameState` declares is on its registry.
func _test_the_registry_lists_every_part_the_state_declares(t) -> void:
	var missing := RunStateRegistry.unregistered_in(GameState, GameState.run_parts)
	t.check(missing.is_empty(), "every run sub-state GameState declares is registered (%s)" % [missing])
	t.check(GameState.run_parts.parts().size() == 7, "and the list holds the seven parts")

func _test_a_part_left_off_the_list_is_caught(t) -> void:
	var owner := FakeOwner.new()
	var registry := RunStateRegistry.new()
	t.check(RunStateRegistry.unregistered_in(owner, registry) == ["part"],
			"a part declared and never registered is named")
	registry.register(owner.part)
	t.check(RunStateRegistry.unregistered_in(owner, registry).is_empty(),
			"and not named once it is registered")

## Photographs a run, spends more of every kind of thing an attempt can spend, gives back: the run
## is what it was at the photograph, every part of it.
func _test_every_part_gives_back_what_it_photographed(t) -> void:
	SCENARIO.build()
	GameState.run_parts.photograph()
	var photographed := GameSave.run_data(GameState.run_parts)
	GameState.complete_resistance_step(9)
	GameState.fail_resistance_step(8)
	GameState.resistance.sabotage_done = not GameState.resistance.sabotage_done
	GameState.resistance.carrying_package = not GameState.resistance.carrying_package
	GameState.attempt_spend.consumed_one_shots.append("spent_after_the_photograph")
	GameState.add_scar("scarred_after_the_photograph", Vector2(1.0, 2.0))
	GameState.posters.paste(Vector2i(40, 41), 2, false, 1)
	GameState.posters.tears += 2
	GameState.pelican.draws += 4
	t.check(GameSave.run_data(GameState.run_parts) != photographed, "the attempt spent something of every part")
	GameState.run_parts.give_back()
	t.check(GameSave.run_data(GameState.run_parts) == photographed,
			"and giving back puts every part back (%s)"
			% _first_difference(GameSave.run_data(GameState.run_parts), photographed))

## A part's variables and its data keys correspond one to one: a field added to a part and not to
## its `to_data()` is the mistake the old six places made easy.
func _test_every_part_declares_each_field_once_in_its_data(t) -> void:
	for part in GameState.run_parts.parts():
		var variables := 0
		for property in part.get_property_list():
			if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
				variables += 1
		var name: String = part.get_script().get_global_name()
		t.check(variables == part.to_data().size(),
				"%s writes one key per field (%d fields, %d keys)"
				% [name, variables, part.to_data().size()])

## Each part, written through JSON and read back into a reset part, writes the same data.
func _test_every_part_round_trips_through_json(t) -> void:
	SCENARIO.build()
	for part in GameState.run_parts.parts():
		var data := part.to_data()
		var through: Dictionary = JSON.parse_string(JSON.stringify(data))
		var name: String = part.get_script().get_global_name()
		part.reset()
		part.restore(through)
		var again: Variant = JSON.parse_string(JSON.stringify(part.to_data()))
		t.check(again == through, "%s reads back what it wrote" % name)
