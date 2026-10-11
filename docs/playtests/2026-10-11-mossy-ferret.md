# Playtest mossy-ferret — The south water, Hard Mode's nerves, and a bug band and an up-next band

2026-10-11.
Said in one session as three notes the assistant captured into the inbox on GitHub Issues, #708, #709
and #710, with the player's further words appended to them. Each note is recorded as it holds: first
what its words answered, then the words themselves, whole, and each later word after what it
answers. The questions and context are the assistant's; only the quoted lines are the player's.

## #708

1. **What the note answered** (the assistant):

   Said unprompted mid-session, while the agent landed the velvet-marten filing (PR #702) and filed GoatCounter counts by release (PR #707), with two performance fixes (bouncy-swan and M159) running.

2. **The note.**

   > we need to redo the water+its animation at one point. we basically just need a blue base and we can create white lines via randomly placing centroids and drawing the voronoi outlines of each region. then we oscillate the intensity of each centroid which will move the voronoi boundaries around in a way water looks. we will have to start with a standalone experiment

3. **What the next words answered** (the assistant):

   The agent replied that the entry would quote M100 ("water, smoke and steam move") as what it replaces, keep the burst water main out of scope unless said otherwise, start with a standalone experiment returned early as a short motion capture, and measure its per-frame cost, since the phone records show the phone's renderer is bound by how many pixels it fills and a per-pixel Voronoi effect over every water tile could cost exactly there.

4. **The player's words.**

   > I meant only the water at the south end of the map -- this technique won't work for other water instances. we could prerender into tiles if performance becomes an issue

## #709

1. **What the note answered** (the assistant):

   Said unprompted mid-session. Hard Mode is quiet-lynx (#681, "checkpoints, and a Hard Mode that has none"): in a normal run, nerves at 0 go back to the latest checkpoint (day 1, 4, 8 or 12) with five nerves; in Hard Mode they end the run (the bad ending).

2. **The note.**

   > can we make hard mode not regenerate nerves as well?

3. **What the next words answered** (the assistant):

   Asked: Hard Mode was built under "hard mode doesn't affect gameplay -- only restart pacing" (gentle-osprey). Today a won day gives one nerve back, up to five, in both modes (`GameState.regain_a_nerve()`). (a) No regain at all in Hard Mode: a won day gives nothing back, and the docs' one-line rule is rewritten since Hard Mode would then change how the run plays (the agent's pick, the plain reading). (b) Regain only in some cases, for example on reaching what would have been a checkpoint day (4, 8, 12).

4. **The player's words.**

   > (a) this doesn't affect *gameplay* it still only affects restart pacing

5. **What the next words answered** (the assistant):

   The agent read the answer as: in Hard Mode a won day gives no nerve back, and "hard mode doesn't affect gameplay -- only restart pacing" stands unchanged, since nerves only decide when a run ends.

6. **The player's words.**

   > by gameplay I mean -- enemies are not harder. or excitement or sleepiness doesn't move in on different values

7. **What the next words answered** (the assistant):

   Continuing the player's definition of "gameplay" in "hard mode doesn't affect gameplay -- only restart pacing", after "by gameplay I mean -- enemies are not harder. or excitement or sleepiness doesn't move in on different values".

8. **The player's words.**

   > or distribution of events doesn't change

9. **What the next words answered** (the assistant):

   Continuing the player's definition of "gameplay" in "hard mode doesn't affect gameplay -- only restart pacing", after "by gameplay I mean -- enemies are not harder. or excitement or sleepiness doesn't move in on different values" and "or distribution of events doesn't change".

10. **The player's words.**

   > anything that happens *during* a day is gameplay

## #710

1. **What the note answered** (the assistant):

   Said after the agent listed the queue (`tools/queue.sh`: 17 entries in `now`, 9 in `next`, 17 in `later`, 1 parked), the three active agents (bouncy-swan, M159's crowd tick, spotted-badger) and the inbox (#708, #709). The bands are `now`, `next`, `later` and `parked` (brisk-heron, statement 13: "a priority system?"), set by an entry's `priority:` line and an inbox note's `queue_<band>` label; there is no order list to edit.

2. **The note.**

   > next to pick up 709, teal-trout, feathery-lemur, pebbly-ibis, spry-magpie. we need a new band "bug" that has priority over now. also, maybe something to indicate what to work on next?

3. **What the next words answered** (the assistant):

   Clarifying "maybe something to indicate what to work on next?" in this note.

4. **The player's words.**

   > like "immediately after the current items are done" next, not the band next

5. **What the next words answered** (the assistant):

   Asked how an entry is marked as "pick up immediately after the current items are done". Options: "up-next line (Recommended)": an `up-next: true` line in the entry's opening block, printed first by queue.sh in an 'up next' section with the active entries (those with a live agent brief), removed by the orchestrator when it starts the work; "Inbox label": a GitHub label `up_next`, read by queue.sh through the GitHub CLI; "A short list file": a checked-in `docs/todo/UP-NEXT.md`, which brings back the shared file M223 removed.

6. **The player's words.**

   > what would be the issue with making it a band?

7. **What the next words answered** (the assistant):

   Asked whether notes from playing, filed `now` today ("a playtest note is filed now unless the player names another band", 2026-09-27), should be filed in the new `bug` band. Options: "Bugs from play → bug (Recommended)"; "Only when you say so": notes still default to `now`, an entry goes to `bug` only when the player names that band (an issue label `queue_bug`); "Every playtest note → bug".

8. **The player's words.**

   > Only when you say so

## Filed as

- **#708**: [amber-puffin](../todo/2026-10-11-amber-puffin/README.md), the south water is a blue base
  with drifting Voronoi lines, starting with a standalone experiment.
- **#709**: [dotted-hawk](../todo/2026-10-11-dotted-hawk/README.md), in Hard Mode a won day gives no
  nerve back.
- **#710**: [lilac-stork](../todo/2026-10-11-lilac-stork/README.md), a bug band above now, and an
  up-next band above both. The four entries it names besides #709 (teal-trout, feathery-lemur,
  pebbly-ibis and spry-magpie) were started in the session; #709's dotted-hawk is filed `now`.
