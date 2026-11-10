# minty-quail — The car and the vehicle that lets men out ask the live event through Figure, and no behaviour holds its event (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method", and "fields are not API
interaction between different objects need to go through APIs" (inbox #1173 in gray-dolphin). The
step "the live event's behaviours ask it through `Figure`, and are handed the rest" of the events'
interface design (`docs/todo/2026-10-18-minty-quail/event-interface.md`, its row 2a) is built as
seven pull requests, a cut the orchestrator's planning agent made and no tracked file holds; this
is the fifth, after the doors, the sources and the encounter watch (minty-quail-velvet-owl), where
she is as one object (minty-quail-olive-finch), the seven behaviours that walk, wait and hold
(minty-quail-tiny-alpaca) and the chase (minty-quail-tawny-swan). Two remain: the live event's
field asks its row, and its body is a part of its own.

## What was built

- **The car's driving (`EventCarDriving`) and the vehicle that stops for her and lets men out
  (`EventInvestigation`) no longer hold their live event**, the last two behaviours that did. Each
  is handed what never changes in its constructor and asks what changes through `Figure`.
- **`EventBehaviour.event`, `EventBehaviour.attach()` and the composer's `_attach()` are deleted**,
  since nothing read them any more; the base's class comment says a behaviour never holds its
  event.
- **What each is handed**: the car the figure, where she is, its row, the map, its route walk (or
  none), the investigation (or none) and the event's move (`MoveProposal`), once, so its
  `note_the_pose()` and `check(ends_its_route)` no longer take the move per call and read it
  through its methods; the investigation the figure, where she is, its row, the map and its route
  walk, and the car once the car is made (`take_its_car()`), held by a `WeakRef`, the shape the
  chase gave the man on foot's departure, since the car holds the investigation.
- **`EventInstance.let_out(officer)` starts the man's trail itself** (`officer.on_foot.let_out_of(self)`),
  since the investigation has no event to name itself by; the order is unchanged. **The men it
  let out are called back by the event too**: the loop that ends every man but the one who stopped
  her moved from the investigation into `EventInstance.call_back_its_officers(stopped_by)`, which
  asks the investigation for its men (`its_officers()`), so no behaviour calls another live event's
  private `_be_done()`; the investigation's own method is gone. The investigation asks a man it
  let out `is_gone()` instead of reading `is_finished`.
- `docs/ARCHITECTURE.md` says no behaviour holds its event. `tools/field_reads.txt` lost 25 lines
  and gained none; `tools/test_only_members.txt` is unchanged; no suite or probe changed.

## `Figure`'s questions and events

Added here, two questions and two events, each called only by the car: `gait_phase()` (where its
stride is), `lights()` (the traffic lights its manager tells the event after setup, or none),
`take_back_its_step(heading, travelled, gait_phase)` (the refused step put back as one event,
where the car wrote four fields) and `turn_its_body_to(angle)` (the body's collision shapes
turned, in the shape the chase's `pin_its_body_at()` has). `Figure` now has twenty-eight questions
and twenty-one events. The design's `drop_its_body()` is still not added: no behaviour drops a
body.

## Parity

The run log is line for line what it was (`tools/test.sh observers`). Both identity probes give the
same hash on `main` at `75ef3ad57`, the commit this branch was made from, and on the code commits
`52a42b9c8` and `80f1d84f2` (the review's fixes): what every source charges her tick by tick (`probes/excitement_fingerprint.gd`, its
`XF` lines less `XF_COST`), and every event, crowd agent and baby meter on every tick
(`probes/m159_tick_sweep_events_cost.gd`, the `chain` values). `probes/event_car_give_way_trace.gd`
prints the same lines on both trees once its timing line is taken out.

## Choices the builder made where the design was silent or the brief and the fence met, open to the player's overturn

- **The traffic lights are asked through `Figure.lights()`, not handed in** as the brief listed:
  the spawner sets the event's `signals` on the line after `setup()`, and two suites and the give-way
  probe do the same, so a constructor would be handed none. The design's step where the spawner
  hands a live event everything in one setup call (its 3b) is where they can be handed in.
- **The car is not handed `VehicleSpec` or the navigator, and the investigation not `HuntSpec`**,
  as the brief listed: the car reads nothing of the one and never uses the other, and a member
  nobody reads is code nothing reaches (inbox #1180 in gray-dolphin); the investigation would read
  `HuntSpec.lets_out`, whose design name is the field's own, so it asks the row's `lets_out()`, as
  the chase asked the row's `notice_within()` and not `NoticeSpec`.
- **The route walk is handed to both**, which the brief did not list: the car asks its route's
  length and the investigation drives its route, and the design hands siblings in.
- **The car is handed the move once** and reads it through `MoveProposal`'s existing methods.
- **`take_back_its_step()` is one event carrying the whole change**, rather than `walk_on()` with a
  difference, which would not give back the same float, and a setter per field.
- **`let_out_of(self)` moved into `EventInstance.let_out()`**, as the chase moved the man's call-back
  into `call_back_its_officers()`.

## Reads left, and why

- **The row's fields read through the handed row** where the row has no method yet (`shape`,
  `speed`, `stops_where_it_arrives`, `paces`, `mobile`, `pursuit`, `vehicle`); where it has one, it
  is asked (`notice_within()`, `lets_out()`, `heard_within()` in place of `outer_radius`).
- **No field of the live event was made private**: each one the two stopped reading still has a
  reader elsewhere (the looks, streaming, the warning board, the resistance, the dev rigs, the
  suites), apart from `_heading`, `_path_travelled`, `_gait_phase`, `_gait_moving`, `_map` and
  `_obstruction`, which have no reader outside the event's own file in the game now.
- **`tests/test_prediction_reuse.gd` swaps a car's row after setup**, harmlessly: the car there is
  standing and answers before it reads a shape, on `main` and here alike.
