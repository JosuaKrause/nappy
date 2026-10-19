# minty-quail — Does Godot still crash under the agents' test runs? · 2026-10-19


If Godot's crash dialog appears again while agents run tests, note the time and which session was
running, and keep the dialog's report. The player's report that the agents kept crashing Godot
(minty-lemur #792) has no confirmed cause: the multi-suite call the PR #781 reviewer saw die with
"Message queue out of memory" did not die on `main` when it was run again with thirteen suites, and
the test runner now lets frames pass between suites, which removes the mechanism suspected. A second
crash fell inside `./tools/check.sh`, whose headless import step hides its output, so nothing of it
was seen. **Has it happened again since the test runner changed?** If not by the end of the refactor
(minty-quail), this item goes; if it has, the log of that run is the next step. The record is
`2026-10-18-minty-quail`.
