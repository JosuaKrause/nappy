# The route siting says it offers a row's own ground, not only building faces

**Low · found answering the player in [mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md)
(inbox #650).** Asked how a man shouting can be unplaceable, the session answered that he needs "a
building face on the stretch of the day's route ahead of her", and the player asked "why?". He does
not: `EventScheduler.WalkSiting._faces_on()` offers every tile of the row's own ground pool
(`_ground_as_a_set(def)`, a sidewalk for the man shouting, a mast site for a mast) on the route's
cells ahead of her, between the streaming band and the far window. It is a building face only for
day 3's fire and the poster crews, the rows the siting was first written for. The wording that
misled the answer says otherwise in several places: the `_waited("no building face on the branch
ahead of her")` and `"every face on her branch broke a placement rule"` log reasons and the doc
comment of `ahead_of()` in `src/events/event_scheduler.gd`, the comments at the top of
`src/events/event_director.gd` and above `site_what_is_on_her_way()` and its refusal, the
`sited_on_her_way` comment in `src/events/event_def.gd`, and `docs/EVENTS.md`'s paragraphs on the
on-her-way siting and its set-piece row. Say "a tile of the row's own ground" (a building face for
the fire and the crews), and rename `_faces_on()` to match; no test or tool pins the log reasons' text.

So a place marble is unplaceable when she is off the day's routes, or when the branch ahead has no
tile of the row's ground past the streaming band that passes the placement rules, which happens near
a branch's end, close to home.
