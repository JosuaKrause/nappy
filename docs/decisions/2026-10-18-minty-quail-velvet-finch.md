# minty-quail — CI runs the game's tests on twelve shards · 2026-11-06


minty-quail's `ci-speed.md`, its first half: CI had grown from about 11 to 13 minutes on main, and
the player chose twelve shards over eight, for about 1.5 times the runner minutes
(brisk-moose #1130).

**Built.** `.github/workflows/ci.yml` runs twelve shard jobs, with an output and a cost slot for
each; `tools/test.sh`'s examples and the **verify** and **using-tools** sentences that named eight
shards name twelve. The per-shard kill limit comes from the plan (2.5 times its planned seconds
plus 120 s), so nothing else needed the count.

**Measured** on the pull request's run 42255143857 against main's last green run 42253762693: the
plan's estimate per shard went from about 534 s to about 356 s; the slowest shard took 529 s against
725 s, and the whole run 714 s against 766 s. Shard jobs ranged from 4m50s to 8m49s on the same
plan, so the runners' own variance sets much of the spread. The `gates` job took 10m59s and is now
the longest job of the run, which is why the run shortened by less than the shards did.

**Rejected:** keeping eight and only trimming suites, since only the shard count moves wall time
much.
