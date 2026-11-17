# The test runner sets the engine's frame sleep once, if it pays

*Proposed, not asked for:* measure whether the frame sleep slows the other tick-driven suites (the
ones that walk her or let a day run), by timing a handful of them with and without the lowered sleep.
If it pays, the runner (`tools/test.sh` and what it starts) sets it once for every suite, and the
one suite that sets it itself stops doing so. If it does not, the finding goes into a record and the
entry closes. A suite's result must not change with the sleep: only its wall time may.
