# Playtest 67 — 2026-09-13

A few sessions on a phone, on the live page, reported in one message after playtest 66's four
milestones and the mirrored-halo fix landed and v0.9.1 was released the same afternoon. Which
version the phone sessions ran is not stated; v0.9.1 went live at about 14:35 UTC and the report
came after it, so the sessions may have been on v0.9.0, v0.9.1 or both.

## An eastbound car's halo sits off its body

> Yeah I noticed sometimes the halo of West to East driving cars are offset vertically. But it's
> not consistent.

A car driving east is drawn in its side view. On v0.9.0 the halo kept whatever silhouette it had
when its glow settled, so a car that turned onto an east-west street while lit kept the rim of
its diagonal view — registered about 30px lower than the side view was — until the glow changed:
a vertical offset, only on cars that had just turned under a halo, which is *"not consistent"*.
M121 re-traces the rim every frame and registers every view to the strike box, and the
mirrored-view fix made the westbound half draw a rim at all. Whether this is that defect seen on
v0.9.0, or something still present on v0.9.1, is M123 in `TODO.md`.

## The phone is laggy

> I played a few sessions on mobile. It is a bit laggy now. Are we using proper texture atlases
> or is everything an individual loaded texture? Maybe we can optimize the game a bit more.

The answer to the question is *individual textures*: every SVG and every PNG transfer is its own
resource, drawn from each entity's own `_draw()` with `draw_texture_rect`, and nothing is packed.
M100 carried *"frame rate at the game's scale on somebody else's machine"* as the one unanswered
question about the web build; this is its answer, and it moves to M124 in `TODO.md` with what
the last two days added to a frame.

## The tests are slow again

> Also the tests are slow again, too. Tests that only restate numbers in tables etc can be
> completely removed.

The rule already stands in the **verify** skill from 2026-09-03 — *"this was one example of
pointless brittle tests … they just double the amount of work when changing things"* — and the
suite has grown past it again: main's CI run on the M121 merge counts over a million checks, and
five suites take between three and twelve minutes each. M125 in `TODO.md`.

## The audit

> Other than that do a thorough audit of the codebase.

M126 in `TODO.md`: a read-only audit whose findings become items, not a rewrite.
