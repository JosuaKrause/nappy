**The pelican comes from one shared bag of 399 cyclists and 1 pelican per run.** It replaces the
flat 1/400 roll of `EventManager.rolls_a_pelican()` (`PELICAN_SHARE`, one draw per cyclist from the
day's own `pelican` stream). The same bag serves every day of the run, so a full run meets at most
one pelican. It is kept in the standard save file, and a lost day sets it back to its state at the
beginning of that day; a new run starts a full bag.

The README's **Proposed, not asked for** has how the save keeps it (a count of cyclists drawn, as
the poster tears do) and where the draw is made. Tests: over a run, never two pelicans; a lost day
and a resumed save draw the same cyclists and pelican as the day first drew; `--pelican` still
makes every cyclist a pelican. `docs/GRAPHICS.md` ("about one cyclist in 400 is drawn instead")
and `docs/TELEMETRY.md` ("the one cyclist in about four hundred") are updated with it.
