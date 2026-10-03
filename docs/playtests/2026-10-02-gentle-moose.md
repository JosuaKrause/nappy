# Playtest gentle-moose — Compare ground preparation before and after

2026-10-02.

## The preparation plan

The assistant is implementing silky-rabbit, spread nearby ground preparation across frames,
for issue 446. Its plan divides each existing region into four sections, advances at most
one section per region per frame while allowing several regions under the existing CPU
budget, includes TileMap renderer preparation in that budget, and completes approaching
unfinished regions synchronously at the safety boundary. Unfinished work survives reversals
inside the existing retention boundary and is discarded when distant or stale. The assistant
plans to verify matching visuals, low-frame-rate coverage and memory/drawing overhead.

After intermediate progress and parallel PR 448 review messages, the player asks to see the
plan directly:

> so where is the plan that you want to tell me?

The assistant gives the plan above in its final response and links draft PR 452.

## Measure the impact and test the stricter rule

The player asks for before-and-after measurement and a stricter scheduling experiment:

> do you have a way to measure the impact? before and after? can we also test one section per frame (an even stricter rule)?

Here the plan's rule is one section per region per frame, allowing multiple regions to
advance in one frame. The assistant reads the stricter experiment as one section total per
frame across all regions. It proposes a controlled comparison of the atomic nearby-region
runtime, that global section limit, and the per-region section limit, measuring preparation
spikes, rendered-frame spans, steady rendering cost, coverage and safety-guard completions.
The question requests the experiment; it does not choose the final runtime scheduler.
