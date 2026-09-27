Each PR's title carries its category in brackets, `[category]`, and `tools/release-notes.py`
groups the bullets by it, with the bracket dropped from the bullet text.

**Proposed, not asked for:** where the bracket goes (a prefix, `[game] …`, so it survives the
squash as the commit subject the script already reads); the category names (`game` and `tooling`,
matching today's two sections, or more); what a title with no bracket does (falls back to today's
path rule, so the tags before this change still sort); and a check that rejects a PR title with
no known category, in CI or in the PR-opening step of **committing**. Each is the player's to
settle before this is briefed.
