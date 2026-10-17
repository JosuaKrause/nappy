---
name: inbox
description: The player's inbox on GitHub Issues — where it is found at the start of a session, which issues count as the player's notes, capturing the player's words into it before anything else, asking the player about a note on its issue, and filing a batch of notes into the queue with one pull request that closes them. Load this at the start of a session, and before capturing, reading, asking on or filing a note.
---

# The inbox

**GitHub Issues are the player's inbox, and nothing else** (bouncy-heron 5). A note is an open
issue carrying the label `inbox`, and an issue without it is never filed (plaid-tapir 2), whoever
opened it: `tools/inbox.py` skips it and refuses to close a batch naming it, and CI's
`tools/ci_transcription.py` fails a filing pull request that names it. The player writes one at any
time, edits it until it is filed, and says when a batch of notes becomes a filing pull request. The
queue, the review items, the playtest files and the decision records stay in the repository, because
an entry is reviewed when it enters the queue (`tools/decisions.sh leafy-finch` has the reasons, and
the options weighed against them).

`tools/inbox.py` is the tool, and **the one way an agent writes an issue** (bouncy-heron 14).
`.claude/hooks/github-write-guard.sh` denies a direct `gh issue` write, wrapped in an identity or
not, and an issue write through `gh api` the same way, all but a comment POST to
`issues/N/comments`, which a pull request's own conversation comments share.

## Where it is found

**At the start of a session, `uv run python tools/inbox.py list`** prints the open notes, oldest
first, each with its band and link, and a line for every other issue labelled `inbox` saying why it
is not a note. It sits beside `gh pr list`, `tools/agent-status.sh` and `tools/queue.sh` in
`CLAUDE.md`'s "where to pick up", and **session-cleanup** lists the open notes in the restart
prompt. `uv run python tools/inbox.py show N` prints one note in full: its body as it stands now,
then its comments in order, each block marked as the player's words, context, a reading (`Read as:`),
a note, a correction or the agent's side, and a line for each comment it skips.

A blank note comes from the issue template `.github/ISSUE_TEMPLATE/inbox-note.md`, which puts the
`inbox` label on it.

## Whose notes count

**Only an issue the player opened, or one the capture script (`tools/inbox.py capture`) opened for
them, is a note** (bouncy-heron 19), so people outside the project do not put work into the queue.
The repository is public and the template's label goes on any issue opened with it, so the label
alone admits anybody: an issue from outside the project is welcome as something to look at and is
never an automatic call for action (bouncy-heron 23). A captured note counts when it was opened as
`nappy-claude-orchestrator[bot]` or `nappy-codex-coder[bot]` and carries the capture script's tag,
the label `captured` (bouncy-heron 23). The player's own comments are the player's words, and so, on
a captured note alone, are the quote blocks of its body and of the comments `append` added (below). `tools/inbox.py` skips everything else
with a line saying so, and CI's transcription check (`tools/ci_transcription.py`) fails a filing
that names any other issue.

## The labels

**`inbox` marks a note, and `queue_<band>` sets the band its work is filed in** (dotted-quail 2):
`queue_now`, `queue_next`, `queue_later`, `queue_parked`, and `queue_bug`, a band above `now`
(mossy-ferret #710). A note is never filed `bug` unless the player says so (mossy-ferret #710), and
"up next" is not a label: it is an `upnext: true` line in the entry's opening block. A label outside
that pattern is never taken for a band. The entry filed from a note opens with its band; a note with
no band label is filed as **playtest-feedback** says, `now` for a note from playing and otherwise a
band the filer proposes and names in its report; a note with two band labels is filed under neither
and asked about on its issue.

## Capturing the player's words

**When the player says something in a session that should outlive it — a thought for the queue, a
correction to a task — capture it into the inbox, in one call, before going on with anything else**,
so the words are safe even if the session is cleared before a filing pull request exists. The
player's worry was words lost (bouncy-heron 2) when a session is cleared before an agent writes them
down, and **which messages to capture is the agent's judgment**: no hook reminds it, and the
conversation is not recorded as a whole (bouncy-heron 13).

```sh
cat > /tmp/note.md <<'NOTE'
the player's words, exactly as they were said
NOTE
```

```sh
uv run python tools/inbox.py --role claude-orchestrator capture --band next --body-file /tmp/note.md
```

The words go into a file first, as a command of its own, because the write guard reads a heredoc
fed to the script as commands: words that name a write (`git push`, `gh issue close`) would deny
the capture, while a `cat > FILE <<'NOTE'` that is the whole command is one of the shapes it reads
as text (**using-tools**). The title is the agent's (the first quote's first line when `--title` is
not given). `--band` goes on only when the player named a band.

**A note holds blocks, and every block carries a visible mark saying whose it is** (inbox #767), so
nobody filing it later takes an interpretation for something the player said. The tool writes the
marks itself from the options, so their format never varies, and each option is repeatable and kept
in the order given:

| Option | Block | Whose |
|---|---|---|
| `--quote-file` (`--body-file`; with no block named, standard input) | `The player's words (direct quote)` | the player's, verbatim and nothing else |
| `--context-file` | `Context` | the agent's: what the words answered, with whatever else the filer needs |
| `--reading-file` | `Read as` | the agent's interpretation of the words, never written as though the player had said it |
| `--note-file` | `Note` | the agent's further note |

```sh
uv run python tools/inbox.py --role claude-orchestrator capture --band next \
  --context-file /tmp/context.md --quote-file /tmp/words.md --reading-file /tmp/reading.md
```

**Only a quote block is the player's words**: `show` prints every block under its kind, the draft
labels them, and `ci_transcription.py` and `close --pr` need the quote blocks word for word in the
playtest file, so context, readings and notes need not be copied verbatim. A note takes at least one
quote block. A text holding a mark line (or a marker line the tool writes) is refused, which keeps
a block's kind unforgeable. A lone quote is stored as the bare words, and text with no mark at its
start, a note the player wrote themselves or one captured before the marks, is all the player's.
A stray line the player did not say is never put in a quote block; it belongs in a context or note
block. The player's worry was words lost (bouncy-heron 2) when a session is cleared before an agent
writes them down, and **which messages to capture is the agent's judgment**: no hook reminds it, and
the conversation is not recorded as a whole (bouncy-heron 13). The script tags the note with the
label `captured`, which only it sets, and opens it as `claude-orchestrator` (Codex: `codex-coder`),
which is what makes a captured note count as the player's.

**A further word on the topic of a note already open is appended to that note, never captured as a
new one** (olive-tapir). When the agent already knows an open captured note on the topic, one it
captured or read this session, the player's next words on it go onto that note, with the same block
options:

```sh
uv run python tools/inbox.py --role claude-orchestrator append N --quote-file /tmp/more.md --context-file /tmp/context.md
```

**Only when the agent already knows the note** (olive-tapir): the inbox is never searched or read to
look for an overlap, and with no such note in hand the words are captured as a new note. The words
go into a file first, exactly as for `capture`. `append` posts the blocks as one comment under the
same identity rules as `capture`, led by a marker line (an HTML comment, invisible on the issue) that
only the script writes, so the tool tells them from a question asked with `ask`; one comment, so a
failed post leaves nothing alone on the issue and a retry duplicates nothing. `ask`, `capture`,
`append` and `correct` refuse text with a mark or marker line in it. `append` refuses a note that is
not captured, since a note the player wrote gets the player's own comments, and a closed one.

**A line the player did not say that reached a quote anyway is corrected in a comment on that note,
never by a new note** (inbox #767):

```sh
uv run python tools/inbox.py --role claude-orchestrator correct N --line-file /tmp/line.md --note-file /tmp/why.md
```

The comment is the agent's side, so the append rule above needs no exception. The line must be in
the note's body or its appended words word for word, or nothing is written. `show N` flags the line
as not the player's, and the draft flags it right after its quoted block.

## Asking about a note

**An ingestion never waits on a question** (minty-hedgehog #459), since its point is to get the
notes into the repository fast, and most questions need exploring once the task is picked up anyway.
Every note is filed as it stands, and a question it leaves open is written into its queue entry,
marked open, for whoever picks the task up.

**A question about a note can still be asked on its issue** (dotted-quail 1), when the filer has one
before the batch is filed; the answer is filed with the note, and the batch does not wait for it:

```sh
uv run python tools/inbox.py --role claude-orchestrator ask N --body-file /tmp/question.md
```

The question carries all the context the answer needs, as `CLAUDE.md`'s rule on questions says,
since the player answers from the issue in front of them. The player answers in their own
comments, and `show` prints both in order. **When the note is filed, each answer is recorded with
the question it answers**, as **playtest-feedback** asks for words said in conversation: the
playtest file states the question before the answer it quotes.

## Filing a batch

**A batch is filed when the player asks, never on the agent's own initiative.** One filing pull
request carries the whole batch:

- **List and read every note** with `list` and `show`, and settle what is unclear by asking on the
  issue first.
- **Draft each note's playtest section with `tools/inbox.py draft N M ...`** and put it in a
  playtest file made with `tools/new-name.sh playtest "<title>"`. The draft is the filed layout,
  every block labelled: the player's quote blocks in `> ` lines, the only lines that are the
  player's; context, a note and a correction as the assistant's sentences; a reading under
  `Read as:` (inbox #767); a corrected line flagged in a sentence right after its quoted block,
  never inside it, since a quote must stay one unbroken run of words. The comments the player wrote
  and the quotes appended to the note follow in the order they were said, each after what it
  answers. Wrapping and the `> ` markers are free; every word, letter case and punctuation mark of
  a quote is copied as it stands, and context, readings and notes need not be copied word for word.
  A corrected line is still copied, since it is in the note. A playtest file is a primary source and
  is never rewritten afterwards.
- **File the queue from it** exactly as **playtest-feedback** says, each entry opening with the
  note's band.
- **Patch the citations of the notes just copied**, before the pull request is opened. Records,
  docs, skills and code comments that already quote a note cite it as `inbox #N`, a closed issue
  once it is filed; the playtest goes beside that number, which stays:

  ```sh
  uv run python tools/inbox.py cite N M ... --dry-run   # the numbers of the batch, as in its `Filed from` lines
  uv run python tools/inbox.py cite N M ...
  ```

  The pull request does not exist yet at this step, so the notes are given by number; once it is
  open, `cite --pr P` reads the same numbers from its `Filed from #N` lines, for a later pass.

  `cite` finds each note's playtest from its `## #N` heading under `docs/playtests/` and, in every
  tracked text file outside `docs/playtests/`, turns the plain `inbox #N` (and a run such as
  `inbox #9001, #9002 and #9003`) into `inbox #N in name`, the playtest's bare name, in every file,
  Markdown and skills included, and never into a link: `CLAUDE.md`'s citation rule counts that form
  as a citation, and `tools/check_citations.py` checks that the name holds the note. A number counts
  only as `#N` followed by no digit or letter, or as `issues/N` in a URL, so an SVG colour such as
  `#9004a6` never matches. A bare `(#N)`, a range such as `#9001-#9005`, an issue URL, a link text
  and a run mixing playtests are listed as `file:line: text` and never edited. **Fix a listed
  citation by hand, the same way, when nothing near it names the playtest**; a bare number inside a
  sentence, list or heading that already names the playtest can stay. A line that already names the
  playtest, or a citation already followed by ` in <name or link>`, is left alone (a different
  playtest there is listed), so a second run changes nothing. **Then read `git diff` by eye**: a
  `#N` that is not a note (a pull request, an SVG colour written as three digits) shows up there,
  and an edit the tool should not have made is reverted by hand. Because this edits code comments,
  the filing pull request may touch `src/` and `tests/`, which makes it a code pull request for CI
  (`tools/ci_classify.py`), and **that has a cost**: it is no longer queue-only, so it loses the
  queue update's merge-first lane and its lighter faithfulness review and gets the full review. Its
  commits, push and writes go out as `claude-coder` from that commit on, and its description carries
  a `No queue item: <reason>` line (`tools/ci_code_pr_queue.py`). **Anything written after a filing
  cites the playtest file, not the closed issue.**
- **Open one pull request whose description names every note on a line of its own,
  `Filed from #N`** — never `Closes #N`, which would leave the note open and editable until the
  merge. It is docs-only unless `cite` edited a code comment, so its commits, push and pull request go
  out as `claude-orchestrator` (Codex: `codex-coder`), under **committing**, or as `claude-coder` once
  it is a code pull request. CI's transcription check reads those lines and
  fails a note that is not the player's or whose text, appended words included, is not in a playtest
  file the pull request adds, word for word.
- **Right after pushing the pull request, close the batch in one call** (bouncy-heron 22):

  ```sh
  uv run python tools/inbox.py --role claude-orchestrator close --pr P
  ```

  It closes every note the description names, and closes none when any note's current text, or
  any comment the player wrote on it or any words appended to it, is not word for word in one playtest file the pull request
  adds, so a note the player edited, or answered on, after it was copied stops the close rather
  than being filed half-read. A note with no body (a title alone) is refused the same way, as CI's
  transcription check refuses it; it is asked about on its issue instead. `--dry-run` checks the same and writes
  nothing. From then on the playtest file is the record, and a later thought is a new note.
- **A filing pull request that is abandoned reopens its notes**:
  `uv run python tools/inbox.py --role claude-orchestrator reopen --pr P`, once the pull request is
  closed without merging. It reopens only what `close --pr P` closed: a note still closed whose
  last close came from an inbox identity after P was opened and whose last `Filed in #N.` note
  names P. A note the player closed, or one a later filing closed again, is left closed with a line
  saying why.

## Every write goes out as an agent identity

`tools/inbox.py`'s writes run as the role given by `--role`, or by `NAPPY_AGENT_ROLE`, which
`tools/agent-identity.py run <role> --` sets: each write goes through that wrapper with a token of
its own. The role is `claude-orchestrator` in Claude Code and `codex-coder` in Codex, the two
identities whose captures count, and a write with no role, or with another one, is refused rather
than sent under the player's account, where it would read as the player's own words. Reads need no
role. When `uv run python tools/agent-identity.py status <role>` reports the role not usable, the
session stops and tells the player, as **committing** says.
