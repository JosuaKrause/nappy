# Playtest round-egret — The run's state is made fresh and handed in, not a global

2026-11-02.

The player's words on the run's state being a global the tests share, from the Nappy board and the session, filed into minty-quail, the refactor.

## #985

1. **Context** (the assistant's):

   Answered on the Nappy board under the question "telemetry-exemptions": PR #976 (the telemetry and GoatCounter tests through public seams) makes the runner's after-each-suite leak check look into the parts the always-loaded game objects hold; it found 17 fields of the run's state (GameState) that 44 test files change and that the runner's own run reset (GameState.start_run()) puts back before the next file, and lists them as exempt by name. The question asked whether to keep that named list, have each test restore the fields, or exempt all run state with one rule.

2. **The note.**

   > why would you put a state back in a test? that doesn't sound right from the get go. the state is created fresh and injected for every test

3. **Context** (the assistant's):

   Asked on the board under telemetry-exemptions, after the orchestrator explained that GameState is still one global the whole game reads and proposed filing this note as the item that makes the run's state handed in. Answer given there: no queue item does; main-and-state (record minty-quail-22) made main take the run once and hand it down, but the autoload stayed and the carry-over for its remaining readers (events, resistance) was lost when that step closed.

4. **The player's words.**

   > which item makes the game state not a global?

5. **Context** (the assistant's):

   Asked in the session after the board exchange on telemetry-exemptions.

6. **The player's words.**

   > what is the cost of making the game state not a global?

7. **Context** (the assistant's):

   The orchestrator's answer: in the game only main takes the GameState autoload, once, and hands it down; the autoload exists so the run outlives a scene reload, which the Sitting already does for other state, so the game change is one small PR (the run moves onto the Sitting, the autoload goes). The cost is the tests: 104 test files, about 2,100 lines, read or set GameState directly, and the runner resets it between files. Proposed: one game PR first, keeping the global as a thin stand-in the tests still use; each test-conversion wave of tests-public-seams also moves its own suites onto a fresh run state handed in; the stand-in goes when the last test stops using it; the runner's reset and PR #976's 17-field exemption list go with it, and #976 skips the run's state until then. Asked whether to file this note (inbox #985) as that refactor item.

8. **The player's words.**

   > yes, do it. consider it part of the refactor

9. **The player's words.**

   > so it comes before items that were scheduled for after the refactor
