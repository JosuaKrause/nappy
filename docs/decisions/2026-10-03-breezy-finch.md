# breezy-finch — A watchdog is a timed read, not a sleep · 2026-10-03 · not from an entry


*(The player, 2026-10-03: "let's make this test less flaky")*

**A process that is waited on with a limit is watched by a timed `read` on a FIFO, never by a
`sleep` in a subshell.** `wait_or_kill` in `tools/lib_dev_flags.sh` and `run_one_process` in
`tools/test.sh` both work this way. The caller holds a FIFO open read-write on fd 9 and writes one
line to it once the watched process has exited; the watchdog is a subshell doing `read -r -t
"$limit"` on it and kills only when that read fails. The watchdog forks nothing, so nothing can
outlive the call. `run_one_process` reads twice, `$RUN_TIMEOUT_S` for TERM and 5 seconds more for
KILL, and a release in either wait ends it. `wait_or_kill` refuses a limit that is not whole
seconds (`read -t` on bash 3.2 takes only whole seconds, and a rejected read would otherwise kill
a healthy process at once), and its `9<>` redirect is on a brace group so a caller's own fd 9 is
restored afterwards.

**The cause.** The watchdog used to be `( sleep "$limit"; ...kill... ) &`, stopped with `kill
"$watchdog"`. That ends the subshell but not the `sleep` it forked, and the `sleep` held the
caller's stdout and stderr. Anything waiting for EOF on those pipes (`subprocess.run(...,
capture_output=True, timeout=20)` in `tools/test_cli_help.py`, a terminal pipeline) waited out the
whole limit. It passes when the subshell is killed before it forks the `sleep`, so it is a race
that a loaded Linux runner loses more often. Evidence: the three CI failures of
`test_trailer_playback_reaches_recipe_end_before_cutting` on `main`, runs 37133680398, 37134313496
and 37150984978, all `TimeoutExpired ... trailer.sh --shot choice timed out after 20 seconds`; a
copy of the library with a 0.5 second delay before the kill, which times out a captured call and
leaves an orphaned `sleep` with PPID 1; hundreds of orphaned `sleep`s after a stress loop of the old
code; the review's run under 2 x ncpu CPU burners, where the old library failed the test 5 of 10
times and the new one passed 20 of 20. `tools/test_cli_help.sh` carries a check that a captured call
on a 0.3 second process returns at once; it takes 7 seconds on the old code.

**Rejected: redirect the watchdog's streams and kill its `sleep` from a TERM trap.** It closed the
pipe but lost a TERM that arrives while the subshell is starting, which left the subshell alive and
the caller hanging in `wait "$watchdog"`: 2 of 6 parallel stress loops of 300 calls hung, and a
`--validate` test run hung once in about 50. A trap using `jobs -p` instead of a variable closes
one gap but not the signal that arrives before the trap exists. A redirect alone (what
`lib_movie_evidence.sh` used to do around its call) only hides the stray `sleep`, which then runs on
for the limit.

**Rejected: a trap that removes the FIFO when the caller is interrupted.** A sourced function would
have to replace the caller's own INT, TERM or EXIT trap (`tools/trailer.sh` has an EXIT trap of its
own), so an interrupted call leaves one empty FIFO in `$TMPDIR`, as it already left its marker file.

**One instance remains: `tools/measure-ground-frames.sh`**, whose `(sleep 150; kill "$child") &` has
the same shape: its `sleep` outlives the kill of its subshell and holds the caller's stdout and
stderr for the limit. It is the one watchdog of this kind that is not a timed read.
