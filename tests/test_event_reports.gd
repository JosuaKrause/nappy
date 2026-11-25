extends RefCounted
## `EventReports`, where a day's events say what happened: each teller sends the one signal it is
## named for, with the arguments it was handed, on the bus handed in (`use_bus()`), and no other.
## The one realistic mistake in that file is a teller pasted with its neighbor's signal, which
## nothing else would notice until a page counter counted the wrong thing.
##
## **Built with no scene tree and handed a recording bus of the suite's own**, never the autoload,
## so nothing else hears what it says. The live event a teller names is a bare one, never put in
## the tree: a teller only hands it on.

## The bus script, so the suite's recording bus is the class `EventReports.use_bus()` takes.
const _BUS := preload("res://src/autoload/event_bus.gd")

func run(t: TestRunner) -> void:
	_test_each_teller_sends_its_own_signal(t)

## Every teller with what it is handed and the signal it is named for: `[teller, arguments,
## signal]`. `instance` stands for the live event a teller names.
static func _tellers(instance: EventInstance) -> Array[Array]:
	return [
		["tell_event_telegraphed", [instance], "event_telegraphed"],
		["tell_event_activated", [instance], "event_activated"],
		["tell_hard_fail_triggered", ["shut_in"], "hard_fail_triggered"],
		["tell_event_sighted", ["burning_building"], "event_sighted"],
		["tell_event_lit_unmet", ["burning_building"], "event_lit_unmet"],
		["tell_player_detained", ["chatting_mother"], "player_detained"],
		["tell_poster_pursuit_sent", [], "poster_pursuit_sent"],
		["tell_pursuit_warned", ["door_guard"], "pursuit_warned"],
		["tell_pursuit_began", ["robber"], "pursuit_began"],
		["tell_pursuit_caught", ["dog"], "pursuit_caught"],
		["tell_pursuit_cut_short", ["guard"], "pursuit_cut_short"],
		["tell_pursuit_ended", ["robber", true], "pursuit_ended"],
		["tell_encounter_seen", [4, "street_musician"], "encounter_seen"],
		["tell_encounter_influenced", [5, "dog_walker", false], "encounter_influenced"],
		["tell_run_bout_began", [6], "run_bout_began"],
		["tell_pelican_spawned", [instance], "pelican_spawned"],
		["tell_pelican_sighted", [instance], "pelican_sighted"],
		["tell_pelican_excited_her", [instance], "pelican_excited_her"],
		["tell_pelican_struck_her", [instance], "pelican_struck_her"],
	]

## Listens on `bus` for `name`, a signal of `arity` arguments, appending `[name, arguments]` to
## `heard` each time it is said.
static func _listen(bus: _BUS, name: String, arity: int, heard: Array[Array]) -> void:
	var said := Signal(bus, StringName(name))
	match arity:
		0:
			said.connect(func() -> void: heard.append([name, []]))
		1:
			said.connect(func(a: Variant) -> void: heard.append([name, [a]]))
		2:
			said.connect(func(a: Variant, b: Variant) -> void: heard.append([name, [a, b]]))
		3:
			said.connect(func(a: Variant, b: Variant, c: Variant) -> void:
					heard.append([name, [a, b, c]]))

## **Each teller sends exactly the signal it is named for, with what it was handed, and nothing
## else**, on the bus it was handed: every teller is called once in turn, with every signal any of
## them sends listened for.
func _test_each_teller_sends_its_own_signal(t: TestRunner) -> void:
	var bus: _BUS = _BUS.new()
	var instance := EventInstance.new()
	var tellers := _tellers(instance)
	var heard: Array[Array] = []
	for row in tellers:
		_listen(bus, String(row[2]), (row[1] as Array).size(), heard)
	var reports := EventReports.new()
	reports.use_bus(bus)
	var declared: Array[String] = []
	for method: Dictionary in reports.get_method_list():
		if String(method["name"]).begins_with("tell_"):
			declared.append(String(method["name"]))
	var asked: Array[String] = []
	for row in tellers:
		asked.append(String(row[0]))
	declared.sort()
	asked.sort()
	t.check(not asked.is_empty() and asked == declared,
			"the table asks every teller the reports declare (%d of %d)"
			% [asked.size(), declared.size()])
	for row in tellers:
		var teller: String = row[0]
		var arguments: Array = row[1]
		heard.clear()
		reports.callv(teller, arguments)
		var expected: Array[Array] = [[row[2], arguments]]
		t.check(heard == expected, "%s sends %s with what it was handed, and nothing else (%s)"
				% [teller, row[2], heard])
	instance.free()
	bus.free()
