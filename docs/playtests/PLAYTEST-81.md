# Playtest 81 — The staircase follows its tile grammar

**Date:** 2026-09-19

## What was checked

The M158 stair-side assembly at commit `7e9b7940` was reviewed in the escape stairwell with
`./tools/run.sh --start-escape stairwell:left`.

## What the player said

> "the layout of the staircase is completely wrong"

The player supplied this key:

> `. - background`
>
> `D - door`
>
> `F - floor`
>
> `t - top stair facing right`
>
> `T - top stair facing left`
>
> `m - middle stair facing right`
>
> `M - middle stair facing left`
>
> `c - corner diagonal tile facing right`
>
> `C - corner diagonal tile facing left`
>
> `b - a tile that has a gray rectangle at the top edge with the height as the diagonal`

The first diagram omitted one tile:

> "i forgot a b on the right side"

The player then supplied this corrected version, which is the layout authority:

```text
..........
.D........
.Ft.......
.Fmt......
.bcmt.....
...cmt....
....cmt...
.....cmtD.
......cmF.
.......cF.
.......TF.
......TMF.
.....TMCb.
....TMC...
...TMC....
.DTMC.....
.FMC......
.FC.......
.Ft.......
.Fmt......
.bcmt.....
...cmt....
```

> "here is the corrected version"

And the traversal contract:

> "when the player steps on eith tmTM tiles they move sideways and the same amount up or down
> depending whether they face the same as the stair goes. bcC. are not walkable at all. the D
> moves to the corridor."

## What this changes

The diagram replaces the current stairwell cell layout rather than decorating it. `F` is level
floor and `D` keeps the corresponding corridor transition. The four stair cells `t`, `m`, `T`
and `M` carry diagonal traversal: moving in the direction the flight descends moves equally
sideways and down, while reversing along it moves equally sideways and up. `b`, `c`, `C` and
`.` are not walkable. The reviewed six SVG stair-side sources remain the drawing authority for
their roles; the old broad decks and every railing remain absent while this corrected assembly is
under review.

This overturns the earlier M158 implementation constraint that the stair map, collision and slope
redirection stay unchanged. Door destinations and the wider escape route remain the same.
