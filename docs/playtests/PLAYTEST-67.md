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
mirrored-view fix made the westbound half draw a rim at all. Asked which version, later the same
day:

> I'm unsure if it was 9.0 or 9.1 I will report it again if I see it otherwise let's consider it
> fixed

So it closes as M121's finding, and a fresh report on v0.9.1 or later reopens it.

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

## The first press walks her

Reported later the same day, after the four above were filed:

> Also the player direction should be reset to zero when the game starts. Right now it always
> starts already walking (probably from clicking the button) same with exiting pause or any other
> screen

> Pause can keep the last direction just don't overwrite it from the button press

Nothing earlier in the playtests reports this. A run begins from a press on a title-screen disc,
a day continues from the summary's button, and the pause screen closes from its own; the report
is that the press that dismissed the screen is read as a walk direction, so she is already
walking when play resumes. The player's design: at the start of a run her direction is zero;
when any screen closes, whatever direction was locked in before it opened stands — pause keeps
the last heading — and the button press itself never becomes one. M127 in `TODO.md`.

## Questions for a human eye

> Also ask me a couple of questions (one at a time) for things that need a human eye. I might be
> able to answer them. Go one by one through the questions file

The questions file is `REVIEW.md`. The next session asks them one at a time, each with the
context its entry gives, and files each answer as a finding here or in the next playtest file,
removing the item from `REVIEW.md` in the same commit.
