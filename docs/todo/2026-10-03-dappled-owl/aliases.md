**A git alias does not hide a write from the guard** ([busy-ibis](../../playtests/2026-10-03-busy-ibis.md),
statement 7: "let's do A for aliases").

Today `git -c alias.ship=push ship origin v1` is allowed outright in every environment, and pushes
a release tag as the player; so are the player's own global aliases, `git ci -m wip` (`ci` is
`commit`) and `git m <branch>` (`m` is `merge`). The guard reads `-c` settings given before
`push` since #448 but not `alias.*`, and no record lists aliases as an accepted gap.

Option A, as chosen: the guard denies any `-c alias.*` setting on a git command, the way it denies
an inline `push.default=matching`; and for a subcommand it does not recognise, it asks git what the
alias stands for (`git config --get alias.<sub>`) and judges that command instead, so `git ci`
counts as the commit it is. Tests for both.

**Proposed, not asked for:** an alias that expands to a read stays allowed, and one that runs a
shell command (`!…`) is treated as unreadable and denied.
