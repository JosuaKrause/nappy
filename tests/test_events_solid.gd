extends RefCounted
## Playtest 07, findings 16 and 13: *"none of the non-moving obstacles do anything -- I can freely
## walk over them"*, and *"I can walk over the robber and he doesn't do anything"*. The answer is a
## rule rather than a list of rows, and these are the two ways it can quietly stop being one:
## anything that stands still has to be solid, and a lethal thing still has to be reachable. Asked of
## the rows alone: no city, no live event and no day planned is built. The placements the catalogue
## produces (a parked van at the kerb, nothing on ground a route holds) are
## `tests/test_events_placement.gd`'s.

const STEP := 1.0 / 60.0

func run(t: TestRunner) -> void:
	_test_everything_that_stands_still_is_solid(t)
	_test_a_lethal_thing_can_still_be_reached(t)

## **Anything that stands still is solid.** Every exemption is named here rather than left to be
## inferred from a zero, because the failure this catches is the one that happened: a field that
## is only set where somebody remembered to set it, on five rows out of thirty, for six
## milestones.
func _test_everything_that_stands_still_is_solid(t: TestRunner) -> void:
	var checked := 0
	for def in CatalogueRows.every():
		# A moving wall pins her against a building on a two-tile pavement, which is a different
		# game from being priced out of a street. See `dog_walker`.
		if def.moves() or def.pursues():
			continue
		# Nothing checks that a thing sited out of where she happens to be walking leaves a route
		# to a park, so `EventDef.validate()` refuses a body on one outright.
		if def.spawn_mode_on(1) == EventDef.SpawnMode.AHEAD_OF_PLAYER:
			continue
		# Nothing drawn in the world, nothing to bump into: a curfew announcement carried by a mast
		# that is already solid on its own, a playground the park itself draws, the escape city's
		# explosion, whose picture is drawn only in its badge.
		if not def.look().is_drawn_in_the_world():
			continue
		# A flock is several bodies wheeling inside one disc with pavement between them, so there is
		# no silhouette for a body to be half of — and being walked into is the whole event, which a
		# body would stop at the rim. `EventDef.validate()` refuses one that obstructs.
		if def.is_a_flock():
			continue
		# The picture is drawn on the building the row stands against rather than on the sidewalk it
		# is sited on — the fire on its facade, the burnt building it leaves — so there is no
		# silhouette here for a body to be half of either. `tests/test_events_catalogue.gd` holds
		# both to having none.
		if def.id() in ["burning_building", "burnt_shell"]:
			continue
		checked += 1
		t.check(def.obstructs_within() > 0.0,
				"'%s' stands still, so it is solid" % def.id())
	t.check(checked >= 15,
			"and the rule covers most of the catalogue (%d rows)" % checked)

## **A lethal radius and a solid body are the same mechanism**, so an event carrying both can
## turn its own kill off. She is stopped `obstructs_within() + PLAYER_BODY_RADIUS` from the centre;
## if that reaches the inner radius, no amount of carelessness ever ends the day there.
##
## This is `alley_robbery`'s bug in the abstract: at an inner radius of 22 against a man 11 wide,
## the pram would have been held three pixels outside the thing that takes the baby.
func _test_a_lethal_thing_can_still_be_reached(t: TestRunner) -> void:
	var lethal := 0
	for def in CatalogueRows.every():
		if not def.ends_the_day() or def.obstructs_within() <= 0.0:
			continue
		lethal += 1
		t.check(def.obstructs_within() + Tuning.PLAYER_BODY_RADIUS < def.core_within(),
				"'%s' is solid to %.0f and lethal inside %.0f, so touching it still ends the day"
				% [def.id(), def.obstructs_within(), def.core_within()])
	t.check(lethal > 0, "and there are lethal solid things to check")

