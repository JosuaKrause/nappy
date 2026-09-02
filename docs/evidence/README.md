# Evidence

**Every log, telemetry map or screenshot a doc in this repo refers to lives here.** *(Asked for on
2026-09-01: "when referencing an image or log make sure to copy the files into the repo so the
reference doesn't get lost when cleaning up. make sure all current references are in the repo so I
can clean up the log folder.")*

The rule is in `CLAUDE.md` under "A reference to a file outside the repo is not a reference". The
short version: `user://telemetry/` is a scratch directory the player has to be able to empty, and a
finding whose evidence was in it stops being checkable the moment they do.

Keep the original filename. It carries the run's timestamp, seed and commit, which is most of what
makes the file worth having.

## What is here

| file | what it is | referenced by |
| --- | --- | --- |
| `run-2026-08-31T205921-seed8000-7367ab0-dirty-map-day01.png` | Day 1's plan on `feature/the-calm-has-a-shape` at `7367ab0`, seed 8000. Purple is the day's corridor, blue friction, yellow walls, green calm outlines, orange the spine. | [PLAYTEST-17.md](../PLAYTEST-17.md), finding 1 |
| `rig-2026-09-01T014558-seed4242-f604488-dirty-map-day01.png` | Day 1 of seed 4242 **before** the gap weighting — the pair below is the same day either side of one change, so the two are told apart by their timestamp and by nothing else. Both say `f604488-dirty`, because the "before" was taken with the change stashed rather than on a commit of its own. Walls (yellow) are scattered over the whole map. | [DECISIONS.md](../DECISIONS.md), M55, "Something between parallel strands of corridor" |
| `rig-2026-09-01T014420-seed4242-f604488-dirty-map-day01.png` | The same day **after**. The walls have gathered onto the streets between the parallel purple strands, and about half of those streets still have nothing on them. | [DECISIONS.md](../DECISIONS.md), M55, "Something between parallel strands of corridor" |
| `shot-2026-09-01-seed4242-d69631a-corner-nw-before.png` | The north-west corner of the map **before** M55's corner fix, `tools/shot.sh --spawn corner:nw`. The grass and forest step diagonally into the scree and mountain. | [DECISIONS.md](../DECISIONS.md), M55, "The corners of the world stop going diagonal" |
| `shot-2026-09-01-seed4242-d69631a-corner-nw-after.png` | The same corner **after**: the mountain runs the full width and the seam is straight. | [DECISIONS.md](../DECISIONS.md), M55, "The corners of the world stop going diagonal" |
| `shot-2026-09-01-seed4242-d69631a-corner-se-after.png` | The south-east corner after, which is the other pair of bands — the bulkhead and the water carry on under the forest. | [DECISIONS.md](../DECISIONS.md), M55, "The corners of the world stop going diagonal" |

## Why a lost log stays lost

**A run log cannot be regenerated**, and that is the part worth understanding before anybody tries:
it is a record of what a *player* did, so it is not a function of the seed. Replaying the seed on
the same commit gives a different run.

Three traces from playtests 03, 13 and 14 were already gone when this directory was made — the
scratch folder prunes itself, so evidence that lives only there is one ordinary Tuesday from being
unrecoverable. What those documents quote from them is still the record; the files behind the
numbers are not, and the citations that named them have been removed rather than left dangling.
This directory exists so that stops happening.
