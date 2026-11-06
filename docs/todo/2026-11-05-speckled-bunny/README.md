priority: now

# speckled-bunny — The skills say where a standing permission has to live for the classifier to see it · filed 2026-11-05



**The ask.** Claude Code's auto-mode classifier refused the reviewer agents' approvals of three
pull requests and refused starting a reviewer for a fourth, although `CLAUDE.md` gives the
orchestrating session standing permission to merge once the merge gates hold. Asked whether they
may post, the player answered "add standing permission", then asked "what's the problem with that
you can't spawn reviewers and let them post reviews? do I need to add standing permission for that,
too?", said "the whole point of adding the standing permission was that I *don't* have to spell it
out in the chat", and "let's add wording akin to what is in claude.md to that line as well"
(curly-rabbit #1094). The player then added the permission to their own Claude Code settings: two
allow rules for a reviewer's posts as `claude-reviewer` and one line stating the standing
permission for starting reviewers, posting verdict reviews, and merging once the gates hold, a
release still needing its own go-ahead. The band is the player's (the note's `queue_now` label).

**Read as:** the player's words are about their own settings, which they have changed. *Proposed
by the filer, not asked for:* what is left is in the repository: **pr-review** and **committing** say that a
standing permission reaches the classifier only through the player's Claude Code settings
(`~/.claude/settings.json`'s allow rules and its auto-mode environment lines), never through
`CLAUDE.md` or a skill, which the classifier does not read as the player's consent; and that a
refusal of a write the standing permission covers is reported to the player with that place named,
rather than worked around.

**Build:** the two skills' sentences, in their permission paragraphs ("Merging" in **committing**;
"The findings go on the PR" in **pr-review**), and `CLAUDE.md`'s standing-permission paragraph
gaining the same clause.
