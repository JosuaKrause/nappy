## M77 — Everything arrives from off screen · built 2026-09-07

Opened from playtest 19 *(2026-09-02: "the charging dog doesn't have an offscreen indication it
should start further away and appear first as offscreen indicator", and "bikers / unleashed dogs all
pop in in front of the player instead of starting off screen")* and raised to the front of the queue
by playtest 33, which added the 200ms figure, the biker's lethality and the day-3 dog's overturn.

**The cause was one constant sized for one axis and used on both.** `Tuning.SIGHT_AHEAD` was 200px
flat, and its own comment called it *"the furthest ahead of her something may be sited and still be
on screen when it gets there"* — sized for the vertical, where the visible world is 180px from her
to the edge at zoom 2 over a 1280x720 viewport. Sideways the boundary is 320px, so anything the
director sited while she walked east or west appeared 120px **inside** the view. That is the whole of
*"pop in in front of the player"*: on one axis the flat number was a floor and on the other it was a
ceiling.

**So the siting became a function of the heading rather than a number.**
`Tuning.offscreen_boundary(heading)` is a ray to the edge of a `VIEW_HALF_EXTENT` box of
`(320, 180)` — the same arithmetic `DangerEdge` already draws the screen-edge badge with — and
`offscreen_lead(heading, closing_speed)` adds `OFFSCREEN_NOTICE` (0.2s) of closing on top of it.
**`closing_speed` is the row's own speed plus `WALK_SPEED` (92px/s), not the row's speed alone**,
because she is usually walking into it: `cyclist` at 165px/s closes at 257 and buys 51px with its
200ms; `charging_dog` pursuing at 130px/s closes at 222 and buys 44px. The unit asked for was time
and the pixels are what it costs per row.

**A crossing row was deliberately left alone.** `cat_dash` and `pigeon_flock` keep
`AHEAD_LEAD_DISTANCE` — a crossing's whole content is a three-second interruption reacted to as it
happens, not an approach watched closing, so there is no closing speed for the margin to be stated
over. *Chosen as the smaller reading of a silence*: the instruction named "events that go towards
the player", and a crossing already pays its fairness in the reaction-window rule instead.

**The badge had to follow the siting or the change would have removed warning rather than added
it.** `DangerEdge._is_worth_an_arrow` refused every `AHEAD_OF_PLAYER` row outright, on the good
reasoning that announcing a three-second cat from the screen edge spends the moment that *is* the
row. A pursuer carries the same spawn mode and is now sited outside the view, so it is exactly what
the badge exists for while it is out there; the refusal became `AHEAD_OF_PLAYER and not pursues`.
`tests/test_danger.gd` checks both halves — the dog earns an arrow, the cat still does not.

**The day-3 dog's unavoidability was overturned by the player rather than traded away here.**
*Asked for a close, unavoidable teaching dog · overturned to a further one on 2026-09-07, because
"the run tutorial spawns inside the visible area making the headsup way too short now (tap controls
are slower than awsd and arrows)".* The dog moved out with everything else. **Whether the lesson
still lands, and where unavoidability comes from now that it is not siting, is open and deliberately
not answered by the siting code.**

**The biker's declared lethality was never able to fire, and the fix is the siting rather than the
telegraph.** `_cyclist()` carries `hard_fail = true` and a 33px `inner_radius`, but
`EventInstance.is_lethal_at()` returns false for the whole of `is_telegraphing()` and the cyclist's
`telegraph_time` is 3.3s — sited at 200px and closing at 257px/s it arrived in 0.78s and rode
through her, declared lethal and refused every frame. `Tuning.outlasting_telegraph_lead()` takes
whichever is further: the ordinary offscreen margin, or `(telegraph_time + OFFSCREEN_NOTICE) *
closing_speed`, which for the cyclist is 900px against a 371px offscreen margin — the telegraph is
the binding term. **Shortening the telegraph was the other way to make the arithmetic work and was
rejected**: it buys the lethality back by taking the notice away, which is the complaint the rest of
the milestone is about.

**Two checks that used to compare against `SIGHT_AHEAD` now ask for a worst case rather than a
heading.** `EventDef.validate()` refuses a `TOWARD_PLAYER` row whose `outer_radius` reaches
`Tuning.min_offscreen_lead(speed + WALK_SPEED)`, and `tests/test_events.gd` measures a pursuit
against the same floor — `min_offscreen_boundary()` is the vertical axis, 180px, the least the
director can ever site at. A validation-time check has no heading to ask about, so asking about a
generous one would pass a row on an encounter the game can still produce on a worse one.
