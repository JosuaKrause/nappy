Reproduce on the teal-moose sweep (`tests/test_burnt_door.gd`'s fronts; seed 1 has cases) and say
which of the closures, seals or region walls cuts the remembered building off on day 8. Then make
day 8's task always reachable from home: the remembered building is used only when its door can be
reached, and otherwise the day falls back to a burnt building that can, or the day's blockers are
checked against the task's door before they are accepted (the **city** skill's "checked before
accepted"). Which of the two is the filer's question for the player if both are cheap; the fallback
already exists. A check that fails on `main` for a seed where the day cannot be won.
