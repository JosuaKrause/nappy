## M96 — The dog waits from day 4, and the day-3 charge sprinkles in · built 2026-09-13

*(2026-09-13, [PLAYTEST-68](../playtests/PLAYTEST-68.md): "The waiting is good. But we can sprinkle
the day 3 charging dog in every now and then, too. Since they always come from offscreen the only
difference now is that day 3 dog is guaranteed to happen and has a tutorial tip.")* Two agent
commits on `feature/m96-dog-waits`, reviewed here; the burst is
`docs/evidence/m96-dog-waits-2026-09-13/`.

**The map-placed dog waits.** `EventDef` gains `pursues_within_after_first_day` and
`pursues_within_on(day)`, mirroring the spawn-mode switch — a derived answer, never a mutation,
for the reason the heated shape is a derived copy. Because an instance reads `pursues_within` off
the def it was handed, the day's answer arrives as a copy the scheduler builds once in
`_for_day()`, wired where map placement already branches on the day. `charging_dog`'s trigger from
day 4 is 130px, inside its own 150px field and above the stand-off the pursuit rules require
(104px); a first attempt set it equal to the field, which is day 3's un-narrowed field rather than
the robber's on-sight band, and was revised. Boot validation now checks the switched trigger too,
since the catalogue's validation only exercised the heat axis. Day 3's own at-once charge and its
tests are untouched; `tests/test_tutorial_dog.gd` holds that a day-4 copy waits outside the
trigger and telegraphs inside it.

**The day-3 shape sprinkles in.** `EventDirector._owe_the_sprinkled_dog()` rolls
`Tuning.CHARGING_DOG_SPRINKLE_CHANCE` (0.25) once a day past the switch and, on a hit, pushes the
unmodified row — trigger 0, sited off screen along her heading, no tip — to the **front** of the
director's queue. The probe that set the number (`tests/probes/m96_dog_sprinkle.gd`) found the
bug first: appended, the roll was met zero times in 88 sampled days, because a busy day's own
ahead-of-player pool queues dozens and drains a handful, so an appended item sat at index thirty
and beyond. Measured over eight seeds, days 4 to 14: 0.15 gives a mean of 1.0 sprinkled dogs a
run, 0.25 a mean of 1.75 (0 to 3), kept as *a few per run* reading nearer two than one. The
lead-time floor playtest 20 measured is held for the sprinkle by the same siting branch day 3
uses, with the row's own notice and speed untouched.

**Open to overturn.** The 130px band rather than one proportional to the robber's; push-to-front
rather than a randomised later slot; and a capture gap — `--spawn event:<id>` stands her at 0.6
of the outer radius, inside this row's own stand-off, so no rig can photograph the silent wait
and the test is the proof.
