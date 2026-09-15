# Playtest 76 — 2026-09-15

A design session with no run behind it: the state of the queue and the four open pull requests
were read out on 2026-09-15, and the player answered the question M149 had put to them and set
the queue's order.

## Atlases by group: build it, and the reason is the composite

> "M149 yes, especially for things like parks with grass features or damage patterns / garbage
> in the street it is good to have everything built into atlases so the composite doesn't have
> to deal with multiple image sources. same for 8 directions of entities. and we can do another
> warm test run"

Said on 2026-09-15, answering the question M149's entry put on 2026-09-14 — whether to build
the atlases now that no entity picture turns out to load late, or to leave them until draw
calls are the cost. The reason given is not the one the entry weighed. It is the composite:
the ground is built from a base, grass features, damage stencils and kerb components, and the
street carries litter and garbage sacks over it, and each of those is its own image source at
draw time. One atlas per group is asked for so that whatever composes a scene reads from one
picture per group rather than from many, and the eight directions of every entity family are
the same request seen from the actors' side. So the scope is wider than the entry's two groups
— the head indicators and the entity families — and takes in the ground's composition groups
and the street's decoration. Rewritten as M149 in `TODO.md`, with the items an agent can build.

**The warm test run.** The three laptop readings in `REVIEW.md` — the spike lines under
`--debug --spikes`, the graph under the readout, and whether the once-a-second 24 ms frame is
still there with every picture warm — stand as written, and the run is asked for on the build
that carries M149, so one sitting reads all of them.

## M125 after this session's items

> "is M125 still current? what needs to be done there?" — "okay we can finish M125 once the
> other items of this session are done"

Said on 2026-09-15, after the queue was read out. M125, the test suite is slow again, is
current: `tests/suite_costs.txt` records the events suite at 161 s and the routes suite at
141 s serial, both over the two-minute budget the head of `tests/run_tests.gd` states, and four
suites — the crowd atlas, the day controller, the frame graph and the route lines — have no
cost row yet. The order set: after the pull requests open at the session's start (the desktop
stutter, M145's tint trial, M146's standing agent, M129's four rules) and after M149.
