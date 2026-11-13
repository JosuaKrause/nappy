# Filing a batch of notes

Part of **inbox**. Read it whole before filing a batch of the player's notes into the queue: it is
the steps in order, from reading the notes to closing them, with what `tools/inbox.py cite` edits
and what it leaves for a hand fix. The rules that hold at every other moment (what a note is,
capturing, asking) are in `SKILL.md`.

**A batch is filed when the player asks, never on the agent's own initiative.** One filing pull
request carries the whole batch:

- **List and read every note** with `list` and `show`, and settle what is unclear by asking on the
  issue first.
- **Draft each note's playtest section with `tools/inbox.py draft N M ...`** and put it in a
  playtest file made with `tools/new-name.sh playtest "<title>"`. The draft is the filed layout,
  every block labelled: the player's quote blocks in `> ` lines, the only lines that are the
  player's; context, a note and a correction as the assistant's sentences; a reading under
  `Read as:` (inbox #767 in minty-lemur); a corrected line flagged in a sentence right after its quoted block,
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
  uv run python tools/inbox.py cite N M ...           # the numbers of the batch, as in its `Filed from` lines; prints the diff, writes nothing
  uv run python tools/inbox.py cite N M ... --write   # edits the files
  ```

  The pull request does not exist yet at this step, so the notes are given by number; once it is
  open, `cite --pr P` reads the same numbers from its `Filed from #N` lines, for a later pass.

  `cite` finds each note's playtest from its `## #N` heading under `docs/playtests/` and, in every
  tracked text file outside `docs/playtests/`, turns the plain `inbox #N` (and a run such as
  `inbox #9001, #9002 and #9003`) into `inbox #N in name`, the playtest's bare name, in every file,
  Markdown and skills included, and never into a link: `CLAUDE.md`'s citation rule counts that form
  as a citation, and `tools/check_citations.py` checks that the name holds the note. A number counts
  only as `#N` followed by no digit or letter, or as `issues/N` in a URL, so an SVG colour such as
  `#9004a6` never matches. A run wrapped across a line (up to three lines, a `> ` quote marker
  skipped) is read as one run, and a citation whose ` in` ends a line is named by the next line's first
  word. A bare `(#N)`, a range such as `#9001-#9005`, an issue URL, a link text
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
