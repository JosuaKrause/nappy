# minty-quail — The test-only member check judges every member by its class · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal (curly-rabbit #1098), and the CI
check of test-only members is what lists them; the queue item named what that check could not see, and the fix to make
(record minty-quail-feathery-finch).

## What was built

- **`tools/check_test_only_members.py` judges every member by its receiver's class**, using
  `tools/check_field_reads.py`'s typing of receivers (declarations, declared return types, preloaded scripts, autoloads,
  class names) over the game's and the tests' files, scoped per top-level block (a function, or a whole inner class).
  Before, a member whose name only one file defined was judged by the bare word, so a local or an engine method of that
  name counted as a game reader.
- **A game file's receiver of another class, or of an engine or builtin type, no longer counts**, except in a file whose opt-out line
  silences that access's warning, where an engine-typed value can hold a game object (`main.gd`'s
  `var _hud: CanvasLayer`). An untyped receiver still counts. A static function counts only when called through its
  class.
- **The list grows by 126 lines and loses none**, as its header allows for a change to the checker: members the check
  newly sees, 104 under `[own file only]` and 17 under `[no reader]`, and five `[kept]` lines. `ParkCordon.gap` keeps
  the reason record minty-quail-grassy-squirrel gave it, `RouteTree.grow()` the reason `tests-unseen-reads.md` gives it
  ("How a test writes game state"), and three members no test reads stand in the group for lines the check misreads,
  each with its cause: `CarTurn.centre`, `CrowdField.radius` and `FrameLedger.count`. `EventInstance.look` and
  `EventInstance.phase` are among the `[own file only]` lines; the comments on them and on `ParkCordon.gap` now say the
  list holds them.
- **A test's receiver the typing gives up on counts as one the check cannot tell**, never as reaching nothing, and the
  typing finds a test's fakes: an inner class named with a leading underscore, one reached through its outer class, a
  value through `await`, and a call inside a test's inner class is looked up on that class first.
- **Two skills' sentences are made true**: the using-tools row says the check fails a member nothing else under `src/`
  reaches, and pr-review's `references/test-only-members.md` says what the check cannot see is a member another file
  uses on a receiver the check cannot type.
- **The queue item's Scope and its paragraph on what the check cannot see are rewritten** to the list as it now stands.

## Verified

The checker's unit tests, `tools/check.sh`, the field-read, layer and typing checks and lint pass; `main`'s checker run on
this tree prints a `REMOVE` line for each new member and no `FAILED` line; CI is green.
