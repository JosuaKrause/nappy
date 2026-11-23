# minty-quail — The live event's suites build one event, not a city (row 5, second group) · 2026-11-22

**What was asked.** Row 5 of minty-quail's `event-interface.md`, its second group: the live event and its parts' suites
test the live event, with one real event on open ground or a hand-drawn map and fakes around it, never a city (inbox
#1156 and #1159 in gray-dolphin). Built as #1646 by a Sonnet agent.

**What was built.** The pursuit suite's wall cases stand on a small hand-built map, not the shared generated city; the
police car's on a street map; the protest's live cases on open ground with a recording drawer. Every case that tested
another module's question moved unchanged to that module's suite: a failed lesson's retry to the event's parts, the
warned cyclist and a parked body's route to the manager's suite, two day-planning cases to the scheduler's, the
protest's two director cases to the resistance's steps; the police car's run-log case was rewritten to build no city in
the run log observer's suite.

**Split.** The group was too large for one pull request: the drawing suites, the fake live event they need, the live
event's look going private, `behaviours()` and four field-read groups are the group's next pull request, the live
event's looks. The chat suite needs a real manager because the manager's tick starts the hold, so it is the manager's
group's; the car front suite's subject is the crowd's cars, so it is with the event halves held in other modules'
suites. The phase, behaviours and car driving suites built no city; the first two still read the live event's `behaviours()`,
which goes with the group that converts its last reader.

**Measured.** On CI, the four converted suites (pursuit, police car, fire truck, protest) took 38.2 s on main and 7.5 s on
the branch; the scheduler's suite, which took the two moved day-planning cases, grew by about 27 s.
