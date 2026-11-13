class_name DawnScars
extends DawnPhase
## **The scars' dawn phase**: the permanent marks earlier days left (`DawnContext.scars()`) are
## placed again exactly where they happened, each into the day's plan, unless a body of one would
## cover a tile a route runs along or the street she starts on
## (`DawnContext.keeps_the_routes()`): then it is not stood today, which is the day's routes kept
## open by construction rather than a repair taking it away afterwards. A scar holds no location:
## it stands where something happened, and the draw is spaced from it as from anything down. The
## scar of a mast she silenced names no row and is the masts' to read (`DawnMasts`). Model: no
## node.

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var day := context.day()
	var events := context.events()
	var heat := context.heat()
	for scar in context.scars():
		if int(scar["since_day"]) >= day or String(scar["id"]) == DawnMasts.SILENCED_MAST:
			continue
		var def := EventCatalogue.by_id(String(scar["id"]))
		if def:
			var plan := EventPlan.new(EventCatalogue.heated(def, heat), scar["position"])
			plan.permanent = true
			if context.keeps_the_routes(plan):
				events.add(plan)
