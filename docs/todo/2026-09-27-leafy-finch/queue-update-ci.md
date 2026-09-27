**CI runs every mechanical check of a queue update** (statement 9), where a queue update is a PR
whose every changed file is under `docs/todo/`, `docs/review/` or `docs/playtests/`. As close as
possible to the checklist the pr-review skill gives its narrow review today:

- **No existing playtest file changes.** Any change under `docs/playtests/` other than an added
  file fails.
- **Nothing open disappears unaccounted for.** A deleted item file or entry folder under
  `docs/todo/<entry>/` needs its entry's decision record on `main` already, or a line in the PR's
  description, `Dropped: <path> — "<the player's words>"`, whose quoted words appear verbatim in a
  file under `docs/playtests/`. A deleted review item needs a playtest file that names it.
- **The queue still reads.** `./tools/lint.sh` passes, and `tools/queue.sh`'s lines for every
  entry the PR touched go into the job's summary for the reviewer to read.

Any failure names the file and the rule. The reviewer still verifies what CI checked — that a
record which exists covers the item deleted, that a quote says what the drop claims — since a
script can see that a record exists, not what it says (statement 9: "the CI is only a help").

**Proposed, not asked for:** the `Dropped:` line's exact form.
