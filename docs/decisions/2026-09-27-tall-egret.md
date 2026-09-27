# tall-egret — Each agent posts on GitHub as an app of its own · 2026-09-27 · not from an entry


*(2026-09-27: "right now everything goes through my github account and it's basically me talking
to myself when in reality it's me and claude and other agents talking to each other. I would like
to be able to distinguish coding claude from reviewing claude from myself and from other agents" ·
"I need a nappy-claude-coder, nappy-claude-reviewer, nappy-codex-coder for now".)*

**What was decided.** Each agent role posts on GitHub as a GitHub App of its own, so a pull
request shows the player, `nappy-claude-coder[bot]`, `nappy-claude-reviewer[bot]` and
`nappy-codex-coder[bot]` as four different authors. `tools/agent-identity.py` creates an app
through GitHub's manifest flow (`create`, run on the player's machine, which has the browser that is
logged in), checks one (`status`) and runs a command as one (`run <role> -- ...`): it mints a
one-hour installation token scoped to this repository and sets `GH_TOKEN` plus the git author and
committer to the bot's noreply address, so `gh` posts and `git commit` records as the bot. The
keys stay in `~/.config/nappy-agents/`, outside the repository. The reviewer app has read-only
contents, so it cannot push. committing and pr-review say which role does what, and fall back to
the player's account when a role is not usable.

**Rejected.** *Machine users* (second GitHub accounts): GitHub's terms allow one free machine
account per person, which is one identity where three were asked for, and each brings an email and
2FA to keep. *Labelling on the player's account* (a role in the commit author name, a header on
each comment): GitHub still shows the player as the poster and the player still cannot approve a
PR an agent opened, so it helps a reader and not GitHub. *Using Approve/Request changes for the
review verdict* now that the reviewer is a separate identity: left as it is, since how a verdict
is given is the player's call and was not asked about.

**What does not work, measured.** In a Claude Code cloud session `api.github.com` goes through a
proxy that serves only repository-scoped endpoints under the session's own authorization
(`GET /users/octocat` answered "This GitHub API path is not available: sessions are bound to their
configured repositories"), `gh` is not installed and there is no browser. So identities work on
the player's machine, in Claude Code and Codex alike, and a cloud session still posts as the
player. The manifest and token paths were verified by mocked tests only, since the container
cannot reach GitHub's API; the first real `create` is the review item.
