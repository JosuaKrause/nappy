# Rows warned of before they exist

Read this before touching `warned_first`, `PendingWarning`, `EventSpawner.as_warned()`,
`EventManager.warn_first()` or a pursuer sent from out of her sight. The design, row by row, is
`docs/EVENTS.md`, "Everything arrives from off screen"; this file holds what the fairness contract
asks of such a row and the traps in the code.

## What the contract asks of a row warned first

**For a row warned of before it exists, "becomes visible" is its badge**, and the contract holds
`EventDef.warning_time()` — the badge to the earliest it can reach her — against
`minimum_telegraph()`, which for such a non-pursuer is the flat `Tuning.OFFSCREEN_WARNING_MIN` (a
second, the player's time to react), never a figure worked out from its field or speed — the fire
engine and day 13's column included, whose place follows her so a walk out of their field is not one
she can take during the badge. A pursuer warned first is held to `validate_pursuit` like every
pursuer: its telegraph is the approach she watches once it exists. A sent robber or guard instead
arrives chasing, with no approach: its notice is its badge alone. Running while it is offscreen
counts toward `PURSUIT_SHAKEN_OFF`, so it can be shaken off before it becomes visible (tall-owl).
`EventDef.validate()` requires that badge and validates its chase without inventing an approach.
What binds every pursuer, warned first or not (the day-3 dog's separate notice floor, the clock of
a pursuer that waited for her, verifying escape with the actual Baby meter), is `SKILL.md`, "The
telegraph fairness contract".

## From the badge to the thing

A row that arrives from off screen under the screen-edge badge is one
`EventDef.warns_before_it_exists()` answers true for: flagged `warned_first` on its row, or made so
by `EventSpawner.as_warned()`, which every warning goes through. It is a `PendingWarning` first
(`EventManager.warn_first()`; PLAYTEST-145 2): nothing in the world, the badge up at once for the
row's own `EventDef.warned_for()`, **at most `Tuning.WARNING_ALONE_MAX`** (`validate()` refuses
longer; busy-quail #569), its place fixed against her so the badge moves only with her walking and
never jumps.

Then the thing is created **just off screen** (calm-kestrel #559), where its ground has a place for
it from where she is by then: `SpawnSiting.just_out_of_sight()` puts everything it can draw
(`EventFootprints.footprint_of()`) wholly outside the camera's whole view, corners included, never
nearer than `SpawnSiting.least_distance()`. **No pop-in** (olive-hedgehog #598), and
`tests/test_no_pop_in.gd` holds it. Each kind of row has its own ground, listed in the doc; a
pursuer sent from out of her sight (the resistance's trap, the torn poster's man on foot) is one
`SpawnSiting` search under its named rules (`WarningBoard.send_from_out_of_sight()`).

- **A non-pursuer is created with its telegraph spent** (`EventManager.spawn_warned()`), since the
  warning was the telegraph.
- **A pursuer is created with its telegraph still to run**, since its telegraph is its approach —
  except one that arrives chasing (`PursuitSpec.Start.ARRIVES_CHASING`): the resistance's sent
  robber and guard, and a torn poster's pursuer on foot (olive-hedgehog #598).
- **Where its ground has no place when the warning's time has run, the warning is withdrawn**; a
  withdrawn day-3 dog is owed again.

**The warning time is the row's own number** (PLAYTEST-145 1). Nothing about where a thing is
created may be derived from its telegraph, and a row's telegraph is not shortened by shrinking its
field.

**The day-3 dog keeps its gold timing, in the player's terms**: the warning is badge to visible,
the chase is lunge to catch, and the chase has three answers, one each for her walking into the
dog, standing, and walking away from it. `tests/test_events_pursuit.gd` fails if the warning or any
of the three moves, and holds the figures. **No pursuer gives up on a walker** (olive-hedgehog #598):
every chase lasts `Tuning.PURSUIT_TIME`, a long cap, so walking away loses by construction; running
ends it at `PURSUIT_SHAKEN_OFF`'s rate.

## What is not warned first

**A patrol sent down the road and a `MAP` mover** (`military_convoy`). The patrol does not telegraph
its coming at all (slower than a walk; its strike is a car's, warned the way a car warns, see
`event-cars.md`); the planned convoy telegraphs in the world, with a badge because it is faster than
a walk, as a place the day planned, not something sent at her. **Do not add a row to this list, and
do not cite it as the reason something else is not warned first.** What stands in the way of it is
`docs/EVENTS.md`, "Everything arrives from off screen".
