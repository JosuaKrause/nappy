# speckled-bunny — Where a standing permission has to live for the classifier to see it · 2026-11-06


**Built.** Claude Code's auto-mode classifier refused reviewer agents' approvals and a reviewer spawn
although `CLAUDE.md` gives the orchestrating session standing permission to merge. The player added the
permission to their own Claude Code settings (curly-rabbit #1094). The repository now says where such a
permission has to live: the player's Claude Code settings (`~/.claude/settings.json`'s permission allow rules
and its auto-mode environment lines), never `CLAUDE.md` or a skill, which the classifier does not read as the
player's consent; and a refusal of a write the permission covers is reported to the player naming that place,
never worked around. The wording is the filer's proposal, open to overturn.

**Where.** One paragraph in **committing**'s "Merging" (the full statement), one sentence in **pr-review**'s
"The findings go on the PR" (a refused post or reviewer spawn, pointing at **committing**), and two sentences
in `CLAUDE.md`'s standing-permission paragraph.

**Options weighed.** Stating the full rule in all three places was rejected: `CLAUDE.md` does not grow and
duplicated text drifts, so **pr-review** and `CLAUDE.md` carry the short form. A separate new skill was
rejected as too much for one rule.
