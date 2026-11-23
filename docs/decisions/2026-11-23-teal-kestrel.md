# teal-kestrel — test_event_manager's check count never moved; the name matched three suites · 2026-11-23

**What it was.** The reviews of #1650 saw `tools/test.sh test_event_manager` print different counts
in different checkouts: 1565 against 1483 on main before #1650, 912 against 827 at #1650's head,
each time about 82 more in a review agent's freshly made checkout than in a builder's worktree.

**The cause.** A suite name given to `tools/test.sh` is a substring of the suite's file name, so
`test_event_manager` runs `test_event_manager.gd`, `test_event_manager_fire.gd` and
`test_event_manager_units.gd` together, while `test_event_manager.gd` runs the one suite. The
larger count was the three suites, the smaller the one. Nothing in the suite is nondeterministic.

**The evidence.** In a fresh detached checkout of main, as its first Godot run, with no import
cache, `test_event_manager.gd` gave 827 checks, as it did again in the same checkout and in a
worktree that had run Godot before (alone five times, repeated and shuffled, and six processes
at once under load, with identical per-case counts). `test_event_manager` gave 912 there: 827 and
the two sibling suites' 85. At the commit before #1650 (d6b81dc75), where the suite was split in
the same way, the substring gave 1542 and `test_event_manager.gd` 1460, a difference of 82. A fresh
checkout and a warm one plan the same day.

**What was not changed.** Folding the per-event checks into one check per set was tried and not
kept: the count does not move, so nothing needs it. A walk of every object reachable from two
copies of the cached map (`tests/city_map_cache.gd`) found none shared.

**What to remember.** Compare counts of one suite by its file name with `.gd`; a bare name is a
filter over every suite whose file name contains it.
