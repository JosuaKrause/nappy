# Playtest brisk-pelican — Reload times, tests that touch nothing real, work that survives an interruption

2026-11-02.

The player's notes from the session and the Nappy board on 2026-11-02: reloads and the shown times, tests that touch nothing real, and work that survives an interruption.

## #965

1. **Context** (the assistant's):

   Said in the chat on 2026-11-02, unprompted, while the minty-quail refactor was running. Related queue work: lilac-marten's total-time.md (every screen that ends the game shows the total game time beside its segment's time; curly-moose #803), and the frame-locked clocks (inbox #866: the day countdown and every shown-time clock count physics ticks the walk stepped, not paused, no screen up). A save is written during a day; resuming it after the page is reloaded or closed restores the day's state, and the ticks walked since the last write are not in it.

2. **The note.**

   > One thing. A reload breaks the time counter. If we start from a reload we need to set a flag and then indicate that the displayed times are inaccurate due to reloading. But only if a running game was interrupted during reload. Reloading from a day brief is fine

3. **Read as:** (the assistant's interpretation, not the player's words)

   When a run is resumed from a save written while a day was being walked (the page reloaded or closed mid-walk), the run carries a flag, and the times the game shows (the day's completion time, and the total game time on the ending screens) say they are inaccurate because of the reload. A save made at a day brief, before the day is engaged, resumes with no flag. Open: whether the flag marks only that day's time or the run's total for the rest of the run (the total keeps the lost stretch, so read as: the day's time for that day, the total for the rest of the run).

## #984

1. **Context** (the assistant's):

   Answered on the Nappy board under the question "save-guard": should tests be made unable to touch the player's real save at all? The context said a test had overwritten the desktop save (the player said nothing needed restoring), that test was fixed to stop unless it took its scratch save, and proposed a guard in which the save refuses the real path whenever the test runner runs, plus one shared helper building a stand-alone game boot with a scratch save. My pick was to file that guard in band now.

2. **The note.**

   > so a) tests shouldn't touch anything real. all of that should be mocked out or handled in a test state only matter b) are you talking about preventing such a thing from happening at all? how would that work? if you write a bad test it will happen. don't write bad tests

## #986

1. **Context** (the assistant's):

   Said in the session after the orchestrator had fixed the board (a question deleted instead of moved to Settled) and was holding PR #976 on an open board question while writing queue moves for #982 and #983. The board's Running table was stale at the time, and the session's plan (which PR waits on what, which review is next) lived only in the conversation.

2. **The note.**

   > consider: what happens if you get interrupted / the computer dies / you get compacted / you get cleared while you're in the middle of something. it should be possible to recover from this

3. **Context** (the assistant's):

   Said right after the note above, while the orchestrator was starting to write the session's in-flight state into the local, git-ignored .claude/restart-prompt.md instead of updating the board's stale Running table.

4. **The player's words.**

   > that's why we store things on the board or the issues or the repo

5. **The player's words.**

   > so it doesn't have to rely on an active conversation (that might get deleted at any time)

6. **The player's words.**

   > local files are fine, too... for some information, like restart prompts etc

7. **The player's words.**

   > as long as a new you is able to reorient and continue where the previous session ended

8. **The player's words.**

   > it is good

9. **Context** (the assistant's):

   Answering the orchestrator's line "From here on, the board's Running table and local restart prompt get rewritten at every merge, verdict, hand-back and answer so a fresh session can resume."

10. **The player's words.**

    > not everything needs to be updated every time. it's enough if the state *can* be recovered. if it's cheaper to just update the local file then it can be updated more frequently and the board gets updated in batches

11. **The player's words.**

    > if I want to see what's going on I usually ask before looking on the board anyway

12. **The player's words.**

    > treat the board as information for me (and a channel to respond) but keep (temporary) information for you local
