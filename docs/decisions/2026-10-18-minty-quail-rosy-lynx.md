# minty-quail — The danger badges, the run log, the crowd and the city ask an event through methods · 2026-11-09

**The ask.** "provide a consistent interface for events that can be used without knowing details of
the event", "never read fields directly. always read through a method" (inbox #1173 in gray-dolphin). The design
is the queue item `docs/todo/2026-10-18-minty-quail/event-interface.md`; this record is its first
step, the callers outside the events folder.

## What was built

- **The danger badges, the HUD, the run log's observer and map, the crowd, the day's streets, the
  poster walls and the building's plan ask an event through methods.** Nine files hold no read of a
  field of an event's row, its plan, its live event or a pending warning, apart from the two below.
- **The questions they ask were added to the four event classes**, under the design's names and
  answering from the fields as they stand:
  - the row (`EventDef`): whether its coming is announced (the badge's rule, moved from the badge's
    own model), how fast it closes, how far it is heard, whether it ends the day, its picture, how
    long it telegraphs, how often it comes again, whether it detains her;
  - the live event (`EventInstance`): its row and the row's name, whether it is gone or on its way
    out, whether she was warned of it, whether it pursues, drives or ends the day, how long it
    telegraphs, whether it closes on a point, whether its field reaches a point, whether it has
    given up;
  - the plan: whether it detains her, how far it obstructs, whether it ends the day, whether its
    field reaches a point, and the four things the building's plan tells it (how often it comes
    again, when it first comes, that it comes where she stands, that it arrives aged);
  - the pending warning: its row, where it points, how long it has left.
- **A live event and a plan ask the row's methods and not its fields**, so the new methods add no
  line to the list of field reads; 22 lines left it.
- **Only the questions these nine files ask were added.** A public method nothing calls is
  unreached code; the questions of the later steps come with their callers.
- **Nothing the player sees and nothing the logs say changed**: the run log's recorded baseline is
  line for line identical.

## What is left of the step

- **Two reads stay, because a method and a variable cannot share a name in GDScript** and both
  fields are still public for other callers: the plan's role, read by the run log's map, until the
  dawn's step makes the plan's fields private; and the row's speed, read where a badge is made
  for a warning with nothing in the world yet, until rows are written as parts.

## Choices the builder made where the design was silent, open to the player's overturn

- **A warning with nothing in the world yet is logged with the row's plain speed**, which for a
  pursuer warned of first is 0 and not its chase speed, as before. It is kept for parity, like the
  three answers the design lists as slightly wrong.
- **The building's plan writing when an event first comes** has no name in the design; it is
  `come_first_in(seconds)`.
- **The badge's subject stays a plain record** that carries answers in place of nine copied
  settings.

## Measured

Taken by the builder with the machine heavily loaded by other work, the base always run before
the branch, so order and load are not separated from the change:

- **What every source charges her, tick by tick** (the excitement fingerprint): identical on the
  base and the branch in three pairs of runs.
- **The events' step and the baby's sweep per tick** (`tests/probes/m159_tick_sweep_events_cost.gd`,
  72 runs a pair, three pairs): the state chain is identical on all runs. The times are higher on
  the branch: the events' step by 37%, 62% and 33%, the baby's sweep by 59%, 70% and 31%. So are
  the times of code the change does not touch: streaming by 39%, 65% and 49%, and the crowd's
  source query, the control, by 17%, 71% and 37%. As measured, the rise cannot be attributed to
  the change.
- The probe fails six of its own checks on one seed and day, on the base as on the branch.

The player's word on cost (inbox #1278): the clean design is built whatever it costs, and the
numbers are there to know where to look. A clean pair of runs, alternated and on a quiet machine,
is taken with the baseline measurements (`baseline-measurements.md`).
