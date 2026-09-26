## M93 — The caret is chosen by expected impact · built 2026-09-09

Playtest 37's finding 5 — *"carets shouldn't be chosen by source value but by expected impact
value"* — built by an agent on `feature/caret-by-expected-impact` from the entry below, six items
in six commits plus two review fixes.

**What decides a caret now.** `Tuning.MARK_WORTH_A_DETOUR` (25, a row's own static cost) is gone.
`Tuning.EXPECTED_IMPACT_POINTS` (`METER_MAX * 0.4`, 40) and `Tuning.EXPECTED_IMPACT_HORIZON` (5s)
are the one number and one horizon the halo and the caret both read; `ExcitementHalo.WINDOW` is
the horizon read backward rather than a constant of its own, and its `SATURATES_AT_POINTS` is the
shared line. `EventInstance.expected_impact_at()` and `CrowdAgent.expected_impact_at()` project
the source's own velocity in quarter-second steps over the horizon, sample its field at her fixed
position at each step, sum, and subtract its present rate times the horizon — implemented by
translating the *query point* by `-velocity * t` so `contribution_at()` is reused unchanged for
falloffs, flocks and jolts. Anything whose reach (speed × horizon + outer radius) cannot touch her
is skipped without sampling. `will_be_lethal()` on both classes asks the lethal geometry at each
step: a `hard_fail` row's `inner_radius`, a car's strike box. `_caret_strength()` on both classes
answers 0, 1 or 2 once per frame, keyed on the entity's own clock, and `wants_a_mark()`,
`mark_colour()` and the drawing read it. A car's honk is a consequence rather than the rule:
`_draw_horn_mark()` became `_draw_mark()`, marking a car in either strength whether or not it has
honked, breathing with the horn's decay while one runs and holding full size otherwise.

**The review found the red caret could not exist during a telegraph, and three gaps fed it.**
`will_be_lethal()` reused `is_lethal_at()`, which refuses for the whole of `is_telegraphing()`;
`travel_velocity()` is zero for a pursuer while it telegraphs, so a noticed `charging_dog` at its
stand-off projected nowhere; and `current_intensity()` is damped to `TELEGRAPH_INTENSITY_FRACTION`
(15%) for the whole telegraph, so amber under-projected by 85%. The fix: `will_be_lethal()` inlines
the geometry with the telegraph gate dropped (finished, leaving and waiting still refuse);
`_caret_velocity()` heads a noticed pursuer at her at `pursue_speed` whether or not it is still
telegraphing, and otherwise answers `travel_velocity()`; `_caret_intensity()` divides the damping
back out for the projection's future samples while the subtracted present rate stays the real,
damped one, through an `intensity_override` on `contribution_at()`. The exclamation mark's own
reading of `travel_velocity()` is untouched. `tests/test_danger.gd` holds the scenarios: a
telegraphing cyclist on her line is red and still flashes, a noticed telegraphing dog is red, a
waiting robber in an alley she is not in is unmarked.

**Measured on the arterial.** A rig standing at `CrowdLanes.arterial_pavement()` through forty
simulated seconds of the real crowd, every agent polled every step: zero amber-caret frames. The
capture is `docs/evidence/shot-2026-09-09-seed4242-69c97bd-arterial-standing-no-caret.png` —
walkers glow with their own halo, none carries a caret. A walker cannot clear the line alone
(`4.2/s × 5s = 21 < 40`), and `CrowdAgent` draws a caret only for a car.

**Choices made where the entry was silent, each open to overturn.** `set_player_at()` joins the
halo's duck type and is called on every candidate every frame, because `Crowd` hands an agent the
player's position only when it is a car near a road. `will_be_lethal()` landed with the projection
rather than with the strengths, since the two share one loop. The scenario tests replace the
catalogue-wide monotonicity check outright, since a mark is no longer a property of a row. And
`docs/EVENTS.md`'s cost table lost its `mark` column at the merge review: the dots encoded the old
rule and no code reads them, and a column that is not a rule is a stale sentence in table form.

**What only a walk settles.** Whether an amber caret that comes and goes with a thing's course
reads as *stand here and this will cost you* or as flicker; whether the red caret's flash through a
cyclist's whole 3.3s approach reads as warning or as alarm. The vocabulary's four sentences are in
`docs/EVENTS.md` under "The visual vocabulary" and in the cues skill.

### The entry as it stood when it was built

[PLAYTEST-37.md](../playtests/PLAYTEST-37.md) finding 5, in three sentences: *"caret == lethal is good but is
inconsistently applied at the moment"*, *"a cat has a caret but it's benign"*, *"a pedestrian
without caret has a greater impact than a cat"* — and the instruction: **"carets shouldn't be
chosen by source value but by expected impact value."**

**What decides the amber caret today is a source value.** `EventInstance.wants_a_mark()` marks a
row when `EventDef.walk_through_cost()` — the points a straight walk through the field at walking
speed would cost, derived from the def's intensity, radii and speed — reaches
`Tuning.MARK_WORTH_A_DETOUR` (25, a quarter of the bar). It is the same answer for every instance
of the row, wherever it stands and whichever way she walks, and the crowd is outside it entirely:
`cat_dash` is marked, the pedestrians who cost more over a pavement never are. The invariant
`tests/test_danger.gd` holds — *if A is marked and B is not, A costs more to walk through than B* —
is true only because it is stated over the catalogue alone.

**Expected impact is the halo's quantity turned forward, measured with her held still.** The halo
(M92) is the points a source actually landed on the meter over the last five seconds; the caret
becomes the points a source *will* land over the horizon **if she does nothing** — the thing's own
motion and field projected onto where she stands, the same field the meter is fed from. That
direction is the player's: *(2026-09-08: "I don't want a caret when walking into a car from the
side".)* It is already the screen-edge badge's rule and the cues skill's sentence — *measure the
thing, not the gap; a rate that includes her 92px/s is a cue for walking* — arriving at the caret.
A car bearing down on her marks; a car she steps into from the side does not, since held still she
is never in its path. A cat whose dash lands less than the line on a standing player is not marked,
whatever its row says; a knot of walkers coming at her is, if what they will land clears it. **And
a stationary thing never earns a caret** — held still, a café does nothing to her — which is the
halo's job from the moment she is in its field.

**The doubled red caret keeps its meaning — lethal — and gets the same rule.** *(2026-09-08: "we
can keep the double red == lethal", then "and not all lethal things need a caret either".)* So it
is one sentence in two strengths, both measured with her held still over the horizon: **amber** if
the thing's own approach will cost her at or above the line, **doubled red** if it will end the
day — her position inside a car's strike or a `hard_fail` row's lethal radius on its current
course. Nothing otherwise. A robber waiting in an alley she is not in carries no mark until he
stands up and comes; a car marks while she stands in its lane, which is exactly when it honks, so
`CrowdAgent._draw_horn_mark()`'s rule becomes a consequence rather than the definition; the
cyclist marks when its line reaches her; and a car she steps into from the side carries none
*(2026-09-08: "I don't want a caret when walking into a car from the side")*.

**The amber caret stays.** *(2026-09-08: "amber one is fine as long as it represents a meaningful
thing".)* What changes is only what decides it.

**And the vocabulary is restated as one language.** *(2026-09-08: "but then we need to create a
consistent language around the other carets too".)* Each row of `docs/EVENTS.md`'s "The visual
vocabulary" and the cues skill becomes one sentence decided by one quantity — caret: *stand here
and this will cost you*, or *end your day*; halo: *this is costing you now, and this much*;
exclamation over her: *the clock on you has started*; badge: *something lethal or fast is coming,
and this is what* — with **one number** (the amber line and the halo's red are the same points, so
an amount means the same thing whether it already landed or is about to) and **one direction**
(everything about a thing is measured with her held still, so nothing is a cue for walking). That
rewrite is this milestone's first item.

**The two numbers are the halo's, confirmed.** *(2026-09-08, on a five-second horizon and a line at
40 of the 100-point meter: "both sound good to me".)* So one horizon and one line serve past and
future alike: the halo is red at 40 points landed over the last five seconds, the caret is amber at
40 points expected over the next five. A cat's dash on a standing player lands about 30 and is not
marked; a café she is standing in is the halo's, not the caret's. The one thing the line must not
do is mark the ordinary crowd at ordinary density, which is a measurement on the arterial rather
than an argument, and is the last item.

- [ ] **One number and one horizon, shared.** `Tuning.MARK_WORTH_A_DETOUR` (25, derived per row)
      is replaced by a single pair the halo and the caret both read — the line at
      `METER_MAX * 0.4` and the horizon at five seconds — living in `Tuning` rather than on
      `ExcitementHalo`, where M92 first put the saturation. Their docs carry the player's sentences
      above.
- [ ] **Expected impact, per source, with her held still.** A method on both `EventInstance` and
      `CrowdAgent` — the same duck type the halo reads — answering the points this thing's own
      motion and field will land on her current position over the horizon **beyond what it lands
      now**: the source's velocity extrapolated in steps of a quarter second, its field sampled at
      her position at each step, summed, less its present rate times the horizon. A stationary
      thing she is inside therefore expects nothing (the halo has it); an approaching thing expects
      its approach; a departing thing expects less than nothing and is unmarked. Sources whose
      reach cannot touch her inside the horizon — further than speed × horizon plus their outer
      radius — are skipped without sampling, which is what keeps two hundred walkers cheap. A
      pursuer that has noticed her is heading for her and is projected as such; one still waiting
      has no velocity.
- [ ] **The two carets are that quantity in two strengths.** `EventInstance.wants_a_mark()` and a
      `CrowdAgent` equivalent: **doubled deep red** when a step of the projection puts her inside
      the thing's lethal reach — a `hard_fail` row's `inner_radius`, a car's strike box — on its
      current course; **amber** when the expected points reach the line; nothing otherwise. The
      honk stops being the car's rule and becomes a consequence (a car whose lane she stands in
      is projected into her). The flash while telegraphing is kept as the phase. `mark_colour()`
      follows the strength, not the row.
- [ ] **The vocabulary is restated as one language**, in `docs/EVENTS.md`'s "The visual vocabulary"
      and `.claude/skills/cues/SKILL.md`: caret *stand here and this will cost you* / *end your
      day*; halo *this is costing you now, and this much*; exclamation *the clock on you has
      started*; badge *something lethal or fast is coming, and this is what*. One number, one
      direction; nothing is a cue for walking.
- [ ] **`tests/test_danger.gd` states the new invariant.** The catalogue-wide monotonicity check
      goes, since a mark is no longer a property of a row; in its place, scenarios: a café she
      stands in is unmarked; a cat dashing at her is unmarked; a cyclist whose line reaches her is
      red and one passing wide is not; a car she stands in front of is red and one she would have
      to step into is not; a walker brushing past is unmarked. The pram, the exclamation mark and
      the badge tests are untouched.
- [ ] **Measured on the arterial.** One capture standing on the busy pavement: how many amber
      carets are up. The answer has to be *none at ordinary density*, or the line moves before
      this merges.
