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
`-c alias.*` or `--config-env alias.*` setting in every spelling, and its environment spelling: a
`GIT_CONFIG_KEY_<n>` assignment naming `alias.` (or one an expansion supplies), or any
`GIT_CONFIG_PARAMETERS=`, before the git. When git's own options hold an unquoted substitution or a
backtick, an alias that stands for a write, or cannot be read, counts as a write inside that git's
command, and a git whose subcommand cannot be read counts as a push, so a reviewer's
`git -C $(pwd) push` is refused too. Every guard test runs under a pinned global git config with no
system config, so the player's own aliases cannot change a result; the Codex adapter's tests are
pinned the same way. `tools/codex-hooks.py` needed no change: it already passes `cwd` through, and a
test proves an alias there is read. *Open to overturn, chosen by the implementer:* an unknown
subcommand that is not an alias is read as written; aliases are looked up in the session's
directory; a mere mention of an alias (`echo git ci`) is denied like any mention of a write.
**Accepted gap**, named in the guard's header: an alias in any config git reads from somewhere other
than the session directory's own — after a `cd`, under `-C` or `--git-dir`, with `GIT_DIR=`,
`GIT_CONFIG_GLOBAL=`, `HOME=` or `XDG_CONFIG_HOME=`, through `include.path`, from the inherited
environment, or in Codex's `workdir`, which the adapter drops — and one defined earlier in the same
command.

**Only a reviewer approves.** An approving review is denied unless it runs wrapped as
`claude-reviewer` or `codex-reviewer`: `gh pr review` with `--approve`, `-a`, a short-flag group
starting with `-a`, or any word holding `$` or a backtick, which an expansion could turn into one; a
`gh api` POST to a pull request's reviews or a review's events whose event is APPROVE or cannot be
read (from a file, a variable, or `--input`), a `%`-encoded path under `pulls` included; a GraphQL
review mutation naming APPROVE, or with its event or another field read from a file or an
expansion; a `gh alias set` that names a review or holds an expansion, and every `gh alias import`;
and a review whose flags `xargs` or `parallel` input could supply. A comment, a request for changes
and a pending review stay open to every identity; a coder's review body goes in with `--body-file`,
since `--body "$(cat f)"` holds an expansion. This narrows the tall-egret record's third accepted gap:
the guard enforces that some bot identity is used, that a reviewer role is refused the named push and
merge routes, and that only a reviewer role approves. **committing** says so. *Open to overturn,
chosen by the implementer:* an `-a`, APPROVE, `$` or `review` later in the review's own command
counts as an approval; on a review endpoint, input that could add flags refuses a reviewer too, since
it could turn the call into a merge. **Accepted gaps:** a GraphQL review whose mutation cannot be
read, an endpoint an expansion supplies, a gh alias already in gh's config before the session, and
clients other than gh.

**The asking switch's reason.** The guard's comment on `NAPPY_ASK_FOR_PLAYER_WRITES` says the session
sets it; that switched on any other way, such as a settings file an agent can write, it only turns
each ordinary write into a prompt for the player; and that leaving it alone is **committing**'s rule,
not something the hook enforces. This replaces the frosty-pelican record's reason, that "a command an
agent runs cannot change the environment its hooks are started in, while a file it can write".

**Two reads settled.** `git -C $(git rev-parse --show-toplevel) log | grep merge` reads again: a git
whose options hold an unquoted substitution counts only write words inside its own command, not in
the rest of the line, and where the command's parentheses do not pair, the span runs to the end of
the command, as before. So the frosty-pelican record's example of a `status` denied for a later write
in the same line no longer holds. `git rebase --show-current-patch` reads only as rebase's one
argument. The dry runs of a push and a commit stay accepted false denies, named in the guard's
header, since misreading one would be a write as the player.

**Verified** by the guard's whole test file before and after every item and every review fix, and
the Codex adapter's tests; nothing the guard denied before is let through, and every probe of the
review that it still allows is allowed on `main` too or is a named gap. The densest 64 KB command
takes about 5 s against about 4 s before, inside the hook's 10 s timeout, under timed tests; the
guard's test file takes about 8 to 9 minutes rather than 6.

**The guard fails closed, and passes no long text as an argument.** CI on Linux found two 64 KB
commands allowed: their joined findings went to `jq` as one argument, which Linux refuses over 128 KB
and macOS does not, and a hook that prints nothing lets the command through. The jq program, git's
alias table and the reason now go in through a file or stdin, and the flagged list is capped. When
jq cannot print the answer, a fixed deny is printed instead; when jq is missing, a command that names
git, gh or a pushing script is denied and anything else is let through, so installing jq stays
possible. Both were open on `main` before. The tests shim jq and git to refuse an argument over
128 KB, as Linux does, and force each failure. `.claude/hooks/git-grep-guard.sh` has the same two
patterns and is not changed here.

**For any agent working on the guard:** it denies a Bash command whose text mentions a write,
heredocs and test strings included, so edit scripts go in a file and run from there.
