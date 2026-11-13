class_name DawnAmbient
extends DawnPhase
## **The ambient rows' dawn phase**, the first of the city's fixed parts (the design's "the
## city's fixed parts have phases of their own", `docs/EVENTS.md`, "The three views and the
## placement order"): every ambient row of the day stands where its source is, one plan for each
## playground (`EventDef.AmbientSource.PLAYGROUND`), at the playground's middle. Nothing is
## rolled, and each plan is recorded on the location holding it
## (`DawnContext.hold_fixed_part()`), so the draw passes over it. Model: no node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var planned := _plans(context)
	context.events().add_all(planned)
	for part in planned:
		context.hold_fixed_part(part)

## The day's ambient plans, one for each source of each ambient row.
static func _plans(context: DawnContext) -> Array[EventPlan]:
	var map := context.map()
	var planned: Array[EventPlan] = []
	for def in EventCatalogue.of_kind(GameEnums.EventKind.AMBIENT, context.day(), context.heat()):
		match def.ambient_source:
			EventDef.AmbientSource.PLAYGROUND:
				for rect in map.playgrounds:
					planned.append(EventPlan.new(def, map.tile_rect_to_world(rect).get_center()))
			_:
				pass
	return planned
