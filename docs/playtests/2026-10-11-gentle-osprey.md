# Playtest gentle-osprey — Checkpoints and a Hard Mode checkbox

2026-10-11.
Said as an inbox note, #678 on GitHub Issues, and answered in comments on it. The note has no
context comment, so statement 1 is the body alone. Each later comment is recorded as the comment
held it: first what its words answered, then the words themselves, whole. The player numbered their
answers as the assistant numbered its questions (1 to 7); those numbers stay inside the quotes, and
the statement numbers are this file's.

## #678

1. **The note.**

   > I want to introduce a partway continue checkpoints. what are good days for checkpoints that restart after game over with 5 nerves? also on that note I want a "Hard Mode" checkbox on the title screen (if new game) that decides whether checkpoints are available. with hard mode the escape also has normal nerve counts and ends if nerves go to zero (instead of restarting indefinitely; this is only for normal mode). needs telemetry whether someone chooses hard mode and whether they are restarting from a checkpoint after losing all nerves

2. **The assistant asked four questions, each with options:**

   1. Which days are checkpoints (a game over in normal mode restarts at the latest one reached, 5 nerves, same city, the run as it stood that morning; acts are I = 1-3, II = 4-7, III = 8-11, IV = 12-14)? Options: "4, 8, 12 (Recommended)" = the first day of each act after the first; "6, 9, 12" = first chalk mark, first gatehouse, act IV; "Every act start incl. 1".
   2. In normal mode, a game over before the first checkpoint (days 1-3)? Options: "Day 1, same city (Recommended)" = day 1 is checkpoint zero, same seed, 5 nerves; "New run, new city" = as today.
   3. Hard mode's escape (enters with the nerves left after day 14, a lost section costs one): does getting through a section give one back? Options: "No refill (Recommended)" = keeps the escape's current no-regain rule; "Section won gives one back" = clearing "Escape the building" gives a nerve before "Escape the city".
   4. GoatCounter event names? Options: "Mode + checkpoint and day lost (Recommended)" = nappy-mode-hard / nappy-mode-normal once when a fresh run starts, and nappy-checkpoint-N-from-day-M on a checkpoint restart; "Mode + checkpoint only" = nappy-mode-hard / nappy-mode-normal and nappy-checkpoint-day-N.

3. **The player's words, answering those four** (the checkpoint days, the city before the first checkpoint, a section won in hard mode's escape, and the telemetry names):

   > 1. 4, 8, 12 (Recommended)
   > 2. Day 1, same city (Recommended)
   > 3. Section won gives one back
   > 4. in addition to the above we should also count regular day starts with mode. so we know how far people get in each mode. the event stats (influence/lethal/etc) should not include hard mode since hard mode doesn't affect gameplay -- only restart pacing

4. **Asked after the four answers above:**

   5. Can the player get into a situation where they can't complete enough tasks from a checkpoint (the player's own question)? The assistant answered: no new trap, since a checkpoint restores the run as it stood that morning; tasks are day-bound (days 6-13, goal 5 plus the day-14 sabotage), so a run can already be past the good ending before any checkpoint, and winning day 14 still gives the neutral ending.
   6. Normal mode at 0 nerves collides with PLAYTEST-28 finding 4, "the game over screen cannot have a continue button". Options: "No game over in normal (Recommended)" = normal mode never reaches the GAME OVER ending; its lost-day screen says e.g. "Back to day 8" with five stars and keeps the ordinary continue button, and the GAME OVER screen (no continue button) is hard mode's only; "GAME OVER, then checkpoint" = the GAME OVER screen's catch-all press goes to the checkpoint; "Continue button on GAME OVER" = overturns PLAYTEST-28 finding 4 for normal mode.
   7. Day starts by mode (GoatCounter). Options: "Add a hard-only copy (Recommended)" = keep nappy-day-N-began for every run and add nappy-day-N-began-hard for hard runs only, normal = total minus hard; "Split the name" = nappy-day-N-began-normal / -hard, ending the old series.

5. **The player's words, answering those three** (whether a checkpoint can leave too few tasks, normal mode at 0 nerves, and day starts by mode):

   > 5. one question about tasks. can the player get into a situation where they won't be able to complete enough tasks from a checkpoint? should we care?
   > 6. No game over in normal (Recommended)
   > 7. Add a hard-only copy (Recommended)

6. **A last word**, after those answers, with no question before it.

   > store the exact state at the checkpoint -- continuing should not have anything that happened after the checkpoint

7. **What the next words answered:**

   The player asked: "what I mean is if I neglected tasks in Act 2 and I get the checkpoint in Act 3 I won't be able to get the good ending at all, right?" The assistant answered: not quite. There are 8 tasks (one each day 6-13: act II has 2, act III 4, act IV 2) and the good ending needs 5 plus the day-14 sabotage. Skipping both act II tasks and returning to checkpoint 8 leaves 6, so one more can be missed. It is gone once tasks done plus task days left falls below 5 (e.g. day 12 with fewer than 3 done). The checkpoint holds exactly what the run had; a normal-mode game over sends her back into the same run, and only the pause screen's held restart starts over. The assistant recommended leaving it as it is (the held restart is the fresh start, and the game deliberately never explains tasks), with the alternative of the out-of-nerves screen offering a start over when the good ending is already out of reach.

8. **The player's words:**

   > what I mean is if I neglected tasks in Act 2 and I get the checkpoint in Act 3 I won't be able to get the good ending at all, right?
   >
   > okay sounds good
