# minty-quail — The looks drawn on the event's own canvas ask through methods · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and a component is handed what it depends on (minty-lemur #794). Row 2b of
`event-interface.md`, the looks: after the probe (minty-quail-polite-newt), the footprints
(minty-quail-mossy-hedgehog) and the base look handed its row and drawer (minty-quail-tall-toad),
this is the six looks that draw on the event's own canvas.

## What was built

- **The figures, the pursuers, the vehicles, the flock, the checkpoint and the fire**
  (`figure_look.gd`, `pursuer_look.gd`, `event_vehicle_look.gd`, `flock_look.gd`,
  `checkpoint_look.gd`, `fire_look.gd`) read the row and the drawer they are handed and the live
  event's methods, and otherwise only what "Reads left" lists.
- **Three questions are new**: `EventDef.core_within()` (how far the field's core reaches, asked by
  the looks), `EventInstance.is_drawn_as_a_pelican()`, and
  `EventInstance.how_long_its_victim_has_walked()` beside `is_taking_a_victim()`, which answers 0
  for an event with no take running, as a live event without a part answers that part's questions
  with nothing. The fire's
  strength is the base look's `_share_of_its_peak_now()` floored at 0.2, the same number; the van's
  victim's share of her walk is worked out once and used by both the slide and the stride.
- **`guard_warns_her` is private**; the three suites that read or wrote it ask
  `is_its_guard_warning()` or tell `raise_its_guards_hand()`, and the two comments that named it
  name the question.
- **`Bird.view_sector` is deleted**, with its place in the flock's save and restore: the flock's look
  holds each bird's view sector itself. `docs/EVENTS.md` and `docs/GRAPHICS.md` name the method where
  they named the field. `tools/field_reads.txt` lost 27 lines.

## Reads left, each with its reason

- The live event's `age`, twice in the fire's look: its natural name is the field's.
- The flock look's reads of a bird (`at`, `lift`, `heading`, `phase`): `Bird` is an inner class the
  field-read check does not see, and four suites read the same fields, so they stay until the
  suites' rewrite.
- The row's `abduction`, read three times by the van's look, and that spec's `taken_over` and
  `standing_offset`: the spec's own fields under their own names, until the look is handed the spec.

## Parity

The look probe's `LK` lines (`a12e4cc9…`), the excitement fingerprint (`7510c1d0…`) and the events
tick sweep's chains (`bf69e949…`) hash the same on `main` at `8c624413a` and on the code's head.
The dog walker's reach and the abduction's slide and offset changed their receivers only. The
fire's strength changed its expression, `maxf(0.2, _share_of_its_peak_now())` for the old clamp,
the same number in every case, a zero or negative peak included. The look probe sees all three
through the pictures they place; the dog's lead and the shadows are drawn where it does not look.

## Open to the player's overturn

- **A bird's first view sector** is the one nearest its heading when the look first sees it, not
  the value 2 the brief named: `build()` overwrote that 2 at once, so it was never in effect. It
  differs only for a flock first drawn some seconds after it was built, or restored, and only for a
  bird whose heading sits inside the turn's hysteresis band; none of the probes sees it. Keeping it
  exact would need the per-bird field the brief deletes.
- **The builder's names**: `how_long_its_victim_has_walked()`, `_victim_walk_share()`,
  `_held_sectors` and `_see_every_bird()`. `core_within()` and `is_drawn_as_a_pelican()` are the
  design's.
