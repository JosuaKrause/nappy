class_name VehicleSpec
extends Resource
## **A car: solid at its own `shape` in every state, and lethal only in front of it while it
## drives.** *(azure-koala, inbox #601: "police cars don't have a hitbox"; leafy-puffin, inbox
## #648, offered "solid in every state, lethal only in front while driving": "yes to the police car
## hitbox".)* `police_patrol` and every copy of it carry one, and so does `fire_truck`
## *(calm-kestrel, inbox #558: "Lethal driving, solid parked")*.
##
## **These are the only bodies that move, and the spec answers the reason a moving thing is
## otherwise exempt from being solid** — a moving wall pins her. `EventInstance` never moves the
## body into her: a step or a turn that would bring it into contact with her or her pram is refused
## and the car stands where it is until she moves, a car stopping for her rather than a wall
## shoving her. She is stopped by it the way she is stopped by anything solid, and nothing follows
## her into a wall.
##
## **`obstructs_within()` stays zero, because it closes no ground**: it drives down a carriageway she
## walks round it on. So the planners' disc, the crowd's per-tile record and the director's refusal
## of a director-sited body know nothing about it, and the body is `shape` itself, laid along the
## car's heading (`EventInstance.solid_axis()`).
##
## **What kills is not the body**: a strike area ahead of the nose, only while it drives its route,
## and only with her on the carriageway (`EventInstance.is_lethal_at()`) — a crowd car's own
## contract, the painted carriageway she chooses to step onto and a warning `Tuning.CAR_HORN_TIME`
## of its travel ahead of the strike (`EventCarDriving.closes_on()`), which `tests/test_tuning_fairness.gd`'s traffic check
## holds against the time it takes to walk off the carriageway. it never ends the day: every rule
## it drives — a route wall, a field kept clear, the doubled telegraph margin — is about a place
## that ends the day, and this is a car on a road.

## **It holds no setting of its own**: its presence on a row is the car that drives. Whether its field is
## priced from its centre rather than from its body is the field's (`FieldSpec.from_its_centre()`,
## `fire_truck` alone).

## A car that drives.
static func driving() -> VehicleSpec:
	return VehicleSpec.new()
