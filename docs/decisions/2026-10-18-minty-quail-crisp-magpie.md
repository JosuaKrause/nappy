# minty-quail — The power station's yard-layer case checks the station alone · 2026-11-12

**The ask.** A suite tests the one module it is named for (inbox #1159 in gray-dolphin), and the power station's suite
held a check queued to move to the frame record's suite: the station's yard layer counted as scenery
(`tests-one-module.md`, "The order", the night group).

## What was built

- **The case was two checks of two modules, and only one is held nowhere else.** That the yard layer declares the scenery draw kind
  is the station building's own behavior; that a tagged canvas counts as scenery is the frame record's, and its suite
  already checks it on a plain canvas (`_test_draws_are_counted_by_listening`), which the recorder cannot tell from the
  yard layer, since it classifies a node by that tag alone.
- **`tests/test_power_station.gd` keeps the building's half**: when the station's pictures are stood up, its yard layer
  enters the tree already carrying the scenery draw kind, the one child that does besides the roof objects the recorder
  counts by their class, with no frame record, recorder or sitting. The recorder
  half is gone as a duplicate. Moving the whole case, as the queue had it, would have had the frame record's suite
  build a real building to test the building (the review of #1418).
- **The queue item's night-group entry loses the clause that queued the move.**

## Verified

The power station's, the frame record's and the wiring suites, `tools/check.sh` and the field-read, test-only member,
layer and typing checks pass; the new check fails with the tag removed; CI is green.
