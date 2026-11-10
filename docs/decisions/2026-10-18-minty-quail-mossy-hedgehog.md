# minty-quail — The footprints ask the row what its pictures and its body are (minty-quail, the events' interface) · 2026-11-10

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin). The events' interface design's row 2b, "the looks ask the live event and are handed
their settings" (`docs/todo/2026-10-18-minty-quail/event-interface.md`), is built as six pull
requests, a cut a Fable planning agent made and no tracked file holds; this is the footprints'
part, built beside the base look's (minty-quail-tall-toad) after the picture probe
(minty-quail-polite-newt).

## What was built

- **`EventFootprints` reads no field of its row, of the live event (`def`) or of `GroundShape`**;
  no signature changed. It asks the row's existing `picture()`, `ground_shape()`,
  `rounding_radius()`, `has_a_body()`, `obstructs_within()`, `drives()`, `has_a_field()` and
  `ends_the_day()`, and six new questions: `drawn_width()`, `lies()`, `is_a_flock()`,
  `casts_a_shadow()` (the same insertion the base look's pull request makes), `drags_a_lead()` and
  `vanishes_into_its_hold()`.
- **`lies()` answers a new enum, `EventDef.Lie`** (as it faces, as a spread, along its street,
  across it), testing the row's three flags in the order the footprints tested them; no row sets
  two, each of the fourteen that set one being its own catalogue function, and nothing but the
  catalogue writes one.
- **`event_pictures.gd` is typed** and loses its first-line opt-out (one loop variable typed).
- `tools/field_reads.txt` lost 15 lines and gained none; `flock_spread` and `warning_picture`
  stay listed reads, as the brief said.

## Parity

The run log is line for line what it was (`tools/test.sh observers`), and the cost table is
unchanged (`tools/cost-table.sh --check`). On `main` at `651606332`, the commit this branch was made
from, and on the code commit `669997cba`, each probe gives one hash: what every source charges her
(`probes/excitement_fingerprint.gd`, its `XF` lines less `XF_COST`), every event, crowd agent and
meter on every tick (`probes/m159_tick_sweep_events_cost.gd`, the `chain` values), and what every
row's look draws (`probes/look_fingerprint.gd`, its `LK` lines, the file from its own pull request
at `943ed9d8b`, the same in both trees).

## Choices the builder made where the design was silent, open to the player's overturn

- **`lies()` returns one of four as an enum on the row** until the body part exists, where the
  design names the body part's `lies()`.
- **The look's settings get the names `casts_a_shadow()`, `drags_a_lead()` and
  `vanishes_into_its_hold()`**, the planning agent's picks, since the design's 4.1 gives none.
