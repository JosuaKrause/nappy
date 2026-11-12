# Members only their own class and the tests use become internal

**The ask.** Told that about 250 public functions are called only by their own class and the
tests, the player asked "so basically they're not part of the API but tests use them to probe the
state? so they're kind of a loophole", then said "we should add the underscore", and of the pick
that each becomes internal, its tests checking what the class does from outside, in its own pass
after the current test builds, one staying public only where nothing outside can confirm the
behavior, with its reason written down, "yes, that's cleaner" (curly-rabbit #1098). It overturns
the reading that a caller in the member's own class counts as a game caller.

**Read as:** a public member a test reads, whose only other user is the file that defines it, gets
a leading underscore, and its tests move to what the class does outward: what it draws, the plans
and events it puts in play, the world, a signal, real input and frames, or a fake handed in where
the game hands the real one. A member stays public only where nothing outward can confirm the
behavior, and its builder writes down why, in its record and beside the member's line in the CI
check's list of kept members.

*Proposed by the orchestrator, not asked for, open to the player's correction:* the rule covers
functions and variables, a public variable only its own class uses being the same probe of state,
and not constants, since a test reading a constant to assert a relationship ("the horn lasts at
least as long as the fairness floor needs") is what **writing-tests** asks for. The
balance helpers `Tuning.required_horn_time()`, `required_horn_sight()` and `sleepiness_gain_calm()`
stay public for the same reason: the fairness tests check numbers against them.

**Scope.** The CI check of test-only members lists the owners one by one, and its list is the scope: every member under
`[own file only]`, and every member under `[no reader]` apart from the lines `tests-unseen-reads.md` owns.

**What the check still cannot see** (record minty-quail-feathery-finch): a member a game reader reaches through a
receiver the check cannot type, an untyped value, a Variant, or an engine-typed value in a file whose opt-out line
silences that access's warning, counts as read. These thin out as `typed-everywhere.md` types the remaining files, and
whatever the check then lists joins the scope.

**Build.** The members named in Scope, owner by owner (or several small owners together) in a pull request each, each
also removing a check that holds nothing once its member is gone (curly-rabbit #1097). An `[own file only]` member
becomes internal, its tests moving to what the class does outward, or, where nothing outside can confirm the behavior,
takes a `[kept]` line with its reason (curly-rabbit #1098). A `[no reader]` member gets a reader in the game, is tested
through what the game shows, or is deleted, or takes a `[kept]` line where the information cannot be had another way
and the test needs it to confirm the behavior (curly-rabbit #1095). A builder deletes the member's line from the CI check's list as it goes.
