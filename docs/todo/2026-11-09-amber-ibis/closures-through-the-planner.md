# Something holds that every street closure comes from the closure planner

The city skill's rule is that anything new that closes a street goes through the closure planner
(`ClosurePlanner`), which is what keeps every day winnable. The closure rigs check what the
planner plans, so a closure made outside it is invisible to them; the skill says the rule is
unenforced.

**Build:** a check that fails when a street is shut by anything the planner did not plan (a test
over a started day comparing the map's shut streets with the plan, or a static check for writes of
the map's closed state outside the planner), whichever the builder shows catches a planted case.
