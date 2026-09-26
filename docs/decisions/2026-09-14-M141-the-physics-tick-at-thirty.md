## M141 — The physics tick at thirty · built 2026-09-14

*(2026-09-14, [PLAYTEST-74](../playtests/PLAYTEST-74.md): "physics should be capped at 30fps at
the least not 60".)* One agent commit on `feature/m141-physics-tick-30`, reviewed on the PR;
the still and the burst are `evidence/m141-physics-tick-30-2026-09-14/`.

**Why.** The phone reading with the crowd parked (M140, the phone reading, below) put the
physics tick at 6 to 9 ms and showed it is not the crowd's: `Crowd._physics_process`
returning at once did not move it. At the engine's default of sixty ticks a second, a phone
drawing 33 to 45 frames ran that tick once or twice a frame, twelve to eighteen ms of a 22 to
30 ms frame. Halving the tick halves that before anything in the tick is made cheaper. Thirty
is the number asked for; nothing depends on thirty in particular, so lower is a number the
next phone reading can argue for.

**What it is.** `project.godot` sets `physics/common/physics_ticks_per_second=30` and
`physics/common/physics_interpolation=true`, and a test in the presentation suite reads both
off the running engine so the setting cannot drift out of the file unread. Interpolation is
what keeps her smooth: she and her camera's target move on the tick, and at thirty ticks
under a desktop drawing a hundred frames she would otherwise step every third frame while the
camera's own smoothing glides. With it on, the engine draws every physics-moved `Node2D`
between its last two ticks — and moves a `Camera2D`'s own smoothing onto the physics tick,
which it logs once at boot. Everything moved in `_process` opts out on itself, since
interpolation would draw such a node between two stale tick positions: `CrowdAgent._ready()`,
`EventInstance._ready()` and `DevRig`'s `--follow` camera set
`PHYSICS_INTERPOLATION_MODE_OFF`. And every teleport of her calls
`reset_physics_interpolation()` so it is not drawn as a one-tick slide from the old place:
`Stroller.teleport_to` (a door release), `Stroller.reset_at` (the day start and both finale
section resets route through it, and it resets the camera it snaps back too),
`InteriorScene.teleport_to_door`'s non-`Stroller` branch, and the camera at
`focus_camera_on` and where the ease back hands it back to its parented follow. Every test
rig steps the world by hand with its own `STEP` constant and never reads the engine's rate,
so the suites did not move. `docs/TELEMETRY.md` says the tick is thirty a second where it
explains the `physics` column, and the M100 cadence item's ratios are rewritten to the new
tick.

**Two things the entry said that the tree did not bear out, resolved rather than guessed.**
The entry put the opt-out on `Crowd`, `EventManager` and `ResistanceDirector`, "inherited by
everything under them"; none of the three has a scene child — every agent, instance and
contact point is added under `City`'s shared y-sorted `Entities` node beside her, so the flag
on the managers would have reached nothing, and on `Entities` it would have switched her off
too. The opt-out went on the movers themselves, and the three managers carry a note saying
where it lives. `ContactPoint` needed neither: it follows its rider on the physics tick, and
the director's own `_process` only ever relocates a mark beyond `NOTICE_RADIUS`, which is past
the screen's half-diagonal, so the jump is never on screen to slide. And the entry's
`shot.sh` line truncated the burst: the number after `--press <action>` is *when* the action
is tapped, not a length, and a burst tapped at three seconds needs the process alive to six;
the capture was retaken with a total wait of seven.

**What it does not settle.** Whether her walk reads smooth on the desktop, and whether the
phone's frame moves, are the `REVIEW.md` items. The M100 cadence item's own recommendation —
moving the agents onto the tick — would now draw the whole crowd at thirty frames a second,
which is a larger piece of that trade than it was.
