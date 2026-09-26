## M117 — Excitement decays visibly on quiet ground · built 2026-09-12

*(2026-09-12, playtest 63: "the decay for excitement is too low anywhere -- except for the main
street and maybe alleys there excitement should go visibly down when no excitement source is
around -- prioritize this fix", and on the round as a whole: "this round's feedbacks should all be
prioritized since I'm actively testing the changes as they come in".)* The three questions the
instruction left open were put back the same day with a recommendation each and answered **"None
— build as recommended"**, so all three are decisions here rather than proposals.

**The complaint was about a net rate, so it was measured before it was changed.**
`tests/probes/m117_decay.gd` is the instrument and is parked rather than deleted: it walks a leg
on each kind of ground for forty seconds with the day's own crowd focused on her, sums what the
crowd loads against what the ground gives back per sample, and prints the net. Three seeds, day 1
and day 9. Its first calm leg walked the diagonal of a calm *block* and spent two samples in five
off the grass, which averaged quietly into a number that looked like a park — it now walks the
longest straight run of the tile type it is about and prints the multiplier it actually spent its
samples on, so a leg that wanders off its own ground says so.

**Before and after**, day 1 (act I), means over three seeds, in points per second and in seconds
to clear a full meter:

| Ground | before | | after | |
| --- | ---: | ---: | ---: | ---: |
| Quiet ordinary pavement | −1.18/s | 85s | **−3.76/s** | **27s** |
| Main road | +6.01/s | never | +6.01/s | never |
| Precinct | −2.88/s | 35s | −6.63/s | 15s |
| Calm, on grass throughout | −7.70/s | 13s | −12.00/s | 8.3s |
| Alley | −0.04/s | — | −0.02/s | — |

Day 9 (act III), where the streets have emptied: quiet pavement −3.16 → −5.74/s, precinct
−5.04 → −8.79/s, main road +0.10 → +0.10/s, alley −0.37 → −0.35/s.

Both halves of that table were taken on one tree with only the constants differing, which is what
makes it a controlled comparison. **M110, the crowd goes round a seal, landed afterwards and moves
the crowd term** — the same probe now reads the quiet pavement at −3.60/s and the main road at
+5.72/s, because walkers stepping round solid bodies stand somewhere slightly different. The ground
half is untouched by it.

**The numbers.** `EXCITEMENT_DECAY_WALKING` 3.5 → **6.0**. Every other ground is a ratio re-derived
to hold its own absolute rate where it was put, so only the quiet ground moves:
`EXCITEMENT_DECAY_MAIN_ROAD_MULTIPLIER` 0.6 → **0.35** (2.1/s, exactly today's), a new
`EXCITEMENT_DECAY_ALLEY_MULTIPLIER` at **0.58** (3.48/s, today's 3.5), and
`EXCITEMENT_DECAY_CALM_ZONE_MULTIPLIER` 2.2 → **2.0**. The calm one is the only number that came
down rather than across, and the entry's own guard is why: at 2.2 a park would clear a full meter
in 7.6 seconds, under the eight the entry set as the line between a place and a switch; at 2.0 it
is 8.3. The precinct stays at 1.5 (9.0/s) because only the park carried a stated floor. Ordering
holds: calm > precinct > street > alley > main road. `EXCITEMENT_DECAY_IDLE` stays zero and
`EXCITEMENT_DECAY_RUNNING` stays 0.5 — the first is question 1 answered, the second is untouched
because the run button is a trap by design and raising its decay would soften the one thing it is
for.

**Merging with M118 moved the crash's number, because the two priced one walk in opposite
directions.** M118 set `CAR_ACCIDENT_INTENSITY` to 45.0 against the walking decay of 3.5/s it was
measured under, where the cheapest squeeze past a crash cost 56.3; at 6.0/s the same walk costs
**46.7**, under the `METER_MAX / 2` line the row exists to sit on the far side of, and
`tests/test_seals.gd`'s walk refused the merge on both street axes. The relationship is the
player's (*"prevents the player from walking past it"*), so the number moved and not the test:
`tests/probes/m118_crash_gap.gd` at **50.0** puts the cheapest pass at **54.4** and the dearest at
55.3, and the cost table's row goes to +65.7 walking and +58.3 running — running still the right
move on this one row, now saving about seven points rather than four. The required telegraph is
stated over radii and speed, not intensity, so the fairness contract did not move.

**And the calm-zone admission distance is decoupled, which is the half that is not a rebalance.**
`EventScheduler._denial_radius` read the calm ground's live decay, so raising the walking rate
would have admitted louder rows beside every park as a side effect. `Tuning.CALM_ZONE_DENIAL_RATE`
pins it at the 7.7/s it has always been. The pram settling faster is a statement about the pram;
which events may stand next to a park is a statement about the parks, and tying the two put the
second decision inside the first where nobody making it would see it. The spoiler geometry does
not move at all.

**Nine checks went red and each was decided rather than updated.** *(Their reasons are beside them
in the tests; what follows is the list.)*

1. **"Brushing past somebody outruns the walking decay"** → *"walking into somebody outruns it, and
   one person at arm's length does not."* Question 3, answered by the player: at 4.2/s a lone
   passer-by no longer clears 6.0, and that is the decision rather than a casualty of it — *no
   source around* has to read as recovery. A contact (18/s) still costs and is a thing she did;
   a crowded pavement still costs because the load is a sum. The crowd's intensities, radii and
   counts are untouched, since raising them to chase the decay raises the main road's crossing
   cost with them.
2. **The arterial floor, 3. the back street's, 4. the park's and 5. the alley trickle** were all
   priced against the raw constant while the ground multiplies it. Each now compares against
   `City.decay_multiplier()` at the point it was measured. Only one of the four was failing; three
   would have gone on passing for the wrong reason. The back street gained a second check — that
   the crowd takes back less than half of what the ground gives — which is the milestone's own
   sentence as a relationship.
6. **"One bump from 90 on an empty street ends the day"** → *"one contact is fatal only from
   inside the band the pram is already warning about."* Its own doc called it measured rather than
   designed. From 90 a contact now reaches 98.8; the height it kills from is 91.2, against a
   nearly-crying cue at 80. A contact that killed from under that cue would be a death with no
   warning in front of it, which is the thing worth pinning.
7. **Four rows became cheaper to walk through than around.** `poster_crew` goes back on the
   scenery list it used to sit just above — nothing about the row moved, the ground under it did.
   `chatting_mother`, `checkpoint_hut` and `checkpoint_post` get a named list of their own: their
   price is `CHAT_EXCITEMENT` charged over the hold, so a field sized to clear the decay as well
   would charge the same body twice at a number driven by a test rather than by what the row is.
   The exemption owes a check of its own, so those three are held to charging their capture.
8. **"The sample has both kinds of wall in it"** and 9. **"gaps carry a wall"** →
   `WALL_WORTH_OF_COST` 0.4 → **0.35** of the meter. The threshold is in points, and raising the
   decay lowers every row's cost *unevenly*: the decay is netted off over the time the crossing
   takes, so a wide moderate row loses far more than a narrow intense one. `protest` (269px of
   15/s) fell 42.3 → 27.6 and crossed under `dog_walker` (105px of 26/s, 36.5 → 30.8), which no
   threshold can undo. The line is re-derived between the two rows that set it — above the dog
   walker, which has to stay friction, and at or below `leaf_blower` (37.7), which has to stay a
   wall or the non-lethal half of *"very costly to deadly"* is act III rows only.

**Choices the entry was silent on, all open to overturn.** The alley multiplier is 0.58 rather than
an exact 3.5/6.0, which costs 0.02/s and buys a two-decimal number. The precinct multiplier was
left alone. `WALL_WORTH_OF_COST` moved, and with it **`protest` from a wall to friction** — it is
now on the day's corridors with the ordinary expensive city, because it genuinely costs less to
walk through than a dog walker does. `poster_crew` and the three detainers were exempted rather
than made louder. The probe is parked under `tests/probes/`, which the runner never discovers.

**Two rows the change made nearly free went back to the player and were retuned in the same
milestone.** Reported as forks first — `busker` fell to +2.9 to walk through against the +13.3 it
cost before, `alley_mouse` to +1.0 against +4.2 — with the note that above a walking decay of about
**6.7** both turn free outright, which is the ceiling on this number and the reason it is 6.0 and
not 7.0. The answer came in three sentences, the second revising the first and the third deciding
how the question is asked at all:

> busker should be adjusted. alley mouse can be nearly free

> alley mouse is a bit above charging cat

> consider that the mouse is in the alley but the cat is usually not

**The third is the one that set the number, and it is a correction to the method.** The cost table
nets every row against the same walking decay, but a row is met on the ground it is placed on:
`alley_mouse` is `ALLEY`-only, where the ground gives back 3.5/s instead of 6.0 and
`EXCITEMENT_FROM_ALLEY` (+3.0/s) is already being charged, while `cat_dash` is met on an ordinary
street at 6.0/s. So the alley hands the mouse most of the gap before its own intensity is touched,
and the raise needed is far smaller than the table implies — 21.0 rather than the ~29 that reading
the table uniformly would have demanded. **`alley_mouse` 9.0 → 21.0**: it walks to **+19.9 in an
alley** against the cat's **+17.6 on a street**, a bit above, as asked. On the table, which cannot
say "on its own ground", it prints +12.7 against the cat's +17.6, and a note under the table names
the three rows that reading misprices rather than changing the table's method — the same integral
feeds the danger caret and a per-row ground would be two answers to one question. The large number
on a 60px field is the idiom rather than a mistake: the crossing is a second and a third, there is
no `impulse` field, and a spike here is bought in intensity.

**`busker` 9.0 → 13.0**, the lowest round number above both of its floors, and low on purpose.
It stands on calm ground, so what it has to beat is the park's 12.0/s — under that it is a park
*bonus* with a picture of a nuisance on it — and it has to stay at least as expensive to cross as
before M117. At 13.0 the core of it runs **+1.0/s** inside `inner_radius` at the top of its beat
and it crosses at **+15.3** on the table against the +13.3 floor. **What every extra point costs is
park**: `_denial_radius` is pinned at 7.7/s now, so intensity is the only thing that widens it, and
this raise took the busker's denial radius from **100.1px to 137.6px** in a lot 704px across —
nearly twice the area one of them takes out. Stated rather than hidden: along a *whole line* through
one, on park ground, a busker is still net recovery (−9.5), because the rim is under the park's own
decay. Its core costs and its rim pays back, which is a place to walk round rather than a wall.

**What this still narrows, reported rather than fixed.** `playground`, the other row that stands on
calm ground, clears it by three rather than by seven; its pulse runs down to a quarter of its
intensity, so the middle of a playground is expensive at the top of its nine-second beat and free at
the bottom. The busker's pulse does the same thing for the same reason.

**Rejected on the way.** Raising the crowd's numbers to chase the decay (the entry's own
instruction, and it would have moved the main-road crossing). Raising the detainers' and
`poster_crew`'s intensities to clear the new decay (charging the same body twice). Raising
`playground` to restore its old margin — `_denial_radius` is pinned now, so a louder playground
would deny *more* park than it does today, which is the exact side effect the decoupling exists to
stop. A walking decay of 7.0, which reads better against the player's "or better" and clears a
park in 7.1 seconds even at the lowered multiplier while turning the busker and the alley mouse
free.

**Evidence**: `docs/evidence/m117-visible-decay-2026-09-12/`, a thirty-six frame burst under
`--invincible` — which empties the incoming sources and leaves the decay running, so the frames
are the decay and nothing else. The bar reads 90 at the doorstep, 72 at the first burst frame and
54 at the last, with `incoming 0.00/s, decay 6.00/s, net -6.00/s` throughout. The street does not
scroll during the burst: she walked eight tiles south in the three seconds before it and then met
a solid `market_stall` at (1,10), so the window caught her held against it. The travel is in
`run.log`; the frames are evidence about the meter. What no rig can answer is in `REVIEW.md`.
