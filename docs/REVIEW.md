# Review

**What waits on a human.** Everything here is built, measured by a rig, and unfelt: a person has
to play it, look at it, or decide about it. *(2026-09-11: "keep a document with items that need
human review / test runs. That way you can keep working without having to stop. And test runs
can capture multiple items at once.")* The work goes on while this list waits, and one run
answers as many of these as it passes through.

**How it is kept.** Each item is a file under [review/](review/), named after the queue entry
whose work it asks about (`<entry name>.md`, and `<entry name>-2.md` for a second item from the
same entry). It enters when work lands that only a person can judge, in the same PR as the work,
and names what to do, where to look, and the question a run answers — not what was built, which
is the record's under [decisions/](decisions/). A playtest closes the items it covered: the
finding goes in the playtest's file, the item's file is deleted in the same commit, and what the
player asked for goes to the queue. Nothing here is a task; a task is an item under
[todo/](todo/). What a rig has measured and no person has felt yet is an item like any other.

## Next run, in one sitting

Each file under [review/](review/) is a thing to try or look at and the question it settles.
`tools/run.sh` plays the desktop build; `--seed <n> --day <n>` puts a run where an item says; `1`
to `5` in a debug build toggle the field, shadow, bounding-box, readout and route-line layers
(`docs/TELEMETRY.md`, "The debug view"). `--invincible` is the way to walk the whole list in one
sitting: nothing ends the day, the clock stands still and the excitement meter never rises, so one
run can stand next to every item for as long as looking takes.
