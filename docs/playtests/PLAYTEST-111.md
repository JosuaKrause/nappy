# Playtest 111 — The second day's street drew the old tiles

2026-09-20. A run on build `ed64fe3b`, seed 851093948, with a still asked for on day 2. The run
is `docs/evidence/m171-ground-recipe-reread-2026-09-20/`.

## What the player said

With the still:

> "street on the second day uses all old and wrong tiles"

Told the cause — the orchestrator fast-forwarded the player's checkout while the game ran, the
ground's composition recipe moved on disk, and `GroundLayers` reads that file again at every
day's repaint, so day 2 found none, composed nothing and drew the whole authored tiles without
an error — and offered a rule to check for a running game before updating the checkout:

> "why does it need to read the file while it is running? it should be one of the atlases that
> don't unload/load in the day -- your change should have not caused any issue. checking for a
> running game shouldn't be necessary"

> "it's pretty bad if you do I/O that frequently -- let's fix that" · "urgently"

## What the run shows

`run.log` composes day 1 with the recipe — `ground composed: 66 sources over 65 pictures into
424x444` — and day 2 without it: `66 sources over 66 pictures into 240x342`. The checkout was
updated between the two, at 11:54:17 local time; the run began at 11:53:24.

## What is asked for, as statements

1. **The ground's recipe is read from disk once and held for the life of the process**, like
   the `ground` page it composes from. A day's repaint reads nothing from disk.
2. **No rule about checking for a running game.** A game that is running does not depend on
   what the checkout holds.
3. The silent fall back to whole authored tiles is PLAYTEST-110's, and is removed there.
