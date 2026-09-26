## Gotchas learned in M23

- **`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** Found
  by playtest 03, present since M6. `main.gd` sets it on itself so Esc quits while the summary
  has the tree paused; every descendant defaults to INHERIT, so the city, the player, the
  crowd, the events and the resistance director all inherited the exemption and
  `get_tree().paused = true` paused nothing for six milestones. The player kept walking behind
  the screen saying the day was over — and the **resistance deadline kept running out**, which
  could lose a run its good ending while somebody read a summary. Fixed with
  `main._pauses_with_the_game()`; a new node under `Main` needs that call and nothing warns
  you. Also in `CLAUDE.md`.
- **The format only gets tested by the first real question asked of it.** M23 shipped, and the
  first question put to it the next day — *did I walk down the road, and did a car go through
  me* — it could not answer. Road time was not recorded (only road entry, so walking a mile
  down the carriageway looked identical to crossing at each junction), and the crowd was
  invisible by design. Both are entries now. Reasoning about which fields would be useful is
  not a substitute for being asked something.
- **A stretch in progress when the day ends is never written down.** The `road` entry fired on
  *leaving* the road, so a player killed by the traffic they were walking among got no entry
  at all, having never left it. Anything accumulated over a span needs flushing at day end.
- **A green suite says nothing about whether a log is any good.** The observer passed every
  test and its first trace of a minute's actual walking had four defects in it: a `run` entry
  claiming a six-hundred-pixel event was "in reach", two instances of the same event that the
  log could not tell apart, a duplicated field, and — the bad one — a meter breakdown reading
  `crowd 0.0, events 0.0` while excitement climbed, because the player was doing it to
  themselves with the run button and nothing said so. This is the screenshot rule with a
  different output format, and it is now in `CLAUDE.md` next to it.
- **The breakdown has to add up or it lies by omission.** Printing the two spatial sources was
  true and useless. It prints the baby's whole incoming rate alongside them now, so whatever
  the remainder is — running, an alley — is visible as a remainder.
- **Hoisting a roll to print it is the dangerous edit.** `if rng.randf() > threshold` becoming
  `var roll := rng.randf()` is identical, and *nearly* the same edit that consumes an extra
  value and moves every event placed afterwards. `tests/test_telemetry.gd` plans all fourteen
  days twice, with the log off and on, and compares event ids and positions to the pixel.
- **Telemetry must be inert by default, not disabled by a flag.** The suite creates schedulers
  and city states directly; if the log were on by default it would write a file per check.
  `Telemetry` is dormant until `begin_run()`, which only `main.gd` calls — so the suite pays a
  boolean and the game gets a trace with no flag to remember. The observer is not even added
  to the tree when telemetry is off.
- **A roll that passes and then fails to place is invisible.** `_place_one_shots` can roll a
  one-shot in and then find nowhere to put it, in which case it is *not* consumed and gets
  rolled again tomorrow. From outside that is indistinguishable from a roll that failed, so it
  gets its own line.
- **`user://` is somewhere nobody can find.** On macOS it is inside `~/Library`, which Finder
  hides. The path is printed at the start of every run *and* `tools/telemetry.sh` exists, and
  it still took someone asking where the logs were. Neither was sufficient alone.
- **macOS ships bash 3.2, so no `mapfile`.** `tools/telemetry.sh` reads `ls -t` in a `while`
  loop instead, like the rest of `tools/`.
