Each PR's title carries its category in brackets, `[category]`, and `tools/release-notes.py`
groups the bullets by it, with the bracket dropped from the bullet text.

**The bracket is a prefix.** Asked on the board (release-categories) how a PR title says which
section of the release notes it goes in, with the work built on the orchestrator's pick (a
`[game]` or `[tooling]` prefix, which survives the squash as the commit subject), the player:
"how about labels? I guess they don't survive squash merges? in that case prefix, yes"
(gentle-owl #1241). **Read as:** a prefix, `[game] …`, since a pull request's labels live on GitHub
and never reach the squashed commit, and `tools/release-notes.py` computes the notes from git
alone, with no network call. *Read as, open to correction:* the names `game` and `tooling` come
with the pick the player accepted, matching today's two sections.

**Proposed, not asked for:** what a title with no bracket does (falls back to today's path rule,
so the tags before this change still sort); and a check that rejects a PR title with no known
category, in CI or in the PR-opening step of **committing**. Neither waits for the player before
this is built, since only a question very costly to pivot on blocks (inbox #1194 in gentle-owl),
and draft pull request #1215, paused for the refactor, is built on these picks (the prefix and the
fallback; no title check). Each is open to the player's correction.
