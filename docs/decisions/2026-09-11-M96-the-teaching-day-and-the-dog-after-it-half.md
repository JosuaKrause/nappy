## M96 — The teaching day, and the dog after it · half built, measured 2026-09-11

Three agent commits on `feature/tutorial-dog-later`, reviewed here, with the M100 item on a
pursuer's memory alongside. **What the queue decided** *(2026-09-09: "the tutorial dog may appear
later but not as tutorial")*: day 3 keeps the dog on her line, and from day 4 it is placed on the
map the way `alley_robbery` is and met by routing. **What was built is less than that, and it is
not the decision**: `EventDirector` keeps `AHEAD_OF_PLAYER` and, past `RUN_TAUGHT_DAY`, sites the
dog off a bearing rotated 50–110° from her heading to a coin-flipped side, still past the edge of
the view — never on her line, held by `tests/test_tutorial_dog.gd` over five seeds and four
headings, with day 3 still on it. The agent went this way because the two shapes the entry named
were both outside its fence: a second row is blocked by the one-picture-per-row check (no spare dog
silhouette), and a day-dependent `spawn_mode` lives on the def and in the scheduler; mutating the
shared `EventDef` singleton at runtime was considered and rejected, since it would persist across a
replay in the same process and break the day-3 lesson on a second run. The map placement stays in
the queue with its shape named; the off-heading siting is an interim that already removes the
"still in front of her" half of the complaint.

**The lead-time gap is closed already.** Playtest 20 measured 1.5s to evade the tutorial dog
against 0.8–0.9s on the days a later dog killed her. On the current tree, over eight headings, the
off-screen notice is 0.493s on every heading and an immediate flee evades in 1.517s on every
heading, zero spread: M77's arrival-from-off-screen rule made the siting heading-independent by
construction, and the row's radii were never the cause.

**One contact at 89 is a cliff.** A real crowd agent's startle against the baby at excitement 90
ends at 100 and crying; at 89, the same; at 85 it ends at 96.8 and awake. `tests/test_meters.gd`
pins the measurement as a measurement, not a requirement. The nearly-crying cue is returned at
exactly 80 and drawn as the flashing pram cue, confirmed by reading rather than by eye. The rule
about the last ten points is the player's, in the entry.

**The pursuer's memory, half.** `EventInstance.resume()` takes a third, defaulted argument for the
notice and restores it, and the heat suite's test that pinned the forgetful behaviour now asserts
the intended one, for `alley_robbery` as well as the patrol that surfaced it. The caller does not
pass it yet — `EventManager._stream_in()` has nothing to pass, because `EventScheduler.Planned`
carries no notice — so play is unchanged; the remaining half is in the M100 item, named exactly.
