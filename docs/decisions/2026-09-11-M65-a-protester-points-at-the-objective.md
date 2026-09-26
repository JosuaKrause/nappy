## M65 — A protester points at the objective · built 2026-09-11

*(2026-09-03, playtest 20: "the chalk is currently unfindable I spent almost a full day searching
for it. let's make the protesters point into the direction (with their arms or something) of the
current objectives (not only chalk marks). and make the protesters more common. they're not
really an obstacle/event anyway so they can be placed independently."; 2026-09-09: "M65 we need
to revisit after M62"; 2026-09-11, the player, asked whether to build the entry as written now
that the city has walls: "the mark is findable now -- I don't think we need pointing for that.
but the other tasks are not as easy and need pointing".)* Two agent commits on
`feature/protesters-point`, reviewed here. **Protesters never point at a chalk mark**; they point
at the current objective when it is any other kind of resistance step, and wear the plain pose on
a mark day or with no step at all. The density raise stood as asked. The two findings the
milestone was opened for — the first mark announced, a mark never on screen — were M78's, and the
walled city turned out not to change what finding a mark is like.

**Pointing.** `ResistanceDirector.pointable_objective()` is the one accessor: `Vector2.INF` for a
mark pickup or no step today, otherwise the contact position read back — never a placement or a
move of its own, so M78's rules are untouched. `EventInstance._protester_texture()` picks the
nearest of the eight 45° sectors the `protester_point_*` poses were drawn for, on the compass
convention the run log already uses; the objective is pulled fresh on every redraw, since the
instance already redraws every frame, rather than pushed through `EventManager`; the director is
found through a `"resistance"` node group it now registers itself in, the pattern the baby and the
stroller already use. Every body in a protest rank shares one pose, from the rank's own bearing.
`tests/test_protest.gd` holds all eight sectors, off-centre bearings, the plain pose with no
objective and on a real day-4 mark step, and the pointing pose on a real day-5 perform step, the
last two through a live director.

**Density.** `protest.max_per_day` 6 → 12. Measured before on nine seed-and-day pairs of days 12
to 14, the row's own cap bound every time — six of six placed while the day's budget had plenty
left — and after, nine to twelve, mostly at the new cap. Weight and first day were considered and
not taken: weight draws against the shared per-attempt pool for no guaranteed gain once cap-bound,
and first day changes when protests exist rather than how many. Every other row's count is unchanged.

**Unwalked, and one thing not captured.** A screenshot of the pointing pose itself was not
reachable: a fresh boot's resistance always starts on the day-4 chalk mark whatever `--day` says,
since no dev flag pre-sets the completed steps and there is no save across processes. The evidence
capture shows the denser plain rank; the pointing is held by the suite. A dev flag that pre-sets
resistance progress would make the pointing pose capturable and is a `tools/` item if the
played verdict wants a picture first.
