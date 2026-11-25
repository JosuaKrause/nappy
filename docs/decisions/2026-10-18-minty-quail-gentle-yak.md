# minty-quail — The crowd's fields read through its methods · 2026-11-18

**What it is.** The crowd's part of minty-quail's `field-reads.md` conversion (the crowd is among
the modules that do not wait for the events): the fields of `Crowd`, `CrowdAgent` and `LaneMover`
read from outside their files, fifteen lines of `tools/field_reads.txt`. An Opus builder designed
and built it. It changes nothing in play.

**What was built.** `Crowd.sources` is private behind `sources()` (the live set) for the world
simulation and the run log's session; `CrowdAgent.excitement` is private and its readers (the day
director's tally, the debug layers) call `mood()`, which the agent already had; `LaneMover.shape`
is private behind `shape()` (the live shape) for the debug layers' shadow outline; every reader of
`LaneMover.kind` outside the crowd asked only car or walker and calls `is_car()`. `mood()` and
`shape()` hand out the live object, so the per-agent tick and the shadow drawing allocate nothing.
`tools/field_reads.txt` lost ten lines and gained none.

**What is left, and why.** The five settings the simulation builder writes into the crowd (`view`,
`timing`, `atlas`, `skip_motion`, `skip_agent_drawing`) and `LaneMover.kind` keep their direct
write: the game's only outside touch of each is that write (or the agent's own setup), and suites
read them, so a method would leave them public for tests alone, which
`tools/check_test_only_members.py` fails. They join the item's group of fields only a test reads.

**Proposed, not asked for, open to the player:** `mood()` rather than a new `excitement()` getter,
since `mood()` already existed with 79 callers and two getters for one value is the legacy shape
minty-quail rules out; the five settings kept as fields rather than one configure method; `kind`
kept public with `is_car()` on `LaneMover` for the game's readers.
