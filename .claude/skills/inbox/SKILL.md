---
name: inbox
description: The player's inbox on GitHub Issues — where it is found at the start of a session, which issues count as the player's notes, capturing the player's words into it before anything else, asking the player about a note on its issue, and filing a batch of notes into the queue with one pull request that closes them. Load this at the start of a session, and before capturing, reading, asking on or filing a note.
---

# The inbox

- **At the start of a session, `uv run python tools/inbox.py list`** shows the player's open notes.
- **The player's words that should outlive the session are captured verbatim, in one call, before anything else.**
- **The words go through a file in a fresh directory, never a fixed name under `/tmp`.**
- **Only a quote block is the player's words**; context, a reading and a note are the agent's and are marked so.
- **A further word on a note the agent already knows is appended to it**; the inbox is never searched for an overlap.
- **When it is not certain what the words refer to, the agent asks before recording any reading.**
- **`tools/inbox.py` is the one way an agent writes an issue**, as `claude-orchestrator` (Codex: `codex-coder`).
- **A batch is filed only when the player asks**, in one pull request that names each note `Filed from #N`, and never waits on a question.

**GitHub Issues are the player's inbox, and nothing else** (bouncy-heron 5). A note is an open
issue carrying the label `inbox`, and an issue without it is never filed (plaid-tapir 2), whoever
opened it: `tools/inbox.py` skips it and refuses to close a batch naming it, and CI's
`tools/ci_transcription.py` fails a filing pull request that names it. The player writes one at any
time, edits it until it is filed, and says when a batch of notes becomes a filing pull request. The
queue, the review items, the playtest files and the decision records stay in the repository, because
an entry is reviewed when it enters the queue (`tools/decisions.sh leafy-finch` has the reasons, and
the options weighed against them).

`tools/inbox.py` is the tool, and **the one way an agent writes an issue** (bouncy-heron 14): the
write guard (`.claude/hooks/github-write-guard.sh`) denies a direct `gh issue` write, wrapped in an
identity or not. **Which GitHub identity writes what is committing's** ("Who a commit and a pull
request are from"); what is this skill's own is that the tool runs each write as the role given by
`--role` or `NAPPY_AGENT_ROLE`, `claude-orchestrator` in Claude Code and `codex-coder` in Codex,
the two roles whose captures count, and refuses a write with no role or any other, since a note
written under the player's account would read as the player's own words. Reads need no role.

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
never an automatic call for action (bouncy-heron 23). **Nor is anybody else's feedback captured**:
a Reddit reply or another playtester's report reaches the inbox only as the player's own words
about it, never as a capture of theirs (**playtest-feedback**, downy-beaver #820). A captured note
counts when it was opened as `nappy-claude-orchestrator[bot]` or `nappy-codex-coder[bot]` and
carries the capture script's tag,
the label `captured` (bouncy-heron 23). The player's own comments are the player's words, and so, on
a captured note alone, are the quote blocks of its body and of the comments `append` added (below). `tools/inbox.py` skips everything else
with a line saying so, and CI's transcription check (`tools/ci_transcription.py`) fails a filing
that names any other issue.

## The labels

**`inbox` marks a note, and `queue_<band>` sets the band its work is filed in** (dotted-quail 2):
`queue_now`, `queue_next`, `queue_later`, `queue_parked`, and `queue_bug`, a band above `now`
(mossy-ferret #710). A note is never filed `bug` unless the player says so (mossy-ferret #710), and
"up next" is not a label: it is an `upnext: true` line in the entry's opening block. When the player asks for an entry to be done immediately, that is up next, never a band of its own and never `bug` (inbox #1025 in brisk-ferret). A label outside
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

**The words go into a file in a fresh directory, in three calls, never into a fixed name under
`/tmp`** (**committing**, "Text handed to a write goes through a file", spells the sequence for
every text an agent posts). `/tmp` outlives a session, so a fixed name can already hold another
run's text, and a write that did not land would post that text as the player's verbatim words. One
call makes the directory:

```sh
mktemp -d
```

A second is only the heredoc, with the directory it printed pasted in place of `<dir>`:

```sh
cat > <dir>/note.md <<'NOTE'
the player's words, exactly as they were said
NOTE
```

A third passes the file:

```sh
uv run python tools/inbox.py --role claude-orchestrator capture --band next --body-file <dir>/note.md
```

The heredoc is a command of its own because the write guard reads a heredoc
fed to the script as commands: words that name a write (`git push`, `gh issue close`) would deny
the capture, while a `cat > FILE <<'NOTE'` that is the whole command, with nothing in front of it
and nothing after, is one of the shapes it reads
as text. Every file in the examples below is made the same way, in that directory. The title is the agent's (the first quote's first line when `--title` is
not given). `--band` goes on only when the player named a band.

**A note holds blocks, and every block carries a visible mark saying whose it is** (inbox #767 in minty-lemur), so
nobody filing it later takes an interpretation for something the player said. The tool writes the
marks itself from the options, so their format never varies, and each option is repeatable and kept
in the order given:

| Option | Block | Whose |
|---|---|---|
| `--quote-file` (`--body-file`; with no block named, standard input) | `The player's words (direct quote)` | the player's, verbatim and nothing else |
| `--context-file` | `Context` | the agent's: what the words answered, with whatever else the filer needs |
| `--reading-file` | `Read as` | the agent's interpretation of the words, never written as though the player had said it |
| `--note-file` | `Note` | the agent's further note |

**When the words answer a message of the agent's, the context block carries the exact text of what
was answered** (inbox #1074 in gentle-walrus): the list or the options as shown, in their order and
numbering, not a summary of it, since the player's answer may point at its order or wording (invented examples: "the ones right
after the first", "2, 3 and 4").
**And when it is not certain what the player's words refer to, the agent asks before recording any
reading**, not a guess, even one marked as a reading (inbox #1074 in gentle-walrus). The question
goes on the note's issue with `tools/inbox.py ask`, or on the board, per the **board** skill.

```sh
uv run python tools/inbox.py --role claude-orchestrator capture --band next \
  --context-file <dir>/context.md --quote-file <dir>/words.md --reading-file <dir>/reading.md
```

**Only a quote block is the player's words**: `show` prints every block under its kind, the draft
labels them, and `ci_transcription.py` and `close --pr` need the quote blocks word for word in the
playtest file, so context, readings and notes need not be copied verbatim. A note takes at least one
quote block. A text holding a mark line (or a marker line the tool writes) is refused, which keeps
a block's kind unforgeable, and so is a look-alike of a mark (another heading level, a curly
apostrophe, no space after the `#`s), since on the issue it reads as the real one. A quote alone is
marked like any other block; text with no mark at its start, a note the player wrote themselves or
one captured before the marks, is all the player's. A stray line the player did not say is never put
in a quote block; it belongs in a context or note block. The script tags the note with the label
`captured`, which only it sets, and opens it as `claude-orchestrator` (Codex: `codex-coder`), which
is what makes a captured note count as the player's.

**A further word on the topic of a note already open is appended to that note, never captured as a
new one** (olive-tapir). When the agent already knows an open captured note on the topic, one it
captured or read this session, the player's next words on it go onto that note, with the same block
options:

```sh
uv run python tools/inbox.py --role claude-orchestrator append N --quote-file <dir>/more.md --context-file <dir>/context.md
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
never by a new note** (inbox #767 in minty-lemur):

```sh
uv run python tools/inbox.py --role claude-orchestrator correct N --line-file <dir>/line.md --note-file <dir>/why.md
```

The comment is the agent's side, so the append rule above needs no exception. The line must be one
whole line of a quote in the note's body or its appended words, compared word for word, or nothing is
written; a fragment of a line, or a run across two lines, is refused. `show N` flags the line
as not the player's, and the draft flags it right after its quoted block.

## Asking about a note

**An ingestion never waits on a question** (minty-hedgehog #459), since its point is to get the
notes into the repository fast, and most questions need exploring once the task is picked up anyway.
Every note is filed as it stands, and a question it leaves open is written into its queue entry,
marked open, for whoever picks the task up.

**A question about a note can still be asked on its issue** (dotted-quail 1), when the filer has one
before the batch is filed; the answer is filed with the note, and the batch does not wait for it:

```sh
uv run python tools/inbox.py --role claude-orchestrator ask N --body-file <dir>/question.md
```

The question carries all the context the answer needs, as `CLAUDE.md`'s rule on questions says,
since the player answers from the issue in front of them. The player answers in their own
comments, and `show` prints both in order. **When the note is filed, each answer is recorded with
the question it answers**, as **playtest-feedback** asks for words said in conversation: the
playtest file states the question before the answer it quotes.

## Filing a batch

**A batch is filed when the player asks, never on the agent's own initiative**, and one filing pull
request carries the whole batch. `references/filing-a-batch.md` has the steps in order, from
reading the notes to closing them; read it whole before filing. What holds whether or not that
file is open:

- **Every note is copied word for word into a playtest file** (`tools/inbox.py draft N M ...`
  prints the filed layout), and the queue is filed from it as **playtest-feedback** says, each
  entry opening with the note's band.
- **The description names every note on a line of its own, `Filed from #N`**, never `Closes #N`,
  which would leave the note open and editable until the merge.
- **Right after pushing the pull request, `close --pr P` closes the batch in one call**
  (bouncy-heron 22), and a filing that is abandoned reopens its notes with `reopen --pr P`.
- **Anything written after a filing cites the playtest file, not the closed issue**;
  `tools/inbox.py cite` puts the playtest beside the citations that already exist.
