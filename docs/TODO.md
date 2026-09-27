# TODO

**The queue. Open work only.** Each entry is a folder under [todo/](todo/), named
`<date filed>-<adjective>-<animal>` and spoken by its two words ("busy-badger"); an entry filed
before names keeps its milestone number (`2026-09-26-M210`). Its `README.md` holds the player's
words, the playtest links and the context, and each item is a file of its own beside it, written
in full prose. Finishing an item deletes its file; when the last one goes, the folder goes and the
entry's record is written to [decisions/](decisions/) under the same name, in the same commit.
Search the records (`tools/decisions.sh <noun>`) before designing anything. No ticked boxes, no
"Done:" paragraphs, no branch names or status words in headings, here or in an entry.

`tools/new-name.sh todo "<title>"` makes a new entry's folder, its `README.md` opening with
`priority: later` unless `--priority` names another band, and prints its name. Read
[HANDOFF.md](HANDOFF.md) first for the state of the tree.

Each entry is one git branch, squash-merged to `main` through its pull request. An item somebody
is mid-way through says so in its own text.

---

## The order is `tools/queue.sh`

**There is no order list to edit.** *(2026-09-26: "what's the point of any of this if there is
still a centralized TODO.md ordering list? can we think of a better solution there? a priority
system?", [2026-09-26-brisk-heron](playtests/2026-09-26-brisk-heron.md), statement 13.)* Each
entry's `README.md` opens with its band, one of `now`, `next`, `later` and `parked`, and, where it
truly waits on another entry, an `after:` line naming that entry's folder:

```
priority: next
after: 2026-09-09-M100

## M56 — The resistance is noticed
```

`tools/queue.sh` prints the queue from those lines: the bands in that order, `now` newest first
*("for "now" do reverse chronological maybe?", statement 14)* and every other band oldest first by
the date the folder's name starts with. Entries filed on the same day sort by name, not by when
they were filed: old milestone numbers in number order, then named entries by their words, and
`now` reverses that too. An entry never prints before an open entry its `after:` names; one that
would is held back to straight behind it. An `after:` naming an entry that has closed (its folder
gone, its record under `decisions/`) holds nothing back and prints as `<name>, closed`, and the
end-of-session pass deletes the line, so closing an entry never edits another.
`tools/queue.sh --band now` prints one band. Moving an entry between bands edits one line of one
file, and `tools/lint.sh` rejects an entry with no band, a band outside the four, an `after:`
naming neither an open entry nor a closed one, an `after:` cycle, and a band line anywhere but the
opening lines of the `README.md`.

**A band is chosen on what the entry does to the route decision, and nothing goes lower for being a
drawing.** *(2026-09-07: "let's remove the note about not working on graphics because it causes
much confusion.")* Prepared drawings stay available while the entries that own them settle their
placement and behavior; [GRAPHICS.md](GRAPHICS.md) is the asset catalogue, the live bindings and
the prepared parts.
