# minty-quail — Two resistance checks no test held become tests · 2026-11-19

minty-quail's `tests-public-seams.md` (its open gaps), after the events' interface for the
resistance was built (record `2026-10-18-minty-quail-curly-heron`): two behaviours of the resistance
that deleting failed nothing. Each gets a check that fails when the behaviour is removed and passes on
the code as it is, through public seams and real frames. Tests only; no behaviour changed.

**Built.**

- **The director's fallback to the map's navigator** (`tests/test_resistance_traps.gd`). A director
  handed no navigator and no siting (`ResistanceDirector.setup()`) builds its spawn siting on the
  map's own navigator, over the events' view and the streets' region. The check hands one the test
  city's parts and nothing else, hands the note over with her standing on it, and asks of the trap
  everything the city-sited handover asks (`_check_the_trap_comes_from_off_screen()`): the robber's
  warning is up with nothing in the world, and once it is over he stands just out of her sight, on
  legal ground, never waiting, and catches her where she stands.
- **The raid's wait for the patrol car's beat to be out of her view**
  (`tests/test_resistance_placement_kinds.gd`, beside the raid's other checks, which hold the real
  siting). The beat reaches further from her door than the vans stand, so a view that is the car's own
  drawing box at the beat's far end holds the car and neither van. Two premises are checked first,
  or the test would pass on the vans' check alone: neither van would be drawn in that view, and the
  car would. Then the raid holds back for a tick with her far enough from her door, and arrives the
  tick the view looks at nothing. The siting asks the box's centre and four corners, not its area, so
  a view smaller than the box that holds none of them shows nothing: the view is the box itself.

**Mutations run**, each reverted and never committed:

- Making the setup use the handed navigator alone (`var moves_by := navigator`) leaves the
  fallback siting with no navigator, and the trap's first search stops with the engine's
  "Nonexistent function 'clear_line' in base 'Nil'", so the suite fails.
- Deleting the patrol car's loop over the beat in `ResistanceHappenings._maybe_raid()` fails the
  new check's wait (the raid arrives at once); the vans' own check does not hold it back, and the
  other raid checks still pass.

**Remeasure:** nothing; no behaviour changed.
