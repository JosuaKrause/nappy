# minty-quail — The checkpoint, chat and encounter suites run the event manager in a tree on real ticks (tests through public seams: W1) · 2026-11-03

minty-quail's `tests-public-seams.md` and `run-state-handed-in.md`: the checkpoint, chat and
encounter suites, subtask W1 of the scoped plan. No `src/` change and no seam added.

**Built.**
- Each suite hands its `EventManager` a bare `CityMap` and a fresh `RunState` through
  `setup_world()`, which `main` calls for the escape's building, and puts it in the tree before a
  real stroller, so the manager's own physics ticks run the hold start, the steps and the release
  instead of the suites calling `_tell_them_where_she_is()` and `_physics_process()` by hand.
  Fingers are screen touches pushed through the viewport.
- `tests/physics_ticks.gd` (`PhysicsTicks`) lets real ticks pass one per frame, restoring the
  engine's steps per frame and time scale, and `settle()` ends the runner's startup frame so its
  backlog of ticks does not land in a test's first wait.
- Private-read lines: checkpoints 58 to 3, events_chat 16 to 0, encounters 14 to 0; hand-called
  frames 13 to 0. Every test kept under its name; the never-drawn-at-the-entry check samples tick by
  tick (two fewer checks, since the manager ends the hold and releases her on one tick), and the
  door-release catch uses a real hut hold.
- Mutation runs listed in the PR; two gates are caught by nothing, since other conditions stop the
  same cases first (the old suites missed them too).

- The first review found the chat suite aborting with no check named when the hold was broken (a
  mother freed mid-conversation); it frees the manager first, and the mutation fails eighteen named
  checks. The door rig's frame-after check and the door guard's charge take real ticks.

**Not done:** the arm test writes the crowd's `_player` and calls its `_stop_for_gates()`; public
steps are called by hand where nothing ticks them: the street-door rig on a city that never ticks,
the crowd's `step()` in the gate rig (its own tick passes the car at another time), and a lone
guard's `step()` in the pursuit simulations.
