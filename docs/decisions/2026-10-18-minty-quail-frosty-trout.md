# minty-quail — The live event is handed its behaviours (row 4b) · 2026-11-22

**What was asked.** The twelfth and last pull request of row 4b of minty-quail's `event-interface.md` (a row is written as
its parts): what the review of the eleventh found the row still owed, the composer's writes of the live event's behaviour
slots (twelve public fields of `EventInstance` written from `event_behaviours.gd`, the `[EventInstance]` group of
`tools/field_reads.txt`) and the two members `dead-code-sweep.md` handed to 4b. Built as #1634 by a Sonnet agent.

**What was built.** `EventBehaviours.compose()` returns one value holding the live event's behaviours, each asked by its
own method (none where the row has none) and in tick order, and `EventInstance.setup()` takes it once and keeps each
behaviour private. The tick order and the behaviours' construction are unchanged. The suites that check one behaviour
through its event ask the event's `behaviours()`, which only tests read, kept in `tools/test_only_members.txt` with the
reason its neighbours carry (row 5 gives each behaviour's suite its own fakes). `tools/field_reads.txt` lost the group
and gained nothing. **Rejected:** keeping the slots public and filled from `setup()`, which leaves ten fields only tests
read; a setter per slot (minty-dolphin #852).

**Two members deleted.** `EventDef.effect()`, which nothing called; with it the enum it answered,
`GameEnums.BlockerEffect`, which had no other reader. `EventHold.stop()`, a hold ended by
hand for a rig no rig was: its one caller, `test_prediction_reuse.gd`, reaches a hold that is over the way the game
does, by saving the event with no time left and restoring it.

**Measured.** The row fingerprint differs from main's only by the row's `effect()` line on each row, and the main
fingerprint with only that deletion applied hashes the same as the branch's; the look and excitement fingerprints print
the same but timings.

**Open to overturn:** the value's shape (one object with a method per behaviour) and the tests' `behaviours()`.

With this, row 4b's twelve pull requests are built.
