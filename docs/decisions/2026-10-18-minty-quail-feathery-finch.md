# minty-quail — The test-only member check tells a member from another class's member of the same name · 2026-11-06

**Built.** `tools/check_test_only_members.py` judged a member by its word: when another class had a
member of the same name, that class's own uses counted as the game reading it, so a member only a test
reads was never test-only, could take no `[kept]` line (it would read as stale), and its test-only read
went unseen. For a name more than one file defines publicly, the check now qualifies each `.name` by
its receiver's class where the file shows it: a name declared `x: Foo` or built `x := Foo.new()`,
`self`, a `ClassName.name`; `x: Foo.Inner` and a one-line `if c: Foo.f()` declare nothing. A reader
typed as the member's class, a class it extends or a class that extends it reaches it (a call
dispatches on the object, so a reader typed as the base reaches the override); one typed as another src
class does not; an untyped one still does (the game's, conservatively; a test's, of every class with
the name). In a file that defines the name too, only such a `.name` counts, except in an ancestor's
file, where a plain use is a call the override answers (a template method). A `[kept]` line for a
colliding name stands while all its other uses are untyped, and is a `REMOVE` once a typed reader reads
it. Names defined once are judged by word, unchanged; the output format is unchanged. `CollisionTests`
hold a colliding pair, typed and untyped reads, an override read through its base, a template method, an
inner-class type, `self`, a subclass, and the kept line.

**Measured.** On the tree the check lists 13 members it could not see before, and `Main.use_sitting`'s
line is stale: the test reads `title.use_sitting` on a `TitleScreen`, the namesake that hid it, so
`Main.use_sitting` has no reader at all. A first build that reached a member only through its own class
or a subclass listed 49: 36 were overrides the game calls through a base class (`LaneStrategy`,
`RunSubState`, `WorldContext`, `RoadClosure`, `EventLook`), found in review. CPU time of one run is
about 1.7 s against about 2.0 s for the check before (user time, three runs each; wall time varies
with the machine), each file being blanked once for the passes that read it.

**The 13** stand in the real groups of `tools/test_only_members.txt`, `[no reader]` and `[own file only]`,
so their owners' passes delete them. Two have no test reader either, `CrowdField.contains` and
`MarbleBag.take`: the tests' `.contains(` and `.take(` are `String.contains` and `EventStreaming.take` on
receivers the check cannot type, and it counts them. The two groups only shrink against the pull
request's base, except in a diff that also changes the checker, which may surface members the old one
could not see; a `[kept]` group is never a to-do list.

**Not seen yet.** `ParkCordon.gap` and `RouteTree.grow`, the proposal's motivating case, are still
hidden: only one file defines each, so they are judged by word, and a local `gap` and `Rect2.grow` calls
elsewhere hide them. A plain word in another file would count as a read only where that file's class
extends the member's class, with an engine-typed or local receiver not a src class's; that stays queued.
A declaration is typed for the whole file, not per function, so a name typed in one function and rebound
untyped in another carries the first type; no live case on the tree, and per-function scope (the
declarations of each `func` body plus the file's top-level vars) is the fix to make.

**Rejected.** Qualifying every name, not only the colliding ones: a name defined once is never in doubt
about whose it is among src classes, and typing it would turn engine members (`Node.name`) into false
readers. An autoload's name (`Telemetry.configure`) is not a src class, so it counts as untyped and
conservatively reaches every class with the name. A separate `[newly seen]` group: the two existing
groups carry the remedy.
