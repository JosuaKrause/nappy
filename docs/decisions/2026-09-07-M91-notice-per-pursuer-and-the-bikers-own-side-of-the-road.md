## M91 — Notice, per pursuer, and the biker's own side of the road · built 2026-09-07

Three findings from [PLAYTEST-34.md](../playtests/PLAYTEST-34.md), and the headline is that **one rule was wrong
at both ends at once**: M87 gave every approaching row the same `OFFSCREEN_NOTICE` (0.2s of closing
on top of the ray to the edge of the view), and the player asked for two rows to move in **opposite**
directions on the same day. *(2026-09-07: "pursuing dog is still too short notice while biker is now
too long notice.")* So notice became per-row — `EventDef.offscreen_notice`, defaulting to the old
shared constant.

| row | field | was | now |
|---|---|---|---|
| `charging_dog` | `offscreen_notice` | 0.2s | **0.5s** |
| `charging_dog` | `telegraph_time` | 2.4s | **4.5s** |
| `cyclist` | `telegraph_time` | 3.3s | **2.0s** |
| `cyclist` | `outer_radius` | 145px | **90px** |

**Two of those four are consequences rather than choices, and both are the kind of thing that gets
"fixed" back by somebody who does not know why.**

**The dog's telegraph had to nearly double.** Siting it further out gives a player who only walks
more ground to retreat across before the row's own budget runs out, and `tests/test_events.gd`'s
*"walking away is not enough"* went red. **Raising `duration` was tried and reverted**: the suite
holds every pursuer's duration to `Tuning.PURSUIT_TIME` exactly, tighter than `validate_pursuit`'s
own 2x ceiling, so that lever does not exist. Closing the worst-case gap at 38px/s
(`pursue_speed - WALK_SPEED`) takes about 7.0s, inside the 7.5s the new `telegraph_time + duration`
allows.

**That leaves half a second of margin, and it was put to the player rather than quietly accepted.**
*(2026-09-07: "getting lucky once is fine.")* On the worst siting geometry a walking player could
outlast the clock rather than being caught. Recorded so a later report of *"the dog gave up and I
never ran"* is recognised as this rather than investigated as a new defect — and see
[PLAYTEST-35.md](../playtests/PLAYTEST-35.md) for the full answer to *does the dog ever give up while she walks*:
the give-up condition is 0.35s of the gap **opening**, which only a run can produce.

**The biker's field had to shrink to let its telegraph shrink.** `telegraph_time` is tied to
`outer_radius` by a fixed `hard_fail` margin (`outer_radius * TELEGRAPH_HARD_FAIL_MARGIN /
WALK_SPEED`), and 3.3s was already only 0.15s above the floor for a 145px field — there was no room
to shorten the telegraph alone. **This is an explicit overturn of M87's own recorded rejection**,
which refused to shorten this telegraph because doing so *"buys the lethality back by taking the
notice away"*; the complaint has flipped for this row and the player flipped it. The cyclist's
walk-through cost falls from +30.2 to +20.9 and its row moves up `docs/EVENTS.md`'s cost table.

**The lethality defect did not come back.** `EventInstance.is_lethal_at()` still refuses for the
whole telegraph and the telegraph term still binds the siting, so the arrival lands after the
telegraph ends — the failure playtest 33 finding 11 named.

**The biker's side of the road was a lead problem, not a placement one.** *(2026-09-07: "also biker
should be on the same side of the road not the other side".)* `placement` was already
`[SIDEWALK, SQUARE]`; the row was sited hundreds of pixels out along her **literal** heading, and a
heading only slightly off the corridor axis drifts across a six-tile street long before that lead
ends — a diagonal on the touch controls is enough. `EventDirector._onto_her_side()` straightens the
siting heading onto the corridor's own axis first, using `CityMap.pavement_inward()`'s axis-aligned
normal. **A preference and not a requirement, deliberately**: off a plain sidewalk edge, or walking
straight across the street, the literal heading is used exactly as before, because a `TOWARD_PLAYER`
row that cannot be sited is an encounter that silently does not happen.
