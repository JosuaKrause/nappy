# minty-quail — The test-only member check tells a member from another class's member of the same name · 2026-11-06

**Built.** `tools/check_test_only_members.py` judged a member by its word: when another class had a
member of the same name, that class's own uses counted as the game reading it, so `Cordon.gap`-like
members were never test-only, could take no `[kept]` line (it would read as stale), and a test-only read
of them went unseen. For a name more than one file defines publicly, the check now qualifies each
`.name` by its receiver's class where the file shows it (a name declared `x: Foo` or built
`x := Foo.new()`, `self`, a `ClassName.name`), following `extends`. A reader typed as another class is
not a reader of the member; an untyped one still is (the game's, conservatively; a test's, of every
class with the name). In a file that defines the name too, only such a `.name` counts. A `[kept]` line
for a colliding name stands while all its other uses are untyped, and is a `REMOVE` once a typed reader
reads it. A name defined once is judged by its word, unchanged; the output format is unchanged. Its unit
tests (`CollisionTests`) hold a colliding pair, an untyped and a typed read, a subclass, and the kept line.

**Measured.** On the tree the check now lists 49 members it could not see, 130 listed in all, and one
line became stale (`Main.use_sitting`: the test reads `title.use_sitting` on a `TitleScreen`, the namesake
that hid it). The run takes about as long as before (a second or two).

**The new members** are in the last `[kept]` group of `tools/test_only_members.txt`, each line saying it
is the work, not an exception: the group is the only way to list them, since the other two groups only
shrink. Each owner's pass makes its members internal or keeps them with a reason, and deletes the line.
`ParkCordon.gap`, `ParkClosure.from_along` and `RouteTree.grow` named in the proposal are not among
them: no game file reads them under a namesake's cover on the current tree.

**Rejected.** Qualifying every name, not only the colliding ones: a name defined once is never in doubt
about whose it is, and typing it would only turn engine members (`Node.name`) into false readers. Flow
typing (a variable's type per function): a declaration is taken for the whole file, and a name declared
as two classes in a file is untyped. An autoload's name (`Telemetry.configure`) is not a src class, so
it counts as untyped and conservatively reaches every class with the name.
