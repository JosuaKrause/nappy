priority: now

# coral-squirrel — A resume from a mid-walk reload marks its shown times as inaccurate · filed 2026-11-02


**The ask.** The player, unprompted: "A reload breaks the time counter. If we start from a reload we
need to set a flag and then indicate that the displayed times are inaccurate due to reloading. But
only if a running game was interrupted during reload. Reloading from a day brief is fine" (inbox
#965 in brisk-pelican).

**Read as:** the save is written when a day starts (record M166, the save is written when a day
starts and a saved game opens on the day brief), so a reload in the middle of a walk resumes by
charging the abandoned day a nerve and opening on the day brief, and the day is walked again. The
stretch already walked is lost from the run's total time (record M107, the run clock: the saved total
of seconds played misses it), so a time the game shows that adds up the run comes out short. When a
run resumes from a save written while a day was being walked, the run carries a flag, and the times
it shows say they are inaccurate because of the reload. A save written at a day brief, before the day
is engaged, loses nothing and resumes with no flag. (The context written when the note was captured
said the resume restores the day without the walked ticks; M166 says the day restarts, as above.)

**Which shown times carry the mark, and how it reads.** Asked on the board (reload-mark) which shown
times say they are inaccurate after a reload in the middle of a walk, and how, with the work built
on the orchestrator's pick (a line under every time that adds up more than the day being walked,
none on a day's own time), the player: "do your research into my answer" (gentle-owl #1240).
**Read as:** the player's own words already answer it, chiefly the note this entry quotes ("A
reload breaks the time counter", "indicate that the displayed times are inaccurate due to
reloading", inbox #965 in brisk-pelican), and it is not asked again. The work has started: draft
pull request #1207, paused for the refactor, is built on the pick (the mark under "Time played" on
the ending screen alone). When it resumes after the refactor (minty-quail and polite-tapir), the research into the player's words,
with the whole entry and the records it names (gentle-owl #1244), goes into #1207 before it merges:
it states the answer the words give and changes the build to it, the pick standing only as far as
the words bear it out.

*Proposed, not asked for:* the band, `now`, as a note from playing (the player named none).

**Related queue work:** lilac-marten, the fuller escape: `total-time.md` (every screen that ends
the game shows the total game time beside its segment's time, curly-moose #803). The frame-locked
clocks (the day countdown and every shown clock count the physics ticks the walk stepped, inbox #866
in minty-dolphin) decide what a shown time counts; this entry says when it is marked inaccurate.

