# sandy-ferret — A torn poster sends a policeman on foot at once; a police car or the raid's van stops and lets men out · 2026-10-11


The player ([olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md), inbox #591): "the poster
pursuit should not be placed! it should happen instantly with the pursuer spawning off-screen! and
it should be a proper pursuer not a police car -- maybe a policeman on foot?" and "policemen get
switched to guardman on day 9"; in [merry-stork](../playtests/2026-10-10-merry-stork.md), his catch
"Ends the day (Recommended)", and "an investigating police car should not leave the street. it
should stop if close to her and a policeman should emerge and pursue her". On the review of PR #663
(inbox #669): "we make it somewhat costly. once the policeman reaches her they stop and walk back to
the car", "it needs to give a substantial cost but not lethal directly", "well if the excitement
meter is already high it can be lethal", and, on the night raid's van, "Van stops, men get out
(Recommended)".

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
drives on until its body is clear of the box and stops there. The day's man gets out at its door on
her side, in her view, holds his ground for a 1.8s notice and then chases under the pursuit
contract. **His catch is a stop, not the end of the day** (`EventDef.stop_excitement`): when he
reaches her he stands with her for `Tuning.OFFICER_STOP_SECONDS` (1s) while his own field lands
`Tuning.OFFICER_STOP_EXCITEMENT` (40 points), fading, then walks back the way he came and gets in
at the door he got out of. Forty points never end a calm day; on a meter already high they carry her
to the cap and past the push that ends it, as any source does. Once he is back in, the car drives on
along its route the way it was going — standing first while she is in its way — and leaves where
the route ends. This was azure-koala's finding 7 ("police cars chasing the player behave like
running people").

**The night raid's van hunts on foot** (`EventDef.hunts_on_foot`): at `Tuning.HEAT_HUNTS_LEVEL`
the hunting copy no longer pursues her; it stands where it is, never `hard_fail`, and once she is
within 180px along a clear line lets two men out (`EventDef.lets_out`), guardsmen on day 10, who
pursue her. Their catch is the car's man's stop: the first to reach her stops her and both walk
back, and the van stands over its block for the rest of the day. No police vehicle pursues her at
any heat; the unmarked van (`abduction`) still hunts as itself at `HEAT_HUNTS_LEVEL`.

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
  its 70px". The hunting raid's van lets men out instead, and their catch costs her rather than
  ending the day.

**Open to overturn, chosen while building:** "close" read as the car's 150px notice; the stop's
size, 40 points over 1s (`Tuning.OFFICER_STOP_EXCITEMENT`, `OFFICER_STOP_SECONDS`) — over a
conversation's 25 and three contacts, under the whole meter; the van's men cost her as the car's
man does rather than ending the day (inbox #669 answered the car's man; the van's was read off the
same answer, against M56's lethal hunting raid); the van lets two men out; one man reaching her calls
every man of his vehicle back, so a vehicle costs her once; the men walk back along their own trail;
a vehicle investigates once; the car drives on along its route after; the man out of a vehicle
follows the door guard's in-view contract; the guardsman takes the policeman's numbers; one torn
poster's pursuer at a time; nothing during the escape; ordinary patrols stay cars; `--force` no
longer suppresses the tear's pursuer. Tests: `tests/test_pursuer_on_foot.gd` (including the
junction box over real `_along_street_path()` routes on three seeds, and the van) and extensions to
`test_posters`, `test_events_pursuit`, `test_no_pop_in`, `test_police_car`, `test_heat`. Pictures
in [ferret-2026-10-10](../evidence/ferret-2026-10-10/README.md).
