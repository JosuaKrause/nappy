# Playtest 128 — Guards and mice turn, the chalk is its picture, the finale is always reachable

2026-09-24. Said in conversation, answering the orchestrator's end-of-session list of open
questions, the items waiting in `REVIEW.md`, and one stale `TODO.md` sentence; three notes from
play followed.

## What was put to the player

- **Directional guards (M56, the resistance is noticed)**: the masked pursuer and the heated
  roadblock guard chase her as a single side picture while eight-view `guard_standing_*` and
  `guard_lunging_*` pictures sit unbound. Turn them to face where they are heading, like the
  robber, or archive the unused direction pictures.
- **The mouse's views (M100, small, real, and nobody's)**: the integration table says to bind the
  alley mouse's directional pictures; `EventCatalogue._alley_mouse()`'s docstring says the mouse
  takes none.
- **The chalk mark (M100)**: drawn in code by `ContactPoint._draw_chalk()` while
  `props/chalk_mark.svg` exists.
- **Finale reachability (M181, the resistance has a reason, and a task is one day)**: should the
  city guarantee a route to the finale's district and to day 9's door and day 12's swing? Today
  the day's own events can occasionally seal them off.
- **The still watch near a red light**: `--quit-when-still` ignores her anywhere on a signalled
  junction's corner sidewalk, a square six tiles on a side.
- **`REVIEW.md`**: the car bob height; the browser tab's favicon and the window icon; a poster
  crew mid-paste, and how hard a push must be to tear a poster.

## What the player said

> "Directional guards (M56) … Yes, hook those up."

> "Mouse views (M100) … The code comment is positive, the queue is normative. The code only
> describes what is, not what should be. That's a general rule."

> "Chalk mark (M100): it's drawn in code even though a chalk_mark.svg exists. Yes, we need to use
> the svg."

> "Finale reachability … Yes, we need to make that a guarantee by construction."

> "Still watch near a red light … What is a still watch? Not sure what you are referring to here."

> "the car bob height — Bob looks good"

> "the live browser tab and window icon — Looks good"

> "a crew pasting posters plus how hard a push has to be. — I didn't see a crew but the posters
> look good. Tearing posters works."

> "the home building shouldn't have a fire escape (it has a double staircase inside)"

> "we can make the extra push needed to end the day a tiny bit more aggressive/tighter"

> "splashing water (from the main break) or puffs of smoke (from the car crash) or steam (from the
> escape) should have (at least) a two frame animation to convey what they are better"

## The statements

1. **The masked pursuer and the heated roadblock guard face where they are heading**, reading the
   eight-view guard pictures through the same helper every other moving family uses.
2. **The alley mouse takes its directional pictures**, as the queue says.
3. **A code comment is positive and the queue is normative.** A comment describes what the code
   does; it never decides what the code should do. Where a comment and `TODO.md` disagree, the
   queue wins and the comment is rewritten when the code changes. A general rule.
4. **The chalk mark is drawn from `chalk_mark.svg`**, not in code.
5. **The finale's district, day 9's door and day 12's swing are reachable by construction**:
   the day's own events never seal them off.
6. **"Still watch" was not a name the player knew.** It is `StillWatch`, the dev tool behind
   `--quit-when-still` (M189, asked for in playtest 127); the question about the red-light
   square was put again with that context and is open.
7. **The car bob reads well**; the 1px rise over 64px stays.
8. **The favicon and the window icon look good.**
9. **The posters look good and tearing one works**; no crew was seen pasting, so whether a crew
   mid-paste reads is still unanswered.
10. **The home building has no fire escape**, because it has a double staircase inside.
11. **The push at the top that ends the day crying is made a little tighter**, so the day ends
    somewhat sooner once the bar is at 100 (M96, the day ends crying only after a push at the
    top).
12. **The main break's water, the car crash's smoke and the escape's steam each animate over at
    least two frames**, so each reads as what it is.
