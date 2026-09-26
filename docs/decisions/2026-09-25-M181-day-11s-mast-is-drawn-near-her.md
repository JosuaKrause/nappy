## M181 — Day 11's mast is drawn near her · built 2026-09-25

*([PLAYTEST-130](../playtests/PLAYTEST-130.md): "we need to tip the randomness to have the mast
closeby".)*

**What is built.** `_place_at_a_mast()` in `src/resistance/resistance_director.gd` keeps every
refusal it had (reachable ground beside the foot, not on the home block, not already silenced) and
draws among the masts it offers with weight `1/d²`, `d` the straight-line distance from where she
stands when the task is placed to the tile beside that mast's foot, floored at one tile (32px) so
a mast right beside her does not swamp the rest. With no player in the tree the doorstep stands in.
One `rng.randf()` off the day's RNG, the same weighted draw `poster_walls.gd` makes, so the same
seed and route draw the same mast. `tests/test_resistance.gd` checks that a mast 2 tiles away is
drawn more than three times as often as one 10 tiles away, and that the far one can still be drawn.

**Straight-line, not walking distance, open to overturn.** `ReachabilityGrid` answers only
whether a tile is reached, never how far, so no walking distance was on hand; a mast across a wall
can win on straight-line distance.

**Day 11 re-timed**, `--route mark,task,calm,home --invincible --no-save` through
`tests/probes/m184_route_timing.gd`, alone on the machine:

```
seed       mark    task    calm  settled    home  left180   (was home / left180)
4242      35.2s   98.2s  105.6s  106.2s  126.0s    54.0s    (176.8s /  3.2s)
90210     11.1s   11.9s   31.5s   36.9s   65.3s   115.0s    ( 65.3s / 114.7s)
1234567   34.2s   98.8s  113.1s  113.2s  156.5s    24.0s    (156.0s / 24.0s)
```

On seed 4242 the corner mast is no longer drawn. On 90210 the mast was already near. On 1234567
nothing changes: the offer there holds one or two masts at most, so there is nothing to tip toward,
and the task is still the far one; the weighting chooses among the masts offered and does not
change which are offered.
