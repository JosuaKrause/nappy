# minty-quail — The route rig's planning moves into a planner the rig calls (tests through public seams) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the route rig suite and the
fallen-trees suite. The item lists the eleven route and recipe suites still to do;
`test_scene_recipe.gd` and `test_routes_kerb_tint.gd` had no private read to convert.

**Built.**
- `RouteRigPlanner` (`src/dev/route_rig_planner.gd`) holds the route rig's target resolution,
  planning and clearance, moved out of `RouteRig`, which keeps the walking (pressing toward
  waypoints, the stall ladder, doors, settling the baby). Every public member of the planner is
  called by `RouteRig`; no private member was made public and `RouteRig` gains none. A target on
  blocked ground is moved aside by the same blocked set every plan keeps off, where a hand-kept copy
  of that list stood.
- `test_route_rig.gd` (private-read lines 191 to 1, hand-called frames 4 to 0, `GameState` lines 39 to
  0) asks the planner through the rig's constructor and drives the rig through `setup()`,
  `start_day()` and real physics frames, her walking by her own `move_and_slide()`, reading the rig's
  presses and the `route` lines it writes. Three setup checks added. `test_routes_fallen_trees.gd`
  checks every closure `plan_day()` puts on a bare street rather than calling
  `ClosurePlanner._pick_kind()`.
- About forty mutation runs, each failing the check that guards the code broken.
- The real-frame rig tests step every frame as exactly one physics tick, through one helper that
  pins `Engine.max_physics_steps_per_frame` to 1 and puts it back however the stretch ends. Three
  reviews found the tests reading a timeline of frames while the engine packs several ticks into a
  slow frame (a leg's first plan, a loaded machine): counting frames as ticks failed in CI, widening
  the tolerances by the frame length let a 2.5 s wait pass, and the ladder's first steps could land
  inside one frame. The rethink after the third pinned one tick per frame, so the time checks keep
  their first, tight bounds and hold on a loaded machine. The runner's shared-state check compares
  `Engine.max_physics_steps_per_frame` beside `Engine.time_scale`, and the verify skill names it.

**A rig bug the real-frame test found:** when a stall check started its three-second wait, the rig
still pressed toward the next waypoint that frame and nothing released it, so she walked on into
the crowd through the wait its doc says stands her still. It presses nothing on the frame a wait or
the maneuver starts. *Open to overturn:* it changes how the dev rig walks, so the route timings the
probe `m184_route_timing` measures may move.

**Open to overturn** (the builder's choices where the brief was silent): one planner class holding
resolution with planning, since both use the same clearance; `unstick_order()` in the planner; the
check that the rig avoids what caught her made at the planner (`plan(..., avoid)`), not by wedging
her against a body over frames; the boom check made "a plan aimed at the boom's ground ends beside
it".

**What no check isolates:** dropping `_post_tiles()` (the map's walkability already refuses that
ground), `_simplify()`'s exemption for crossed clearance tiles (a cut's own clearance already refuses
those cuts), and opening the boom's ground beyond the aimed-at check.
