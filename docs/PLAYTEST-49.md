# Playtest 49 — Prioritising the queue · 2026-09-09

A session in which the player went through the open milestones one by one and placed them, closed
two items on sight, corrected one sentence, and reported one bug. The prioritisation itself is in
`TODO.md`'s gameplay queue and in `DECISIONS.md` under "The queue reprioritised"; this file keeps
the words.

## 1. The queue, item by item

> "play the phone build and measure whether a thumb can hold the 8px lane midline. -- not sure what
> this is but yeah the midline works. the home arrow under a thumb, and a browser smoke pass at the
> live address. what is this? home arrow under thumb is not a problem. M61 is kind of important but
> not the immediate next item. M62 should be next. M50, M47, M45, M43, M49, M25, M26: let's check if
> they are still current and rewrite as new milestones with precise tasks. A shortlist of small
> items, M10 polish, and open design questions. consolidate into a current new milestone. what is
> M79? M64 we can do in parallel -- svg is the main graphics for now. M65 we need to revisit after
> M62. illustrated actors is currently a sidearm for codex to work on. M93 is the caret should show
> the expected impact of an interaction. we can do this in parallel, too? M56 is also related to
> the other items to work on right now. I wanna wait reaching act III until those things are done."

## 2. The main road needs no toll of its own

On the M47 item that asked for the spine to be genuinely expensive to cross:

> "M47's toll already exists -- it's timing the traffic lights. we don't need to penalize routing
> through it just yet -- it naturally happens that only some routes cross it"

## 3. The tutorial dog

Confirming M96's first item:

> "the tutorial dog may appear later but not as tutorial"

## 4. The non-adjacency rule and parks

Correcting the rewritten M97's claim that the rule covers every calm purpose:

> "non -adjacency rule doesn't cover parks yet -- that's something we might want to tweak later."

## 5. Events spawn inside a fully blocked street

> "a definite bug is that inside fully blocked streets (eg tree) restaurants etc can still spawn
> which is silly"

Filed in `TODO.md` under M100, at the top of its defects, with the mechanism that lets it happen.

## 6. The fire comes first, then the engine

> "the player should encounter the burning building before the fire truck. basically the fire
> truck should spawn when the player sees the burning building not the other way around"

Today it is the other way around: `fire_truck` is the day-3 one-shot, drives its route, and leaves
`burning_building` where it stops. Filed in `TODO.md` as M101.
