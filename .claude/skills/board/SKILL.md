---
name: board
description: The Nappy board, the shared Claude Doc where the player and the orchestrator keep the open questions, the running work and the recent merges — its layout, how a question is written, answered and settled, how the player's words on it are captured, and the reads and writes that keep it cheap. Load this BEFORE reading or writing the board, and whenever the player says "doc" or "check the doc".
---

# The Nappy board

**Questions and steering live on one standing page, not in the chat** (inbox #830). In the chat a
question is drowned by the reports that follow it, gets repeated at the end of every message, and a
numbered list renumbered between messages lets an answer land on the wrong question. The player
asked for a standing list of tasks and questions, with their thoughts written under each one and
the answers given in line, and chose a shared doc over GitHub issues, which are too slow for a
conversation (inbox #830).

The board is the Claude Doc "Nappy board", https://claude.ai/artifact/UbMpXbepDzN4Mfgs7tAxqm (doc
id `df72dcc8-963b-4b22-bf78-ca097d25c920`, its one tab `4560d3a5-7376`, the tab's body node
`bdec01d2-2025`). Only a Claude Code session with the Claude Docs tools reaches it; Codex has no
route to it. **Only the orchestrating Claude Code session acts on it**: any other session that opens
it changes nothing and answers nothing (inbox #830), and the board says so. Claude is never
@-mentioned in it, since a mention summons a separate session that has none of this context.

## When it is read

**On every turn the orchestrator takes, and whenever the player says "doc" or "check the doc".**
Nothing notifies the terminal session of an edit, and the player gives a heads-up when it matters
rather than have the board polled (inbox #830). A report from an agent, a merge or a review
verdict updates the Running table in the same turn.

## The layout

Top to bottom, every part present even when empty:

1. The title, the date and the player's mention, and one line: comment on any block to steer it.
2. `## Waiting on you`: the open questions, each as below, or the one line "Nothing is waiting on
   you right now." **A heads-up the player may want to act on goes here too, not only into a chat
   report** (inbox #850), since a line in a report is read once and scrolled away: a review thread
   resolved by mistake, a finding that slipped past a merge. *Proposed, not asked for, open to the
   player's correction:* it is written as a question, its My pick saying what happens if they leave
   it, and it stays until they answer it; a choice an agent made where the design was silent stays
   in its report and the pull request's description rather than coming here.
3. `## Settled`: answered questions, kept until they are filed into the queue, each as below.
4. `## Running`: a table `Item | What it is | State | Next`, one row per piece of work in flight —
   a refactor step, a fix, inbox notes waiting to be filed. A PR is a link in the State cell. Under
   it, one line on what comes after the running work.
5. `## Recently done`: a table `Merged | What`, the PR linked, newest first, the last six or so.
6. `## How this board works`: a bullet list of the rules below, in the player's terms.

**A question is a level-3 heading with a stable kebab-case name and one bullet list under it**,
nested exactly like this, the layout the player set on the board:

```markdown
### charger-size

- **Question:** how much larger should chargers' notice radius get?
- **Context:** everything needed to answer it, in this message.
  - **My pick:** the answer I would build, and why.
  - **You:** 
  - **Me:** 
```

- **Lists, never paragraphs** (inbox #830): a loose paragraph under a heading is a format error.
- **A bold label ends in a plain space** (inbox #830): `**You:** ` with the space outside the bold,
  so the player's typing after it is not bold. A Me stub is the same.
- **Context carries everything an answer needs**, as `CLAUDE.md`'s question rule says: what was
  asked and when, what it collides with, what each answer costs. A game thing is named the way the
  player knows it, with a clause saying what it is.
- **A question that blocks says so on its Question line**, ending it with `(blocks <the work>)`.
- A name stays with its question until it leaves the board, so the player can refer to it.

## Blocking, and no dialogs

**No question is put to the player as a modal dialog in the chat** (inbox #830): a dialog stops
the session and the player cannot scroll back while it is open, so they lose the context they need
to answer. The board is where a question goes. **A blocking question still blocks** (inbox #830):
the work it names stops until it is answered, and other work goes on. A question that does not
block runs on My pick; work built on a pick changes to the player's answer before it merges, if the
answer differs.

## Answering

- **General discussion is on the You line; the answer goes on the Me line under it** (inbox #830).
  The player's words are never written over, reworded or moved out of their line; a formatting fix
  the player asked for (unbolding their text) keeps every word.
- **A question about specific words is a comment on them** (inbox #830), answered in the same
  thread with a Claude Docs `create` utterance whose parent is the thread's root; never the Artifact
  tool's comment actions, whose replies do not show on the doc. A thread the player wrote in is
  never resolved by the orchestrator.
- **The player's words on the board are captured into the inbox like words in the chat**, before
  acting on them, with context naming the board question (**inbox**).

## Settling

A question is settled when the player's answer leaves nothing open. Its Me line then begins
"settled:" and says what will be built, and the question moves under `## Settled`. **A settled
question leaves the board once it is filed** — when the filing pull request carrying its inbox note
merges — since the queue holds it from then on and the board holds open things only. A Running row
moves to Recently done when its pull request merges.

## Keeping it cheap

A local script cannot run the board: it lives behind claude.ai's connector, which only the session's
Claude Docs tools call, with no credential a script could use. The saving is in what is read and how
often:

- **Read the changes, not the page.** Keep the last read's `rev` and read
  `{"kind":"view","sinceRev":<rev>}`: only the blocks changed since come back. Comments the same
  way: `query` with `under` the tab and `afterSeq` the last `seq` seen. A full read is for a lost
  bookmark only; `session-cleanup`'s restart prompt carries both numbers.
- **Write in one call.** Several ops go in one `update`, applied in order; a write's acknowledgement
  is the next write's anchor, with no read between.
- **Keep the page small.** Settled questions leave once filed and Recently done keeps the last few;
  the player's typed answers come back split into many small text runs, so a long-lived answer costs
  more on every full read.

The editor's traps that have each cost a failed call:

- A markdown source drops a trailing space, so a `**You:** ` stub written as markdown loses its plain
  space and the player's typing turns bold. Write the stub's paragraph as blocks instead: a bold
  `You:` text run followed by a plain `" "` run.

- A read prints later ids of a session short (`.10005`); a write needs the full id, the session of
  the nearest full id printed above it (`mqa612es4mw.10005`).
- A whole-block `replace` or `delete` needs `ifHash` and `ifRev` from the read that showed the block.
- A `replace` and a `move` of the same block are two calls, and one `move` takes one contiguous run
  of blocks.
- A paragraph with a comment on it is moved, never retyped, since retyping detaches the thread. In a
  list item, move it first in the item before deleting what else the item holds, or the delete is
  refused as leaving the thread nothing to hold.
