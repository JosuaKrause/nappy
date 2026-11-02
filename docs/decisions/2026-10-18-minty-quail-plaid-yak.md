# minty-quail — The events' statics judged, the kept ground handed in, and the scheduler's private names gone (hidden statics, tests through public seams) · 2026-11-02


minty-quail's `hidden-statics.md` and `tests-public-seams.md`: the statics under `src/events/` and
`ResistanceSteps`', the scheduler's private names, the probes' last private reach into the rig and the
director. Both items stay open (the atlas library and the frame record; the arrow's privates and the
recipes' planner reach).

**Built.**
- `EventScheduler`'s kept ground (`_kept_ground_of`, `_stamp`, `_answers`) is a `KeptGround` object
  that `DayPlanner` holds, living as long as the city's events, so a retried escape section reuses it
  as the static did; `plan_the_escape_city()`, `build_day()` and `_fill_the_walk_from_the_bag()` take
  it, and a caller that hands none (a recipe's single plan, a test) reads the ground afresh. The
  placement fingerprint is identical to main's on its 15787 lines.
- The statics left under `src/events/` and `ResistanceSteps._all` are constants or pure memos built
  once and never written by a caller: the catalogue's tables and its derived rows, the heat memo, the
  warning sizes read off the baked pictures, the empty bird list and open walls.
- `EventScheduler.open_ground_for()`, `room_around()`, `place_masts()` and `street_ground()` hold their
  bodies; the privates and the forwards are gone and every caller uses the public names.
  `_is_spoiled()` is public as `is_spoiled()`.
- The probe `bouncy_egret_day11_mast.gd` builds on `_build_city_in_a_new_run()`, and the rig's
  `_build_city()` and `_with_clean_run()` are gone. `ResistanceDirector.trap()` answers null once its
  pursuer is finished, so the trap probe no longer clears the director's field; a crossing check
  retires the robber and expects null.

**Open to overturn** (the builder's choices where the brief was silent): `KeptGround` held by
`DayPlanner`; `EventScheduler.judgements` left as a game counter a test reads.
