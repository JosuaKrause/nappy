# Members only their own class and the tests use become internal

**The ask.** Told that about 250 public functions are called only by their own class and the
tests, the player asked "so basically they're not part of the API but tests use them to probe the
state? so they're kind of a loophole", then said "we should add the underscore", and of the pick
that each becomes internal, its tests checking what the class does from outside, in its own pass
after the current test builds, one staying public only where nothing outside can confirm the
behavior, with its reason written down, "yes, that's cleaner" (curly-rabbit #1098). It overturns
`tests-unseen-reads.md`'s former reading that a caller in the member's own class counts as a game
caller.

**Read as:** a public member a test reads, whose only other user is the file that defines it, gets
a leading underscore, and its tests move to what the class does outward: what it draws, the plans
and events it puts in play, the world, a signal, real input and frames, or a fake handed in where
the game hands the real one. A member stays public only where nothing outward can confirm the
behavior, and its builder writes down why, in its record and beside the member's line in the CI
check's list of kept members.

*Proposed by the orchestrator, not asked for, open to the player's correction:* the rule covers
functions and variables, a public variable only its own class uses being the same probe of state,
and not constants, since a test reading a constant to assert a relationship ("the horn lasts at
least as long as the fairness floor needs") is what **verify**'s testing policy asks for. The
balance helpers `Tuning.required_horn_time()`, `required_horn_sight()` and `sleepiness_gain_calm()`
stay public for the same reason: the fairness tests check numbers against them.

**Scope.** The CI check of test-only members lists the owners one by one, and its count is the
scope; its own-file group holds no line, every member it lists being internal or kept with its
reason. What is left is the members the check cannot see, below.

**What the check still cannot see** (record minty-quail-feathery-finch): it qualifies a member by its class where a
reader's type is known when another class has a member of the same name, and a reader typed as a base class reaches an
override. A member whose name only one file defines is still judged by its word, so a local or an engine method of
that name hides it: `ParkCordon.gap` (other files have a local `gap`, so it can take no `[kept]` line, whose reason
stands as a comment on it, record minty-quail-grassy-squirrel) and `RouteTree.grow` (`Rect2.grow` calls). The check
takes a plain word in another file as a read only where that file's class extends the member's class, and an
engine-typed or local receiver as not a src class's. A declaration is taken for the whole file, not per function.
Three members have no test reader: `CrowdField.contains` and `MarbleBag.take` (the tests' reads are `String.contains`
and `EventStreaming.take`, which the check cannot type) are dead and are deleted, and `Main.use_sitting` is a hand-in
no test calls (the tests' `use_sitting()` is `TitleScreen`'s), so a test hands it in or it is deleted.

**Build**, owner by owner, after `tests-unseen-reads.md`'s builds, each owner a pull request (or
several small owners together), each also removing a check that holds nothing once its member is
gone (curly-rabbit #1097). A builder deletes the owner's lines from the CI check's list as its members turn
internal.
