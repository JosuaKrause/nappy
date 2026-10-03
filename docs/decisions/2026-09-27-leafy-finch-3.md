# leafy-finch-3 — Issues as the inbox: the inbox skill, capture, and the write guard · built 2026-10-03

*([bouncy-heron](../playtests/2026-09-27-bouncy-heron.md), statement 5: "Issues are the inbox, not
the queue" · statement 14: "if it goes through a script it's safe we just need to get it working
once -- an agent shouldn't use gh issue directly" · statement 19: "for now let's also require that
inbox issues are created by me so random people opening github issues don't get their comments
ingested into the queue" · statements 1, 2, 6, 13, 21 to 23 ·
[dotted-quail](../playtests/2026-09-27-dotted-quail.md), statements 1 to 3)*

**Built (PR #429).** The **inbox** skill and `tools/inbox.py` read and file the player's inbox:
the open issues labelled `inbox` that the player opened, or that `capture` opened as
`nappy-claude-orchestrator[bot]` or `nappy-codex-coder[bot]` with the label `captured`; every other
issue and every comment not the player's is skipped with a line saying so. `list` gives each note's
band from its `queue_<band>` label, `show` prints a note's current body and its comments in order,
each marked as the player's words or the agent's side, `ask` posts a question on the note,
`capture` opens a note with the player's words verbatim, and `close --pr P` closes every note a
filing PR's `Filed from #N` lines name, in one call, refusing unless each note's current text is
word for word in a playtest file the PR adds; `reopen --pr P` reopens them once the PR is closed
unmerged. An issue template puts `inbox` on a blank note. **playtest-feedback** names the inbox as
the first place the player's words are written, **session-cleanup** lists the open notes in the
restart prompt, and `CLAUDE.md`'s "where to pick up" names the inbox.

**An issue without the `inbox` label is never filed**, whoever opened it ([plaid-tapir](../playtests/2026-10-03-plaid-tapir.md),
statement 2: "if an issue has no inbox label it shouldn't get filed"): `tools/inbox.py` skips it and refuses to close a batch
that names it, and CI's transcription check (`tools/ci_transcription.py`, PR #462) fails a filing PR
that names it. A test runs both scripts' rules over the same notes, so the two cannot drift apart.

**The write guard denies a direct `gh issue` write, wrapped in an identity or not**; only
`tools/inbox.py` writes an issue, and it runs each write under `claude-orchestrator` or
`codex-coder` and refuses to write with no role, since a note written as the player would read as
the player's own words. This reverses what PR #424 built and tested (a wrapped `gh issue
create/close/reopen/comment/edit` let through as `claude-orchestrator`), as the write-guard item
asked. Where no identity can work and the guard asks the player about a write instead of denying
it, a `gh issue` write is still denied, never asked about. The guard also stops reading a write
command's words as a command when they are only text: a quoted argument of a text-only command, or
a heredoc body such a command reads, where the guard can tell. A heredoc fed to a shell, an
interpreter or `sed`, anything after a wrapper word, and anything piped on are read as before.

**Issues were weighed as the queue itself and rejected** (statement 1: "items get reviewed when
they enter the queue which in theory can reduce miscommunication or misinterpreted statements …
another con of issues is that things can be edited without history"). An issue enters with no
review, is edited with no reviewed history, and loads no path-triggered rule; Issues are the inbox
only, and the queue, the review items, the playtests and these records stay in the repository.

**Not yet exercised:** no live capture, ask or close has been made; the first real filing is issue
#423 ("shadows are misplaced", `queue_next`), filed by the player's trigger as its own PR
(velvet-otter), and the entry's last item.

**Open to overturn:** `capture` as a subcommand of `tools/inbox.py` rather than a script of its
own; `close` taking the PR rather than a list of issues; a write refusing to run with no role and
only as the two capture identities; a note with two band labels filed under neither and asked
about; `capture --title` defaulting to the words' first line cut near 70 characters;
`--context-file` posting what the words answered as the note's first comment; an issue comment
written through `gh api .../issues/N/comments` not refused as an issue write, since that endpoint
also carries a pull request's conversation comments.
