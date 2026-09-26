## M128 — The playground is free, and the busker denies sleep outright · built 2026-09-13

*(2026-09-13, [PLAYTEST-68](../playtests/PLAYTEST-68.md): "Playground should be free since
otherwise small parks really have no way of ever getting to sleep. The busker is a bit intense.
We should nerf it a bit but keep it so the baby cannot fall asleep in the park with it. But on
a street with a busker closeby should cause less excitement"; then, in
[PLAYTEST-69](../playtests/PLAYTEST-69.md), three refinements ending in "can we do a net sleep gain
that is slow enough to never reach 100% in the alotted time?" and, on the table below, "the
busker numbers look good".)* Two agent commits on `feature/m128-park-beats`, the second rewritten
three times, reviewed here; the instrument is `tests/probes/m128_park_beats.gd`.

**The playground costs nothing.** `playground`'s intensity is 0.0; the row stays because
`tests/test_events.gd` and `EventInstance._field_distance()` name it by id and both `EVENTS.md`
tables carry its line, and the park's swing frame is drawn from the map rather than from the
row. Ambient rows were already exempt from the usable-park guarantee and the spoiling pass, so
neither moved. Standing on the ambient source's own centre the meter now settles in six to
eleven seconds, pinned as `tests/test_balance.gd`'s `_test_the_playground_itself_settles_her`.

**The busker: radii unchanged, peak 19.3, and why the dial turned out to be a cliff.** Three
shapes were built in turn. First, intensity 12.5 with the reach pulled from 190px to 55px:
street-side spill fell to 45% on average and to nothing for most placements, but the ground he
denies shrank from a 138px radius to 39px in a 256px park, so a one-block park with a busker
became sleepable — overturned by the player on sight (*keep the radius the same but tweak the
excitement number*). Second, the radii back and the peak at the lowest value whose beat-mean
does not fall: the pulse is a cosine between a quarter and all of the peak, so its mean is
62.5%, and the floor is 12.0 ÷ 0.625 = 19.2, which came out as 19.5 and 150% of the street
spill. Third, at the player's *net sleep gain slow enough to never reach 100% in the allotted
time*, the probe simulated the baby's own excitement and sleep update standing at his core in a
one-block park for a whole day, sweeping the peak in tenths:

| peak | sleep meter at his core |
|---|---|
| 13.0, before this milestone | full in 5.7s |
| every value under 19.2 | full within 35s |
| 19.2 and above | never fills |

A park fills sleep so fast that the quiet half of any beat under the beat-mean floor is enough
to finish the job; there is no slow drift to tune with intensity alone, and the two floors are
the same number. **Chosen: 19.3**, one tenth above the crossing so the number does not sit on
the line. At 19.3 the beat nets +0.06 a second at the core (+7.3 at the top, −7.2 at the
bottom), the denial radius is 157px (138 before), the cost-table entry +34.7 (between the dog
walker and the leaf blower), and **the street beside the lot is 148% as loud as before**, the
opposite of the third sentence. Accepted on the numbers, and read with the player's later
framing: with M129's line on the far pavement, a busker's spill onto one side of the street is
a price rather than a wall, so the reach did not need to come down. **Rejected on the way**: a
sleep-rate cut inside his reach, which would have given the slow drift at a peak near 13 — a
new mechanism, offered and not taken.

**Docs.** `EVENTS.md`'s rows and cost table and `CITY.md`'s park rows follow; the scheduler's
own denial-radius sentence names 19.3 and 157px. The old reasoning — *"13.0, the lowest round
number above both of its floors"* — is above under M117.
