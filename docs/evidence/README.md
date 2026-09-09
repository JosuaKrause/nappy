# Evidence

**Every log, telemetry map or screenshot a doc in this repo refers to lives in this evidence tree.** *(Asked for on
2026-09-01: "when referencing an image or log make sure to copy the files into the repo so the
reference doesn't get lost when cleaning up. make sure all current references are in the repo so I
can clean up the log folder.")*

The rule is in `CLAUDE.md` under "A reference to a file outside the repo is not a reference". The
short version: `user://telemetry/` is a scratch directory the player has to be able to empty, and a
finding whose evidence was in it stops being checkable the moment they do. Approved design
references stay at this level; historical runtime captures are organized by date under
[`archive/session-captures/`](archive/session-captures/), and rejected graphics are under the
guarded [`archive/rejected-graphics/`](archive/rejected-graphics/) archive.

Keep the original filename. It carries the run's timestamp, seed and commit, which is most of what
makes the file worth having.

## What is here

| file | what it is | referenced by |
| --- | --- | --- |
| `shot-2026-09-09-seed4000-d9856f2-seal-ground-before.png` | A vertical crash scene displaced north of its ground point. | [DECISIONS.md](../DECISIONS.md), SVG seal artwork review |
| `shot-2026-09-09-seed4000-9b72a2e-dirty-seal-ground-after.png` | The same scene centred on its street with an aligned shadow; vehicle perspective remains under review. | [DECISIONS.md](../DECISIONS.md), SVG seal artwork review |
| `shot-2026-09-09-seed4242-d29eec6-seal-skip.png` | M64's skip at the kerb, the near half of a soft seal, on seed 4242 day 1. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4242-d29eec6-seal-burnt-out-car.png` | M64's burnt-out car, four bodies across a street, on seed 4242 day 5. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4000-1e3995b-seal-car-accident-east-west.png` | M64's car accident on an east–west street, drawn from the rotated asset. | [DECISIONS.md](../DECISIONS.md), M64 eight seal pictures |
| `shot-2026-09-09-seed4242-150985c-seal-car-accident-onlookers.png` | The accident on a north–south street with the game's own person figure as each onlooker. | [PLAYTEST-50.md](../PLAYTEST-50.md), [DECISIONS.md](../DECISIONS.md), M64 |
| `archive/session-captures/2026-09-09/run-163539-seed2295276695-v0.8.2-27-gc3305c2/` | Playtest 50's whole run: the log, the day-5 maps, two asked-for stills and the game's own capture of the guard robber's chase from inside a building. | [PLAYTEST-50.md](../PLAYTEST-50.md), `TODO.md` M100 |
| `shot-2026-09-09-seed4242-21d3ba2-signal-head-back-before.png` | A signalled junction on seed 4242 with the north-facing head still drawn face-on, red lamp toward the camera. | [DECISIONS.md](../DECISIONS.md), M95 |
| `shot-2026-09-09-seed4242-21d3ba2-signal-head-back-after.png` | The same junction with the north-facing head drawn as its back, no lamp. | [DECISIONS.md](../DECISIONS.md), M95 |
| `archive/session-captures/2026-08-31/run-2026-08-31T205921-seed8000-7367ab0-dirty-map-day01.png` | Day 1's plan on `feature/the-calm-has-a-shape` at `7367ab0`, seed 8000. | [PLAYTEST-17.md](../PLAYTEST-17.md), finding 1 |
| `archive/session-captures/2026-09-01/rig-2026-09-01T014558-seed4242-f604488-dirty-map-day01.png` | Day 1 of seed 4242 before M55's gap weighting. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/rig-2026-09-01T014420-seed4242-f604488-dirty-map-day01.png` | The same day after M55's gap weighting. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-before.png` | North-west corner before M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-nw-after.png` | North-west corner after M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |
| `archive/session-captures/2026-09-01/shot-2026-09-01-seed4242-d69631a-corner-se-after.png` | South-east corner after M55's corner fix. | [DECISIONS.md](../DECISIONS.md), M55 |

## Why a lost log stays lost

**A run log cannot be regenerated**, and that is the part worth understanding before anybody tries:
it is a record of what a *player* did, so it is not a function of the seed. Replaying the seed on
the same commit gives a different run.

Three traces from playtests 03, 13 and 14 were already gone when this directory was made — the
scratch folder prunes itself, so evidence that lives only there is one ordinary Tuesday from being
unrecoverable. What those documents quote from them is still the record; the files behind the
numbers are not, and the citations that named them have been removed rather than left dangling.
This directory exists so that stops happening.
