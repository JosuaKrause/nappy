class_name ToldEvents
extends RefCounted
## Reports for an emitter a suite makes by hand (`EventInstance.new(reports)`,
## `EncounterWatch.new(reports)`), on the bus the suite listens on: what a manager handed that bus
## (`EventManager.use_bus()`) gives the parts and the live events it makes.

const _BUS := preload("res://src/autoload/event_bus.gd")

## Reports that go out on `bus`.
static func on(bus: _BUS) -> EventReports:
	var reports := EventReports.new()
	reports.use_bus(bus)
	return reports
