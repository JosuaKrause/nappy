# sandy-ferret — A torn poster sends a policeman on foot at once; an investigating car stops and a policeman gets out · 2026-10-10


The player ([olive-hedgehog](../playtests/2026-10-05-olive-hedgehog.md), inbox #591): "the poster
pursuit should not be placed! it should happen instantly with the pursuer spawning off-screen! and
it should be a proper pursuer not a police car -- maybe a policeman on foot?" and "policemen get
switched to guardman on day 9"; in [merry-stork](../playtests/2026-10-10-merry-stork.md), his catch
"Ends the day (Recommended)", and "an investigating police car should not leave the street. it
should stop if close to her and a policeman should emerge and pursue her".

**Built in PR #663.** A torn poster's pursuit marble calls `EventManager.send_a_pursuer()`: the
0.5s screen-edge badge goes up at once, then `policeman_giving_chase` (through day 8) or
`guardsman_giving_chase` (from day 9) is created just off screen already chasing, placed by the
task robber's rule, never by the scheduler and never in the day's queue; the director's sent patrol,
its 1s wait and its street search are gone. Both rows take the robber's numbers (130px/s, a 26px
catch, a 116px lunge, the 30s `PURSUIT_TIME` cap) and his catch ends the day with its own line.
The policeman's drawings (`art/events/policeman_*`) are bound; the guardsman draws the checkpoint
guard. `poster-pursuit` goes out when his warning goes up. **The investigating car**
(`EventDef.investigates`) drives its route until she is within 150px along a clear line, stops on
the carriageway, and the day's man gets out at its door on her side, in her view, holds his ground
for a 1.8s notice and then chases under the pursuit contract; the car then drives on along its road
and leaves only out of her sight. This was azure-koala's finding 7 ("police cars chasing the player
behave like running people"). *Open to overturn:* "close" read as the car's 150px notice; the car
drives on after; the man out of the car follows the door guard's in-view contract; the guardsman
takes the policeman's numbers; one pursuer at a time; nothing during the escape; ordinary patrols
stay cars. Tests: `tests/test_pursuer_on_foot.gd` and extensions to `test_posters`,
`test_events_pursuit`, `test_no_pop_in`, `test_police_car`, `test_heat`. Stills in
[ferret-2026-10-10](../evidence/ferret-2026-10-10/README.md).
