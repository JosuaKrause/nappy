# calm-pelican — A door does not end the tearing slide, and the poster docs say what is checked · 2026-10-10

From the re-review of PR #593 (a held push tears every sheet she slides past, inbox #591) and PR
#585 (merry-elk, more posters, from the first day they appear).

**Built in PR #639.** `PosterWalls._push_to_tear()` keeps the slide going across a front tile that
has no poster cell — an entrance door's column, a civic portico, a fire-escape column — while her
heading still pushes into the wall (the same reach test the sheet tiles use,
`_presses_into_the_front()`); turning out of the wall, stepping back or leaving the front still
resets it. Before, the 0.4s count started again at every door and the next sheet escaped, bringing
the player's "every second poster" back. The new test slides across a gap made by erasing one cell
from the tile map (the agent's construction, open to overturn); it fails two checks on the old code.
`docs/MECHANICS.md`'s held-push paragraph names doors and walking off the front.

The poster docs and tests now say what is checked: a sheet is in view along at least 45% of the way,
pooled over the routes on the first poster day, and one route can pass as few as two sheets
(`docs/CITY.md`, the `DAWN_SHARE` comment); the day-14 floor is called a guard that also passes at
the old rates; the density message says the walls never lose a sheet by dawn and hold at least
twice day 4's by the end; a crew pastes a few of its wall's cells (`docs/EVENTS.md`); and the header
of `src/city/poster_walls.gd` points at the poster paragraph of `docs/CITY.md`. Rewording was chosen
over a per-route check, open to overturn.
