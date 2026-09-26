## M177 — The second mark is any alley she comes across, and a step says it was done · built 2026-09-20

*(2026-09-20, [PLAYTEST-116](../playtests/PLAYTEST-116.md): "I did the first mark then the yeller
(there should be an indication that I did it correctly) but then there was no second mark I
checked multiple alleys. it should follow the same rules as the first mark in that it can
basically be any alley you come across", and "remove the \"anyone of them could be it\" this is
unnecessary information that sounds odd"; [PLAYTEST-117](../playtests/PLAYTEST-117.md): "chalk marks
should only get pinned whenever you see them (and not at the edge of the screen really). they
need to be a little bit more obviously visible".)* One agent, four commits on
`feature/m177-second-mark`, reviewed here.

**What the run showed.** Day 6's mark moved to the alley nearest her doorstep two seconds into
the day and was marked *seen* 0.4 seconds later, because `ResistanceDirector` pinned a mark the
first frame its tile was inside the view; a seen mark never moves, so every alley she checked
was empty. Playtest 19's "a mark that was never on screen was never placed" is kept: what
changed is what counts as seeing.

**Seen is within 150px of her, on screen, for one continuous second**
(`SEEN_DISTANCE`, `SEEN_DWELL_SECONDS`; the dwell resets when either breaks). 150 sits under the
view's 180px vertical half-extent at the game's zoom, so a mark inside that circle is on screen
on every bearing and never at its edge — the player's "not at the edge of the screen" as
geometry, with no screen-space margin to maintain. Both numbers are open to overturn. The
orchestrator's first proposal was 200px, which the vertical extent does not cover.

**A mark avoids an alley a step was already taken from** while another is in reach, at its
first placement and at every relocation; `GameState.completed_resistance_alley_tiles` is a
top-level key of the save, absent in an older one. With no other alley in reach it uses the
old one, so the avoidance never costs the placement. The record is not given back on a lost
day: it can only make the next mark avoid one more alley.

**The acknowledgement was built on a misreading, and all of it came out again the same day.**
PLAYTEST-116's "(there should be an indication that I did it correctly)" follows "then the
yeller" in parentheses; the orchestrator's entry applied it to the mark as well. Built: "Taken."
and "Done." on the HUD's teaching line, the prepared `chalk_mark_touched` picture bound in place
of the hand-drawn mark, and the mark drawn 1.35 times larger with a heavier stroke for "a little
bit more obviously visible". The player ([PLAYTEST-117](../playtests/PLAYTEST-117.md)): "the mark
doesn't have a problem for recognizing that it was taken!!!! no need to change anythign there",
"no larger mark!", and "yeller should just start walking offscreen -- no onscreen text for
acknowledgements like this". So the mark is drawn exactly as it was before this milestone —
`ContactPoint`'s three strokes and a circle, `Palette.CHALK_DONE` once touched — the two SVGs
and the atlas membership are as they were, and the HUD says nothing. What a finished perform
step shows is M182, a finished task is shown by the world, in `TODO.md`.

**The first mark's note is one sentence**: "Give it to the one who won't stop shouting."

**Not captured:** no still of a mark. `--spawn contact` asks for the contact before the
director has placed one (open in `TODO.md`, M100), and the seed's day-4 mark is 1650px from the
doorstep.
