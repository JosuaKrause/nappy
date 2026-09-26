## M180 — Posters she notices, and loudspeakers that are somewhere: seen, walled and torn · built 2026-09-23

Closes the milestone's three remaining items, on top of the masts and the poster art already
filed above. *(PLAYTEST-116 to PLAYTEST-125 record the requests; `TODO.md`'s former M180 entry
held them in full before this closed it.)*

**Four kinds of poster, on the walls.** `PosterWalls` (`src/city/poster_walls.gd`, a child of
`City`) reads every building's blank ground-floor cells (`Building.blank_ground_floor_cells()` —
never a window, door, fire escape column, storefront, portico, her home block or the power
station) and pastes a share of them every dawn from day 4, more on the streets the day's routes
use, following the progression table: rules and the leader's portrait from day 4, the curfew sheet
from day 6, the uniform sheet from day 8, the wanted notice from day 12. A new sheet usually
covers the old one exactly; a quarter of the time the old one shows through, offset 8px across and
2px up so two fifths of it is visible, and never over a sheet of the same kind. `Building.
_draw_posters()` draws them inside the building's own `_draw()`, after the plinth and before the
door and fire escapes, under every entity. `GameState.posters` (`PosterState`) is photographed and
given back with scars and block arcs, so a lost day's pastes are undone and the retry's dawn
pastes the same sheets again; it is also a saved top-level key.

**Posters are seen at all.** `poster_crew` carries `sited_on_her_way` and a new `pastes_a_front`;
`EventScheduler._hand_to_her_walk` sites one crew at a time, on a stream of its own, on the
frontage lane facing a blank wall along the day's own routes — the way day 3's fire is sited. A
crew in view has `PosterWalls` paste its wall one sheet every 2s, the first 0.8s after she sees
it, and the wall keeps those sheets for the rest of the run; the pasting pose alternates
`poster_crew_back_b.svg` with the ordinary back view every 0.8s. The day's roll and the row's cost
are unchanged. **Measured, not photographed** (`tools/test.sh probes/m180_crews_on_her_way.gd`):
**1 to 8 crews met per walk**, over three seeds and three days.

**She tears a poster down by pushing against its wall.** Her steering has to point **at least 30°
into** the postered wall (`PosterWalls.PRESS_INTO`; a diagonal push counts), her feet **within
26px** of the wall face (`PRESS_REACH`: the 22px the pram already stops her at, plus 4px), held
for **0.4s** (`PRESS_TO_TEAR`). A diagonal push slides her along the wall, and **the 0.4s count
carries across cells** while she keeps pushing — a cell-local count would make whether a diagonal
tears depend on where she happened to start, since she crosses a 32px cell in about 0.5s. The torn
sheet shows one of three tear masks, chosen by a hash of the run, the cell and the tear count, so
no RNG stream is drawn from it. **The marble bag** (`src/city/marble_bag.gd`): a pre-bag holding
one guaranteed "no pursuit" marble, then bags of one "pursuit" in ten "no pursuit", drawn without
replacement and refilled with the same set when empty, seeded from the run seed; `PosterState.
tears` is its whole state, so a save, a lost day and a retry all draw the same marbles. A pursuit
marble sends a heated `police_patrol` `TOWARD_PLAYER` down the carriageway toward her — the same
off-screen lead `owe_the_return()` uses, now one shared helper — **waiting `EventDirector.
TEAR_PATROL_AFTER` (1s of her walking)** so she has turned from the wall, and **at most one waits
at a time**; nothing is sent during the escape or under `--force`.

**Open:** the wanted notice's neighbor slot and its crossed copy are drawn (above, the poster
art), but every notice shows the neighbor's plain face until M181's day 10 (warn the neighbor
before the raid) is built.

**Open to overturn, chosen where the brief was silent:** the dawn share per act, the kind weights
and the quarter-share overpaste (`PosterWalls.DAWN_SHARE_*`, `KIND_WEIGHTS`, `OVERPASTE_SHARE`);
only south faces carry posters, since a front is a lot's only drawn face; the push thresholds
(30°, 26px) and the diagonal push carrying its count across cells; the 1s wait before a tear's
patrol is sent, and a second pursuit marble sending nothing while one patrol still waits.
