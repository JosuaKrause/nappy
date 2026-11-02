# minty-quail — The event drawing suites drive public seams (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the event drawing suites. The item stays open for the reads
they keep and the other suites.

**Built.**
- `EventLook`'s gait, idle, view, anchor and telegraph queries the drawing code calls across classes
  are public (`gait_is_stepping()`, `gait_is_second_half()`, `victim_gait_is_stepping()`,
  `idle_is_stepping()`, `body_anchor()`, `select_view()`, `robber_waiting_heading()`,
  `mast_is_telegraphing_now()`), and `EventLook.is_mirrored()` replaces the same expression at ten
  drawing sites in `FigureLook`, `PursuerLook`, `RankLook`, `EventVehicleLook` and `EventLook`.
- The suites ask the redraw gate the game's own `_process()` asks (`redraw_if_the_picture_changed()`)
  and read its answer, find the fire truck's body among the instance's children, and step real
  physics and process frames with the instance in the tree and its atlas group acquired as the
  manager does. A first review found six members public that only tests read; they are private
  again, removed, or given the game reader above.
- Private reads: event_redraw 57 to 6, event_views 35 to 6, event_strides 29 to 5,
  destination_drawing 6 to 0, fire_truck_body 8 to 0, event_parts 3 to 0, event_phase 2 to 1;
  prediction_reuse unchanged at 25. Every check kept; event_redraw gains one (a fresh instance's
  first ask draws and a second does not), and `test_scenery_animation.gd` asks the gate in place of a
  hand-called `_process()`.

**Open to overturn** (the builder's choices where the brief was silent): the public names
(`gait_is_stepping()` rather than `is_stepping()`).
