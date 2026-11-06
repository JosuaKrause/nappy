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

**The members the check now sees** (record minty-quail-feathery-finch): the CI check qualifies a member by its
class where a reader's type is known, so a member whose name another class shares is no longer hidden by that
namesake. The ones it newly lists, in the last `[kept]` group of the CI check's list, are `BuildingShadows.compute`,
`City.sleepiness_multiplier` and `decay_multiplier`, `CityMap.walkable_lut`, `is_crossing`, `corridor_offsets` and
`alley_at`, `MarbleBag.take`, the `photograph` and `to_data` of the run-state parts, `CarStrategy` and
`WalkerStrategy` helpers, `CrowdField.contains`, `ParkClosure.barrier_width` and `barrier_runs_across`, and others;
each is made internal, or kept with its reason, in its owner's pass, which deletes its line.

**Build**, owner by owner, after `tests-unseen-reads.md`'s builds, each owner a pull request (or
several small owners together), each also removing a check that holds nothing once its member is
gone (curly-rabbit #1097). A builder deletes the owner's lines from the CI check's list as its members turn
internal.
