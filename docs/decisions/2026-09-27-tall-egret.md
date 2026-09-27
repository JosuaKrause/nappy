# tall-egret — Each agent posts on GitHub as an app of its own, mandatorily on every write · 2026-09-27 · not from an entry


*(2026-09-27: "right now everything goes through my github account and it's basically me talking
to myself when in reality it's me and claude and other agents talking to each other. I would like
to be able to distinguish coding claude from reviewing claude from myself and from other agents" ·
"I need a nappy-claude-coder, nappy-claude-reviewer, nappy-codex-coder for now" · 2026-09-26: "I
want to create nappy-claude-coder, nappy-claude-reviewer, nappy-codex-code, and
nappy-codex-reviewer for now" — read as `nappy-codex-coder`, the name already in use · once the
four identities existed: "once that is done I want to make it mandatory for each agent to use
their respective identity when interacting with github. a reviewer app will be allowed to approve
pull requests"; asked on which commands and what an agent does when its identity is unusable, the
player answered "writes only" and chose the option "Stop and tell me" — it never posts as the
player instead, on any command.)*

**What was decided.** Each agent role posts on GitHub as a GitHub App of its own, so a pull
request shows the player, `nappy-claude-coder[bot]`, `nappy-claude-reviewer[bot]`,
`nappy-codex-coder[bot]` and `nappy-codex-reviewer[bot]` as five different authors.
`tools/agent-identity.py` creates an app through GitHub's manifest flow (`create`, run on the
player's machine, which has the browser that is logged in), checks one (`status`) and runs a
command as one (`run <role> -- ...`): it mints a one-hour installation token scoped to this
repository and sets `GH_TOKEN` plus the git author and committer to the bot's noreply address, so
`gh` posts and `git commit` records as the bot. `origin` here is an SSH remote
(`git@github.com:JosuaKrause/nappy.git`), so a push under the bot's own token cannot ride the
player's SSH key: `run` also sets `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n`/`GIT_CONFIG_VALUE_n` for
its one child process, redirecting both SSH forms of the remote to the HTTPS one and carrying the
token as a Basic `Authorization` header, never written to a config file or a URL git might echo.
The keys stay in `~/.config/nappy-agents/`, outside the repository. The reviewer apps have
`contents: write`, not read: a live probe (throwaway PR #392, into a probe branch under a
temporary ruleset requiring one approval) found a reviewer's own APPROVE left the PR
REVIEW_REQUIRED/BLOCKED under `contents: read`, and the reviewer app was refused
`resolveReviewThread` (FORBIDDEN) under that same permission; `codex-coder`'s own APPROVE, with
`contents: write`, made the PR APPROVED/CLEAN, and with `contents: write` live a reviewer resolves
its own threads too (verified: nine of `claude-reviewer`'s own threads on PR #391, each returning
`isResolved: true`). The permission changed, but a reviewer identity is still refused the named
push and merge routes: `.claude/hooks/github-write-guard.sh` denies `git push`, the pushing
`tools/` scripts, and a merge-type write (`gh pr merge`/`update-branch`, a `gh api` write to an
endpoint ending in `/merge`, `/merges` or `/update-branch`, or to a `/contents/` or `/git/refs`
path) when the wrapping role is `claude-reviewer`/`codex-reviewer`, whatever GitHub's own
permission allows — coders push and merge instead. A GraphQL mutation is not refused by name,
which is the fourth accepted gap below.

**Using their own identity is mandatory, and enforced on writes.** committing and pr-review say
which role does what: Claude Code's orchestrator and its implementation agents commit as
`claude-coder` (with `actions: write` too, live, so a wrapped `gh run rerun`/`gh workflow run` can
work — nothing else is widened), its review agents as `claude-reviewer`; Codex the same as
`codex-coder`/`codex-reviewer`. When `status` says a role is not usable, the session stops and
tells the player instead of posting as them — there is no fallback to the player's account any
more. A `PreToolUse` Bash hook (`.claude/hooks/github-write-guard.sh`) makes the rule mechanical
rather than only remembered: it denies a `git push`; a commit-making git verb (`commit`, and
`cherry-pick`/`revert`/`am`/`merge`/`rebase`/`pull` past their own abort-like or safe flag); any
`gh` noun's write verb (every noun, not only `pr`/`issue`/`release`); a `gh api` call with a
non-GET method or a field outside `-X GET`, or a GraphQL call whose query is a mutation or is not
written inline (a file, a variable, `--input`); or one of the `tools/` scripts that pushes or posts
internally (`tools/release.sh`, `tools/prune-merged.sh`, `tools/land-prs.sh`,
`tools/update-pr.sh`), only in command position — unless the same command runs through
`tools/agent-identity.py run <role> -- ...` (the hook's own header comment carries the exact,
current list, rather than a second copy of it here that can drift from it); a read (`git status`,
`gh pr view`, ...) stays unguarded. Each of those four scripts routes every one of its own GitHub
calls, reads included, through a fresh token this way too (`tools/lib_agent_role.sh`'s
`agent_run`), rather than relying on the one token the whole script may itself have been wrapped
in, since a run past the one-hour token's life must not have a later read 401 or a later write
fail; run without `NAPPY_AGENT_ROLE` set (a human at their own terminal, not an agent), a script
calls `gh`/`git` directly, exactly as it always did. `.claude/settings.json`'s allow rule for
`tools/prune-merged.sh` names the wrapped line, `uv run python tools/agent-identity.py run
claude-coder -- tools/prune-merged.sh`, rather than the bare script: the hook denies the bare
form, and a Claude Code allow rule is a literal prefix match on the command's text, so a rule for
the bare script never matched what an agent must now type. The player, asked whether to move the
rules: *"can you add it?"* There is no `codex-coder` rule: Codex's approvals are its own
sandbox's and are not read from this file, and Claude Code runs as `claude-coder`, so such a rule
would only pre-approve Claude Code running as Codex's identity. The reviewer's own review now carries GitHub's
verdict too: APPROVE when the verdict is *ready*, REQUEST_CHANGES when it is *not ready*, COMMENT
for an interim or partial review — it still never merges, which stays committing's call under its
permission rule. Merging now also needs one approving review, from a reviewer bot or the player —
the live `main approvals` ruleset exempts the player (a repository admin) on any PR they merge, not
only their own — in addition to the green `test` check. **A review thread is resolved only by
whoever opened it**, a convention and not a gate: it blocks neither an approval nor a merge, and
the live ruleset does not require thread resolution.

**Rejected.** *Machine users* (second GitHub accounts): GitHub's terms allow one free machine
account per person, which is one identity where four were asked for, and each brings an email and
2FA to keep. *Labelling on the player's account* (a role in the commit author name, a header on
each comment): GitHub still shows the player as the poster and the player still cannot approve a
PR an agent opened, so it helps a reader and not GitHub.

**What does not work, measured.** In a Claude Code cloud session `api.github.com` goes through a
proxy that serves only repository-scoped endpoints under the session's own authorization
(`GET /users/octocat` answered "This GitHub API path is not available: sessions are bound to their
configured repositories"), `gh` is not installed and there is no browser. So identities work on
the player's machine, in Claude Code and Codex alike, and a cloud session still stops rather than
posting as the player. The manifest exchange's own error paths (a rejected code, a network error)
are exercised by mocked tests only, since no container here can reach GitHub's API to provoke them
for real.

**Live, on the player's machine.** The four apps are created and installed on `JosuaKrause/nappy`,
and `status` reports all four usable. Each has posted its own comment on a pull request as its own
bot. `run claude-coder -- git commit`/`git push` records and pushes as `nappy-claude-coder[bot]` —
`git log` shows it as both author and committer with the session's own `Co-Authored-By` trailer
kept, and `gh api repos/JosuaKrause/nappy/events` shows the push event's actor as
`nappy-claude-coder[bot]`, over HTTPS even though `origin` is an SSH remote. The reviewer apps have
`contents: write` live (probe PR #392, since closed and deleted), and a reviewer app's own APPROVE
was verified there to satisfy a required approval. `main` carries two rulesets now: the original
one (a pull request required, the `test` check green) is unchanged and nobody bypasses it; a
second, "main approvals", requires one approving review, does not require thread resolution
(`required_review_thread_resolution: false`), and lets repository admins (the player) bypass it on
any PR they merge, not only their own. `require_extra_approval_for_unattributed_changes`, an
unintended default on that second ruleset, is now `false` too, matching the original ruleset's own
setting. Both rulesets, and a GitHub App's own permissions, are changed in GitHub's settings by the
player — no bot identity can make either change, so `github-write-guard.sh`'s deny message and
**committing** both say an admin action is the player's to do directly, never something to wrap and
retry.

**Accepted gaps.** The write guard is a guardrail against an agent's own ordinary mistake, not a
security boundary against a deliberately adversarial shape. Four gaps exist, each probed against
the hook with a JSON payload:

- **The wrapper's shape inside a mention exempts what follows it.** The guard reads raw text with
  quotes stripped, so `FOO="tools/agent-identity.py run claude-coder --" git push` reads as a
  wrapped push and is allowed, though the push runs as the player. Closing it means telling a
  mention from a real invocation, the parsing problem `git-grep-guard.sh` accepts rather than
  chases.
- **A write through anything but `git`, `gh` or the four pushing scripts is not seen.** `curl -X
  POST -H "Authorization: token $(gh auth token)" https://api.github.com/…`, a Python script that
  calls the API, and a GitHub MCP tool (which posts under the MCP server's own credential) all pass.
  The guard names the tools an agent uses for GitHub in this repo; it does not try to recognize
  every HTTP client.
- **The guard trusts the role a command names.** It cannot tell which agent is running, so a review
  agent that wraps a push in `run claude-coder --` (or nests that inside its own `run
  claude-reviewer --`), or a script that sets `NAPPY_AGENT_ROLE=claude-coder` itself, goes out as
  the coder. Which agent uses which role is the skills' rule; the hook enforces only that some
  bot identity is used, and that a reviewer role is refused the named push and merge routes.
- **A GraphQL mutation under a reviewer role is allowed.** `run claude-reviewer -- gh api graphql
  -f query='mutation { mergePullRequest(input:{pullRequestId:"x"}) { clientMutationId } }'`, and
  the same with `enablePullRequestAutoMerge`, pass. A reviewer needs one mutation,
  `resolveReviewThread`, to resolve its own threads, so mutations cannot be refused wholesale, and
  the guard does not keep a list of GraphQL mutation names.
