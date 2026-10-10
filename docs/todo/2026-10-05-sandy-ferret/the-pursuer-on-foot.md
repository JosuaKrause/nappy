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
what is true. The README has the proposals. **His catch ends the day**, as the robber's does: asked whether it
ends the day or costs calm and ends the chase, the player chose "Ends the day (Recommended)"
([merry-stork](../../playtests/2026-10-10-merry-stork.md)).

**The investigating police car gets out, too.** On a hot run a patrol stops patrolling and comes
over to investigate her; built in [sunny-finch](../../decisions/2026-10-07-sunny-finch.md), it
drives up to her and stops against her. The player (merry-stork): "an investigating police car
should not leave the street. it should stop if close to her and a policeman should emerge and
pursue her". So the investigating car stays on the carriageway, stops once it is close to her, and
the same pursuer on foot (a policeman, a guardsman from day 9) gets out of it and pursues her, his
catch ending the day as above. *Read as, open to correction:* "close" is the distance at which the
car today stops coming over, and the policeman owes the pursuit contract the robber does from the
moment he gets out (in view, so the badge is not the off-screen one).

[azure-koala](../../playtests/2026-10-07-azure-koala.md), finding 7, re-reports a chasing police
car moving like a person and asks for the police sprite. Reproduce the triggering pursuit before
assuming it is the poster's: cover other police pursuit paths affected by that report, or give
them an explicit owner. Ordinary driving patrols stay vehicles, as the README proposes. The catch is answered above.
