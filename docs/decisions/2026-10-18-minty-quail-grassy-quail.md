# minty-quail — The looks are tested round a fake event (row 5, the looks' first part) · 2026-11-22

**What was asked.** Row 5 of minty-quail's `event-interface.md`, the live event's looks (the record
minty-quail-pebbly-plover split them from the live event's suites): a fake live event for the later groups, the drawing
suites reading what a look shows off a recording drawer or a look made round the fake, and the live event's `look`
private. Built as #1647 by a Sonnet agent.

**What was built.** `FakeEvent` extends the live event and overrides each of the questions the looks ask of their event,
each override checked against the interface, answering what a test set; its answers were read off a real event first. A
look is made round it with `EventLooks.for_row()`. The redraw and view suites ask a look round a fake, or read a real
event's pictures through the recording drawer, and no longer read the live event's look; their cases about other
modules moved unchanged to the phase, behaviours and excitement source suites. The field-read groups for the charge
record, an event's behaviour, a flock and the warning are gone, their fields private behind methods.

**Split.** The other readers of the look, about a dozen suites and five probes, are the next pull request, and the look
goes private there; the crowd car's drawing suite is the crowd's, with the event halves held in other modules' suites.

