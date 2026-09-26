## M8 — Resistance subquest · `feature/resistance`

- [x] Chalk marks, drawn under everything that stands on them. No marker, no quest log.
- [x] Hold-to-interact with decay when you let go or walk away
- [x] All 6 steps, as a data table
- [x] Robbery-vs-contact alley roulette, seeded from run seed + day
- [x] Seen-by-patrol resets the hold *(changed from the planned progress penalty — see
      docs/NARRATIVE.md for why)*
- [x] Timed step failure (contact lost permanently for the run)
- [x] Resistance tally in the day summary; one terse HUD line otherwise
- [x] The good ending needs the goal **and** the day-14 sabotage
- [x] `tests/test_resistance.gd` (66 checks)
- [x] Dev flag: `--spawn contact`

### Notes

- `GameState.day_rng()` takes a `stream` now. Without it the events and the resistance
  would both start from the same day seed and their first rolls would move together.
- Building the step table with `set(key, value)` from a Dictionary silently DROPPED every
  `Array[int]` placement list — `set()` does not report a type mismatch — so three of the
  six steps had nowhere to go, with no error anywhere. It is an explicit factory now.
