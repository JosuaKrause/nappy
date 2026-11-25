# minty-quail's end remeasure: the escape, the run logs and GoatCounter's names (group L)

What was measured, with which trees and commands, and what each reading was. Nothing here is judged:
a number is listed beside its "before" and sized. The record `tools/decisions.sh minty-quail-cozy-rabbit`
holds what moved on purpose and what did not.

**Trees.** `head` is `f98443b5b19ddada1899c13c4d939d84049ea453` (origin/main when the measuring
started; the commit after it, `0fa36e151`, changes docs only, so every file under `src/`, `tests/`
and `tools/` is the same). `v0.29.2` is the tag, `094536ab0a34842aa4dfd523dde2191d8c6814e5`, a
detached worktree made with `tools/agent-setup.sh --detach v0.29.2 mq-r2-old` and removed with
`--remove` after. The first version of the run-log fixture is `6992c9bff85c327c47ca87c23369d0302e2147b2`.
Engine: Godot 4.7.2.stable, `/Applications/Godot.app`, headless, macOS, one run at a time
from this worktree (another builder's Godot test run was alive beside every one of these; the load
at the start of each is in `raw/*.load`; the first L2 pair's load file was not taken). No file under
`src/`, `tests/` or `tools/` was edited and no probe was copied or changed.
Head's version string in its run logs ends `-dirty` from the second pair on only because this
evidence folder was untracked in the worktree while they ran.

## L1: the escape's mix and walks

Command, in head: `ESCAPE_WINNABLE_PARALLEL=3 tools/test.sh probes/escape_winnable.gd` (24 seeds, both
exits, the game's own walker; 1,091.9 s). Run again with `ESCAPE_WINNABLE_MIX="as built"` (the
walks and the as-built plan, 1,087.9 s) to read the walks' spread. Kept: the probe's own lines,
`raw/escape_winnable.lines.txt` and `raw/escape_winnable_rerun.lines.txt`.

| Reading | Recorded after the switch (polite-tapir-coral-badger) | Head, run 1 | Head, run 2 |
|---|---|---|---|
| dangers a street | 0.66 | 0.66 | 0.66 |
| streets with none | 34% | 34% | 34% |
| trucks (military_convoy) | 181 | 181 | 181 |
| explosions (finale_explosion) | 178 | 178 | 178 |
| vans (abduction) | 89 | 89 | 89 |
| roadblocks | 46 | 46 | 46 |
| out by the tunnel | 12 of 24 | 10 of 24 (14 lost) | 10 of 24 (14 lost) |
| out by the bridge | 10 of 24 | 9 of 24 (15 lost) | 9 of 24 (15 lost) |
| mean time out, tunnel / bridge | not recorded | 59.7 s / 54.6 s | 59.7 s / 54.6 s |

The other mixes the probe plans (not walked): 5,4,3,2,1 gives 0.90 dangers a street, 10% with none
(176, 183, 223, 97); 6,5,4,3,2 gives 0.87 and 13% (175, 182, 193, 104); 0,0,0,0,1 gives 0.00 and 100%.

The two runs agree on every one of the 48 walks, outcome and time to the tenth of a second, so the
walks' spread over two runs is none. Per seed (outcome and the time it happened at; run 1, run 2
identical):

| Seed | Tunnel | Bridge |
|---|---|---|
| 4242 | LOST_HARD_FAIL 62.7s | out 40.5s |
| 1 | LOST_HARD_FAIL 25.1s | LOST_HARD_FAIL 24.6s |
| 77 | LOST_HARD_FAIL 6.0s | LOST_HARD_FAIL 5.5s |
| 9001 | out 61.6s | LOST_HARD_FAIL 60.2s |
| 23 | out 53.2s | LOST_HARD_FAIL 69.6s |
| 5 | out 67.1s | LOST_HARD_FAIL 36.5s |
| 31337 | LOST_HARD_FAIL 6.4s | out 39.8s |
| 2024 | out 53.2s | out 57.7s |
| 7 | LOST_HARD_FAIL 76.3s | LOST_HARD_FAIL 13.3s |
| 808 | LOST_HARD_FAIL 49.4s | out 50.2s |
| 4216201080 | LOST_HARD_FAIL 34.5s | out 60.1s |
| 11 | out 88.1s | LOST_HARD_FAIL 15.2s |
| 13 | LOST_HARD_FAIL 48.7s | out 68.9s |
| 17 | LOST_HARD_FAIL 49.8s | LOST_HARD_FAIL 52.7s |
| 19 | LOST_HARD_FAIL 46.8s | out 69.3s |
| 29 | out 45.6s | LOST_HARD_FAIL 38.7s |
| 31 | out 54.8s | LOST_HARD_FAIL 34.7s |
| 37 | LOST_HARD_FAIL 10.3s | LOST_HARD_FAIL 17.6s |
| 41 | LOST_HARD_FAIL 15.7s | LOST_HARD_FAIL 19.1s |
| 43 | out 58.2s | LOST_HARD_FAIL 55.5s |
| 47 | LOST_HARD_FAIL 5.9s | out 41.7s |
| 53 | out 53.2s | LOST_HARD_FAIL 37.7s |
| 59 | LOST_HARD_FAIL 22.9s | out 63.4s |
| 61 | out 62.4s | LOST_HARD_FAIL 9.6s |

## L2: the run log for the same run, v0.29.2 beside head

Each pair started together, the same flags, `--no-save --no-title`, headless:
`$GODOT --headless --path <tree> -- <flags> --no-save --no-title`, then read back from the run folder
the game prints (`tools/telemetry.sh -d` names the folder; a run folder's name carries the tree's version).

| Run | Flags | Files |
|---|---|---|
| s1 | `--seed 4242 --day 1 --route calm,home` | `raw/s1_head.log`, `raw/s1_v0.29.2.log` |
| s2 | `--seed 90303 --day 9 --route mark,task,calm,home --invincible` | `raw/s2_*` |
| s3 | `--start-escape city --seed 4242 --route tunnel` | `raw/s3_*` |
| s4 | `--start-escape --seed 4242 --route tunnel` (the building, then the city) | `raw/s4_*` |

Line counts by kind (v0.29.2 / head; `near`, `path` and `cross` follow the walk):

- s1: ahead 2/2, asleep 1/1, calm 2/2, contact 1/1, cross 6/6, crowd 4/4, cue 1/1, frame 43/43, freeze 1/0, home 1/1, left 1/1, near 7/3, path 9/9, plan 4/4, route 3/3, run 3/4, start 1/1, texture 11/11, thaw 1/0, turn 1/1
- s2: ahead 1/2, arc 8/8, asleep 1/1, calm 2/2, chase 2/2, chat 2/4, checkpoint 2/4, contact 10/10, cross 7/9, crowd 2/2, cue 5/6, frame 50/62, home 1/1, left 1/1, near 19/25, path 15/19, plan 4/4, roll 3/3, route 8/11, start 1/1, texture 11/11, turn 5/6
- s3: ahead 0/3, calm 0/1, chase 0/3, cross 0/10, cue 0/2, frame 0/62, left 0/1, lost 0/1, near 0/24, plan 1/2, route 0/2, start 1/1, taken 0/3, texture 12/12
- s4: ahead 0/3, calm 0/1, chase 0/3, cross 0/10, cue 0/4, frame 0/95, home 0/1, left 0/1, lost 0/1, near 0/37, plan 0/2, route 0/4, run 0/2, start 1/2, taken 0/3, texture 10/12

What the readings show:

- **s1, day 1, calm then home.** Same header (`day 1  act 1  run seed 4242  city seed 4242  length
  210.0s`), the same kinds of line in the same order, and the same home line (`WON`: 166.5 s to spare in
  head, 165.9 in v0.29.2). The plan events line differs by design (placement was redesigned: v0.29.2 plans
  alley_mouse x4 and market_stall x61, head no alley_mouse and market_stall x59); the walk differs with it
  (v0.29.2 meets the homeless yeller and logs `freeze` and `thaw`; head meets a leaf blower and a dog walker).
- **s2, day 9 with the chalk task.** Same arc, plan, contact, roll, chase, crowd, checkpoint and home line
  kinds; both WON with 180.0 s to spare. The events line differs by design, and head adds a `poster_crew is
  sited ahead of her` line where v0.29.2 has a `cat_dash` crossing.
- **s3 and s4, the escape.** v0.29.2 has no walker for the escape (its route rig knows the days and the
  finale's own leg): its logs end after the section's `start` line (s3 `entered the city`, s4 `entered the
  building`) and the run stops at the rig's 225 s wall-clock limit, so the walk and what follows it have no
  v0.29.2 counterpart. The first lines compare: the log header is `escape  run seed 4242  length 180.0s` in
  v0.29.2 (one for both sections) and `day 15  Escape the building ...` then `day 16  Escape the city ...` in
  head (records minty-quail-3 and -7); the finale's plan line has the same shape (625 placements in v0.29.2,
  628 in head) and head adds `plan  every unit drawn before she sets off: 32 units, 20 rows`.
  Head's walks: s3 is lost to a roadblock after 62.7 s of the city section (L1's seed 4242 tunnel walk,
  `LOST_HARD_FAIL at 62.7s`); s4's building leg ends out of the building and its city leg is lost to the same roadblock.
- **Frame lines.** The `frame` line's `physics` figure is larger in head: the mean over the frame lines of s1 is
  23.34 ms in head against 5.96 in v0.29.2 (medians 13.3 and 3.12), of s2 12.45 against 6.64 (6.34 and 2.88);
  fps means 132 and 138, 141 and 141; the worst-frame mean 30.0 and 18.4 ms, 18.1 and 16.0. The pair ran side
  by side under the same load. Whether the column measures the same thing in both trees was not established
  (head has a frame record that accounts for time in buckets, `src/telemetry/frame_record.gd`), so it is
  listed, not read as a slower game.
- **The free "before".** `tests/fixtures/observed_run_log.txt` at `6992c9bff` is a rendered run log of a
  scripted observer run (`nappy run log  (memory)`, a header per day, indented lines); at head it is a
  recording of the observer's calls (`begin_day 1 1 4242 4242 210.0`, then `<time> <kind> <text>`), so the two
  compare by their lines' text. The plan events lines differ by design; the `lost` lines carry the same
  causes in the same order (a car, crying, the homeless yeller, timeout), the `nerve` lines are the same, the
  escape's header is `escape  run seed 4242  length 180.0s` in the first and `begin_section 15 Escape the
  building 4242 180.0` in head, and the masked man's loss names `masked-pursuer`.

## L3: GoatCounter's names

- `tools/test.sh test_observers`: 27 checks, 0 failures; `tools/test.sh test_visit_counter`: 191 checks, 0
  failures (`raw/test_*.log`). Both drive the real send path through `tests/recording_page.gd`.
- The sent lists of `tests/test_observers.gd` at `6992c9bff` against head differ in one list, the escape's.
  First version: `nappy-run-fresh, nappy-escape-begun, nappy-escape-lost, nappy-day-14-blackout,
  nappy-escape-city, nappy-escape-out, nappy-ending-neutral`. Head, with the building at day 15
  (`DaySpec.BUILDING_DAY`) and the city at day 16 (`DaySpec.CITY_DAY`): `nappy-run-fresh, nappy-escape-begun,
  nappy-day-15-began, nappy-day-15-lost-hard-fail-masked-pursuer, nappy-escape-lost, nappy-day-15-began,
  nappy-day-15-won, nappy-escape-city, nappy-day-16-began, nappy-day-16-blackout, nappy-day-16-won,
  nappy-escape-out, nappy-ending-neutral`. The other sent lists (the ordinary day's, the checkpoint and
  endings', the resumed run's, the fresh run's) are line for line equal.
- The `nappy-` name literals of `src/autoload/visit_counter.gd` at v0.29.2 and at head are the same 21 strings
  and the builders are the same templates; the header doc that lists the names differs in wording and in
  the escape's paragraph (the sections counted as days 15 and 16).
- Against `docs/TELEMETRY.md`: every name it lists is a template of head's counter (`nappy-day-15-*` and
  `nappy-day-16-*` included). The two `docs/stats/` files name no `nappy-` event in a spelling head lacks.
- `task-guard` and `dog-tutorial` names already stand in v0.29.2's counter; minty-quail-17 moved which
  counts they hold (the ordinary dog's and the alley robber's counts no longer include theirs), not a spelling.
- **L4, GoatCounter's counts against `docs/stats/`, was not taken**: the live site counts released builds only,
  and nothing merged since v0.29.2 is released. Owed after a release.

## L5: the behaviors the records hold with a probe or a suite

| Reading | Recorded | Head |
|---|---|---|
| `probes/escape_stairwell_guard_trigger.gd`, seed 4242, nearest he comes on a tick (minty-quail-21) | turn-10 walk caught 22.0, run through 57.9, walk-run through 99.0; turn-11 22.5, 33.1, 24.6; turn-9 22.7, 111.8, 127.5; turn-9-left 38.0, 133.1, 135.8; door 212.5, 215.8, 256.7 px | all 15 figures and outcomes equal (`raw/probe_escape_stairwell_guard_trigger.log`) |
| `test_events_pursuit`'s 2.00 s warning | 2.07 s on the 30 Hz tick | 2.02 s for the charging dog, the roadblock and the alley robbery (290 checks, 0 failures) |
| `probes/escape_density.gd`, 10 seeds, 309 streets, the escape's own rows (minty-quail-jolly-toad) | 203 (military_convoy 67, abduction 39, roadblock 18, finale_explosion 79) | 200 (72, 37, 18, 73), planned in 310 to 387 ms a city |

## L6: not taken here

The recorded recipe's log (minty-quail-3) needs `tools/record.sh`, which opens a window: group P's.

## Reproducing

Make a tree for each side (`tools/agent-setup.sh --detach v0.29.2 <name>`, `./tools/check.sh` once in
each), then run the commands above; the run folders are under `tools/telemetry.sh -d`.
