# Playtest 97 — The route's tint goes back on both sides of the street

**Date:** 2026-09-19

Said in conversation, on being told that the hard walls met on the route's own sidewalk
([PLAYTEST-94](PLAYTEST-94.md)) are parked delivery vans the route-sidewalk rule never covered,
and that the rule is being rebuilt by physical fit. No run attached.

## What the player said

> "also let's do the mark for the correct path on the full segment (both sides) again -- that way
> those obvious problems now (with obstacles on the path side but no obstacle on the other side)
> are not obvious anymore -- I can still confirm whether you actually fixed those issues via the
> path debug view."

## What is asked for, as statements

1. **The route's yellow curbstone tint is on both sidewalks of every street the route uses,
   again.** *Asked for one side on 2026-09-15 ([PLAYTEST-76](PLAYTEST-76.md): "why is the yellow
   tint on both sides? clearly the bottom path cannot be on any route") · overturned by the
   player to both sides on 2026-09-19, because a one-sided mark makes a wall on the marked side
   with an empty sidewalk opposite obvious.* The mark says *this street*, not *this sidewalk*.
2. **The route debug view stays exact.** The purple route lines (layer `5`) keep following the
   tree's own sidewalk, which is how the player checks that nothing she cannot pass stands on the
   walked side.
3. **The placement rule does not move with the mark.** Bodies that leave no lane are still kept
   off the sidewalk the route actually walks; the tint is the only thing that widens.
