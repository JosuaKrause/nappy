# Playtest feathery-lynx — A shared marble bag for the pelican, the pelican counted apart, the touch corners left out of what she sees, a test leak

2026-10-05. Four notes captured in the session, #575, #577, #581 and #583, each said in a
conversation rather than while playing. Each of the player's words is copied word for word, after
what it answered.

## #575 — A shared marble bag, refilled when empty, for cyclist vs pelican

Said on 2026-10-05, a new idea rather than an answer to a question. What it builds on: the nested
bag that olive-badger (what she meets on her route is drawn from a marble bag, PR #565) built is a
bag marble inside an outer bag, and its inner bag of n is spent once and then gone. The pelican
today is one cyclist in about 400: `EventManager.PELICAN_SHARE`, a flat 1/400 roll for each
cyclist.

> I have an idea of a shared marble bag -- the shared marble bag would contain its own marbles but can appear in regular bags multiple times. each time the shared on is drawn a marble *from* the shared one is drawn. if it's empty it gets refilled (unlike the nested one). we could use it for the biker vs pelican. have one shared biker/pelican marble bag with 399 bikers and 1 pelican and the same bag is used throughout the run. what are the expected stats on this? how likely would it be to encounter a pelican if the same bag is used throughout the run and if each day has its own shared bag for it? and how does it compare to the flat 1/400 chance?

The assistant answered with a table, an estimate that had never been measured, for 20, 30 and 40
cyclists in a run, of the chance of meeting at least one pelican: a flat 1/400 per cyclist 4.9%,
7.2% and 9.5%; one shared bag for the whole run 5.0%, 7.5% and 10.0%; a fresh shared bag every day
about the flat figures. The expected number of pelicans is N/400 in all three (N cyclists in the
run). A bag changes the odds noticeably only if it outlives the run (kept across runs: one pelican
in every 400 cyclists, about every 13 runs) or is smaller (1 in 40). It offered: "If you want, an
agent can measure the real number of cyclists per run so the table is exact rather than an
estimate." "The telemetry for individual events" in the reply is inbox #574, the GoatCounter seen
and influenced events per encounter (spry-llama), then being built for the patch release.

> that would be a good use of the telemetry for individual events ;)

The assistant's comparison went on: one shared bag per run makes the chance of at least one
pelican exactly N/400, and it "can also never give two pelicans in one run. With the flat chance
that happens about 0.3% of the time at N = 30"; otherwise the bag barely changes the odds unless
it outlives the run or is smaller.

> I think being able to get at most one pelican per full run is already a benefit of the approach

The assistant then asked two things: (1) when to build the shared bag, its pick being the batch
after this patch, with the other bag work; (2) a retried or resumed day, its pick being that the
bag is saved with the run and that a retry bought with a nerve rewinds it to its state at the start
of that day. It had said before that a bag matters only if it outlives the run (saved across runs
and retries: one pelican per 400 cyclists, about every 13 runs), and the player had answered that
at most one pelican per full run is already a benefit. The save today is one file,
`user://save.json`, deleted when a run ends (`GameSave.clear()`, called from
`GameState._end_run()`).

> if the bag outlived the run (forcing us to never delete a save but instead reset it for everything except the bag)

The assistant proposed keeping the bag per run (saved with the run, rewound on a retry, gone when
the run ends) rather than a bag that outlives the run in a file of its own, which would cost the
seed's reproducibility and still be lost when the player clears the site's data, and asked:
"Should I file it that way, for the batch after this patch?" With it went a table of the runs it
takes until 50%, 90% and 99% of players have seen a pelican, and the run by which one is
guaranteed, estimated at 30 cyclists a run: a flat 1/400 10, 31 and 62 runs, never guaranteed; one
bag per run 9, 30 and 59, never; a bag per day 10, 31 and 62; a bag kept across runs 7, 12 and 14,
guaranteed by run 14. A measurement of the real number of cyclists in a run was under way on the
marble-bag branch.

> let's do a bag per run but save it in the standard save file to reset the bag to the beginning of the day on a lost day. by how long does it take I meant the expected value of runs until you see at least one pelican do the p50, p90, p99

The measurement it asked for is in
[pelican-cyclists-2026-10-05](../evidence/pelican-cyclists-2026-10-05/README.md): 26.2 cyclists a
run on average over 120 cities, and the expected number of runs until the first pelican 15.8 with
the flat 1/400 and 15.3 with one bag per run.

## #577 — The pelican is counted apart from the cyclist

Said on 2026-10-05, on spry-llama (the counter counts encounters: seen, influenced, bouts of
running), filed from #574 in PR #576. It answers the question that entry had left open, under
**Proposed, not asked for**, since the player had not answered it: whether the GoatCounter seen and
influenced events count a pelican as `pelican`, apart from its row's `cyclist`.

> yes cyclist and pelican are treated separately

Two questions from the player followed, about spry-llama as PR #578 was building it, after the
build had listed its rules: a row whose field excites her counts as influenced once it has landed
10% of a full meter on her; a row whose field does not (playground, fallen_tree, burst_water_main,
skip, scaffolding, construction, barricade and the like) counts only inside its lethal reach or its
hold, or while it chases her, which none of those rows do, so they never send influenced; and there
is no rule for walking around a blocker.

> should we count a pelican as pelican *and* cyclist?
>
> also static things like trees and main water breaks will count as seen but never influenced?

The assistant recommended against the first: "I'd say no, only as `pelican`. Sending both would
double-count it in the cyclist ratio. For the pelican-bag maths, cyclists per run is just
seen-cyclist plus seen-pelican, which the readout can add up."

> counterpoint: a pelican is functionally a bicycle. if we want to measure the rate of anything bicycle we could either add bicycle and pelican up every time or just count pelicans as both. that said we can always add them up later so let's keep it separate for now

On the second, the build had reported that the static rows (fallen_tree, burst_water_main, ...)
are seen but never influenced, and that a pursuer which chases her but lands under 10% of a full
meter is not counted as influenced. The assistant proposed: "Chases and catch distance count for
every event: an event chasing her, or her coming within its catch distance, always counts as
influenced, whatever it adds to her meter. Pure blockers stay seen-only: the readout shows '—' for
their ratio".

> the static things question was meant for telemetry. we need to record seen for them. let's count chases and catches as influenced always.

## #581 — What she can see leaves out the corners under the joystick and the run button, in the joystick mode

Said on 2026-10-05, a new instruction after the build of spry-llama (PR #578) reported its seen
test: an encounter is seen on the first frame 80% of the instance's drawn box is inside the
camera's view. "The other mode" is the control mode without the on-screen joystick and run button
(the tap mode), and the "speed button" is the run button beside each joystick ring. Elsewhere the game's on-screen test, `EventManager._is_on_screen()`, checks only an
instance's centre point against the view's half extent.

> when counting the 80% visibility for seen remove the area at the bottom left and right up to the top of the joystick circle and horizontal extent of the speed button -- use that everywhere where visibility is concerned -- for the other mode those rectangles *do* count

PR #578 then put the visible area in one shared function, `VisibleView.visible_share()`: in the
joystick mode the view minus both bottom corners, each from the screen's side to the far edge of
its run button and from the top of the joystick ring down; in the tap mode the whole view. It used
the function for the telemetry only. The assistant asked: "should the rest of the game switch to
the new visible area in the next batch, alongside M226?", naming what the rest of the game's
visibility is: the off-screen warnings and where things are placed just off screen, when a chalk
mark counts as noticed, and the fire's and the pelican's existing seen events. M226 (the pursuing
dog keeps its day-3 timing, and the other warnings fit it) makes every off-screen warning show the
badge alone for at most a second and then places the thing just off screen.

> if you mean by carving out the bottom rectangles to count as visible. yes, everything should follow this (and treat it depending on the input mode)

## #583 — An order-dependent test leak: four checks fail in a local 4-shard run

Said on 2026-10-05. The assistant had reported an order-dependent test leak already on `main`: a
local full run of the suite in four shards (`./tools/test.sh --shard 4/4`) fails four checks —
`test_frame_record` ("a played frame is kept"), `test_invincible` ("and excitement rises too,
against the same source") and `test_orientation` (its two rotated-touch checks) — each of which
passes when its suite runs alone, so an earlier suite in the same shard leaves state behind. CI's
8-way split never hits it, so `main` stays green. Two agents found it independently, on PRs #565
and #567. It asked: "Should I file it as a queue entry, and in which band? I'd suggest next."

> next

## Routing

1. **#575** → [pebbly-ibis, the pelican is drawn from one shared bag per
   run](../todo/2026-10-05-pebbly-ibis/README.md). Band `now`, the filer's proposal: the player
   said "let's do", and it builds on the marble bag olive-badger has just merged.
2. **#577** → no new entry. It answers spry-llama's open question ([spry-llama, the counter counts
   encounters: seen, influenced, and bouts of running](../todo/2026-10-04-spry-llama/README.md)),
   and PR #578, which builds spry-llama, quotes it in its decision record.
3. **#581** → [dappled-swan, what she can see leaves out the touch-control corners,
   everywhere](../todo/2026-10-05-dappled-swan/README.md). Band `now`, the player's: the note was
   filed with that band, and the player agreed to the next batch, alongside M226.
4. **#583** → [amber-quail, an order-dependent test leak in a 4-shard
   run](../todo/2026-10-05-amber-quail/README.md). Band `next`, the player's own word.
