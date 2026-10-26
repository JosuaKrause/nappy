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
## **`obstructs_radius` stays zero, because it closes no ground**: it drives down a carriageway she
## walks round it on. So the planners' disc, the crowd's per-tile record and the director's refusal
## of a director-sited body know nothing about it, and the body is `shape` itself, laid along the
## car's heading (`EventInstance._solid_axis()`).
##
## **What kills is not the body**: a strike area ahead of the nose, only while it drives its route,
## and only with her on the carriageway (`EventInstance.is_lethal_at()`) — a crowd car's own
## contract, the painted carriageway she chooses to step onto and a warning `Tuning.CAR_HORN_TIME`
## of its travel ahead of the strike (`EventCarDriving.closes_on()`), which `Tuning.validate_traffic()`
## holds against the time it takes to walk off the carriageway. `hard_fail` stays false: every rule
## it drives — a route wall, a field kept clear, the doubled telegraph margin — is about a place
## that ends the day, and this is a car on a road.

## **Its field is priced from its centre, a point, rather than from its body** — `shape` is the body
## and the shadow, and by default the field's datum too (`GroundShape.field_distance()`: a standing
## capsule's field is a stadium about its spine). Set on `fire_truck` alone, whose field
## `docs/COSTS.md` prices as a point's: the body it is given to be solid is not a reason for the
## street beside a parked engine to cost more, and the 340px the fire's siting check closes about
## its kerb (`EventScheduler.WalkSiting`) is then the whole of its field.
@export var field_from_its_centre := false
