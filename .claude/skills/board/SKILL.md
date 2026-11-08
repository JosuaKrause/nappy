---
name: board
description: The Nappy board, the shared Claude Doc where the player and the orchestrator keep the open questions, the running work and the recent merges — its layout, how a question is written, answered and settled, how the player's words on it are captured, and the reads and writes that keep it cheap. Load this BEFORE the orchestrating session asks the player a question, which goes on the board rather than in a dialog (one about an inbox note may go on its issue instead), BEFORE reading or writing the board, and whenever the player says "doc" or "check the doc".
---

# The Nappy board

**Questions and steering live on one standing page, not in the chat** (inbox #830 in minty-dolphin). In the chat a
question is drowned by the reports that follow it, gets repeated at the end of every message, and a
numbered list renumbered between messages lets an answer land on the wrong question. The player
asked for a standing list of tasks and questions, with their thoughts written under each one and
the answers given in line, and chose a shared doc over GitHub issues, which are too slow for a
conversation (inbox #830 in minty-dolphin).

The board is the Claude Doc "Nappy board", https://claude.ai/artifact/UbMpXbepDzN4Mfgs7tAxqm (doc id
`df72dcc8-963b-4b22-bf78-ca097d25c920`; its Main tab `4560d3a5-7376` with body node `bdec01d2-2025`,
its Review tab `86f8ada2-8639` with body node `db7c662c-d0a4`). Only a Claude Code session with the
Claude Docs tools reaches it; Codex has no route to it. **Only the orchestrating Claude Code session
acts on it**: any other session that opens it changes nothing and answers nothing (inbox #830 in
minty-dolphin), and the board says so. Claude is never @-mentioned in it, since a mention summons a
separate session that has none of this context.

## When it is read

**On every turn the orchestrator takes, and whenever the player says "doc" or "check the doc".**
Nothing notifies the terminal session of an edit, and the player gives a heads-up when it matters
rather than have the board polled (inbox #830 in minty-dolphin). A report from an agent, a merge or
a review verdict is not written to the Running table at once: the board is the player's information
and the channel they answer on, so it is updated in batches, and the orchestrator's own temporary
working state is kept in the local restart prompt (**session-cleanup**, step 8), which a fresh session
can recover from. The player usually asks for the current state before looking at the board
(inbox #986 in brisk-pelican). *Proposed, not asked for, open to the player's correction:* a batch is
whenever the orchestrator next writes the board for the player: a question, an answer, or the player
asking for the state. **Both tabs are read**, since the
player answers review items on the Review tab and design questions on the Main tab.

## The layout

Top to bottom, every part present even when empty:

1. The title, the date and the player's mention, and one line: comment on any block to steer it.
2. `## Waiting on you`: the open questions, each as below, or the one line "Nothing is waiting on
   you right now." **A heads-up the player may want to act on goes here too, not only into a chat
   report** (inbox #850 in minty-dolphin), since a line in a report is read once and scrolled away: a review thread
   resolved by mistake, a finding that slipped past a merge. *Proposed, not asked for, open to the
   player's correction:* it is written as a question, its My pick saying what happens if they leave
   it, and it stays until they answer it; a choice an agent made where the design was silent stays
   in its report and the pull request's description rather than coming here.
3. `## Settled`: answered questions, kept until they are filed into the queue and gone the moment
   they are, or until the chat has fully discussed them (see "Settling"), each as below.
4. `## Running`: a table `Item | What it is | State | Next`, one row per piece of work in flight —
   a refactor step, a fix, inbox notes waiting to be filed. A PR is a link in the State cell. Under
   it, one line on what comes after the running work.
5. `## Recently done`: a table `Merged | What`, the PR linked, newest first, the last six or so.
6. `## How this board works`: a bullet list of the rules below, in the player's terms.

That is the Main tab. **The review items have a tab of their own, Review, in the same overall style,
and it is kept in step with `docs/review/`** (inbox #948 in bouncy-marten). A review item under
`docs/review/` is a sign-off check that needs a set-up run or a device and is answered one at a
time, while the Main tab's questions are design decisions about work in flight and are answered in
a batch, so the two kinds stay apart; a review item stays a file in the repository, and the tab only
shows it. The answer goes to a playtest file as before, which closes the item's file
(**playtest-feedback**). *Proposed, not asked for, open to the player's correction:* the tab holds
a title and one line saying what it is for, `## Waiting on you` with the items ready to answer (or
the one line "Nothing is ready for you right now."), and below it a section for items held until
something happens, such as `## Waiting for a release`, where the item's file says what it waits
for; each item is a question in the layout below with its review item's name in its Question line
and the steps in its Context; and an item added, held or closed in the repository is added, moved
or removed on the tab in the same turn.

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

- **Lists, never paragraphs** (inbox #830 in minty-dolphin): a loose paragraph under a heading is a format error.
- **A Context never stands as one long run of text** (inbox #1163 in gray-dolphin): it is a nested list of short
  items, each one fact or one option, and a picture or a diagram may carry what words carry badly.
  Options or steps never sit as "(1) … (2) …" inside a sentence (inbox #1163 in gray-dolphin): each goes in its own
  list item, in an ordered list where the order matters.
  *Proposed, not asked for, open to the player's correction:* a bold lead word on an item where that
  helps the reader scan, and a map, an order of steps, or a before and after as the pictures meant.
- **A bold label ends in a plain space** (inbox #830 in minty-dolphin): `**You:** ` with the space outside the bold,
  so the player's typing after it is not bold. A Me stub is the same.
- **Context carries everything an answer needs**, as `CLAUDE.md`'s question rule says: what was
  asked and when, what it collides with, what each answer costs. A game thing is named the way the
  player knows it, with a clause saying what it is.
- **A question asks one thing** (inbox #1163 in gray-dolphin): a choice with several parts goes on the board as one
  question per part, each with its own heading, Context, My pick, You and Me, so the player answers
  each on its own line and a question never bundles a design with its open choices, or which items
  to build with their order.
- **A question that blocks says so on its Question line**, ending it with `(blocks <the work>)`,
  and its Context says what pivoting later would cost; a question that does not block ends it with
  `(built on my pick)` (see "Blocking, and no dialogs").
- A name stays with its question until it leaves the board, so the player can refer to it.

## Blocking, and no dialogs

**No question is put to the player as a modal dialog in the chat** (inbox #830 in minty-dolphin): a dialog stops
the session and the player cannot scroll back while it is open, so they lose the context they need
to answer. The board is where a question goes, apart from one about an inbox note, which may go on its issue (**inbox**). **A blocking question still blocks** (inbox #830 in minty-dolphin):
the work it names stops until it is answered, and other work goes on.

**A question blocks only when changing course after the answer would be very costly** (inbox
#1194): a pick whose undoing means rebuilding a system, migrating a save or rewriting work several
pull requests stand on. Everything else is built on My pick at once, and the work changes to the
player's answer when it comes, before the pull request merges or in a later one, if the answer
differs. A pick on a placement, a number, a merge order, or a choice between two cheap
implementations never blocks. The exception is a pick that would drop, narrow or reinterpret
something the player asked for: **playtest-feedback**'s "Never silently overturn a decision the
player took" holds, and that part is not built until they answer, however cheap it would be to undo.

**A question the player's recorded words already answer is not asked** (inbox #1185, inbox
#1194): putting one up costs them a round trip to repeat themselves. Before a question goes on the
board, the note it comes from, its appended words and the settled questions on the same work are
read for an answer; where they give one, it is built, and the reading is stated in the brief and in
the pull request's description, open to the player's correction there.

**The same holds for an open point anywhere, not only a board question** (inbox #1232): an `Open:`
line in a queue item or a record, a "whether…" a filer left, or a point the orchestrator would
raise in a chat answer. Before it is relayed, it is read against the player's recorded words, the
whole entry it sits in included (items filed from one note belong together). The words answer it
where their plain meaning does, even if they never name the point (inbox #1234): a hint about a
thing she sees fires when she first sees it. Where the words answer it, the answer is stated as the reading, and the line is rewritten when the item is next
touched; it is never handed back for the player to restate.

## Answering

- **General discussion is on the You line; the answer goes on the Me line under it** (inbox #830 in minty-dolphin).
  The player's words are never written over, reworded or moved out of their line; a formatting fix
  the player asked for (unbolding their text) keeps every word.
- **A reply on a Me line is followed by a fresh You stub and a Me stub** (inbox #1163 in gray-dolphin): when the
  orchestrator writes its reply on a Me line, it adds a fresh You stub right after it, and a Me stub
  after that, so the player can answer again in line; a "settled:" reply, which moves the question
  under Settled, gets no fresh stubs. Each stub is written as the layout says: a
  bold label, then a plain space outside the bold, as "The editor's traps" says.
- **A question about specific words is a comment on them** (inbox #830 in minty-dolphin), answered in the same
  thread with a Claude Docs `create` utterance whose parent is the thread's root; never the Artifact
  tool's comment actions, whose replies do not show on the doc. A thread the player wrote in is
  never resolved by the orchestrator.
- **The player's words on the board are captured into the inbox like words in the chat**, before
  acting on them, with context naming the board question (**inbox**).

## Settling

A question is settled when the player's answer leaves nothing open. Its Me line then begins
"settled:" and says what will be built, and the question moves under `## Settled`. A Running row
moves to Recently done when its pull request merges, apart from a filing's (below), at the next
batch (**When it is read**).

**An item that is fully filed leaves the board whole, with no record of it kept there**
(inbox #877 in minty-dolphin): once the filing pull request carrying its inbox note merges, its settled question,
its mention in the Running row of notes waiting to be filed, and any line about the filing go at the
next batch, and no Recently done row or "filed" note stands in for them. The queue and the records
hold it from then on, and the board holds open things only.

**A question the player and the orchestrator have fully discussed in the chat leaves the board**
(inbox #1163 in gray-dolphin), whether or not it is settled, and that overrides keeping a settled question until it
is filed. A blocking question removed this way no longer blocks: its outcome stands. *Proposed, not
asked for, open to the player's correction:* before it goes, the outcome is recorded on its inbox
note, as the standing pick or the settled answer; where the question has no inbox note, the outcome
goes into the restart prompt and the work it decides.

## Keeping it cheap

A local script cannot run the board: it lives behind claude.ai's connector, which only the session's
Claude Docs tools call, with no credential a script could use. The saving is in what is read and how
often:

- **Read the changes, not the page.** Each tab's body has a `rev` of its own: keep the last read's
  `rev` for each tab and read `{"kind":"view","sinceRev":<rev>}` on each: only the blocks changed
  since come back. Comments the same way: `query` with `under` each tab and `afterSeq` the last
  `seq` seen there. A full read is for a lost bookmark only; `session-cleanup`'s restart prompt
  carries the numbers for both tabs.
- **Write in one call.** Several ops go in one `update`, applied in order; a write's acknowledgement
  is the next write's anchor, with no read between.
- **Keep the page small.** A filed item leaves whole and Recently done keeps the last few;
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
- Deleting a question's heading does not delete the list under it. Name the heading and its list in
  the same delete. Deleting a list the player typed in leaves their typed runs behind as loose
  paragraphs; check for them with an outline read afterwards, and delete them once their words are
  captured.
