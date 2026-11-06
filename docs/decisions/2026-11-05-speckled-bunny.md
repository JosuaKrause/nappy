# speckled-bunny — Where a standing permission has to live for the classifier to see it · 2026-11-06


**Built.** Claude Code's auto-mode classifier refused reviewer agents' approvals and a reviewer spawn
although `CLAUDE.md` gives the orchestrating session standing permission to merge. The player added the
permission to their own Claude Code settings (curly-rabbit #1094). The repository now says where such a
permission has to live: the player's Claude Code settings (`~/.claude/settings.json`'s permission allow rules
and its auto-mode environment lines), never `CLAUDE.md` or a skill, which the classifier does not read as the
player's consent; and a refusal of a write the permission covers is reported to the player naming that place,
never worked around. The wording is the filer's proposal, open to overturn.

**Where.** One paragraph in **committing**'s "Merging" (the full rule, marked as the filer's proposal, with the
one-off approval distinguished and "worked around" defined), one sentence in **pr-review**'s "The findings go on
the PR" (what the repository states versus the player's settings line), and a one-sentence pointer in
`CLAUDE.md`'s standing-permission paragraph. The review of the first version narrowed the technical claims to
what Claude Code documents: the classifier does read `CLAUDE.md`, and `Agent` allow rules are dropped in auto mode.

**Options weighed.** Stating the full rule in all three places was rejected: `CLAUDE.md` does not grow and
duplicated text drifts, so **pr-review** and `CLAUDE.md` carry the short form. A separate new skill was
rejected as too much for one rule.
