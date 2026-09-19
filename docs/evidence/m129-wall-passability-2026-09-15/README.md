# M129 evidence — a wall is also what cannot be walked past

The zero-cost line probe at three states of the branch: before it, after the three changes the
queue item asks for (the passability clause in `EventScheduler._role_for`, `_copies_of` reading the
corridor per sidewalk, and the width rule reading the sidewalk the route is walked along), and
after the two answers the player gave on the pull request — a wall across the street is common
rather than rare, and a pacing row is a wall only where its beat reaches no crossing. Each file is
the whole printed output of

```
tools/test.sh probes/m129_zero_cost_line.gd
```

six seeds by one day per act, unchanged between the runs.

| file | commit |
| --- | --- |
| `probe-before.txt` | `bbcfe15e`, `main` at the branch point |
| `probe-after.txt` | `0bb5cff2`, the third of the branch's first three commits |
| `probe-after-forks.txt` | `39b3cd4a`, the commit that answers both forks |

## What moved

| routes with a zero-cost line (primary reading) | before | after | after the forks |
| --- | ---: | ---: | ---: |
| act I | 83.7% | 100.0% | 95.3% |
| act II | 67.0% | 95.5% | 93.2% |
| act III | 54.1% | 93.2% | 86.5% |
| act IV | 25.0% | 75.0% | 70.8% |
| all | 183 of 296 (61.8%) | 275 of 296 (92.9%) | 262 of 296 (88.5%) |

The day's own catalogue rows, with the seals and the region wall left out, go 66.9% → 95.6% →
92.2%. The density does not move at any point: 431.2, 431.1 and 431.2 placed rows a day that a line
has to avoid.

**The last column is the price of keeping the shouting man on the route**, and it is the cost the
player accepted when he asked for it: *"yeller is something you can time. it stays on the route."*
The probe's primary reading prices a beat at the ground it never leaves free, which for a 170px
field over a 64px sidewalk is both lanes at the middle of the beat — so a man she is expected to
wait for reads here as a row she has to get past.

## What broke the line

| shape (routes / cuts) | before | after | after the forks |
| --- | ---: | ---: | ---: |
| the junction itself is taken | 69 / 97 | 20 / 32 | 32 / 40 |
| the cut is not a straight band across one street | 22 / 40 | 1 / 2 | 1 / 4 |
| a body on one pavement, the far pavement also taken | 8 / 9 | 0 / 0 | 0 / 0 |
| a pacing row whose beat never leaves an opening | 2 / 3 | 0 / 0 | 0 / 1 |
| one row covering the street's whole width by itself | 1 / 1 | 0 / 0 | 0 / 0 |
| three or more rows covering the width between them | 1 / 1 | 0 / 0 | 0 / 0 |
| other | 10 / 33 | 0 / 3 | 1 / 8 |

**A yeller on the route never breaks it by himself**: the shape named for a beat is no routes and
one cut. Where he is in a cut he is in it with others, at a junction — he stands in the blocked
stretches of 25 of the 34 broken routes, second to `leaf_blower`'s 27 and ahead of `roadblock`'s 23.

What is left is almost entirely the junction shape, and the rows standing in it are the ones no
sidewalk rule reaches: `roadblock` on a carriageway, and the wide fields of a wall one street out
reaching over a crossing. The other queue item in this section, "Which placements the three rules
never see", is where the remaining cuts are addressed.
