class_name OnHerWay
extends Resource
## **The day budgets the row but leaves where it stands to the walk she takes** (`EventDef.on_her_way`).
##
## A `MAP` row in every other respect — it is a place, on a tile, with a body and a field, and the
## whole plan is stated against the day's corridor exactly as it would have been at dawn. What moves
## is the moment: a one-shot is planned with no position (`EventScheduler._place_one_shots`), a
## recurring row is rolled and placed at dawn exactly as any other and then handed to her walk with
## that position dropped (`EventScheduler._hand_to_her_walk`), and
## `EventDirector.site_what_is_on_her_way()` puts it on a tile of its own ground ahead of her (a
## building face for the fire and the crews) once her direction for the day is clear, off screen and
## far enough that she meets it rather than watches it appear. Until it has been in the world it may
## be moved again, so a day she turns round is still a day it is on her way.
##
## **This is not `AHEAD_OF_PLAYER`**, which is why it is not a fourth `SpawnMode`: a director-sited
## row has no tile at all, may not obstruct, and is never asked the corridor's questions; this one
## is asked all of them, just later than dawn.
##
## Two rows carry it: day 3's fire, a one-shot, and `poster_crew`, recurring. **Only a one-shot is
## spent where it becomes real and lit at dusk if she never met it** — both are about the set piece
## a run owes, and a crew is not one.

## Whether her walk sites the row on the sidewalk in front of a blank ground-floor cell of a
## building's front, facing the wall, rather than on the side `EventDef.pavement_side` names —
## `poster_crew`, which pastes the wall it stands at (`PosterWalls`). The dawn roll still places the
## row by `pavement_side`, so the day's own stream is spent exactly as it is for any row, and only
## the walk's siting reads this.
@export var at_a_front := false
