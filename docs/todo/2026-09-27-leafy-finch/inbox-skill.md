**A skill, with a script, reads the inbox and files it** (statement 6). The inbox is the open
issues carrying an `inbox` label; an issue template gives the player a blank note with that label
already on it. The script lists the open inbox and prints one note in full: its body as it stands
now and the player's own comments on it, in order.

**For now, only an issue the player opened, or the capture script opened for them, is an inbox
note** (statement 19: "for now let's also require that inbox issues are created by me so random
people opening github issues don't get their comments ingested into the queue"). The repository
is public and the template's label goes on any issue opened with it, so the label alone admits
anybody, and the rule exists so that people outside the project never put work into the queue
(statement 23). An issue the capture script of `capture.md` opens as `claude-orchestrator` or
`codex-coder`, holding the player's own words and carrying the script's tag, counts as the
player's (asked, the player answered "yes, otherwise the workflow wouldn't work", and chose "Yes,
marked by the script"). So the script reads an issue's author and tag and skips, with a line
saying so, every other issue, and every comment not written by the player. The transcription check
of `transcription-ci.md` fails on a filed note with any other author.

**A label on a note says which band its work is filed in** (statement 21: "also add to use labels
for when a task should be queued, now, later, etc"). The queue's four bands — `now`, `next`,
`later`, `parked`, which `tools/queue.sh` orders the queue by — each have a label the player puts
on a note, and the entry filed from it opens with that band. A note with no band label is filed
as **playtest-feedback** says today: `now` for a note from playing, and for anything else a band
the filer proposes and names in its report. The capture script takes a band when the player named
one in what was captured.

**Questions about a note are asked on its issue** ([dotted-quail](../../playtests/2026-09-27-dotted-quail.md),
statement 1: "oh, also if you need more info you can also ask in the github issue. so by the time we queue a
task most questions are already resolved"). An agent that reads a note and needs more from the
player to file it faithfully posts the question as a comment on that issue, through the inbox
script, and the player answers there. The player's answers are their own comments, so they are
copied with the note, and each is recorded with the question it answers, as **playtest-feedback**
asks for words said in conversation.

When the player asks for a batch to be filed, the agent copies each note's current text word for
word into a playtest file (`tools/new-name.sh playtest`), files the queue entries from it exactly
as **playtest-feedback** already says, and opens one PR whose description names every note in the
batch (`Filed from #N`, never `Closes #N`, which would leave the note open and editable until the
merge). Right after pushing the PR, the orchestrator closes every note of the batch in one action
(statement 22). The player edits a note until then; from then on the playtest file is the record,
and a later thought is a new note, not an edit to a closed one (option E's "after filing, a later
thought is a new note", which the player accepted with the rest of the list). A filing PR that is abandoned
reopens its notes.

The skill says where to find the inbox at the start of a session, so **session-cleanup** lists the
open notes in the restart prompt and `CLAUDE.md`'s "where to pick up" names the inbox beside the
open PRs and the queue. A row for the script goes into the **using-tools** catalogue in the same
commit.

**Proposed, not asked for:** the label's name, `inbox`; that the player's comments on a note are
copied with its body; that a filing PR carries a whole batch rather than one PR per note; the band
labels' names (`band: now` and so on, so they read apart from any other label); that a note with
two band labels is filed under neither and asked about; that an abandoned filing PR reopens its
notes; that the inbox script posts the question, under the same identity as a capture.
