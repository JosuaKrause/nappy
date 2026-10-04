---
name: inbox
description: The player's inbox on GitHub Issues — where it is found at the start of a session, which issues count as the player's notes, capturing the player's words into it before anything else, asking the player about a note on its issue, and filing a batch of notes into the queue with one pull request that closes them. Load this at the start of a session, and before capturing, reading, asking on or filing a note.
---

# The inbox

**GitHub Issues are the player's inbox, and nothing else.** *(2026-09-27: "the important thing is
that it ends up in a safe queue in issues and I can choose when we want to turn those into a doc
update PR (so I can even go in and edit the issues after the fact before the get merged)".)* A
note is an open issue carrying the label `inbox`, and an issue without it is never filed, whoever
opened it *(2026-10-03: "if an issue has no inbox label it shouldn't get filed")*: `tools/inbox.py`
skips it and refuses to close a batch naming it, and CI's `tools/ci_transcription.py` fails a
filing pull request that names it. The player writes one at any time, edits it
until it is filed, and says when a batch of notes becomes a filing pull request. The queue, the
review items, the playtest files and the decision records stay in the repository, because an
entry is reviewed when it enters the queue (`tools/decisions.sh leafy-finch` has the reasons,
and the options weighed against them).

`tools/inbox.py` is the tool, and **the one way an agent writes an issue** *(2026-09-27: "if it
goes through a script it's safe we just need to get it working once -- an agent shouldn't use gh
issue directly")*. `.claude/hooks/github-write-guard.sh` denies a direct `gh issue` write, wrapped
in an identity or not, and an issue write through `gh api` the same way, all but a comment POST to
`issues/N/comments`, which a pull request's own conversation comments share.

## Where it is found

**At the start of a session, `uv run python tools/inbox.py list`** prints the open notes, oldest
first, each with its band and link, and a line for every other issue labelled `inbox` saying why it
is not a note. It sits beside `gh pr list`, `tools/agent-status.sh` and `tools/queue.sh` in
`CLAUDE.md`'s "where to pick up", and **session-cleanup** lists the open notes in the restart
prompt. `uv run python tools/inbox.py show N` prints one note in full: its body as it stands now,
then its comments in order, each marked as the player's words or the agent's side, and a line for
each comment it skips.

A blank note comes from the issue template `.github/ISSUE_TEMPLATE/inbox-note.md`, which puts the
`inbox` label on it.

## Whose notes count

**Only an issue the player opened, or one the capture script (`tools/inbox.py capture`) opened
for them, is a note**
*(2026-09-27: "for now let's also require that inbox issues are created by me so random people
opening github issues don't get their comments ingested into the queue")*. The repository is
public and the template's label goes on any issue opened with it, so the label alone admits
anybody: an issue from outside the project is welcome as something to look at and is never an
automatic call for action ("currently anybody on the internet can create an issue. and that is
good for bringing things to our attention but shouldn't be an automatic call for action"). A
captured note counts when it was opened as `nappy-claude-orchestrator[bot]` or
`nappy-codex-coder[bot]` and carries the capture script's tag, the label `captured` (asked, the
player chose "Yes, marked by the script"). The player's own comments are the player's words, and so,
on a captured note alone, are the words `append` added (below).
`tools/inbox.py` skips everything else with a line saying so, and CI's transcription check
(`tools/ci_transcription.py`) fails a filing that names any other issue.

## The labels

**`inbox` marks a note, and `queue_<band>` sets the band its work is filed in**: `queue_now`,
`queue_next`, `queue_later`, `queue_parked` *(2026-09-27: "I created an issue with inbox label and
with priority I choose the convention of queue_now, queue_next, queue_later, and queue_parked")*.
A label outside that pattern is never taken for a band. The entry filed from a note opens with its
band; a note with no band label is filed as **playtest-feedback** says, `now` for a note from
playing and otherwise a band the filer proposes and names in its report; a note with two band
labels is filed under neither and asked about on its issue.

## Capturing the player's words

**When the player says something in a session that should outlive it — a thought for the queue, a
correction to a task — capture it into the inbox, in one call, before going on with anything
else**, so the words are safe even if the session is cleared before a filing pull request exists.
The player's worry was having "to hope that the agent gets to write a comment down before a
session is cleared", and **which messages to capture is the agent's judgment**: no hook reminds
it, and the conversation is not recorded as a whole *(2026-09-27: "okay, we can do via capture and
then it also shows up as issue -- great -- no need for a hook I don't want my entire conversation
recorded. an agent has better judgement there.")*.

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
as text (**using-tools**). The body is **the player's words verbatim and nothing else**, so it can be copied word for word
when it is filed; the title is the agent's (the words' first line when `--title` is not given).
`--band` goes on only when the player named a band. When the words answer something the agent
said — a question, an option with a label — `--context-file` posts what they answered as the
note's first comment, the agent's side, so the filing can record the words with what they
answered as **playtest-feedback** asks. The script tags the note with the label `captured`, which
only it sets, and opens it as `claude-orchestrator` (Codex: `codex-coder`), which is what makes a
captured note count as the player's.

**A further word on the topic of a note already open is appended to that note, never captured as a
new one.** *(2026-10-03: "don't create new inbox notes for the same topic -- keep adding comments
to it".)* When the agent already knows an open captured note on the topic, one it captured or read
this session, the player's next words on it go onto that note:

```sh
uv run python tools/inbox.py --role claude-orchestrator append N --body-file /tmp/more.md
```

**Only when the agent already knows the note** *(2026-10-03: "well, only if you already know that
there is an open issue about this topic -- don't spend time reading all issues just to figure out
whether there is an overlap")*: the inbox is never searched or read to look for an overlap, and
with no such note in hand the words are captured as a new note. The words go into a file first,
exactly as for `capture`, and are the player's verbatim. `append` posts them as one comment under
the same identity rules as `capture`, led by a marker line (an HTML comment, invisible on the
issue) that only the script writes, so the tool tells them from a question asked with `ask`;
`--context-file` puts what they answered, the agent's side, above the words in that same comment,
so a failed post leaves nothing alone on the issue and a retry duplicates nothing. `ask`,
`capture --context-file` and `append` refuse text with a marker line in it. It refuses a note that is not
captured, since a note the player wrote gets the player's own comments, and a closed one. `show`
prints an appended comment's words as the player's and its context as what the words answered, and
the filing treats the words like the body.

## Asking about a note

**An ingestion never waits on a question.** *(2026-10-03: "If there is an open question in an
issue stays open until the task gets picked up. Most of the time there needs to be some exploration
etc done. The whole point of the issue ingestion is to get things in to the codebase fast. The
questions come later after the ingestion is merged")* Every note is filed as it stands, and a
question it leaves open is written into its queue entry, marked open, for whoever picks the task up.

**A question about a note can still be asked on its issue** *(2026-09-27: "if you need more info you
can also ask in the github issue. so by the time we queue a task most questions are already
resolved")*, when the filer has one before the batch is filed; the answer is filed with the note,
and the batch does not wait for it:

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
- **Copy each note's current text word for word into a playtest file** made with
  `tools/new-name.sh playtest "<title>"`: what the words answered first, when a captured note
  carries it as its first comment, then the body quoted in `> ` lines, then the player's
  comments and the words appended to it, in the order they were said, each after what it answers
  (the first comment's context, the question before it, or the context its append comment holds). Wrapping and the `> ` markers are free; every
  word, letter case and punctuation mark is copied as it stands. A playtest file is a primary
  source and is never rewritten afterwards.
- **File the queue from it** exactly as **playtest-feedback** says, each entry opening with the
  note's band.
- **Patch the citations of the notes just copied**, before the pull request is opened. Records,
  docs, skills and code comments that already quote a note cite it as `inbox #N`, a closed issue
  once it is filed; the playtest goes beside that number, which stays:

  ```sh
  uv run python tools/inbox.py cite --pr P --dry-run   # or: cite N M ... for notes given by number
  uv run python tools/inbox.py cite --pr P
  ```

  `cite` finds each note's playtest from its `## #N` heading under `docs/playtests/` and, in every
  tracked text file outside `docs/playtests/`, turns the plain `inbox #N` (and a run such as
  `inbox #9001, #9002 and #9003`) into `inbox #N in [name](relative link)` in Markdown, skills
  included, and `inbox #N in name` in a code comment. A number counts only as `#N` followed by no
  digit or letter, or as `issues/N` in a URL, so an SVG colour such as `#9004a6` never matches. A
  bare `(#N)`, a range such as `#9001-#9005`, an issue URL, a link text and a run mixing playtests are
  listed as `file:line: text` and never edited: **fix each of those by hand**, the same way. A line
  that already names the playtest is left alone, so a second run changes nothing. **Then read
  `git diff` by eye**: a `#N` that is not a note (a pull request, an SVG colour written as three
  digits) shows up there, and an edit the tool should not have made is reverted by hand. Because
  this edits code comments, the filing pull request may touch `src/` and `tests/`, which makes it a
  code pull request for CI (`tools/ci_classify.py`): its commits, push and writes go out as
  `claude-coder` from that commit on, and its description carries a `No queue item: <reason>` line
  (`tools/ci_code_pr_queue.py`). **Anything written after a filing cites the playtest file, not the
  closed issue.**
- **Open one pull request whose description names every note on a line of its own,
  `Filed from #N`** — never `Closes #N`, which would leave the note open and editable until the
  merge. It is docs-only unless `cite` edited a code comment, so its commits, push and pull request go
  out as `claude-orchestrator` (Codex: `codex-coder`), under **committing**, or as `claude-coder` once
  it is a code pull request. CI's transcription check reads those lines and
  fails a note that is not the player's or whose text, appended words included, is not in a playtest
  file the pull request adds, word for word.
- **Right after pushing the pull request, close the batch in one call** *(2026-09-27: "maybe
  let's change the flow to close the issue upon *creating* the PR. so no deferred "Closes #N" but a
  single action by the orchestrator after pushing the PR.")*:

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
