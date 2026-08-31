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

## Three references that were already lost

Found while writing this directory, and worth recording rather than quietly fixing, because it is
the cost the rule exists to stop. None of these three files was still on disk — the telemetry
folder had 163 runs in it and not one of them was these:

- `docs/PLAYTEST-03.md` — `run-2026-08-26T225417-seed437307357.log`
- `docs/PLAYTEST-13.md` — `run-2026-08-30T031851-seed3251793152-b7590fb.log`
- `docs/TODO.md` and `docs/PLAYTEST-14.md` —
  `run-2026-08-30T233248-seed3225216943-834423d-dirty-069s-asked.png`

**They cannot be regenerated**, and that is the part worth understanding before anybody tries: a
run log is a record of what a *player* did, so it is not a function of the seed. Replaying the seed
on that commit gives a different run. The numbers those docs quote from them are still the record;
the file behind the numbers is gone.
