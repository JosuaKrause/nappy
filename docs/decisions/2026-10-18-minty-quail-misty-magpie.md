# minty-quail — The escape rigs stand their events through the game's streaming, and a guard sees out of his own band · 2026-11-05

minty-quail's `tests-unseen-reads.md`, the escape rigs build: the finale rig's hand-built plans,
guards and bands, the roadblock rig, the seal reach rig and the barrier suite, under the player's
rule that a public member only tests call is deleted where possible, the tests going through what
the game does (curly-rabbit #1095); and `tests-hold-nothing.md`'s findings in the same files
(curly-rabbit #1097).

**Built.** A new `RoadblockRig.Stage` (a world context, a run state and an event manager with
physics off) stands a plan through `EventStreaming.add()` and `stream_in()`, as a played day does,
and every hand-built `EventInstance.new()` and `setup()` in the build's four files goes through it.
The band attaches its nodes on the idle frame rather than through `look.attach_nodes()`; the far
guard is the node named `FarGuard` beside the guard; a draw layer is read as `z_index` against
`DrawLayer.z_of()`; a guard coming back as the barrier is a guard shaken off in play and the plan
streamed out and in; the walk-off case uses the game's own `give_up_the_chase()`.
`EventDeparture.plan_the_rest_again()` went, and once these rigs stopped reading them so did
`RoadblockLook.far_guard_node()`, `EventBarrierPost.has_its_far_guard_posted()` and
`DrawLayer.layer_of()`, which nothing then called. The audit's findings in the finale rig and the
barrier suite held and went; the pause test that set the pausable mode itself became two questions
inside the booted pause test.

**A game bug the streamed rig found.** Stood through the streaming, a roadblock's band body is
recorded on the map as on a played day, and on seven streets across three seeds the guard posted
at the band warned for two seconds and never charged: his line to her crossed his own band's body,
which blocked his sight, so she walked past him. The game's comment says a guard sees out of the
band he stands in, and the escape's design is that luring the guard off is the way past a
roadblock, so it was fixed in the shared line walk: `WorldMap.clear_line()` and
`Navigator.clear_line()` take the tiles of the asker's own body, which the day's solids are not
asked on, and `EventInstance.clear_line_to()` passes its own footprint (`own_body_tiles()`, from
`EventSpawner.obstructed_footprint()`). Another band, a building, a café or a seal still blocks the
line, and a catch (`is_lethal_at()`) keeps the strict line, so no one catches her through any
barrier. A check that fails on the old code, `_test_a_posted_guard_sees_and_charges_her_across_his_own_band`,
stands the band over a generated city. Put to the player on the board as a heads-up
(guard-sees-past-own-band), the fix built on the orchestrator's pick unless they say otherwise.
With the body recorded, the guard walks round his own band to reach her, so the roadblock rig's
walk follows a charge begun past the end of her line for up to ten seconds at her pace.

**Open to overturn.** The exemption covers the owner's whole footprint; the catch stays strict
across his own band; the guard walking round his own body is left as the game has it; the ten
seconds of the walk's tail; one stage per build with instances stepped by hand; a stood plan's
successor from `EventSpawner.successor_of()`; `drawing_overhang` passing the plan's own facing;
the `--start-escape city` word check removed with its test.
