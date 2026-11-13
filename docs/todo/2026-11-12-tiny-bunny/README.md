priority: later
after: 2026-10-18-minty-quail
after: 2026-11-11-polite-tapir

# tiny-bunny — The ground-frames probe measures the ground mode it names and finishes in its deadline · filed 2026-11-12

**Where this comes from.** The orchestrator found two defects in `tests/probes/ground_frames.gd`, a
parked probe that runs only when called by path (`tools/test.sh probes/ground_frames.gd`) and never in
the runner's own sweep or in CI. It compares the ground's quadrant, row and atomic scheduling and
checks the ground's residency against real process frames. Nobody asked for this entry; it is filed so
the defects are not lost.

*Not asked for:* this entry is not the player's request. The defects come from reading the probe and
from one run of it. The band, and the wait for the refactor (minty-quail and polite-tapir; an entry
that waits for the refactor waits for both, polite-tapir's README), are the filer's proposal, the
same place lilac-pelican's parked probes have.

**Fixed or deleted, decided when the entry is picked up.** What the probe is still worth is the
player's to say when asked. The item says what a fix would take and what deleting the probe loses,
and decides neither.
