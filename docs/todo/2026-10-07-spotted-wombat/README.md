priority: now

# spotted-wombat — The guard leaves a steady barrier behind · filed 2026-10-07

[azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 4, files inbox #601 in the
player's `now` band:

> the guard pursuer makes his barrier jump up and down and then dissappear

This re-reports the separation required by [M168, the escape after playtest
94](../../decisions/2026-09-19-M168-the-escape-after-playtest-94.md): the guard sets off while
`body_stays_behind` "leaves the band drawn and solid where it was, so the street stays shut".
The work is [keep-the-barrier-in-place.md](keep-the-barrier-in-place.md).

Re-reported in [azure-puffin](../../playtests/2026-10-10-azure-puffin.md), point 5, inbox #664:

> the guarded barriers disappear after shaking off the pursuer. that doesn't make sense.

*The filer's reading of the code, for whoever picks this up to confirm:* a shaken-off guard
appears to end the roadblock's whole instance (`EventInstance._be_done()` finishes a row that does
not depart, and `EventManager._retire_finished()` frees the barrier's body and picture with the
guard).
