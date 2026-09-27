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
`resolveReviewThread` (FORBIDDEN) either way; `codex-coder`'s own APPROVE, with `contents: write`,
made the PR APPROVED/CLEAN. The permission changed, but a reviewer identity still never pushes:
`.claude/hooks/github-write-guard.sh` denies `git push` and the pushing `tools/` scripts when the
wrapping role is `claude-reviewer`/`codex-reviewer`, whatever GitHub's own permission allows —
coders push instead.

**Using their own identity is mandatory, and enforced on writes.** committing and pr-review say
which role does what: Claude Code's orchestrator and its implementation agents commit as
`claude-coder`, its review agents as `claude-reviewer`; Codex the same as `codex-coder` /
`codex-reviewer`. When `status` says a role is not usable, the session stops and tells the player
instead of posting as them — there is no fallback to the player's account any more. A `PreToolUse`
Bash hook (`.claude/hooks/github-write-guard.sh`) makes the rule mechanical rather than only
remembered: it denies a `git push`, a `git commit`, a GitHub-writing `gh pr`/`gh issue`/`gh
release`/`gh api` call, or one of the `tools/` scripts that pushes or posts internally
(`tools/release.sh`, `tools/prune-merged.sh`, `tools/land-prs.sh`, `tools/update-pr.sh`), unless
the same command runs through `tools/agent-identity.py run <role> -- ...`; a read (`git status`,
`gh pr view`, ...) stays unguarded. The reviewer's own review now carries GitHub's verdict too:
APPROVE when the verdict is *ready*, REQUEST_CHANGES when it is *not ready*, COMMENT for an
interim or partial review — it still never merges, which stays committing's call under its
permission rule. Merging now also needs one approving review, from a reviewer bot or the player
(the player exempt on their own PRs), in addition to the green `test` check.

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
second, "main approvals", requires one approving review, does not require thread resolution, and
lets repository admins (the player) bypass it when merging their own PR. Both rulesets, and a
GitHub App's own permissions, are changed in GitHub's settings by the player — no bot identity can
make either change, so `github-write-guard.sh`'s deny message and **committing** both say an admin
action is the player's to do directly, never something to wrap and retry.
