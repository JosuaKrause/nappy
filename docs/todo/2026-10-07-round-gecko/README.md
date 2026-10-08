priority: now

# round-gecko — The unused joystick becomes Run · filed 2026-10-07

The player's words and the question that settled release behavior are in
[dotted-sparrow](../../playtests/2026-10-07-dotted-sparrow.md), issue #602. The player asks that
"whichever joystick button is unused should turn into a run button", that its size match the
joystick, and that every button's effective radius extend 5% beyond its visible radius, except
the joystick dead zone. "The player chooses a side by using the joystick"; it is not permanent.
They chose "Keep Run visible until the player steers from the other side" and explained that
"steering can also be done by tapping so we shouldn't immediately reset".

This replaces [polite-swan's separate inward run buttons](../../decisions/2026-10-03-polite-swan.md),
which recorded the player's earlier "one on each side next to the joystick" and "Inward"
choices. It also replaces [leafy-lemur's two simultaneous heading displays](../../decisions/2026-09-27-leafy-lemur.md)
on the side showing Run. Double-tap running, heading retention after release, and a run hold
that does not steal steering remain requirements.
