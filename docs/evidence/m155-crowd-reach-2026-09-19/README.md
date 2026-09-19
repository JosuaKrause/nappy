# M155 — the crowd's reach comes in

Runs of `tests/probes/m117_decay.gd`, three seeds (4242, 90210, 1337), day 1 and day 9, from

```sh
tools/test.sh probes/m117_decay.gd
```

| file | tree |
|---|---|
| `probe-45417c96.txt` | the base this item started from: `PEDESTRIAN_OUTER_RADIUS` 55px, `CAR_INTENSITY` 5.4, `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` 0.35, before any of M155's numbers moved |
| `probe-car-intensity-attempt.txt` | a rejected attempt: `PEDESTRIAN_OUTER_RADIUS` at 30px, `CAR_INTENSITY` raised to 7.7 to hold the main road's price, `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` unchanged at 0.35. Kept as a record of what was tried and rejected rather than deleted — see below |
| `probe-after-the-fix.txt` | this branch's own tree: `PEDESTRIAN_OUTER_RADIUS` at 30px, `CAR_INTENSITY` back at 5.4, `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` lowered to 0.02 to hold the main road's price instead |

**The quiet-pavement leg is the number the player's complaint is about.** It nets −3.95/s in the
base file, against the empty street's own −6.0/s (`Tuning.EXCITEMENT_DECAY_WALKING`). The
car-intensity attempt only reaches −4.20/s: raising `CAR_INTENSITY` to hold the main road also
raises every other street's own light traffic, since a car is not confined to the arterial, and
that ate roughly half of what the shorter pedestrian reach had bought back. The final file reaches
**−4.73/s**, because the ground multiplier that replaces it is exclusive to main-road tiles and
touches nothing else — the quiet pavement, the precinct and the alley all read exactly as the
radius alone would put them.

**The main-road leg is the one that must not move.** Base file: +5.71/s net on day 1, −0.13/s on
day 9. Car-intensity attempt: +5.70/s and −0.12/s — held, at the cost above. Final file: +5.69/s
and **+1.36/s** — day 1 held to within 0.02/s, day 9 moved substantially: the spine no longer gives
back anything at all even at its lightest traffic of the run, where before it was barely net
recovery. `EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` is not stated per day, so a value that holds day 1
exactly cannot also hold day 9 where the two densities disagree on how much ground recovery would
be needed; day 1 is the one `tests/test_crowd.gd`'s arterial floor and crossing-cost checks are
stated against, so it is the one held exactly.

**Crossing the main road still costs 27.76 of a hundred-point meter** (worst of eight attempts,
seed 4242, `tests/test_crowd.gd`'s own measure), against 26.16 in the base file — comfortably under
the `METER_MAX / 2` ceiling the "expensive, not impossible" rule is stated against, because the
same short pedestrian reach that costs the ground its own recovery also lightens what a crossing
itself loads.

**Precinct and alley moved too, in every file after the base one** — a side effect of
`PEDESTRIAN_OUTER_RADIUS` alone, unrelated to which main-road lever is used (both non-base files
agree): precinct −6.53/s → −8.13/s (day 1), −8.83/s → −8.94/s (day 9); alley −0.10/s → −0.45/s
(day 1), −0.43/s → −0.48/s (day 9). Nobody asked these to hold; they are recorded here since they
moved.

All three files also carry the `docs/EVENTS.md` cost table the same probe prints, unchanged across
all of them, since neither number it depends on moved.
