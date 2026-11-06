# minty-quail — The events and looks suites stop calling members only tests call · 2026-11-05

minty-quail's `tests-unseen-reads.md`, the events and looks build, under the player's rule that a
public member only tests call is deleted where possible, the tests going through a fake or what the
game shows, and kept only where the information cannot be had otherwise and the test needs it
(curly-rabbit #1095); and `tests-hold-nothing.md`'s findings in the same suites.

**Built.**
- Deleted from `src/`: `EventInstance.its_officer()` and `its_officers()`,
  `EventsAhead.sent_pursuer()`, `EventInvestigation.has_seen_her()` and `has_investigated()`,
  `EventCarDriving.is_standing()`, `EventAbduction.take_now()` and `MarbleBag.rig_spaced()`, with
  the sentence in `docs/EVENTS.md` that said nothing used the last.
- The suites find a car's men as the manager's instances whose officer behaviour names the car
  (`tests/men_let_out.gd`), the poster's pursuer as the instance of either on-foot row, whether a
  car saw her by the notice distance and clear line the car uses itself, a standing car by a step
  that left it where it was, and an abduction by standing her inside the van's radius and stepping
  it. `tests/test_event_redraw.gd`, outside the build's files, changed its one `take_now()` call the
  same way. Three probes under `tests/probes` follow; `event_car_give_way_trace`'s fingerprint is
  now "the step left the car where it was", so its older baselines do not compare.
- The audit's findings in `test_event_behaviours.gd`, `test_event_views.gd`,
  `test_fire_truck_body.gd`, `test_police_car.gd`, `test_pursuer_on_foot.gd` and `test_route_bag.gd`
  held and went, and each suite's count moved by exactly the checks removed. The pursuer suite's
  reach check, which the audit listed with the two table read-backs beside it, stays: it is a
  relation to the robber's row, which the audit's own note keeps.

**Kept, each with its reason written on the member.** `EventsAhead.walk_siting()`:
`test_route_bag.gd` reads the mast checks it sites, and `EventsAhead` builds that siting itself, so
a test cannot hand it one. `EventLook.drawn_rect_now()`: the caret is drawn straight onto the event
and no recorder holds it.

**Left.** `RoadblockLook.attach_nodes()` and `far_guard_node()`, `DrawLayer.layer_of()`,
`EventPictures.boom_arm_span()`, `has_its_far_guard_posted()` and `plan_the_rest_again()`, which
these suites no longer read but rigs and suites outside the build still do;
`tests-unseen-reads.md` names them and their owners, the escape rigs build for its three rigs and
suites and a leftover readers build for the rest, which also takes what the atlas build left. A fresh car's "made standing" check is now "not driving",
which is weaker, and `MarbleBag._take()` keeps a `keep_out` parameter that is now always empty;
both are the builder's choices, open to overturn.
