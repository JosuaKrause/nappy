# minty-quail — The plan record is EventPlan, in a file of its own · 2026-11-11

**The ask.** The event scheduler is broken up along the design review the player approved ("I saw
the review and approved it", inbox #1268 in olive-ferret), and its first pull request is the
scripted rename of the plan record, nothing else (`scheduler-breakup.md`). A read that only moved
may add its line to the field-read list (inbox #1350 in grassy-trout).

## What was built

- **The plan record is `EventPlan`, in `src/events/event_plan.gd`**: the inner class
  `EventScheduler.Planned`, one placed event's row, position, role and path, lifted out whole by a
  script, every use of the old name renamed, no member renamed and no forwarder kept. The script,
  safe to run twice, is in pull request #1368's description, so a branch that merges main reruns it.
- **The field-read check sees the plan's fields** for the first time: `tools/field_reads.txt`
  gains the plan's readers under `[EventPlan]` and the row's fields read from the new file, and loses
  two lines the scheduler no longer reads; `--base` passes them as reads that moved, and no read was
  converted.
- **`is_permanent()` is deleted**, with its clause in the plan's suite: only that suite read it, and
  the class's own `spoils()` reads the field. The suite is `tests/test_event_plan.gd`, named for its
  module.
- **The model layer holds the new file** (`tools/layer_map.py`), and the listed break "the day's
  planning reaches into the live event for its placement rules" counts one use in the scheduler and
  one in the plan; `docs/ARCHITECTURE.md` lists the file. The events skill's two sentences that
  named the old class, and the queue's sentences that called the rename pending, say `EventPlan`.

## Choices open to overturn

- **`is_permanent()` deleted** rather than kept for its one test, and **the suite renamed** for its
  module (the planner's).

## Verified

At parity: the excitement fingerprint, the tick sweep's chain and the placement rows hash the same
on the base and the head. The unfiltered suite ran locally before the push, with no failure, since
the rename changes the shared rigs; `./tools/check.sh`, the layer check, the field-read check, the
test-only members check and the lint pass.
