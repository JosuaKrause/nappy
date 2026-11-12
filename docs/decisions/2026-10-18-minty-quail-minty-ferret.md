# minty-quail — The view's and the run log's test-only members go internal · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal, its tests checking what the class
does from outside, one staying public only where nothing outside can confirm the behavior, with its reason written
down (curly-rabbit #1098); a member nothing in the game reads gets a reader, is tested through what the game shows, or
is deleted (curly-rabbit #1095). This pass takes the view's and the run log's lines, the screen-edge badge aside.

## What was built

- **Deleted**: `DrawnView.forget()` (the suite lets a real frame begin after each view move), `FrameGraph.frames()` (the
  window's checks read `mean()` and `classes()`), `HelpText.line`, which its own file only wrote (tests read the label
  as it shows, the pictures recorded by an atlas handed in), and `PauseScreen.resumed`, a signal nothing listened to
  (tests read `is_open()`).
- **Private**: the save indicator's `begin()` and `settle()` (the test announces its saves on the event bus), the frame
  ledger's `keep` and `columns()`, the frame recorder's `save()` (tests read the file it writes as it leaves the tree;
  the check that a later save rewrites the same file moves to `test_frame_record`, on a path the clock cannot name), the
  run log's `lines` (tests read `recorded_lines()`).
- **Kept, with reasons on their lines**: `FrameGraph.mean()`, which exists only as an argument to the draw calls a
  headless run draws to nothing; `ModeButton.symbol`, which three scenes set by name, a read the check cannot see.
- **The queue loses `HelpText.line`** from `tests-public-seams.md`'s open list and the entry README's list.

## Verified

The builder broke each behavior and saw each moved check fail; `tools/check.sh`, the field-read, test-only member,
layer, override and typing checks and lint pass; the 27 suites naming a changed member pass; CI is green.
