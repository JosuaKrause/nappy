# Playtest teal-quail — Fable is no gate while its quota is out, and the edit guard's read check is approved

2026-11-20.

Two of the player's notes from the sessions of 2026-11-20: their words in the session on the pull
requests held only for Fable's review while Fable's quota was out, and their answer on the Nappy board
to the question rules-hook-read-check. Each note opens with what its words answered.

## #1571

1. **Context** (the assistant's):

   The first line opened the session (after "orchestrator, continue."). The orchestrator answered with the pull requests held only for Fable's review (entry grassy-ibis, Fable reviews what Opus designed and built while its quota was out), simplest first:

   | PR | What it does | Size |
   |---|---|---|
   | #1569 | DrawnView stands in the world beside VisibleView, so the event looks stop naming classes above them | 9 files, +47/−22 |
   | #1568 | The street trees' pictures and their ground are a data class (TreePictures), so the trees stop naming Prop | 12 files, +125/−64 |
   | #1567 | The run log is handed the edge's danger badges (EdgeBadges) instead of naming the class that draws them | 24 files, +215/−70 |
   | #1564 | The city's ways out are a data type (CityExit), so the finale and the texts stop naming the edge's drawing class | 34 files, +183/−107 |
   | #1548 | Placement step 4: the beats become rigged marbles in the units ahead of her, including the rigged bag for the man shouting and the van. The one that changes play | 41 files, +1539/−1176 |
   | #1570 | Draft design only: the map interface's world half split off WorldMap; no build or adversarial review yet | 1 file |

   and proposed: merge #1569, #1568, #1567, #1564 now, smallest first, then #1548 alone once CI is green on top of them, editing each branch's "held for Fable" lines in the merge; #1570 goes to a builder instead of waiting. The second line ("yes") answered "Go ahead in that order?".

2. **The note.**

   > what are the simplest items that need a review right now? we can lift the fable need there for now
   >
   > yes

3. **Read as:** (the assistant's interpretation, not the player's words)

   The hold for Fable's review that grassy-ibis puts on polite-tapir's pull requests Opus designed and built is lifted while Fable's quota is out: a pull request with its adversarial review ready and green CI merges under committing's gates, and Fable's review of those designs is no longer a merge gate. "for now" is read as: until the player says otherwise; whether Fable looks at the merged designs once its quota returns is left open.

4. **Context** (the assistant's):

   Said in the session after the orchestrator's report on the edit-guard pull request (#1573) and the other running work; the nearest prior mention of Fable in the session was the orchestrator's report that #1570 (the map interface's world half) "merges once an Opus review passes and CI is green", because "You lifted the Fable hold (inbox #1571)", and that #1570 "keeps the fable-only label".

5. **The player's words.**

   > so once fable is available again it can look over it. but we can just completely work without it for now. if it later finds any issues we can do follow ups

6. **Read as:** (the assistant's interpretation, not the player's words)

   Fable is no gate on any work while its quota is out: pull requests built from Opus's designs in Fable's place merge on their Opus review and green CI, as inbox #1571 already reads. Once Fable is available again it looks over the work that merged without it (the designs of polite-tapir's groups, placement step 4's last pull request), and anything it finds is filed as follow-up work, not a reason to hold or revert. Whether "completely work without it" also lifts "one fable task at a time" (grassy-bison #1560), so that several of polite-tapir's groups are designed by Opus at once, is asked on this note, not read.

7. **Context** (the assistant's):

   Sent right after the line above ("so once fable is available again it can look over it. but we can just completely work without it for now. if it later finds any issues we can do follow ups"), while the orchestrator was recording it with the open point whether "one fable task at a time" (grassy-bison #1560) still holds.

8. **The player's words.**

   > so nothing should be blocking right now

9. **Read as:** (the assistant's interpretation, not the player's words)

   Nothing waits on Fable any more, the limit of one Fable task at a time included: polite-tapir's remaining standing-layer-break groups and its baseline reading are startable now, designed by Opus in Fable's place and built by the lowest model able, in parallel wherever their files are disjoint. Work still waits where two changes share files (row 3b of minty-quail's event-interface.md behind #1570's build), which is sequencing, not a Fable block. grassy-ibis (Fable reviews what Opus designed and built) becomes the later look over merged work, with follow-ups filed for what it finds. The open point in the reading above is answered by these words.

## #1588

1. **Context** (the assistant's):

   Written on the You line of the Nappy board question "rules-hook-read-check", which read:

   - Question: should the edit guard let a refused edit through on its retry only once it sees the named skills read? (built on my pick)
   - Context:
     - Today: the hook that guards an edit refuses the first edit of an area (a folder of the game's code, a doc) until the rules files (skills) that govern it are read; the same edit made again passes, and nothing checks the reading.
     - What happened: two builders since 2026-11-17 made a refused edit again without reading, even after the agents' contract was changed to forbid it.
     - The hook's own reason not to check: a check could refuse an edit for good when a skill reached the agent some other way.
     - The change: on the retry, the hook looks in the agent's transcript for a tool call that reads each named skill (a file read, a skill call, a shell or script command naming its file); one missing means refused again, naming the unread skills.
     - The cap: the third try passes whatever the transcript shows, so a skill read some other way costs at most two refusals.
     - My pick: build it; an agent is building it now and the pull request gets an Opus review. If you would rather keep the plain retry, the pull request is closed.

   The change merged as #1573 on 2026-11-19 (record sandy-trout).

2. **The note.**

   > okay

3. **Read as:** (the assistant's interpretation, not the player's words)

   The player approves the edit guard's read check and its three-try cap as built (#1573), so the rule's citation in CLAUDE.md and the record sandy-trout can rest on this note rather than on the orchestrator's proposal when the note is filed.
