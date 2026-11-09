# The briefs of work long finished are swept

A finished agent's brief under `.claude/briefs/` is deleted when its branch is retired. The briefs
of branches retired before that rule are not: several hundred lie there, and the same goes for
detached review checkouts under `.claude/worktrees/` whose review is long posted.

**Build:** a sweep that lists first and removes only on a second, explicit run (the retirement
script's `--all` inventory is the model): a released brief whose branch is gone, and a detached
checkout that holds no commit of its own, never one that does.
