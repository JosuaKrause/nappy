# breezy-lark — A lost day names its own cause, in one event · 2026-09-26 · not from an entry

*(Reading the counter back for a run whose day 7 was lost four times — 2 × `lost-crying`, 2 ×
`lost-hard-fail`, beside 2 × `instant-alley-robbery`, 1 × `noise-alley-robbery`, 1 ×
`noise-traffic`: "lost-crying still doesn't tell me anything about how they died". Offered: fold
the cause into the loss's own name. The player: "yes, separating out hard fail vs noise from the
reason doesn't help anything and if you want only the hard fail counts you can do a filter by
prefix. the old version only affects one playthrough.")*

**What is built.** A lost day sends one event whose name carries both the loss kind and its
cause, instead of a `nappy-day-N-lost-*` beside a second `nappy-day-N-instant-*` /
`nappy-day-N-noise-*` of its own:

- `nappy-day-N-lost-crying-<source>` — `crowd`, `traffic`, `self`, or a catalogue id, whichever
  landed the most on her over the crying window.
- `nappy-day-N-lost-hard-fail-<what>` — `car` for the one hard fail that is not a catalogue row,
  otherwise the striking row's own id, hyphenated.
- `nappy-day-N-lost-timeout` — unchanged, no cause: the name already says everything about a
  clock that ran out.

`main._on_day_finished()` still emits `EventBus.day_lost_to(day, cause)` just before `day_ended`,
now with the raw, unprefixed cause (`_hard_fail_cause_suffix()` and `_crying_cause_suffix()` no
longer prepend `instant-` / `noise-`). `VisitCounter` no longer sends an event from
`_on_day_lost_to()` itself; it holds the cause in `_pending_loss_cause` and reads it once from
`_on_day_ended()`, which is where the one combined event is sent
(`VisitCounter._loss_event_suffix()`). The fold only ever applies to `LOST_CRYING` and
`LOST_HARD_FAIL`; a `WON` or `LOST_TIMEOUT` day sends its bare name even if something were still
pending, and a `LOST_CRYING`/`LOST_HARD_FAIL` day this counter never got a cause for — reachable
only by driving `_on_day_ended()` without a preceding `_on_day_lost_to()` for the same day, which
nothing in `main.gd`'s own wiring does — still sends the bare `lost-crying` / `lost-hard-fail`
rather than nothing.

`tools/goatcounter.py`'s funnel groups every day's `lost-*` keys under one "Lost" heading with a
subtotal per kind (crying/hard-fail/timeout) and the per-cause lines under each, sorted the same
count-descending way as everything else the day sent (`split_losses()`). The old two-event shape's
bare `lost-crying` / `lost-hard-fail` (no cause — the player: "the old version only affects one
playthrough") needs no special handling beyond still being listed: it folds into the kind's own
subtotal with no cause line of its own, since it carries no cause to split out.

**Verified** headless: `tools/check.sh`; `tests/test_visit_counter.gd` (the fold, the bare-cause
fallback, and that a pending cause never leaks into `WON`/`LOST_TIMEOUT`) and
`tests/test_day_lost_to.gd` (the now-unprefixed cause suffixes); `tools/pycheck.sh`, including
`tools/test_goatcounter.py`'s new `SplitLossesTests` and the `format_text` cases for the "Lost"
heading and the old bare shape; `tools/lint.sh`; `tools/test_cli_help.sh`.

**Choices left open to overturn**: the funnel's "Lost" heading is a synthetic label, not a real
GoatCounter path — a reader wanting the raw per-cause paths still has `--raw`. The heading sorts
among `won` and everything else the day sent by its own total count, same as any other entry.

**Left out**: no change to what counts as a cause — the crying tie-break and the `self` fallback
`main._crying_cause_suffix()` already had are unchanged, only unprefixed.
