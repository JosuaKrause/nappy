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
filing PR's `Filed from #N` lines name, in one call, refusing unless each note's current body
and every comment the player wrote on it are word for word in one playtest file the PR adds (a
note with no body is refused, as CI refuses it); `reopen --pr P`, once the PR is closed unmerged,
reopens a note only if an inbox identity closed it after the PR was opened and its last filing
comment names that PR. An issue template puts `inbox` on a blank note. **playtest-feedback** names the inbox as
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
asked. The same holds for the API: a `gh api` write to a repository's issues or to anything under
one issue (its state, body, labels, comments' edits) and a GraphQL issue mutation are denied
wrapped or not; a POST to `issues/<n>/comments` and GraphQL's `addComment` stay open, since a pull
request's conversation comments share them, and so does a GraphQL query read from a file. Where no
identity can work and the guard asks the player about a write instead of denying it, an issue write
is still denied, never asked about.

**A write's words are text in exactly three shapes, each the whole command** — the player chose
this narrow form after three reviews each found shapes a general rule read as text while main
denied them ([plaid-tapir](../playtests/2026-10-03-plaid-tapir.md), statement 4: "B"): a `cat`
writing a file from a heredoc with a quoted delimiter; a `git commit -F -` reading such a heredoc,
wrapped as a coder or orchestrator identity; and a lone `rg` or `grep` with one quoted pattern.
Every other command is read exactly as main's guard reads it, so a heredoc commit message passed
any other way, two heredocs in one command, or a quoted `echo` naming a write is denied as on main.

**Accepted gaps, named in the guard's header**, each allowed on main too: a wrapped issue write
whose endpoint is built by an expansion or supplied by `xargs`, whose GraphQL query is built by an
expansion or read from a file or pipe whose text the command does not hold, or that runs through a
gh alias; and a script a shape-(a) heredoc writes that a later, separate command runs (a shell
startup file, a git hook).

**Issues were weighed as the queue itself and rejected** (statement 1: "items get reviewed when
they enter the queue which in theory can reduce miscommunication or misinterpreted statements …
another con of issues is that things can be edited without history"). An issue enters with no
review, is edited with no reviewed history, and loads no path-triggered rule; Issues are the inbox
only, and the queue, the review items, the playtests and these records stay in the repository.

**Not yet exercised:** no capture, ask or close has run through the script. Issue #431 was opened
as a captured note before the script existed, by `nappy-claude-orchestrator[bot]` with `inbox` and
`captured`; its body is the session's write-up and the player's words in it are only "add it as
issue". The player chose to file it as it stands ([plaid-tapir](../playtests/2026-10-03-plaid-tapir.md),
statement 3: "file it as is"), with its body marked as the agent's. The first real filing is
issue #423 ("shadows are misplaced", `queue_next`), by the player's trigger (velvet-otter), and the
entry's last item.

**Open to overturn:** the inbox-skill item's own proposals — the player's comments on a note copied
with its body, one filing PR for a whole batch, an abandoned filing PR reopening its notes, and the
inbox script posting a question under the capture identity; `capture` as a subcommand of `tools/inbox.py` rather than a script of its
own; `close` taking the PR rather than a list of issues; a write refusing to run with no role and
only as the two capture identities; a note with two band labels filed under neither and asked
about; `capture --title` defaulting to the words' first line cut near 70 characters;
`--context-file` posting what the words answered as the note's first comment; no label command
(a label to change is asked about on the note); an issue comment written through
`gh api .../issues/N/comments` not refused as an issue write; and CI's transcription check still
reading only a note's body, while `close` also checks the player's comments.
