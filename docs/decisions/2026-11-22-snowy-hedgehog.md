# snowy-hedgehog — A --walk no rig carries is refused · 2026-11-22

**What was asked.** A defect filed from the agent of #1632 (minty-quail row 4b): `--walk`, `--flee`, `--press` and
`--tap` move her only when the screenshot rig (`AutoScreenshot`) is built, which a `--screenshot`, or a frame trace, a
frame record or a recording bounded by `--after`, builds; on any other command line they were accepted and did nothing,
so a run meant to walk her stood on the doorstep. The entry gave two fixes: refuse the run, or have the flag build its own
carrier. The first was taken, the cli-tools rule that a flag a run cannot honour is rejected before any work starts.

**What was built.** `tools/lib_dev_flags.sh` refuses any of the four with no carrier on the line, beside the check that
refuses a route with a screenshot, naming the flag and what carries it; `tools/run.sh` and `tools/record.sh` call it
(only the recording script counts a bounded recording as a carrier), and `tools/shot.sh` always adds a screenshot.
`README.md`'s row says what carries the four. `tools/test_cli_help.sh` holds a refused and an accepted case for each
flag and carrier. No caller passed one of the four without a carrier. A launch of the engine that bypasses the scripts
is not checked, since the game itself is unchanged.
