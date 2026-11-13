class_name DawnMasts
extends DawnPhase
## **The masts' dawn phase**, one of the city's fixed parts: the run's sites
## (`DawnContext.mast_sites()`, worked out once on the city as built,
## `EventWorld.mast_sites()`), planted from `Tuning.MAST_FIRST_DAY` and standing at the same
## places every day of the run. Outside the scripted rows' dawn phase
## (`DawnScripted`) entirely — a mast is not a tile the day's own roll
## chose, it is a fixture the city already carries, the same way `DawnAmbient` hands out one
## plan per playground rather than rolling for one.
##
## **Except a day whose own closures, region wall or checkpoints need that exact tile.** `map`
## already carries today's holds and closures by the time `build_day()` runs — `EventManager.
## start_day()` populates both before calling this — so a site is skipped for the day rather
## than planted on top of a barricade or a hut: `tests/test_events.gd`,
## `_test_nothing_the_catalogue_places_stands_on_held_ground`, holds this for every row the
## catalogue places and a mast is no longer an exception to it. `MastSites` already keeps every
## site a full block off the home street and its own field off a calm interior, so this is rare
## — a closure or a wall is one street's own width, not the whole city — and it costs a day's
## worth of one mast rather than a guarantee.
##
## **And a day whose own doors it would reach.** `MastSites._reaches_a_possible_door()` already
## refuses a site near *any* boundary segment's own door position — the boundary and the wall's
## own end are fixed at generation (`RegionPlanner.assign()`), so that exclusion is as
## day-independent as the sites themselves, and it is `MastSites`' own count that shows how few
## sites it actually costs. `DawnContext.doors()` is only today's *open* doors, narrower than
## every boundary segment could ever be, so this second check is a safety net for whatever the
## siting-time exclusion cannot see (an alley door among them) rather than the rule's main work
## — see `DoorClearanceRule.clear_of_the_doors()`, the same guarantee
## `tests/test_checkpoints.gd` holds for every row.
##
## On `CURFEW_ANNOUNCE_DAY` every standing site also gets a `curfew_announce` plan alongside its
## ordinary `loudspeaker` one — see that row's own doc for why a second, invisible plan is what
## "the masts carry the announcement" means rather than a second mast.
##
## **A mast she silenced on an earlier day stands silenced**: the run's scars
## (`DawnContext.scars()`) carry a `SILENCED_MAST` entry at its foot
## (`ResistanceDirector._silence_the_mast()`), and its plans are made with `EventPlan.silenced`
## already set — the pole and horns are there, the lamp is out and there is no field, for the
## rest of the run.
##
## **So does a mast queued for day 11's task** (`EventManager.queue_a_mast()`): a
## `SILENCED_MAST` scar no site's foot is within a tile of is that mast, and it is planned again
## at its own foot, silenced, under `added_mast_id()`, on every later day whose holds, closures
## and doors leave the tile alone — the same refusals a site is planned under. One that was
## never silenced left no scar and is not planned again (*"Only if silenced"*).
##
## Each plan is recorded on the location holding it (`DawnContext.hold_fixed_part()`), so the
## draw passes over it; a mast's location on a day before the masts holds nothing and is drawn
## like any other. Model: no node.

## The day the masts carry the curfew announcement beside their ordinary broadcast: a named day
## here rather than a field read off a row, so the loudspeaker's row and the announcement's do
## not have to agree about which field means when.
const CURFEW_ANNOUNCE_DAY := 6

## The scar id a mast she silenced leaves at its foot. No catalogue row answers it, so
## `DawnScars` places nothing for it; this phase is its only reader at dawn.
const SILENCED_MAST := "silenced_mast"

## Overrides DawnPhase.run.
func run(context: DawnContext) -> void:
	var planned := _plans(context)
	context.events().add_all(planned)
	for part in planned:
		context.hold_fixed_part(part)

## The day's mast plans: a queued mast planned again from its scar, then each site's.
static func _plans(context: DawnContext) -> Array[EventPlan]:
	var day := context.day()
	var map := context.map()
	var heat := context.heat()
	var doors := context.doors()
	var scars := context.scars()
	var planned: Array[EventPlan] = []
	if day < Tuning.MAST_FIRST_DAY:
		return planned
	var loudspeaker := EventCatalogue.heated(EventCatalogue.mast(), heat)
	var curfew := EventCatalogue.heated(EventCatalogue.by_id("curfew_announce"), heat) \
			if day == CURFEW_ANNOUNCE_DAY else null
	var sites := context.mast_sites()
	for scar in scars:
		if String(scar["id"]) != SILENCED_MAST or int(scar["since_day"]) >= day:
			continue
		var foot: Vector2 = scar["position"]
		var at_a_site := false
		for site in sites:
			if site.foot.distance_to(foot) < Tuning.TILE_SIZE:
				at_a_site = true
				break
		var tile := map.world_to_tile(foot)
		if at_a_site or map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(foot, PackedVector2Array(), doors,
				loudspeaker.field_reach()):
			continue
		var added := EventPlan.new(loudspeaker, foot)
		added.mast_id = added_mast_id(foot)
		added.silenced = true
		planned.append(added)
	for site in sites:
		var tile := map.world_to_tile(site.foot)
		if map.is_closed(tile) or map.is_held_at(tile) or map.is_on_home_block(tile):
			continue
		if not DoorClearanceRule.clear_of_the_doors(site.foot, PackedVector2Array(), doors,
				loudspeaker.field_reach()):
			continue
		var quiet := _was_silenced(site.foot, day, scars)
		var mast := EventPlan.new(loudspeaker, site.foot)
		mast.mast_id = site.id
		mast.silenced = quiet
		planned.append(mast)
		if curfew:
			var announcement := EventPlan.new(curfew, site.foot)
			announcement.mast_id = site.id
			announcement.silenced = quiet
			planned.append(announcement)
	return planned

## The id of a mast queued for day 11's task at `foot` (`EventManager.queue_a_mast()`), the same
## every day it is planned again from its scar, and never a `MastSites` site's own id.
static func added_mast_id(foot: Vector2) -> String:
	return "added-%d-%d" % [roundi(foot.x), roundi(foot.y)]

## Whether a `SILENCED_MAST` scar from an earlier day stands at `foot` — within a tile, since the
## foot a scar records and the foot a site computes are the same point read twice.
static func _was_silenced(foot: Vector2, day: int, scars: Array[Dictionary]) -> bool:
	for scar in scars:
		if String(scar["id"]) == SILENCED_MAST and int(scar["since_day"]) < day \
				and (scar["position"] as Vector2).distance_to(foot) < Tuning.TILE_SIZE:
			return true
	return false
