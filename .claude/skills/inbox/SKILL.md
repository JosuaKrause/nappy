---
name: inbox
description: The player's inbox on GitHub Issues — where it is found at the start of a session, which issues count as the player's notes, capturing the player's words into it before anything else, asking the player about a note on its issue, and filing a batch of notes into the queue with one pull request that closes them. Load this at the start of a session, and before capturing, reading, asking on or filing a note.
---

# The inbox

**GitHub Issues are the player's inbox, and nothing else.** *(2026-09-27: "the important thing is
that it ends up in a safe queue in issues and I can choose when we want to turn those into a doc
update PR (so I can even go in and edit the issues after the fact before the get merged)".)* A
note is an open issue carrying the label `inbox`. The player writes one at any time, edits it
until it is filed, and says when a batch of notes becomes a filing pull request. The queue, the
review items, the playtest files and the decision records stay in the repository, because an
entry is reviewed when it enters the queue (`tools/decisions.sh leafy-finch` has the reasons,
and the options weighed against them).

`tools/inbox.py` is the tool, and **the one way an agent writes an issue** *(2026-09-27: "if it
goes through a script it's safe we just need to get it working once -- an agent shouldn't use gh
issue directly")*. `.claude/hooks/github-write-guard.sh` denies a direct `gh issue` write, wrapped
in an identity or not.

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
player chose "Yes, marked by the script"). Only the player's own comments are the player's words.
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
uv run python tools/inbox.py --role claude-orchestrator capture --band next <<'NOTE'
the player's words, exactly as they were said
NOTE
```

The body is **the player's words verbatim and nothing else**, so it can be copied word for word
when it is filed; the title is the agent's (the words' first line when `--title` is not given).
`--band` goes on only when the player named a band. When the words answer something the agent
said — a question, an option with a label — `--context-file` posts what they answered as the
note's first comment, the agent's side, so the filing can record the words with what they
answered as **playtest-feedback** asks. The script tags the note with the label `captured`, which
only it sets, and opens it as `claude-orchestrator` (Codex: `codex-coder`), which is what makes a
captured note count as the player's.

## Asking about a note

**A question about a note is asked on its issue, before it is filed** *(2026-09-27: "if you need
more info you can also ask in the github issue. so by the time we queue a task most questions are
already resolved")*:

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
  comments, each after the question it answers. Wrapping and the `> ` markers are free; every
  word, letter case and punctuation mark is copied as it stands. A playtest file is a primary
  source and is never rewritten afterwards.
- **File the queue from it** exactly as **playtest-feedback** says, each entry opening with the
  note's band.
- **Open one pull request whose description names every note on a line of its own,
  `Filed from #N`** — never `Closes #N`, which would leave the note open and editable until the
  merge. It is docs-only, so its commits, push and pull request go out as `claude-orchestrator`
  (Codex: `codex-coder`), under **committing**. CI's transcription check reads those lines and
  fails a note that is not the player's or whose text is not in a playtest file the pull request
  adds, word for word.
- **Right after pushing the pull request, close the batch in one call** *(2026-09-27: "maybe
  let's change the flow to close the issue upon *creating* the PR. so no deferred "Closes #N" but a
  single action by the orchestrator after pushing the PR.")*:

  ```sh
  uv run python tools/inbox.py --role claude-orchestrator close --pr P
  ```

  It closes every note the description names, and closes none when any note's current text is not
  word for word in a playtest file the pull request adds, so a note the player edited after it was
  copied stops the close rather than being filed half-read. `--dry-run` checks the same and writes
  nothing. From then on the playtest file is the record, and a later thought is a new note.
- **A filing pull request that is abandoned reopens its notes**:
  `uv run python tools/inbox.py --role claude-orchestrator reopen --pr P`, once the pull request is
  closed without merging.

## Every write goes out as an agent identity

`tools/inbox.py`'s writes run as the role given by `--role`, or by `NAPPY_AGENT_ROLE`, which
`tools/agent-identity.py run <role> --` sets: each write goes through that wrapper with a token of
its own. The role is `claude-orchestrator` in Claude Code and `codex-coder` in Codex, the two
identities whose captures count, and a write with no role, or with another one, is refused rather
than sent under the player's account, where it would read as the player's own words. Reads need no
role. When `uv run python tools/agent-identity.py status <role>` reports the role not usable, the
session stops and tells the player, as **committing** says.
