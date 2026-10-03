# Playtest leafy-hare — Cloud review corrections for nearby ground preparation

2026-10-02.

The player has chosen a phone evaluation and authorized merging PR 452 after review and
CI, recorded in gray-stork. They then report:

> okay pr review found some issues -- let's fix them

The review they point to is posted on PR 452 by the player, attributed to an independent
Claude Code reviewer. Its complete text follows. The required probe/doc correction belongs
to this existing open PR. The merge-before-phone-check question is answered by the player's
recorded choice to merge for that evaluation; optional implementation suggestions remain
proposals to assess rather than proof of a defect.

> ## Review of PR 452 — silky-rabbit, spread nearby ground preparation across frames
> Head: 1b3541e118e8e633ca1ba3efba7ef963901b98c9 · Reviewer: Claude Code (not the author)
>
> ### Semantic check (player's words first)
> - Issue 446: "The compositing process of creating ground visuals can be smeared across
>   multiple frames. That would improve stuttering." Your correction in speckled-marten (the
>   nearby regions that load around the player, not the shared image sheet built at load) is
>   followed. The shared sheet is left alone.
> - gentle-moose: you asked for a before/after measurement and to test "one section per frame
>   (an even stricter rule)". The global "one section in total per frame" reading is the only
>   rule stricter than one per region, and the playtest file records it as the assistant's
>   reading. Both were measured. Per-region is kept and is named as open to overturn. OK.
> - Queue: the silky-rabbit entry was added in e2505b75 and deleted in 1b3541e1, so it doesn't
>   reach main. The decision record is written. A human review item
>   (docs/review/2026-10-02-silky-rabbit.md) asks for a browser and phone play check. OK.
> - Pictures: a 36-frame gameplay burst and a 3-second walking/reversal clip. Ground stays
>   continuous at the junction. OK.
>
> ### Claims I verified rather than took on trust
> - The "per-region" runtime that was measured (pinned commit a64abc1c) is byte-identical to the
>   head. `git diff a64abc1c..head -- src scenes project.godot assets` is empty, so the numbers
>   describe the code that would ship.
> - The "global" pin (59b5e6ba) differs from main only in scenery_ground.gd and
>   scenery_residency.gd. Its fence lets one ground step through per frame in total, which is
>   the stricter rule as described.
> - Live-edit path: City.close_ground() redraws each closed tile and its 8 neighbours through
>   SceneryGround.set_cell(). set_cell() now cancels the pending region that tile belongs to,
>   so a neighbour region that is half-built is rebuilt from the current map. It can't publish
>   stale cells. Correct.
> - Water: SceneryWater draws each cell on its own and doesn't look at neighbours, so splitting
>   one surface into 4 per region can't add seams. This matches the "identical pixels" claim.
> - The frame fence (a per-frame set of regions already stepped, kept by SceneryResidency) can't
>   be bypassed by cancelling a job and starting it again. The new test checks exactly that.
> - CI on the head: classify, gates, game and 7 of 8 test shards are green. Shard 4 was still
>   running when I checked. A Codex reviewer already posted APPROVE on this head.
>
> ### Findings
>
> 1. [medium · decision for the player] The steady costs are permanent; the benefit is unproven
>    where the stutter happens.
>    Every completed region keeps rendering_quadrant_size = 4 (scenery_ground.gd:74), so the
>    renderer draws it in 16-cell batches instead of whole regions. Every region with water
>    keeps one water surface (each with its own shader material) per 4×4 section. Measured in
>    the settled shoreline scene: draw calls 38→46, water surfaces 6→24, about 61% more of
>    Godot's tracked static allocation, steady frame median slightly up.
>    The benefit was measured natively on an M2. There, neither version ever exceeds 16.7ms,
>    so the test reproduced no stutter. Ordinary median is about 11% better; the 15Hz worst
>    cases are mixed. Draw calls and per-surface materials cost the most on WebGL and phones,
>    which is exactly what isn't measured yet (it's the open review item).
>    Ask: should the browser/phone check gate this merge, or do you accept merging first and
>    judging afterwards? I'd run the check first: it's the only evidence that can answer
>    issue 446's "improve stuttering".
>
> 2. [low-medium · stale doc] scenery_residency.gd:11 still says "Native acceptance measures
>    every entered batch." This PR adds a note to tests/probes/scenery_residency_acceptance.gd
>    (line 4) saying its synchronous loop "cannot advance the current process-frame-gated
>    scheduler" and should be run "on the pinned revision". So at head the probe is knowingly
>    broken, and the note describes a different copy (the old revision's own file). The probe
>    also reports ground.worst_prepare_usec (line 88). After this PR that field only records
>    synchronous completions (safety guard, repaint, relocation), not ordinary preparation, so
>    the number it reports changed meaning without being renamed.
>    Fix: delete the probe at head (the pinned revision keeps its own copy), or port it to
>    await real process frames. Either way, reword or remove the line-11 sentence.
>
> 3. [low · optional] Merge the water surfaces when a region completes. Collapsing a finished
>    region's quadrant SceneryWater nodes into one would take water surfaces back from 24 to 6
>    and recover part of finding 1's draw-call cost. The per-step timing would be unaffected,
>    because the merge happens once, on completion.
>
> 4. [nit] scenery_ground.gd:25. `_process` builds a new array every frame
>    (`chunks.values() + _pending_layers()`, plus a lambda `map`) and walks every layer's
>    children to find water. It's small, but in a PR about frame time it's avoidable: keep a
>    list of water nodes and update that.
>
> 5. [nit] docs/ARCHITECTURE.md:510 has a stray short line break ("flushes TileMap internals;
>    incomplete regions" / "remain separately owned…") left over from an edit.
>
> ### Not checked
> - I didn't run the engine or the matched measurement script (no native display here). I
>   relied on the retained results.json, the source pins I checked above, and the Codex
>   reviewer's recomputation of the aggregates.
> - I didn't inspect every burst frame individually.
>
> Verdict: not ready — 1b3541e118e8e633ca1ba3efba7ef963901b98c9
> (Fix finding 2 and decide finding 1. 3–5 are optional.)
