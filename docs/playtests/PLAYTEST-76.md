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

## Every texture load and release in the run log, with its time

> "make sure telemetry records when a texture is loaded/unloaded" — "atlas or not" — "ideally
> with timing information"

Said on 2026-09-15 while M149 was being built. Every load the game does of a picture — a
transfer read from disk by the resolver, an atlas packed and made ready, an atlas released,
the ground's shared texture packed — writes a line to the run log with what was loaded and
how long it took, so a run can be read back for whether a picture arrived before it was
drawn. Added to M149 in `TODO.md` as its own item.

## M125 after this session's items

> "is M125 still current? what needs to be done there?" — "okay we can finish M125 once the
> other items of this session are done"

Said on 2026-09-15, after the queue was read out. M125, the test suite is slow again, is
current: `tests/suite_costs.txt` records the events suite at 161 s and the routes suite at
141 s serial, both over the two-minute budget the head of `tests/run_tests.gd` states, and four
suites — the crowd atlas, the day controller, the frame graph and the route lines — have no
cost row yet. The order set: after the pull requests open at the session's start (the desktop
stutter, M145's tint trial, M146's standing agent, M129's four rules) and after M149.

## The tint is on both pavements

> "why is the yellow tint on both sides? clearly the bottom path cannot be on any route."

Said on 2026-09-15 of a desktop debug still, build v0.10.7-54-g16e6d876-dirty, seed
2533738392, day 1, her at tile 92,85 on the upper pavement of an east-west street with the
readout on: both kerb lines of the street carry the yellow cast, the one she walks and the one
across the carriageway. The still arrived in the conversation rather than as a file and could
not be copied under `evidence/`; the seed and tile reproduce the city. The cause is read from
the code: the tint asks the corridor's depth, and the corridor answers at the grain of a whole
street, so a street on the tree tints both its pavements although the tree itself walks one of
them and, since M129's fourth rule, never crosses the carriageway between them. Filed as M150
in `TODO.md`.

## The map's top-left corner shows for a moment at the start

> "also, when starting the game I can briefly see the top left of the map"

Said on 2026-09-15 of the same session. The world's origin is the map's top-left, so a frame
drawn before the camera has taken her position shows that corner. Which frame is not known
from the code alone — the first after boot, the title's own with the city behind it, or the
run's first after the disc is pressed. Filed as M151 in `TODO.md`.

## Cars teleport at their turns

> "cars are super buggy now. when they turn in the final stretch the teleport a car length
> somewhere else. also in some case instead of routing a turn (or u turn) they just teleport."

Said on 2026-09-15 of the desktop build `v0.10.7-85-gd5d784f2`, the main of that moment, after
the day's six merges: the desktop stutter (M144, M147, M148), the tint trial (M145), the
standing pocketed agent (M146), the four rules (M129), the boot fix (M151) and the atlases
(M149). Two shapes: a car turning in its last stretch jumps about a car length, and a car that
would have routed a turn or a U-turn jumps instead. Neither was reported on the previous day's
builds. Of the six, two touch the cars: M146 moved the pocket question ahead of the step in
`CrowdAgent._process` and stops a caught car where it stands, recycling it only past
`Tuning.OUT_OF_SIGHT` from the field's centre; M149 rebuilt the crowd's atlas on the general
packer. Filed as M152 in `TODO.md`, a bisection first.

## The first frame draws the doorstep, not black

> "I don't really like blanking out the first frame. can we just position the camera to the
> home so it will just draw what the title screen will show anyway"

Said on 2026-09-15 of M151's fix, which hides the city until the day's placement has the
camera on her. Overturned: the two boot frames before her camera exists should draw what the
title will show, the doorstep, rather than nothing. M151 reopened in `TODO.md` with that
design; its record in `DECISIONS.md` stands as what was built first.
## The spike view is its own layer

> "also, spike view should be independent of debug layer 4 it should be its own debug layer
> and turned off by default unless --spikes is set"

Said on 2026-09-15. The spike view is the rolling frame-time graph M148 put under the
readout, drawn and toggled with the readout on the `4` key. Decided: it is a debug layer of
its own, on its own key, off by default, and on from the start when `--spikes` is set. Filed
as M153 in `TODO.md`.

> "and spike recording should only be on while the layer is on. that means toggling the layer
> twice will lead to a blank frame array"

Said a minute later. The graph's ring of frame lengths is fed only while its layer is on and
is emptied when the layer goes off, so turning it off and on again starts from an empty graph.
Added to M153. The run log's own `spike` line stays on `--spikes` alone, as M144 decided it,
since the sentence is about the view's recording and not the log's; that reading is written in
the entry so it can be overturned.
## The leaf blower: a wall to walk past, a busker to stay near

> "a leaf blower should be able to close one side of a street and spaced out correctly a calm
> area" — "walking past a leaf blower should still be like a wall. but staying away from it
> should only prevent sleeping in a calm area (much like the busker)"

Said on 2026-09-15, answering M129's one open question — the wall exemption, and the leaf
blower standing in a cut on 156 of the 196 routes the four rules leave without a zero-cost
line. The answer is neither of the two options put (its reach under the street's width, or the
wall exemption narrowed): it is a field with two parts. Close in, the price of walking past it
is a wall's. Further out, its field is the busker's — loud enough that a baby does not sleep
in a calm area within it, and nothing a walk has to route around. So a leaf blower on a
pavement closes that pavement and not the street, and several of them spaced across a park
keep the park awake. Filed as M129's closing items in `TODO.md`, with the rule change that
follows from it: a row denies the ground it charges for, not the ground it can be heard on.

> "option 2 is valid only if the influence at a junction is low enough that it can be taken
> without having to worry or plan around it"

Said a few minutes later, on whether walls may be counted by the three rules at all. The
condition is what the rule change above states: what a wall may still reach into a route
junction is the part of its field under the walking decay, ground the walk takes without
planning around it, and everything louder is checked like any other row's.

## A row's own drop-off

> "can we influence the drop off of excitement per row?" — "or is the rate by distance always
> the same for every row?" — "1 doesn't change the leafblower row? we can do that for now.
> also we can introduce the exponent but leave everything as is for now"

Said on 2026-09-15, after the leaf blower's two-part field was filed. The rate by distance is
one curve for every row today, shaped only by a row's two radii. Decided: the leaf blower gets
its core as filed, which changes that row and no other; and the catalogue gains a per-row
exponent on the drop-off, every row left at today's curve, so a row that later needs a shape
its radii cannot give has the knob. Both in M129's closing items in `TODO.md`.
