# dappled-owl — The write guard sees through aliases, and only a reviewer approves · 2026-10-12

[busy-ibis](../playtests/2026-10-03-busy-ibis.md), statements 6 to 9: "let's do A for aliases. env
was chosen because it's set by the session and not directly. but even with tricks like updating the
settings all it will do is prompt the command to me anyway. we can prevent approvals from
non-reviewers." The gaps were found by the after-the-fact reviews of #448 and #424. The guard is
`.claude/hooks/github-write-guard.sh`; its tests are `tools/test_rules_hooks.sh`.

**Aliases (option A).** Before reading a command the guard asks git for its aliases in the session's
directory (the hook payload's `cwd`), and for git's built-in commands only when there is an alias. A
subcommand that is an alias and not a built-in is judged as what it stands for, following chains:
`git ci` is a commit, `git m` a merge, `git st` stays a read. A `!` alias, an empty one, a loop, or
one that opens with git's own options is denied, a reviewer's wrapper included, and so is any
`-c alias.*` or `--config-env alias.*` setting, in every spelling. Every guard test runs under a
pinned global git config with no system config, so the player's own aliases cannot change a result;
the Codex adapter's tests are pinned the same way. `tools/codex-hooks.py` needed no change: it
already passes `cwd` through, and a test proves an alias there is read. *Open to overturn, chosen by
the implementer:* an unknown subcommand that is not an alias is read as written; aliases are looked
up in the session's directory, not a `-C` one; a mere mention of an alias (`echo git ci`) is denied
like any mention of a write. Accepted gaps, named in the guard's header: an alias defined earlier in
the same command, one in another repository named by `-C`, and one from `-c include.path` or the
environment.

**Only a reviewer approves.** An approving review is denied unless it runs wrapped as
`claude-reviewer` or `codex-reviewer`: `gh pr review` with `--approve`, `-a` or a short-flag group
starting with `-a`; a `gh api` POST to a pull request's reviews or a review's events whose event is
APPROVE or cannot be read (from a file, a variable, or `--input`); a GraphQL review mutation naming
APPROVE; and a review whose flags `xargs` or `parallel` input could supply. A comment, a request for
changes and a pending review stay open to every identity. This narrows the tall-egret record's third
accepted gap: the guard enforces that some bot identity is used, that a reviewer role is refused the
named push and merge routes, and that only a reviewer role approves. **committing** says so.
*Open to overturn, chosen by the implementer:* an `-a` or APPROVE anywhere later in the same command
counts as an approval, so an unrelated later `ls -a` after a coder's comment review is denied; on a
review endpoint, input that could add flags refuses a reviewer too, since it could turn the call
into a merge. Accepted gap: a GraphQL review whose query or event cannot be read.

**The asking switch's reason.** The guard's comment on `NAPPY_ASK_FOR_PLAYER_WRITES` says the session
sets it; that switched on any other way, such as a settings file an agent can write, it only turns
each ordinary write into a prompt for the player; and that leaving it alone is **committing**'s rule,
not something the hook enforces. This replaces the frosty-pelican record's reason, that "a command an
agent runs cannot change the environment its hooks are started in, while a file it can write".

**Two reads settled.** `git -C $(git rev-parse --show-toplevel) log | grep merge` reads again: a git
whose options hold an unquoted substitution counts only write words inside its own command, not in
the rest of the line (counting only command position would have let `git $(echo …) origin v1`
through). So the frosty-pelican record's example of a `status` denied for a later write in the same
line no longer holds. `git rebase --show-current-patch` reads. The dry runs of a push and a commit
stay accepted false denies, named in the guard's header, since misreading one would be a write as
the player.

**Verified** by the guard's whole test file before and after every item, and the Codex adapter's
tests, also under the host's `/usr/bin/python3`; nothing denied before is let through. A 64 KB `git
-c` chain stays inside the hook's timeout, under timed tests. The guard's test file takes about 8 to
9 minutes rather than 6, since each case that names git makes one or two `git` calls.

**For any agent working on the guard:** it denies a Bash command whose text mentions a write,
heredocs and test strings included, so edit scripts go in a file and run from there.
