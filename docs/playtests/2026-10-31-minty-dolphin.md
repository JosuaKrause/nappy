# Playtest minty-dolphin — Inbox batch: the board, the refactor's order, day one's lessons, frame-locked clocks and agent size

2026-10-31.

## #830

1. **Context** (the assistant's):

   Said on 2026-10-24 in a long orchestrating session where several agents ran at once, each report and fix showed in the chat, and the orchestrator repeated open questions (numbered 1, 2, 3 anew in each message) at the end of every message.

2. **The note.**

   > also we need to figure out a way to better communicate. in chat I currently see every time you make a change anywhere so when you say something it immediately gets drowned out by further work that is happening. also you need to keep repeating the same question over and over again until I get a chance to see it. that bears the risk that I'm answering a question by number when you already reassigned the number for a different question so I need to provide enough context for you to properly associate an answer. ideally, I would like a standing list of tasks and questions where I can write my thoughts/steering under each one separately and you can provide responses in line

3. **Context** (the assistant's):

   Said on 2026-10-24 right after the orchestrator put a blocking multiple-choice question (Claude Code's question dialog) to the player about where the standing list should live (GitHub issues or a shared Claude Doc); the player declined it to clarify.

4. **The player's words.**

   > don't bring up blocking questions much since that is another issue because you cannot do anything while asking me and I cannot scroll so I lose context as well

5. **Context** (the assistant's):

   The player's answer on 2026-10-24 to where the standing list should live: the orchestrator recommended GitHub issues (one per question, a pinned board issue) over a shared Claude Doc (a living page, comments on each item, not sure comments reach the terminal session).

6. **The player's words.**

   > github issues are too slow -- we already use that but it's not a good platform for conversations. a shared doc would work -- how would that look like? how would you get notified I wrote anything?

7. **Context** (the assistant's):

   The player's answer on 2026-10-24 to the orchestrator's description of a shared Claude Doc as the standing list (one block per open question with a stable name, a table of running work, comments on any block answered in the same thread; no push notification reaches the terminal session, so the orchestrator checks the doc whenever it takes a turn, or on a heads-up in chat, or in a /loop). The doc is "Nappy board", https://claude.ai/artifact/UbMpXbepDzN4Mfgs7tAxqm.

8. **The player's words.**

   > okay let's try that. I can always give you a heads up to check the doc so you don't have to poll it

9. **Context** (the assistant's):

   Written on 2026-10-24 in the shared doc "Nappy board" (https://claude.ai/artifact/UbMpXbepDzN4Mfgs7tAxqm), under the question "bands": "Are the new entries' places in the queue right? None of your notes named a band, so these are mine: grassy-beaver (day one) now, after the refactor; lilac-marten (after-refactor fixes) now, after the refactor; coral-newt (sound and art tools) next; sandy-kestrel (music) later; spry-swan (cross-posting) later, after day one. My pick: as listed. One alternative worth a word: day one before the refactor finishes, since it is what loses new players today — it would collide with the refactor's next steps in the event code." Then, in chat: "I responded with one item -- for me it's not clear what is from you and what is from me -- can you just add response stubs".

10. **The player's words.**

    > the escape and day one fixes can go after the refactor the rest is good, too. next time please use a list that makes it easier to read

11. **The player's words.**

    > I responded with one item -- for me it's not clear what is from you and what is from me -- can you just add response stubs

12. **Context** (the assistant's):

    Said on 2026-10-24 while the orchestrator was adding You/Me response stubs under each question on the Nappy board, after the player asked for "response stubs".

13. **The player's words.**

    > where I can fill in my comments

14. **The player's words.**

    > I also like comments, too, we can use both. use comments for specific questions about spans and the response area for general discussion

15. **Context** (the assistant's):

    Written on 2026-10-24 on the Nappy board, under its opening line "Nothing here blocks work: each runs on my pick until you write on its You line."

16. **The player's words.**

    > this is *not* what I meant by not blocking. Non blocking means you don't run a modal dialog in chat. If an item blocks you from continuing you still stop working on it until it is resolved.

17. **Context** (the assistant's):

    Two more on the Nappy board, 2026-10-24: a You line under the board's opening, and a comment on the words "the others carry on with my pick" in the orchestrator's reply "understood: no modal dialogs in chat. A question that blocks a piece of work stops that work until you answer; the others carry on with my pick."

18. **The player's words.**

    > in you answer stubs can you set the font to normal, right now it's always bold when I continue writing (just add a normal space after the bold You/Me)

19. **The player's words.**

    > what do you mean by that?

20. **Context** (the assistant's):

    Said on 2026-10-24 in chat, after the player had nested My pick, You and Me under Context in each question on the Nappy board ("fixed some formatting"), while older items on the board still used earlier layouts (loose You/Me paragraphs, a list with no Question or Context line).

21. **The player's words.**

    > Can you make sure the doc uses consistent formatting throughout (some items you added later follow the new format while some old items still have the old format) male a skill for format and interaction. Is it possible to let it run through a script to safe tokens?

22. **Context** (the assistant's):

    Written on 2026-10-24 by the player on the Nappy board, as a bullet under "How this board works".

23. **The player's words.**

    > If you're not the Claude code session, then you're probably reading this by accident. Don't make changes or answer questions in this case

## #834

1. **Context** (the assistant's):

   On the Nappy board, 2026-10-24, question "release-scope": which fixes does v0.30.0 wait for? Context given: the player approved a minor release once the refactor and "the fixes from the last playtest" land, said on Oct 19 when the newest playtest was minty-lemur (its open fix snowy-goose, explosions in the escape city); the three after-refactor fixes (lilac-marten: a fuller escape, shorter charger warnings with larger radii, total time on the ending screens) came the same day from a note. The orchestrator picked: wait for both.

2. **The note.**

   > the refactor, the escape fix, the day one fixes

3. **Context** (the assistant's):

   On the Nappy board, question "crossing-bubble": should day 1 get a thought bubble for running across the street? (a bubble the first few times she steps into the road away from a crossing, pointing at the nearest crossing; the orchestrator picked yes, built with the other bubbles).

4. **The player's words.**

   > yes

5. **Context** (the assistant's):

   On the Nappy board, question "car-accident-day-1": should the loud car accident (a street closure that also makes noise, placed from day 1, day 1's largest crying loss) come off day 1? The orchestrator picked: yes, off day 1; it stays from day 2.

6. **The player's words.**

   > yes, let's keep things light on day 1. move it to day 2

7. **Context** (the assistant's):

   On the Nappy board, question "park-blocked": on day 2, does yesterday's park need to be blocked, or is spoiled enough? (the player had said a player retrying day 1's path on day 2 "will find the park blocked"; today a park used the day before is spoiled with noisy events but stays walkable; the orchestrator picked: spoiled is enough).

8. **The player's words.**

   > spoiled actually teaches the lesson. there should be a path that touches the first day's park so the player learns this lesson (since they are free to go to it again)

9. **Context** (the assistant's):

   On the Nappy board, question "opening-shot-scope": does "let's experiment" mean only the day-1 shot, or also trying shots on later days? (the player had left the opening shot on day 1 for now, "but let's experiment"; the orchestrator picked: day 1 only, as an experiment the player sees before it is kept).

10. **The player's words.**

    > it means I make a few test runs and see how it feels

11. **Context** (the assistant's):

    On the Nappy board, question "charger-size": how much larger should chargers' notice radius get? ("slightly larger", and later 180px, the escape roadblock guard's, "way too small"; the orchestrator picked: the builder proposes numbers under the balance rules and shows the player before they ship).

12. **The player's words.**

    > both say it should be bigger. we need to experiment

13. **Context** (the assistant's):

    On the Nappy board, question "timing-lesson": should day 2 teach timing a moving obstacle (a cyclist, a dog)? Context given: the player's list had (e) "time the approach for moving obstacles"; the orchestrator proposed it for day 2 only as traffic timing, and the player's answer took traffic out, so (e) had no home; the orchestrator picked day 2's first cyclist or dog placed where she has to time it. "The yeller" is the homeless yeller, the pacing man who walks a beat on a sidewalk.

14. **The player's words.**

    > yeller is also a moving obstacle. -- also we can teach multiple things in a day if we make things progressively harder. we could teach the yeller on day 1 but after the other lessons

## #838

1. **Context** (the assistant's):

   Said on 2026-10-24 in chat, about the player's r/ClaudeGameDev post of 2026-10-20 (a video as the post's main content, the game's link in the body), which docs/stats/2026-10-24-goatcounter.md measured as a short bump: visitors went from about one a day to 8 and back within three days. It bears on spry-swan, cross-posting the game once day one teaches, whose drafts are written for the player to post by hand.

2. **The note.**

   > I think the issue with the post was that we put the video up front and the link on the body. Next time let's flip it around. Link to the game as main link and video in the body

## #842

1. **Context** (the assistant's):

   Said on 2026-10-24 in chat, after PRs #839 and #840 each came back not ready several times (#839 three times, after which the orchestrator wrote a rethink on the PR, as pr-review's "Three verdicts of not ready" section already asks of the orchestrating session, woolly-penguin #759).

2. **The note.**

   > let's implement a rule that if a review comes back not ready three times the agent has to rethink the approach

3. **Context** (the assistant's):

   Written on 2026-10-24 on the Nappy board, on the You line of the question rethink-author: after a PR's third not-ready review, who writes the rethink (options: the builder writes it and the orchestrator checks it; the orchestrator keeps writing it; the builder drafts and the orchestrator decides), and whether to trigger at two not-ready verdicts sharing one root cause. The orchestrator's pick was the builder, plus the earlier trigger.

4. **The player's words.**

   > we can try leaving it to the coder but they might not have the required capabilities (eg if they're a haiku) so it really needs to be decided for each case. if the orchestrator thinks the coder has enough context and capabilities they can ask them otherwise they should do it themselves or start a fresh planning agent

## #845

1. **The note.**

   > why one PR at a time? no way to partition work?
   >
   > okay, let's do the refactor in a way that things will ultimately be independent but it's okay if it needs to be sequential right now

2. **Context** (the assistant's):

   Asked while events-composed (minty-quail, events composed from behaviours) ran as four sequential PRs on the same two files. I proposed starting main-and-state (main.gd's run flow and run state) and shared-components' walker/car split in parallel, since neither touches the events files; the excitement-source and placement parts of shared-components and tuning's constant moves collide with later events steps.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The refactor's goal includes leaving its parts independent of each other, so that later work on them can be partitioned across parallel agents; where two items touch the same code now, running them one after another is fine. Items that are already independent run in parallel.

## #849

1. **Context** (the assistant's):

   Written on the Nappy board under the question `lesson-dog-ids` ("in the events refactor, do the day-3 lesson dog and the task guard keep their current event ids, or become catalogue rows of their own with new ids?"). The orchestrator's pick there was to keep the ids (`charging_dog`, `alley_robbery`) so GoatCounter's event names and the summary screen's loss causes keep one history; this is the player's reply on its You line. It is fork 1 of minty-quail, events-composed; the work it decides is step 2b.

2. **The note.**

   > if we switched ids we would be able to tell them apart on goatcounter? That would be a win. How is it on code duplication? How entangled is the code?

3. **Context** (the assistant's):

   Answer on the board question lesson-dog-ids, 2026-10-25, to the orchestrator's new pick: the day-3 lesson dog and the task guard become catalogue rows of their own with new ids, derived from the charging-dog and alley-robbery rows, so their GoatCounter "seen" and lost-day counts go under new names (events step 2b of minty-quail).

4. **The player's words.**

   > new id, then

## #850

1. **Context** (the assistant's):

   Said in the chat about the orchestrator's message "The reviewer's comment thread for that nit got resolved by mistake. Reopen it on #847 if you want it tracked." — a note left for the player to act on (or not), given only in the chat report after #847 merged.

2. **The note.**

   > I would expect information like this to go in the doc

3. **Read as:** (the assistant's interpretation, not the player's words)

   Anything the player may want to act on — not only a question — goes on the Nappy board, not only in a chat report. The board skill names questions, the running work and recent merges, and says nothing about such notes; that is the gap this fixes.

## #852

1. **Context** (the assistant's):

   Answers on the Nappy board, 2026-10-25, and the session's opening chat message.
   1. Board question thread-847-nit: should the reviewer's resolved nit on #847 be acted on — a comment in the car-jumps test probe names _plan_a_turn() without its class (CarStrategy)? Pick was to leave it, or put it in walkers-and-cars part 2 if wanted.
   2. Board question 848-nits: should events step 2b pick up #848's two open nits (the car-restore test fakes its blocked route instead of building one; a checkpoint guard who left the screen mid-walk comes back carrying that walk's saved state)?
   3. Board question stairwell-badge-flake: a test of the escape building's stairwell masked man, whose screen-edge badge must stay up until he comes into view, failed 4 checks on main after a docs-only PR while the same code passed twice before. Pick was a small queue entry to find what varies between runs.
   4. The chat message that opened the session.

2. **The note.**

   > if it helps readability we should do it

3. **The player's words.**

   > yes

4. **The player's words.**

   > there should be a central handler that provides those badges that can be tested in isolation

5. **The player's words.**

   > Not sure why the previous session stopped but the task is clear refactor then escape then tutorial. PRs that are ready can be merged. I updated the doc

6. **Read as:** (the assistant's interpretation, not the player's words)

   1. Name the class in that comment, in walkers-and-cars part 2 of minty-quail.
   2. Both nits go into events step 2b's brief.
   3. Not only a flake fix: the screen-edge badges come from one central handler that can be tested on its own, and the stairwell test checks the badge through it.
   4. The order of work is minty-quail (the refactor), then the escape (lilac-marten's fuller escape and snowy-goose's explosions), then the tutorial (grassy-beaver, a day one that teaches). Reviewed PRs that are ready may be merged without asking again.

7. **Context** (the assistant's):

   Answers on the Nappy board, 2026-10-25.
   1. Board question crowd-tick-cost: walkers and cars part 2 (minty-quail shared-components) gives the walker and the car a shared mover base the crowd member extends (inheritance); measured headless in the debug build with other agents running, the crowd tick is about 4.5% slower than main and the agents' own frame about 6% slower, from the engine's cost of calling a method defined on a base script. Pick: keep the base class, state the cost, remeasure at the end of the refactor; the alternative was the mover as a separate component.
   2. Board question badge-keeps: should every screen-edge badge stay up until its danger comes into sight, not only a charger's? The badge handler PR (#854) keeps a charger's badge up until he is in sight; the question's context named "a cyclist, a car, a dog that is not charging" as keeping today's rule (a 0.8 s hold once the danger stops closing in). The orchestrator's example of a non-charging dog was wrong: the loose dog has no badge at all (rows that do not telegraph are outside the badge).

8. **The player's words.**

   > let's eat the cost for now and think about optimizing later

9. **The player's words.**

   > cyclist works the same as a charger, no? A non charging dog (a sitting dog?) doesn't need a badge. The stair guard can become a charger that is triggered by a location if necessary

10. **Read as:** (the assistant's interpretation, not the player's words)

    1. Keep the base-class shape and its cost now; optimizing the crowd tick is later work, not this PR's.
    2. The cyclist, which comes at her faster than she walks, keeps its badge the way a charger does; a dog that does not charge needs no badge (none has one today); the stairwell masked man may be made a charger set off by a place if that is what the rule needs (he already pursues, so the charger rule reaches him). Open: whether cars and trucks, lethal but driving their street rather than coming at her, keep the charger's rule too.

11. **Context** (the assistant's):

    Said in chat on 2026-10-25, right after the orchestrator's report on board question badge-keeps, which had read the player's cyclist answer as "kept until it is in sight or turns away from her" and left open whether the lethal vehicles keep today's rule (a 0.8 s hold once the danger stops closing in).

12. **The player's words.**

    > Anyway a badge shouldn't disappear before the entity is visible

13. **Read as:** (the assistant's interpretation, not the player's words)

    Every screen-edge badge, once up, stays up until the thing it points at is visible, for every badged danger (pursuers, the cyclist, the lethal vehicles alike); "or turns away from her" is dropped. The one end besides coming into view is the thing leaving the world (finished or removed), since it can then never become visible.

14. **Context** (the assistant's):

    Said in chat on 2026-10-25, answering the orchestrator's report on which dangers get a screen-edge badge while already in the world, and board question badge-before-placing. The first line quotes the orchestrator's own list item back; the orchestrator had named the patrol car's return leg as one, then corrected it: the patrol car does not telegraph, so it never gets a badge. The read-only catalogue check found two dangers badged while already existing (the stairwell masked man, placed by the escape building at the foot of the stairwell, and the army truck MAP row from day 13, planned at dawn), and four only in theory (the charging dog waiting on a tile, the alley robber, the checkpoint guard from the far hut, the roadblock guard).

15. **The player's words.**

    > The ordinary charging dog that waits on a tile, from the day after day 3 onward. -- if it's a sitting dog it would only start charging after warning when she comes close so no need for a badge, no?
    >
    > Army convoy should definitely placed for her not at dawn. Otherwise it might have driven away by then
    >
    > Why would a return leg need a badge? 
    >
    > Stairwell guard could as well be placed when it should appear instead of when entering

16. **Read as:** (the assistant's interpretation, not the player's words)

    The waiting charging dog needs no badge (it warns and charges only when she is close, so it is on screen; in practice it gets none today). The army truck is placed for her when it comes, warned first like day 13's column, never planned at dawn. The patrol car's return leg needs no badge (it gets none). The stairwell masked man is placed when he should appear, warned first, rather than when she enters the building. This settles board question badge-before-placing.

17. **Context** (the assistant's):

    Said in chat on 2026-10-25, right after the orchestrator settled board question badge-before-placing (the army truck and the stairwell masked man to be placed after their badge, as two queue entries after the refactor) and noted that the waiting charging dog and the patrol car's return leg "get none" today. Earlier the same day the refactor's builders kept forwarders for old names so tests and other files need not change (GameState's forwarding properties in #853, DangerEdge's forwarders in #854), and the badge handler kept the rule that badges a danger already in the world.

18. **The player's words.**

    > Don't let legacy implementations prevent you from establishing a clean design

19. **Read as:** (the assistant's interpretation, not the player's words)

    A general rule for the refactor and what follows it: the target design is built cleanly, and an existing implementation (an old code path, a compatibility forwarder kept to spare edits, a rule that only holds "in practice") is replaced rather than kept alongside it. Applied to the badges: a badge comes from one path only, a warning put up before the danger is placed, so the badge handler's measuring of dangers already in the world goes once the army truck and the stairwell masked man are placed after their badge.

20. **Context** (the assistant's):

    Answer, in chat, to the board question badge-cap (2026-10-25): with at most three screen-edge badges drawn at once (`DangerEdge.MOST_AT_ONCE`, the builder's own choice in M22, never asked for), a fourth danger arriving sooner took the slot of a badge already up, so a badge vanished while its danger was still out of sight, against the rule that a badge stays until its danger is in sight or gone. The options were: leaving ones yield, sooner always wins, a drawn badge keeps its slot, or no cap. The player first asked why there is a cap at all; told nobody asked for it, they answered with the words quoted.

21. **The player's words.**

    > no cap it is then

22. **Read as:** (the assistant's interpretation, not the player's words)

    Remove the cap: every badge is drawn, and a badge once up stays until its danger is in sight or has left the world, with no exception. Built in PR #854.

## #865

1. **The note.**

   > let's try (b)

2. **Context** (the assistant's):

   The player's answer on the Nappy board to the question "masked-man-margin", 2026-10-30, which blocks merging PR #863 (minty-quail events-composed 3b: events step on the 30 Hz physics tick). The masked man in the escape building's stairwell runs at her once she is within 426px (`runs_within`). With the catch checked right after his step on the tick, one runner's line (walk until he runs, then run, turning plain left at the middle of the row below the second flight's top, row 11) now comes within 26.4px of her against his 28px catch, so she is caught; before she cleared it by 0.6px. Options put: (a) accept that this line catches her and change the test; (b) shrink only his catch distance from 28px to about 25px, keeping his 426px run distance (inbox #782 asked for that radius bigger), and check no walker's line changes outcome; (c) check the catch before his step as before. The orchestrator's pick was (b).

3. **The player's words.**

   > 23.5px

4. **Context** (the assistant's):

   The player's answer in the chat, 2026-10-30, to the board question "masked-man-window" (follow-up to inbox #865, option (b)). Measured on the stairwell with the masked man's 426px run distance kept: the runner on the tight line (walk until he runs, then run, turning plain left at row 11) gets through only while his catch distance is under 24.6px; the walkers who should be caught (inbox #764) stay caught only while it is at least about 22.7px. Options put: (1) about 23.5px, roughly 1px margin each side (the orchestrator's pick); (2) 22px or less, letting the walkers turning at rows 9 and 11 through; (3) back to (a), this line catches her; (4) back to (c), check the catch before his step.

## #866

1. **The note.**

   > actually we should make all clocks in the game frame locked. otherwise someone with a faster computer could get lower times over someone with many lag frames

2. **Context** (the assistant's):

   Said in the chat on 2026-10-30, in reply to the orchestrator's report of the approved plan for minty-quail events-composed PR 4. That plan's 4c moves the day's clock (`DayController`) and the resistance tick (`ResistanceDirector`) from `_process` (once per drawn frame) onto the 30 Hz physics tick, and keeps the escape's hundredths countdown label looking as now by showing the tick's clock advanced by the physics interpolation fraction on each drawn frame (the orchestrator's pick on that plan's fork 6).

3. **The player's words.**

   > if we build a "seed of the day" later and let people compete on a leaderboard the timing needs to be fair

4. **The player's words.**

   > yes, that's what I meant -- also lag frames where nothing happens (I don't think we have those) shouldn't count

5. **Context** (the assistant's):

   Answers the read-back: "every clock that makes a time the player sees or decides an outcome counts the fixed 30-per-second physics ticks, never wall-clock time; on a lagging machine the game slows down instead of the clock running on."

6. **Read as:** (the assistant's interpretation, not the player's words)

   A tick counts only when the walk's simulation actually stepped on it: not while paused, while a screen is up, or while the game holds for a load. Catch-up ticks the engine runs after a hitch did advance the game, so they count.

7. **The player's words.**

   > that works

8. **Context** (the assistant's):

   Confirms the reading of the previous comment: a tick counts only when the walk's simulation actually stepped on it (not paused, no screen up, no load hold); catch-up ticks after a hitch count.

## #867

1. **The note.**

   > another idea for when we work on the beginning. in the title screen we have the normal density we have today. then on the first day we show the park and then go back to home. when showing the park, turn off car spawning so when the camera comes back home no cars are around anymore. this should prevent the most common day 1 mistake which (I think) is figuring out the controls and getting hit by a car. the first few blocks shouldn't have cars spawning in and only a thought bubble advising to use the zebra crossings. that way a player can get used to the controls before cars start spawning

2. **Context** (the assistant's):

   Said in the chat on 2026-10-30, unprompted, "for when we work on the beginning": the queue entry grassy-beaver (a day one that teaches; after the refactor). It builds on that entry's opening-shot.md (day 1's camera rests on the close park, follows the intended path back to her door, then play starts; an experiment) and thought-bubbles.md, and on the board's settled crossing-bubble question (the crossing bubble goes into the day-one entry). Related: curly-moose #832, where the player said "traffic crossings are already only where cars are stopped -- the issue comes from players who just run across the street".

3. **Read as:** (the assistant's interpretation, not the player's words)

   The title screen keeps today's traffic density. On day 1, while the opening shot shows the park, no new cars spawn, so the cars there leave and none are near her door when the camera returns. For her first few blocks no cars spawn in; a thought bubble advises using the zebra crossings; after that cars spawn as normal. Open: what ends the car-free stretch (a distance, a number of blocks, her first crossing, or a time), and whether it holds on a retry of day 1.

4. **The player's words.**

   > and a thought bubble advises using the zebra crossings. -- when the player steps on the road

5. **Context** (the assistant's):

   The player quoted the orchestrator's summary of this note ("and a thought bubble advises using the zebra crossings.") and answered when it appears.

6. **Read as:** (the assistant's interpretation, not the player's words)

   The zebra-crossing thought bubble appears when she steps onto the road (the carriageway) away from a crossing, during the car-free stretch.

7. **The player's words.**

   > yyes away from the crossing

8. **Context** (the assistant's):

   Confirms the reading that the zebra-crossing bubble appears when she steps onto the road away from a zebra crossing (not on one).

## #868

1. **The note.**

   > also a thought bubble should hint on going into the alley to get the mark

2. **Context** (the assistant's):

   Said in the chat on 2026-10-30, right after inbox #867 (day 1: no car spawning during the opening shot and the first few blocks, a zebra-crossing thought bubble), about the thought bubbles of the queue entry grassy-beaver (thought-bubbles.md). "The mark" is the chalk mark, the resistance's first encounter: a mark drawn in an alley, found by walking into the alley and touching it (records M78, M100, M213; the alley's robber stands at its far end). CLAUDE.md: the first resistance task is hinted at (PLAYTEST-122 12), day 6's brief names the rumor of chalk, and every task has a red arrow.

3. **Read as:** (the assistant's interpretation, not the player's words)

   On the day the chalk mark is first there, a thought bubble hints that she can go into the alley to reach the mark, adding to the hints that exist (the day brief's rumor of chalk, the red arrow). Open: whether the bubble comes once (first mark) or on every day a mark is there, and what triggers it (the alley mouth coming into view, or her passing it).

## #870

1. **The note.**

   > during development they only need to run their shard. afterwards they should run the whole suite in one go. but actually, why run locally when CI does that for you?

2. **The player's words.**

   > if you're confident you're done (from the shard's result) just push and see if the CI is green

3. **Context** (the assistant's):

   Said in the chat on 2026-10-30, after the orchestrator explained the stream of "waiting on its own background work" notices: builders were running all eight test shards locally because the orchestrator's briefs declared a local full run, although the verify skill says the unfiltered suite is CI's job. The orchestrator then told the builders to run only the touched suites locally and let CI run the full suite, and fixed the orchestrating skill's agent contract so a brief cannot declare a local full run for a change's size alone.

## #872

1. **The note.**

   > I think your system prompt tells you to use scripts instead of the edit tool. this rule was to overwrite that. I don't think that is needed anymore

2. **The player's words.**

   > we can remove it in both places

3. **Context** (the assistant's):

   Said in the chat on 2026-10-30 about the rule "An edit fails loudly" (CLAUDE.md's "Editing files" section, and a short copy in the player's own global ~/.claude/CLAUDE.md). The orchestrator had said the dedicated edit tool already fails loudly on a miss, that script and sed edits still succeed silently and that the run flow 4b builder's replacement script left 48 stray blank lines this session, and recommended keeping the repo rule; "both places" are the repo's CLAUDE.md and the global file. The section's separate sentence "grep for what pointed at it before you move anything" is kept.

## #874

1. **The note.**

   > make a rule to avoid huge long context subagents:
   >
   > 2. Huge, long-lived implementation agents, inside the 63%. These agents carry 300–640k tokens of context through 200–380 turns, and re-reading that context every turn is about 45% of their cost. Smaller briefs, or a fresh agent per step, would cut both this and the cost of item 1.
   >
   > keep them focused on one task. there is a balance between having them establish their context and having huge sessions. too many fresh subagents is bad because the context is recreated from scratch every time. long subagent sessions get expensive

2. **Context** (the assistant's):

   Said in the chat on 2026-10-30. The numbered paragraph is pasted from a cost breakdown the player has (its item 1 is not quoted). This session's builders show the pattern it describes: the run flow 4b builder ran about 200 tool calls through two review rounds and a main merge, the events PR 4 agent planned and then built 4a past 290 tool calls, and both carried their whole history in context.

## #877

1. **Context** (the assistant's):

   Said in the orchestrating session on 2026-10-31, right after the board's Running table was updated for events-composed 4b (a finished run-state row was removed from it). The board is the Claude Doc "Nappy board"; the **board** skill already says a settled question leaves once its filing PR merges.

2. **The note.**

   > we can clean up the board when items are fully filed. no need to keep their record on the board. make that a rule

3. **Read as:** (the assistant's interpretation, not the player's words)

   A rule in the board skill: once an item is fully filed (its filing pull request merged, so the queue and the records hold it), everything about it leaves the board: the settled question, its Running row, and no Recently done line or "filed" note left behind for it.
