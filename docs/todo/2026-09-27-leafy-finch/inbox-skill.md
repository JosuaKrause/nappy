**A skill, with a script, reads the inbox and files it** (statement 6). The inbox is the open
issues carrying an `inbox` label; an issue template gives the player a blank note with that label
already on it. The script lists the open inbox and prints one note in full: its body as it stands
now and the player's own comments on it, in order.

When the player asks for a batch to be filed, the agent copies each note's current text word for
word into a playtest file (`tools/new-name.sh playtest`), files the queue entries from it exactly
as **playtest-feedback** already says, and opens one PR whose description says `Closes #N` for
every note in the batch, so merging closes them. The player may edit a note until the PR merges;
an edit made after the copy is caught by the transcription check and the copy is redone. After the
merge the playtest file is the record, and a later thought is a new note, not an edit to a closed
one.

The skill says where to find the inbox at the start of a session, so **session-cleanup** lists the
open notes in the restart prompt and `CLAUDE.md`'s "where to pick up" names the inbox beside the
open PRs and the queue. A row for the script goes into the **using-tools** catalogue in the same
commit.

**Proposed, not asked for:** the label's name, `inbox`; that the player's comments on a note are
copied with its body; that a filing PR carries a whole batch rather than one PR per note.
