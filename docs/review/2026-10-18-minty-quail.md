# minty-quail — Does Godot still crash under the agents' test runs? · 2026-10-19

If macOS's crash reporter shows Godot crashing again while agents run tests, note the time and which
session was running, and keep the report it offers. The player's report that the agents kept
crashing Godot (minty-lemur #792) counts five crashes on 2026-10-18, at 11:47, 12:57, 13:19, 15:20
and 15:46, and none has a confirmed cause. Only the last left a log: one multi-suite `tools/test.sh`
call died with "Message queue out of memory", and the same kind of call, thirteen suites on `main`,
did not die when it was run again. The test runner now lets frames pass between suites, which removes
the mechanism suspected. The 15:20 crash fell inside `./tools/check.sh`, whose headless import step
hides its output, and the three morning crashes left no trace at all. **Has it happened again since
the test runner changed?** If not by the end of the refactor (minty-quail), this item goes; if it
has, the log of that run is the next step. The record is `2026-10-18-minty-quail`.
