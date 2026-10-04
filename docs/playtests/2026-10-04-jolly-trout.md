# Playtest jolly-trout — Split the frame record's draw, and make the physics tick cheaper

2026-10-04. Two notes captured in a session, #541 and #542, both about M159 (a slow frame names the
frame that was slow) after the phone's frame record was analysed. Each of the player's words is
copied word for word, after what it answered.

## #541 — M159: split the frame record's draw without changing batching

Asked on 2026-10-04 after the analysis of the phone's frame record (M159, PR #532): drawing is the
largest share of a frame and, depending on the model fitted, much of it is not explained by draw
calls, objects or primitives; the next step proposed was to split what is inside `draw`.

> Can we get more granular mobile measurements or would that break up things that are currently drawn together into separate draws? We wouldn't want that I guess

Answered on 2026-10-04: timestamps around work that already happens change nothing about batching;
only splitting the picture into separate canvas items, layers or materials would. The frame
record's `draw` column runs from the end of the process step to the renderer's post-draw callback,
and can be split three ways without touching batching: (1) one more timestamp at the renderer's
pre-draw signal, splitting draw into our own `_draw()` redraws plus the engine's scene preparation,
and the renderer's own work plus any GPU wait; (2) a per-frame count of `_draw()` calls by kind
(crowd, halos, scenery, badges); (3) the engine's own measured render CPU time, if the web build
reports it. Timing each `_draw()` separately is avoided: the page's 100µs clock is too coarse and
hundreds of reads per frame would slow the record. All of it runs only with `?framerecord=1`.
Proposed: file it under M159 as an item (1 and 2, and 3 if available), then one more phone
recording. "Shall I file it?"

> Yes and let's start work on it to go into the next release

Asked on 2026-10-04: "I read 'the next release' as the one after v0.25.0: v0.25.0 goes out as soon
as #536, #538 and #539 pass review, and the measurements follow in the release after. Tell me if
you'd rather hold v0.25.0 for them."

> Yeah a patch release for after 25

## #542 — M159: make the physics tick cheaper

Asked on 2026-10-04 after the phone frame record's analysis (M159, PR #532) found 35% of frames run
two or more physics steps, about 3.8ms per extra step.

> Also what about the physics twice per frame? Should we fix that?

Answered on 2026-10-04: two ticks in one frame is the fixed 30/s tick catching up after a frame
longer than 33ms (the phone's median is about 41ms), which keeps the clock, chases and speeds the
same on any device; each extra tick costs about 3.8ms (crowd 1.7, influence 0.7, events 0.7, other
physics 0.7), about 11% of the phone's time. Ways down: faster frames (the draw split already
agreed), a cheaper tick starting with the crowd's physics step (invisible to the player), or a lower
tick such as 20/s (M141 allows it; costs up to 50ms input latency and coarser collision and chase
steps, so the player's call after a measurement). Capping at one tick per frame would slow the whole
game on a slow phone and is not proposed. "I'd file a 'make the tick cheaper' item under M159,
starting with the crowd's physics step, and measure 20 against 30 headlessly as an option for you
to decide. File that too?"

> Sure we can look into making the tick cheaper

## Routing

1. **#541** → [M159, a slow frame names the frame that was slow](../todo/2026-09-19-M159/README.md),
   the item [split-the-draw-column.md](../todo/2026-09-19-M159/split-the-draw-column.md), for a patch
   release after v0.25.0.
2. **#542** → the same entry, the item
   [make-the-physics-tick-cheaper.md](../todo/2026-09-19-M159/make-the-physics-tick-cheaper.md). The
   player said yes to a cheaper tick only; the 20/s measurement is not filed.
