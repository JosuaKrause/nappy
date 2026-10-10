**A torn poster's pursuit marble sends a pursuer on foot at once, spawned off screen already
pursuing.** In place of `EventDirector.send_a_patrol()`'s police car, sited after a second of walking
along a street with a road route toward her, the marble sends a pursuer on foot the moment it is
drawn: a policeman through day 8 (the drawing merged in PR #594, `art/events/policeman_*`), a
guardsman from day 9 (the checkpoint guard's drawing). He is never placed by the event scheduler
and never joins the day's queue: "the pursuer is not a scheduled event. it is instant!" He is
warned and placed as M226 warns and places a sent robber (a 0.5s badge, then off screen already
pursuing, no closing in), and he comes into view already pursuing, never walking up to her first.

The tears' bag stays its own bag, and nothing crosses between it and the event bags: a tear draws
no event marble and moves no event's turn, and an event draws no tear marble ("nothing influences
across them"). Walking does not end his chase within the 30s `PURSUIT_TIME` cap M226 set for every
pursuer ("pursuers should never (or a long time) stop pursuing if she walks"), so running is the
way out.

Tests: a pursuit marble creates the pursuer at once, off screen, pursuing, with no wait for a
heading or a street; day 8 sends a policeman and day 9 a guardsman; a tear and its pursuer change
nothing the day's event bags draw; walking away does not end his chase before the cap. `docs/MECHANICS.md` (the tears'
pursuit), `docs/EVENTS.md` (the tear's patrol), `docs/GRAPHICS.md` (the policeman bound, no longer
only prepared) and `docs/TELEMETRY.md` (the counter's `poster-pursuit`, one per pursuer sent) say
what is true. The README has the proposals, and one question is open for whoever picks it up:
**whether his catch ends the day**, as the robber's does, or costs her something less; the police
car it replaces cannot end the day. The filer would pick ending the day, since "a proper pursuer"
reads as one like the robber, whose drawing his mirrors.

[azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 7, re-reports a chasing police
car moving like a person and asks for the police sprite. Reproduce the triggering pursuit before
assuming it is the poster's: cover other police pursuit paths affected by that report, or give
them an explicit owner. Ordinary driving patrols stay vehicles, as the README proposes. The observation that the car
is not lethal leaves the catch question above open; ask it before implementing a consequence.
