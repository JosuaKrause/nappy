**A shared marble bag.** A bag with marbles of its own that "can appear in regular bags multiple
times": each time a regular bag draws it, a marble is drawn *from* the shared bag and that is the
draw's answer. When the shared bag runs empty it is refilled, which is what sets it apart from the
nested bag, whose inner bag of n is spent after n draws and never comes back.

Built in `MarbleBag` (`src/city/marble_bag.gd`) beside the nested bag, with its own stream so a
run's draws stay reproducible from its seed, and with tests that a shared bag appearing several
times in one regular bag, and in more than one regular bag, is drawn from as one bag, and that it
refills when empty. What happens to the shared-bag marble itself once drawn is under the README's
**Proposed, not asked for**.
