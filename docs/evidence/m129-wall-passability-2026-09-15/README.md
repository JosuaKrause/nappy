# M129 evidence — a wall is also what cannot be walked past

The zero-cost line probe either side of the three changes the queue item asks for: the passability
clause in `EventScheduler._role_for`, `_copies_of` reading the corridor per sidewalk, and the width
rule reading the sidewalk the route is walked along. Both files are the whole printed output of

```
tools/test.sh probes/m129_zero_cost_line.gd
```

six seeds by one day per act, unchanged between the two runs.

| file | commit |
| --- | --- |
| `probe-before.txt` | `bbcfe15e`, `main` at the branch point |
| `probe-after.txt` | `0bb5cff2`, the third of the branch's three commits |

## What moved

| routes with a zero-cost line (primary reading) | before | after |
| --- | ---: | ---: |
| act I | 83.7% | 100.0% |
| act II | 67.0% | 95.5% |
| act III | 54.1% | 93.2% |
| act IV | 25.0% | 75.0% |
| all | 183 of 296 (61.8%) | 275 of 296 (92.9%) |

The day's own catalogue rows, with the seals and the region wall left out, go from 66.9% to 95.6%.
The density does not move: 431.2 placed rows a day that a line has to avoid, against 431.1.

## What broke the line

| shape | before (routes / cuts) | after |
| --- | ---: | ---: |
| the junction itself is taken | 69 / 97 | 20 / 32 |
| the cut is not a straight band across one street | 22 / 40 | 1 / 2 |
| a body on one pavement, the far pavement also taken | 8 / 9 | 0 / 0 |
| a pacing row whose beat never leaves an opening | 2 / 3 | 0 / 0 |
| one row covering the street's whole width by itself | 1 / 1 | 0 / 0 |
| three or more rows covering the width between them | 1 / 1 | 0 / 0 |
| other | 10 / 33 | 0 / 3 |

What is left is almost entirely the junction shape, and the row standing in most of it is
`roadblock` — a row placed on a carriageway, which no sidewalk rule reaches. The other queue item
in this section, "Which placements the three rules never see", is where the remaining cuts are
addressed.
