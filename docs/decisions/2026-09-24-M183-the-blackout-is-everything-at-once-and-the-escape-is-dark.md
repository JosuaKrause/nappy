## M183 — The blackout is everything at once, and the escape is dark · built 2026-09-24

*([PLAYTEST-119](../playtests/PLAYTEST-119.md): "just wait until a certain distance away -- then
everything is off at once" · "yes all lights should go out. that actually applies also to the
escape sequence"; [PLAYTEST-121](../playtests/PLAYTEST-121.md): "the escape shouldn't be easy!".)*

**The blackout.** `Blackout` (`src/city/blackout.gd`, made by `City.build()`) watches
`GameState.sabotage_done` and her distance from the power station's lot; once the flag stands and
she is `Tuning.BLACKOUT_DISTANCE` (512px) away, `go_dark()` puts out every lit window, the
station's hall (a new `power_station_clerestory_lit.svg`, lit on day 14 only), every spine traffic
light and every loudspeaker mast, in one frame. It stays dark while the flag stands; a retried day
clears the flag at dawn and the power with it; a city built for the escape is dark from its first
frame. `ResistanceDirector` now only sets the flag, and the masts stop with the power. `--blackout`
stands in for the flag so the moment can be captured on any day.

**Dead lights.** With the power out `TrafficSignals.is_signalled()` answers false, so the crowd's
own junction rule decides the spine's junctions as it decides a side street's, with no crowd code
changed; `has_lights()` says where the dark heads still stand. Over 40 s on seed 4242 day 14 the
lit spine averaged 38px/s with 42% of cars stopped, the dark one 50px/s with 27%, so the dark spine
does not jam, and a test holds it to at least 80% of the lit speed. **The dark crossing's contract
is the side street's**, the painted road and the horn — the orchestrator's reading, open to
overturn — written into `validate_signals()`'s docstring, the **crowd-traffic** skill, `MECHANICS.md`
and `CITY.md`. **Measuring it found the horn short on every street**, capped by the crowd's 200px
watch; that is M191, a car's horn is early enough at every speed, in `TODO.md`, and the skill now
says the horn can only be as early as the car is watching her.

**The escape is dark.** `InteriorScene.lighting_at()` tints the part she is in: a cold gloom in the
hallways and lobby, darker in the basement, red emergency light on both stairwells, and a hallway
brightening while its windows flash. It uses the scene's own `modulate`, since the escape's city
section already has a `CanvasModulate` on the same canvas; the light changes only under a door's
fade. The wall lamp and the chandelier are drawn unlit.

**The last night in the docs.** `docs/NARRATIVE.md`'s Act IV day 14, "Endings → Good" and tone rule
3 ("a silence and a way out — never a victory, and never an easy walk"), and `MECHANICS.md`'s good
ending, say the masts stop because the power does and neither the walk home nor the escape is easy.

**Open to overturn, chosen by the agent:** the 512px distance, the smallest round number that
keeps the station off screen whichever way she leaves; the hall lit on day 14 only; the HUD's "The
loudspeakers cut out mid-sentence." kept, now at the blackout; the escape's colours, a first
proposal that is in `REVIEW.md`. Evidence: `evidence/m183-blackout-2026-09-24/`.
