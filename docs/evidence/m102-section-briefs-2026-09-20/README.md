# M102, the finale is the run's ending — the two section briefs

Two `tools/shot.sh` captures on `feature/m102-finale-is-the-ending`, 1280×720, `--invincible`.
Both are the screen a section *opens* on, not a retry's: the escape raises a brief before the
first walk through each section as much as after a loss, so this is the first thing a player sees
of each half.

- `brief-building.png` — `--start-escape --invincible`, 4 seconds in. The building's brief:
  *"Escape the building"* where a day's `Day N of 14` stands, `5 nerves left` under it, and the
  same continue / hold-to-restart pair every other brief carries. The clock is not running behind
  it — `FinaleController.start_section()` is reached by that continue and by nothing else — and
  the hallway she is already standing in is what shows through.
- `brief-city.png` — `--start-escape city --invincible`, 6 seconds in. The city's brief:
  *"Escape the city"*, the same nerve line, over the night street at the service exit. Reached the
  same way when she walks out of the service door, with a full clock of its own rather than
  whatever the building left.

`tests/test_finale.gd` is the actual verification — that each section opens on its brief, that the
brief is what starts the clock, that a loss comes back to the same brief with the nerves
untouched, and that the city's clock is full whatever the building spent. These two are what a
person looking at the screen sees, which a headless assertion cannot show.
