# minty-quail — The look's other readers read a recording drawer, and the live event's look is private (row 5) · 2026-11-23

**What was asked.** Row 5 of minty-quail's `event-interface.md`, the live event's looks' readers (the records
minty-quail-pebbly-plover and minty-quail-grassy-quail split them off): every suite and probe that read the live event's
`look` reads what a look shows another way, and the field goes private. Built as #1649 by a Sonnet agent.

**What was built.** The stride suite asks a look made round a `FakeEvent` with the stride set from the dog walker's
table, and the live event's own stride of a real event; the drawn view's gate cases a look round a fake, its twin case a
counting excitement source; the pursuit's robber what his look is handed; the police car and fire truck their picture's
foot off the recording drawer on real frames; the barrier, draw layers, halo and scenery suites their slices, band and
rim through the drawer (`RecordingEventDrawer.slices()` added); the no-pop-in and traps suites and the probes a look
round `FakeEvent.answering_as(instance)`, a fake that copies what a real arrival answers; the frame record keeps the real
look behind a counting drawn view. Then `EventInstance.look` is private, and `SpreadLook.slices()`, left with no
reader, is gone, as is the public `EventLook.drawn_heading()`, which only its own file and an override read. The look
fingerprint probe's summary lines come from a look round a copy, so they drop the drawn heading, which only the live look answers
(a posted guard faces out from his post); its picture lines still show what the live look draws. A suite that copies a
real arrival's answers into a fake says why and what the copy leaves out, and a suite fails when the fake gains an
answer the copy does not take.

**Measured.** On CI the converted suites' times moved within a run's noise but for the no-pop-in suite, 16.7 s on main
and 18.4 s on the branch, since it makes a fake per arrival. The look fingerprint's summary lines changed at this merge,
so a later step's base for that probe is taken at or after it; its cost line now times the event's whole frame step
(270 ms against 254 ms on main for the same calls, one run each), so a reading across this merge compares different
work.
