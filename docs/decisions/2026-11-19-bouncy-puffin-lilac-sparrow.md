# bouncy-puffin — The suites read the region plan through methods, and its fields go private · 2026-11-22

**What was asked.** The entry bouncy-puffin, from the design of minty-quail's row 3a: every reader under `src/` asked the
routes' region plan (`RegionPlan`) and a checkpoint boom's shared state (`GateState`) through methods (the record
bouncy-puffin), but the suites, their rigs and the probes still read and built them field by field, so nine fields
stayed public. Fields are not API (inbox #1173 in gray-dolphin), and minty-quail's list was frozen, so it was its own
entry (inbox #1268 in olive-ferret). Built as #1644 by a Sonnet agent.

**What was built.** A scripted pass turned every plan field read in the suites, rigs and probes into the method the
entry named; the two suites that build a plan by hand use its `add_*` methods, and a gate built at a point is
`GateState.new(at)`; the seven plan fields and the gate's position and boom flag are private, and their lines in the
test-only list are gone (eight: the gate's position never had one). No method was added, and no suite's expectation
moved.
