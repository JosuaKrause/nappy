priority: now

# sandy-ferret — A torn poster's pursuit is instant, on foot · filed 2026-10-05

[olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md) files inbox #591, said in a session
on 2026-10-05. Told why no tear pursuit had been met in play (a pursuit marble sends a
`police_patrol`, a police car, down the carriageway toward her, placed only once she walks on along
a street with a road route toward her, retrying every second) and asked whether a police car reads
as a pursuit:

> the poster pursuit should not be placed! it should happen instantly with the pursuer spawning off-screen! and it should be a proper pursuer not a police car -- maybe a policeman on foot?  (we will need a graphic for that anyway for the polic robber chase later) and a guardsman once they are in the city (earlier a guardsman won't make much sense)

Told the plan (a pursuit marble sends a pursuer on foot from off screen at once, once M226's
off-screen warning rework had landed) and asked whether the guardsman replaces the policeman from day 9
(guards first at the checkpoints) or from day 13 (the army arrives):

> the poster tear marble bag is a completely separate marble bag than the event marbles. nothing influences across them. the pursuer is not a scheduled event. it is instant! policemen get switched to guardman on day 9.

On pursuers generally, about PR #597 (M226, one-second off-screen warnings; inbox #598 in [olive-hedgehog](../../playtests/2026-10-05-olive-hedgehog.md)):

> pursuers should never (or a long time)  stop pursuing if she walks -- that will make it impossible to walk away.

And on the band, of this entry with jolly-hare (the fire truck lethal driving and solid parked),
pebbly-ibis (the pelican from one shared bag per run) and olive-badger's forced cases:

> queue those items as immediately now after the release (but don't start them this session)

**Asked for:**

- **Instant, never placed.** A pursuit marble sends the pursuer at once, spawned off screen; "the
  pursuer is not a scheduled event. it is instant!"
- **A pursuer on foot, not a police car**: a policeman through day 8, a guardsman from day 9
  ("policemen get switched to guardman on day 9").
- **The tears' bag is its own.** "the poster tear marble bag is a completely separate marble bag
  than the event marbles. nothing influences across them."
- **A walk does not escape him**: "pursuers should never (or a long time) stop pursuing if she
  walks". M226 built this for every pursuer: `Tuning.PURSUIT_TIME` is a 30s cap, so walking does not
  end a chase early and running still shakes him off.
- **The band `now`, for right after the release**, and not started in the session it was said in.

**What it replaces.** `PosterWalls._tear()` draws the tears' marble and, on a pursuit marble, calls
`EventManager.send_a_patrol()`, which hands it to `EventDirector.send_a_patrol()`: a `police_patrol`
sent toward her down the carriageway lane driving toward her, sited only after
`EventDirector.TEAR_PATROL_AFTER` (1.0s) of walking and then only once a street with a road route
toward her is found, outside the day's own queue (it takes no turn in it and touches no stream).
`docs/MECHANICS.md` describes it ("A pursuit marble sends a `police_patrol` toward her from off
screen"). The tears' bag itself (`PosterWalls.TEAR_PRE_BAG`, `TEAR_BAG`, one pursuit in ten after a
safe first tear, its state `PosterState.tears`) is not changed by this entry.

The record that built the police car is [M180, seen, walled and torn](../../decisions/2026-09-23-M180-posters-she-notices-and-loudspeakers-that-are-somewhere-seen-walled-and.md) (posters
she notices, and loudspeakers that are somewhere), which this entry replaces in part: "A pursuit
marble sends a heated `police_patrol` `TOWARD_PLAYER` down the carriageway toward her ... waiting
`EventDirector.TEAR_PATROL_AFTER` (1s of her walking) so she has turned from the wall, and at most
one waits at a time; nothing is sent during the escape or under `--force`." The pursuer on foot
replaces the patrol and the 1s wait; "at most one" and nothing during the escape are kept, under
**Proposed, not asked for** below. [M225](../../decisions/2026-09-26-M225.md) (the counter counts
every attempt, a key player, and a torn poster's chase) built the counter's own event for it: "A
torn poster that sends a patrol sends its own event, `nappy-day-N-poster-pursuit`, beside
`poster-torn`, when the patrol is sent; a second tear while a patrol is on its way sends none." With
the pursuer sent at once, "sent" becomes the moment the marble is drawn, and the event goes out then.

**What exists to build on.** The policeman's drawing, merged in PR #594 and recorded in
[tiny-beaver](../../decisions/2026-10-05-tiny-beaver.md) (a policeman on foot, drawn for the pursuits
to come): `art/events/policeman_*`, the robber's set one for one (waiting and lunging in five views,
a stride frame each), so the runtime can drive him the way it drives the robber; no catalogue row
or atlas line yet, and `docs/GRAPHICS.md` lists him as prepared. The player judged him: "policeman
looks good". The guardsman is the checkpoint guard's drawing, `art/checkpoints/guard_*`.
[M226](../../decisions/2026-09-26-M226.md) (every off-screen warning is a short badge, then the
thing spawns off screen, PR #597) built how a sent pursuer arrives: `robber_giving_chase` and
`van_guard_giving_chase` "spawn off screen already pursuing after their 0.5s badge, with no closing
in (`telegraph_time = 0`)", and no pursuer gives up on a walker within the 30s `PURSUIT_TIME` cap.

The one item is [the-pursuer-on-foot.md](the-pursuer-on-foot.md).

**Re-report from playing:** [azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 7,
files inbox #601 in the same `now` band:

> police cars chasing the player behave like running people (instead of... cars) but are at least no lethal. pursuing police should rather use the police sprite instead

The on-foot replacement is owned here rather than by a second design. The new report says
police pursuits generally, not specifically a torn poster: identify the triggering pursuit at
pickup and cover any additional affected police pursuit, or record its separate owner explicitly.
"at least no lethal" describes the car in the report; the catch consequence remains the open
question in the item, not an agreed lethal replacement.

**Proposed, not asked for:**

- **The pursuer arrives as M226's sent robber does**: a 0.5s badge starting at the tear, then he
  spawns off screen already pursuing, with no closing in, and the 30s `PURSUIT_TIME` cap. "Instant"
  is read as no wait for a heading or a street, not as no badge at all. The alternative is no badge,
  which the cues rule's warning for something lethal coming toward her would have to exempt.
- **A second pursuit marble while he is still after her sends nobody more**, as a second marble
  before the patrol arrives does today.
- **During the escape nothing is sent**, as today.
- **Ordinary driving patrols stay vehicles**; only a pursuit becomes a pursuer on foot.
