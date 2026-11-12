# minty-quail — The frame-record wiring suite reads what each timed system records · 2026-11-12

**The ask.** A suite tests the one module it is named for (inbox #1159 in gray-dolphin), and the frame-record wiring
suite checked that `main` hands the sitting's frame record to every timed system by reading each hand-in back, which a
getter only this suite called would fail (`tests-one-module.md`, "The order", the telemetry entry and its *Read as*).

## What was built

- **`tests/test_frame_record_wiring.gd` reads what each timed system records**: after real frames, the record's own rows
  hold the baby's sweep over what is near her, the events' time, and the scenery's time with at least one update, which
  she walks south from her doorstep to cause, since the scenery updates only once the view moves. The screen edge's
  badges and the halo share one bucket, so each is read with the other switched off, and with both off it reads zero.
  The six comparisons of a hand-in with the record are gone.
- **Each check fails without its wiring**: the builder removed each of the five hand-ins in `main.gd` and `city.gd` in
  turn, and each removal turned only its own check red.
- **`Baby.timing` goes private as `_timing`**, behind `use_frame_timing()`, which `main` calls; no method is added.
- **Left public**: the city's, the scenery residency's, the event manager's, the screen edge's and the halo's
  `timing`, each written from another file under `src/`, which its module's field-read pass converts with a hand-in.
- **The queue loses the telemetry entry**, the entries after it are renumbered with the two references to them in
  `event-interface.md` and `city-hand-ins.md`, and `field-reads.md`'s bullet on her and the baby's parts keeps only
  `Stroller.atlas`.

## Verified

`tools/check.sh`, the field-read, test-only member, layer and typing checks and lint pass; the wiring, frame-record,
baby, meter, halo, danger and badge suites pass; CI is green.
