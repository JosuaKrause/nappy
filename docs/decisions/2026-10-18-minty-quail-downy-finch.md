# minty-quail — The end remeasure's timings (minty-quail, R3) · 2026-11-25

The timings of minty-quail's end remeasure, taken as pairs of worktrees run at the same moment on an idle machine; every
reading, its rounds and its spread are in `docs/evidence/minty-quail-end-timings-2026-11-25/` (its README). Head is
fc29914e60afd85bb216bd5e9307b00a3b66218a (main with calm-hare, #1742). The befores: after-4b b3693bee7, pre-3a 202f964ec,
v0.29.0 6985ac74f, the tawny-swan merge 75ef3ad57, the polite-newt merge cf0f9db72 and the calm-egret merge d22a78e15.

**The bar for "entry: yes" is the planner's proposal, open to the orchestrator's correction** (the player set none):
head is slower than its before in every side-by-side round, beyond both trees' own spread, and by more than a tenth of the
system's tick. Under it, "no" means within what the player accepted for now (inbox #1278 in olive-ferret; minty-dolphin #852).
No figure here is judged better or worse than another beyond that bar.

## What was measured (rounds 1 to 3 unless said; µs unless said)

- **Dawn planning** (beside after-4b): build_day 42.8 to 47.9 s against 42.9 to 47.5; draw_every_unit 329 to 366 against 331
  to 369; the whole probe 513.6, 549.7, 570.9 against 499.1, 535.8, 556.3 (head 14 to 15 s above in every round, 2.7%; its copy
  also plans closures, wall, seals and builds a city node per city, which the after-4b copy does not).
- **Crowd tick** (beside v0.29.0): head 2374 to 2398; v0.29.0 1672 to 1695 (agents column plus tick column). The baseline's
  after-4b reading was 2351 (2341 to 2481, not at the same moment).
- **Frame profile** (beside after-4b): callback interval profiled 4.10 to 4.64 against 4.15 to 4.96, profiler off 6.81 to 7.44
  against 6.75 to 7.26. Beside v0.29.0: profiled 4.08 to 4.59 against 8.41 to 8.50, off 6.67 to 7.49 against 8.55 to 8.57. The
  unmodified launcher is still rejected by the analyzer (8.1 and 8.3 ms intervals).
- **Frames that carry the physics tick** (the physics runs at 30 Hz, one frame in four carries a tick), profiler off: head
  16.9 to 17.2 ms against 9.9 to 10.0 on v0.29.0 (17.4 and below on after-4b); the other three frames in four 5.4 to 5.5 ms
  against 7.8; the mean of the ten longest frames 21.5 to 22.4 ms against 11.3 to 11.4 (after-4b 21.6 to 22.9); the longest frame 29
  to 32 ms against 12.5 or less.
- **Streaming** (split mode's stream column): head 289.1, 293.2, 289.1 beside pre-3a 208.7, 210.6, 208.3 (about +80 µs, +39%);
  head 272.2, 269.8, 271.0 beside v0.29.0 106.6, 105.9, 105.9 (about +165 µs). Per plan: 988 ns against 714 beside pre-3a; 924
  against 285 beside v0.29.0, a day holding 292.9 plans on head and 371.7 on v0.29.0. The whole mode's events step: head 988 beside
  pre-3a 678, head 928 beside v0.29.0 333.
- **The owed interface readings** (calm-egret merge over tawny-swan merge, four rounds): the events' whole step 1.052 to 1.067,
  the baby's sweep 0.974 to 1.000, XF_COST 1.014 to 1.029, the fields layer's cold whole map 1.007 to 1.079, and the control
  (crowd tick) 1.049 to 1.058; LK_COST, calm-egret merge over polite-newt merge: 1.044, 1.028, 1.001, 1.001. The span holds other
  tracks' merges; nothing is judged. Three rounds started at a one-minute load of 4 or more (the pair's own earlier load) and are
  kept, labelled in the README.
- **Day 13's roadblock from real chalk marks** (head alone): 480 marks, found 421 (median 422 px), swapped 58 (median 1,092 px),
  missed 1; the swap's frame costs median 96.1 ms (max 180.8), of which the whole-city walk median 36.4 ms (max 48.8); a found
  roadblock's frame median 48.8 ms (max 384.1).

## Entry: yes or no

- **The crowd tick: yes, by the proposed bar.** Head is slower than v0.29.0 in all three rounds (2374 to 2398 against 1672 to
  1695, no overlap), by about 700 µs, 29% of head's tick. Against after-4b it has not moved (2351 against 2374 to 2398, within the
  baseline's own spread), so the cost was added before row 4b; the whole refactor's cost, mover base and lane interface
  included, is larger than the 4.5% minty-quail-16 measured for the mover base. Where a phone shows it is polite-plover's
  (attribute the remaining slow frames before another optimization); a headless debug build overstates GDScript call costs
  (minty-quail-brisk-lark) and no release build is measured.
- **Streaming's lookup: no against pre-3a, by the bar; yes against v0.29.0.** Row 3a's plan questions and the state table cost
  about 80 µs a tick (the records said 60 plus 25 to 50), 8% of head's events step (988 µs), under a tenth, so a cheaper lookup
  is not an entry by the bar. Against v0.29.0 the difference is 165 µs, 18% of the events' step, over the bar, but it holds the
  whole refactor and a placement that holds fewer plans; the orchestrator reads which comparison the README's question meant.
- **The frames that carry the tick: yes, by the bar, if the orchestrator reads a frame as the system.** Their mean is 17 ms
  against 10 on v0.29.0 and the ten longest frames average 22 ms against 11, in every round, beyond spread; the other frames
  are faster (5.5 against 7.8 ms), so the mean frame is not slower (callback interval profiler off 6.8 to 7.4 against 8.6). The
  rise from 10.1 to 21.5 that #1732's record lists is reproduced here (11.3 to 22.4 for the ten longest frames) and was already
  present at after-4b, so the events and the crowd stepping on the 30 Hz tick are the cause, not a later step. Whether a frame
  that long shows on a phone is what polite-plover's frame record decides.
- **Dawn planning, the frame profile's mean and the interface readings: no**, within spread or under a tenth of their system.

## Moved on purpose, and moved unexplained

On purpose, by the records that name them: the crowd and events on the 30 Hz tick (minty-quail-21, -33) for the tick frames;
the mover base and lanes (minty-quail-16, -brisk-lark) for the crowd tick; row 3a's plan questions (minty-quail-cozy-stork) for
streaming. Unexplained: the whole mode's events step 333 to 928 µs against v0.29.0 (head's tick-carrying frame holds it) and
the 14 s the head dawn copy's whole probe sits above after-4b's, which the copy's extra planning accounts for in kind, not in size.

## Defects, and what was not measured

No defect found: every probe ran, the one failing check (the split step against the whole step, 3 of 36 cases beside pre-3a and
head alike, 6 in T5's runs) is the known failure of the probe (lilac-pelican's item) and is on both trees. The unmodified
launcher stays rejected. Not measured: a release build, the phone.

Evidence footprint: see the pull request.
