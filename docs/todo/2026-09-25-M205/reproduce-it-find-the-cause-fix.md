**The meter, not the halo, is what is still open.** The halo half is closed
([2026-09-25-M205-2](../../decisions/2026-09-25-M205-2.md)): on the released page the halo draws
correctly, including on the man shouting whenever he clears
`ExcitementHalo.CONTRIBUTION_FLOOR`, and no code defect was found behind the phone and desktop
screenshots that show it dark on him. What is still unreproduced is the meter itself: "the yeller
has no effect on the meter" ([PLAYTEST-140](../../playtests/PLAYTEST-140.md), statement 4) and "the
man shouting charges nothing on an ordinary day, not only on the day of the note"
([PLAYTEST-144](../../playtests/PLAYTEST-144.md), statement 21) — neither reproduced in a bare
`EventInstance`, a real `City` + `EventManager` stream on five seeds, or a full boot of the game
walking toward a live instance; every one of those charges him correctly. See the decision record
for the two live candidates and what to try next if it recurs: telemetry or a screen recording
from the actual encounter, not another guess at the emission code.
