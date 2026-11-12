# minty-quail — The halo and the badge model are typed, and the excitement source's fields go behind methods · 2026-11-12

**The ask.** Every receiver gets a class the field-read check can tell ("it should be made working",
inbox #1268 in olive-ferret), and code is typed where it can be ("we type when we can", inbox #1280 in
olive-ferret): `field-reads.md` with `typed-everywhere.md`, one pass per module; fields are not API, and a reader asks
a method (inbox #1173 in gray-dolphin). This pass is the danger vocabulary's halo, screen-edge badge and badge model
(`src/ui/`). Its search is `ExcitementSource`, one thing in the world that charges the baby
(`src/world/excitement_source.gd`).

## What was built

- **Two of the three files parse without their file-level opt-out line**: `src/ui/excitement_halo.gd`
  (`untyped_declaration`, `unsafe_method_access`) and `badge_model.gd` (`untyped_declaration`); none after.
  `src/ui/danger_edge.gd` keeps its line (below).
- **The excitement source's three fields go behind methods.** `body`, `rim` and `outranked` become `_body`, `_rim` and
  `_outranked`, read through `body()`, `rim()` and `is_outranked()`; `set_outranked()` takes the one write, which
  `EventManager` makes once a frame (`src/events/event_manager.gd`, that one line); the event instance's write of its
  rim calls the existing `use_rim()` (`src/events/event_instance.gd`). Typed, the halo's receiver is an
  `ExcitementSource`, and without these methods the field-read check would see three reads it cannot see today; with
  them, `tools/field_reads.txt` loses the two lines the writes held and gains none. Every reader under `tests/` asks
  the methods (the halo's rig and suites, the barrier, car-view, draw-layer, excitement-source, interior and
  prediction suites, the prediction fixture and the excitement fingerprint probe), and the description shows the
  old-name search for each, no read of this class's fields left outside its file.
- **Typing**: the halo's loops over its candidates, picks and holders take `ExcitementSource`, the holders keyed by
  sources, which are `RefCounted` and never freed (only a body can be, and the halo already guards it with
  `is_instance_valid()`; `body()` hands a freed body back as held, so the guard answers false as before); its rims are
  read as `SourceRim` through `rim()`; the badge model's loop over its watch list takes `int`, the instance id each
  subject is keyed by.
- **The screen-edge badge keeps its line.** `DangerEdge` holds its event source as a `Node` and duck-types it with
  `has_method()`. The game hands it an `EventManager`, but three stand-ins extend a bare `Node` (`_Source` in
  `tests/test_badge_model.gd` and `tests/test_visible_view.gd`, and `Source` in `tests/probes/m226_arrival_timing.gd`),
  so typed `EventManager` the file fails on its three calls, and called by name it would hide them. It waits for those
  suites' conversion to public seams (`tests-public-seams.md`): the stand-ins extend `EventManager`, and
  `DangerEdge`'s fallback to a view of its own, which two of them lean on, goes with its `has_method()` tests.
- **Five sentences the change made untrue now name the methods**: `docs/EVENTS.md`, under "The hold charges its toll";
  the comments in `src/events/event_def.gd`, `event_sources.gd` and `event_manager.gd`; and `src/ui/source_rim.gd`'s.
- **Left**: `BadgeModel.Subject`'s fields, a plain record the screen-edge badge writes, which the check does not see as
  an inner class's; `EventDef.speed`, already listed, which `approach_speed()` derives from rather than returns.

## Fields read and written, by class

`tools/field_answers.py` on the four files, as it prints them at f5547faec, each named method read in its class.

Fields of classes under `src/` that `src/ui/excitement_halo.gd`, `src/ui/danger_edge.gd`, `src/ui/badge_model.gd`, `src/world/excitement_source.gd` read or write through a receiver of that class, each with the method of the class that answers it (`tools/field_answers.py`). `(N calls)` counts a method's calls under `src/` outside its own file, `+N own` those in its own file, `+N untold` the calls of that name whose receiver's class cannot be told.

- `BadgeModel.Subject`: `announces` written (`src/ui/danger_edge.gd`:211): no method; `approach_speed` written (`src/ui/danger_edge.gd`:212): no method; `charging` written (`src/ui/danger_edge.gd`:191): no method; `finished` written (`src/ui/danger_edge.gd`:189): no method; `heard_within` written (`src/ui/danger_edge.gd`:214): no method; `key` written (`src/ui/danger_edge.gd`:187): no method; `left` written (`src/ui/danger_edge.gd`:201): no method; `logged_name` written (`src/ui/danger_edge.gd`:193,202): no method; `payload` written (`src/ui/danger_edge.gd`:210): no method; `pending` written (`src/ui/danger_edge.gd`:199): no method; `position` written (`src/ui/danger_edge.gd`:188,200): no method; `shown` written (`src/ui/danger_edge.gd`:192): no method; `speed` written (`src/ui/danger_edge.gd`:213): no method; `warned` written (`src/ui/danger_edge.gd`:190): no method
- `EventDef`: `speed` read (`src/ui/danger_edge.gd`:213): no method


## Verified

At parity: the excitement fingerprint probe, which prints what every source charges her each tick, its caret and
whether it holds a rim, prints the same lines (but for its cost line) on `origin/main` and at the head; `tools/check.sh`
boots clean; the field-read check against `origin/main` passes with two listed lines fewer; the typing census, the layer
check and the override check pass; the halo's, the badges' and the danger cues' suites and every other that names the
changed classes pass, the halo's again after the merge of main; CI is green.
