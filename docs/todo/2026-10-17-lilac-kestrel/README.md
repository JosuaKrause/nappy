priority: now

# lilac-kestrel — Skills and CLAUDE.md link the player's words instead of quoting them · filed 2026-10-17

[woolly-penguin](../../playtests/2026-10-17-woolly-penguin.md), #759:

> where is the playtest recording my words? recording my words inside the skill are not very useful, no?

> keeping quotes in skills and claude files is just distracting -- just do short links to the actual quote files

> that's a rule
>
> things must stay clean

> it's the job of the reviewer to establish that the interpretation is correct. once that is established we don't have to do it on *every* read of the file

**The rule asked for.** `CLAUDE.md` and the skills under `.claude/skills/` state their rules without
quoting the player; where a rule rests on the player's words, it carries a short link to the playtest
file that records them, and the words themselves live only there. That is a rule of its own, written
into `CLAUDE.md`, and every quote already in `CLAUDE.md` and the skills becomes such a link.

**What it keeps.** The playtest files stay the primary source and are never rewritten; a quote whose
words are in no playtest yet (said in a session, or recorded only in a record under
`docs/decisions/`) links to wherever they are recorded. A quote was there to show the rule reads the player right; that is
established once, by the review of the change that wrote the rule, so a reader does not re-check it.
The reason a rule exists is still said in the skill, in the skill's own words.

*Proposed, not asked for:* the band `now`; the records under `docs/decisions/`, which are history,
keep their quotes; the form of a link (`[name](path)` to the playtest, with
the statement's `#N` or number where the file has several); where a quote's words are in no file,
filing them first rather than dropping the link.

Item: [quotes-become-links.md](quotes-become-links.md).
