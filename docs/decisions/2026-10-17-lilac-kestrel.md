# lilac-kestrel — CLAUDE.md and the skills cite the player's words by name and never quote them · 2026-10-17

The player (woolly-penguin #759, then inbox #762 and #763): the player's words live in a playtest,
and `CLAUDE.md` and the skills cite them rather than quote them; a citation adds no words and is no
link or path, only the file's name; the reading is established once, by the review of the change
that writes the rule; and a change's consequences are fixed in the PR that makes them.

**Built (PR #756).** `CLAUDE.md` states the rule and says once how to read a citation: a name such as
`woolly-penguin` is the playtest of that name under `docs/playtests/`, and a statement in a file of
several is given either as `#N`, the statement under its `## #N` heading, or as the file's own
statement number, as in `(PLAYTEST-16 7)`; words no playtest holds cite their record under
`docs/decisions/` the same way, and `inbox #N in <name>`, which `tools/inbox.py cite` writes, is the
one other form. Every quote of the player in `CLAUDE.md` and the skills became such a citation: 109
traced to a playtest or record, and 35 whose words were recorded nowhere but the skills, moved
verbatim, each under its date and a number of its own, into the new playtest woolly-finch. Where a
quote carried a rule's reason, the skill now says it in its own words; PR #756's description lists
every such rewording.

The same PR changes `tools/inbox.py cite` to write the bare name; adds `tools/check_citations.py`,
which `./tools/lint.sh` runs and which fails a link, path or anchor into the playtests or records, a
name that resolves to no file or to several, a bare name for a file of several statements, and a
number with no statement behind it; and adds to pr-review's semantic questions that every citation a
PR adds or changes is opened and read against its rule. It also carries pr-review's rule that three
verdicts of *not ready* on a pull request mean its approach is rethought, including whether the
chosen solution is the right way (woolly-penguin #759); this PR met it on its own third review.

**Choices open to overturn:** the check runs on the host's own Python, 3.9-compatible, since CI's
lint step runs before uv is installed; a hyphenated word alone in parentheses counts as a citation,
so one that names no file fails lint until reworded or marked `lint-allow`; a file whose statements
carry no number at all (PLAYTEST-56, PLAYTEST-63, PLAYTEST-67, PLAYTEST-78) is cited by name alone;
where a file numbers both a heading and a list item the same, the heading is meant; records are
cited by their full name without the date; rejected-graphics keeps a dated paraphrase of a choice no
file records.
