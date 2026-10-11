# sandy-ferret — A torn poster sends a policeman on foot at once; a police car or a hunting van stops and lets men out · 2026-10-11


The player ([olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md), inbox #591): "the poster
pursuit should not be placed! it should happen instantly with the pursuer spawning off-screen! and
it should be a proper pursuer not a police car -- maybe a policeman on foot?" and "policemen get
switched to guardman on day 9"; in [merry-stork](../playtests/2026-10-10-merry-stork.md), his catch
"Ends the day (Recommended)", and "an investigating police car should not leave the street. it
should stop if close to her and a policeman should emerge and pursue her". On the review of PR #663
(inbox #669): "we make it somewhat costly. once the policeman reaches her they stop and walk back to
the car", "it needs to give a substantial cost but not lethal directly", "well if the excitement
meter is already high it can be lethal", and, on the night raid's van, "Van stops, men get out
(Recommended)"; asked then whether the raid's men end the day, "Ends the day (M56)", and whether
the unmarked van should stop and let men out too, "Same as the police".

**Built in PR #663.** A torn poster's pursuit marble calls `EventManager.send_a_pursuer()`: the
0.5s screen-edge badge goes up at once, then `policeman_giving_chase` (through day 8) or
`guardsman_giving_chase` (from day 9) is created just off screen already chasing, placed by the
task robber's rule, never by the scheduler and never in the day's queue; the director's sent patrol,
its 1s wait and its street search are gone. Both rows take the robber's numbers (130px/s, a 26px
catch, a 116px lunge, the 30s `PURSUIT_TIME` cap) and **his catch ends the day** with its own line.
The policeman's drawings (`art/events/policeman_*`) are bound; the guardsman draws the checkpoint
guard. `poster-pursuit` goes out when his warning goes up.

**The investigating car** (`EventDef.investigates`) drives its route until she is within 150px
along a clear line and stops on its route — never inside a junction box: seen from inside one, it
drives on until its body is clear of the box and stops there. Stopping where it noticed her,
25 of 125 cars on real `_along_street_path()` routes stood with their centre in a box (the first
review's probe), and with the box rule switched off the suite's own real-route test counts 24. The day's man gets out at its door on
her side, in her view, holds his ground for a 1.8s notice and then chases under the pursuit
contract. **His catch is a stop, not the end of the day** (`EventDef.stop_excitement`): when he
reaches her he stands with her for `Tuning.OFFICER_STOP_SECONDS` (1s) while his own field lands
`Tuning.OFFICER_STOP_EXCITEMENT` (40 points), fading, then walks back the way he came and gets in
at the door he got out of. **The car is quiet until it has left her**: from the frame it stops,
through his notice, chase, stop and walk back, and on as it drives on past her or stands at a line
beside her, until it is outside its own field's reach of her — so the encounter's cost is his.
Measured by `tests/test_pursuer_on_foot.gd`, standing still from an empty meter through the whole
encounter until the car has left her field, with no lights, over 37 encounters (a hand-made lane on
days 8 and 9, and real `_along_street_path()` routes on seeds 4242, 90210 and 314159): 58.7 to 82.4
points, under the whole meter; the test requires the worst under 90. It never ends a calm day by
itself, and on a meter already high it carries her to the cap and past the push that ends it, as
any source does. With the car's field on while it stood, the second review measured about 100 by
the time he was back in, and a played run from 0 was lost crying to him in 9.7s; with the car quiet
only while it stood, the third review measured a clean pass beside her at about 104 and a car then
waiting at a line beside her at 134 to 138. Inside a district door's hold, where only the door's
toll reaches her, he does not stop her: he waits and stops her once she is let out. Once he is back in, the car drives on
along its route the way it was going — standing first while she is in its way — and leaves where
the route ends. This was azure-koala's finding 7 ("police cars chasing the player behave like
running people").

**The two vans hunt on foot** (`EventDef.hunts_on_foot`): at `Tuning.HEAT_HUNTS_LEVEL` the
night raid's and the unmarked van's (`abduction`) hunting copies no longer pursue her; each stands
where it is, as lethal as it is cold (the raid never, the unmarked van inside its own 54px once its
telegraph is over), and once she is within 180px along a clear line lets two men out
(`EventDef.lets_out`), the day's pursuer on foot, who pursue her. **Their catch ends the day**, as
M56's hunting vans did: the raid's by the player's answer, the unmarked van's by keeping the
lethality its own hunt had. A man who gives up walks back to his van, which stands as its cold row
does and never leaves while a man of its own is still out. No vehicle pursues her at any heat.

**This replaces:**

- [M180](2026-09-23-M180-posters-she-notices-and-loudspeakers-that-are-somewhere-seen-walled-and.md)'s
  "A pursuit marble sends a heated `police_patrol` `TOWARD_PLAYER` down the carriageway toward her
  … waiting `EventDirector.TEAR_PATROL_AFTER` (1s of her walking) so she has turned from the wall,
  and at most one waits at a time; nothing is sent during the escape or under `--force`", and its
  open-to-overturn "the 1s wait before a tear's patrol is sent". The pursuer on foot is sent at once,
  one at a time, nothing during the escape — and `--force` no longer holds him back, since he is
  not a scheduled event.
- [M225](2026-09-26-M225.md)'s "A torn poster that sends a patrol sends its own event,
  `nappy-day-N-poster-pursuit`, … when the patrol is sent; a second tear while a patrol is on its
  way sends none". It goes out when the pursuer's warning goes up; a tear while he is on his way or
  after her sends none.
- [M226](2026-09-26-M226.md)'s chosen-while-building "the heat-investigating patrol's 4s follow
  left as it was". The car follows nobody; it stops and lets its man out.
- [sunny-finch](2026-10-07-sunny-finch.md)'s "The investigating car does not strike. Built: it
  comes up to her and stops against her". It stops on its route at its notice reach, outside every
  junction box, and drives on along its route once its man is back in.
- [M56](2026-09-02-M56-the-resistance-is-noticed-partly.md)'s "The raid hunts": "the derived copy
  pursues at 130px/s, notices her within 180px, chases for `PURSUIT_TIME` and is `hard_fail` inside
  its 70px", and its "The van takes somebody, and then it takes you": "At and above it the derived
  copy gains `pursues`, 130px/s …". Both vans let men out instead; the men's catch ends the day, so
  the lethality M56 gave the hunting rung stands, carried by the men rather than the vans.

**Open to overturn, chosen while building:** the car quiet from its stop until it has left her
field; the man
waiting out a hold rather than giving up his chase on it (the door's own guard gives up; "if she
voluntarily goes to a hut the whole pursuit has been accomplished" was said of that guard only);
"close" read as the car's 150px notice; the stop's
size, 40 points over 1s (`Tuning.OFFICER_STOP_EXCITEMENT`, `OFFICER_STOP_SECONDS`) — over a
conversation's 25 and three contacts, under the whole meter; the men walk back along their own
trail; each van lets two men out, the day's pursuer on foot (a policeman out of an unmarked van on
day 8); the unmarked van stays `hard_fail` itself while its men are out; a vehicle investigates
once; the car drives on along its route after; the man out of a vehicle follows the door guard's
in-view contract; the guardsman takes the policeman's numbers; one torn poster's pursuer at a time;
nothing during the escape; ordinary patrols stay cars; `--force` no longer suppresses the tear's
pursuer. Tests: `tests/test_pursuer_on_foot.gd` (including the junction box over real
`_along_street_path()` routes on three seeds, and both vans) and extensions to `test_posters`,
`test_events_pursuit`, `test_no_pop_in`, `test_police_car`, `test_heat`, `test_events_chat`.
Pictures in [ferret-2026-10-10](../evidence/ferret-2026-10-10/README.md).
