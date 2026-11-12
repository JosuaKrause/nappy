# minty-quail — The crowd's test-only members go internal · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal, its tests checking what the class
does from outside, one staying public only where nothing outside can confirm the behavior, with its reason written
down (curly-rabbit #1098); a member nothing in the game reads gets a reader, is tested through what the game shows, or
is deleted (curly-rabbit #1095). This pass takes the crowd's eighteen lines.

## What was built

- **Deleted**: `Crowd.pockets()` and `CrowdPockets.tile_count()` (the sealed-junction guard floods its own pockets and
  asks `holds()`), `Crowd.field()` (its readers build their own field over the same map or read what the crowd does),
  `AgentLook.sector()`.
- **Folded into `picture()`**: the walker's and the car's `sector()` and the walker's `gait_frame()` go, and a body is
  drawn from what `picture()`, the redraw key the agent already asks, answers, so the sector is worked out once.
- **Private**: the car look's `travelled`, the car turn's `radius` (tests read its length and build real arcs), the
  agent's `colour` and `skip_draw` (the run-config suite counts the crowd's pictures asked of an atlas handed in), the
  field's `centre`, `city_view` and `uniform_walkers`, the lane mover's `strategy` and `gap_ahead` (through its lane),
  and the door hold's `inside`.
- **Kept, with its reason on its line**: `CarLook.body_anchor`, the point a car's picture is registered at, handed only
  to a draw a headless run draws nothing for; a drawer handed to the crowd's looks would let it go. The misread line
  `crowd_field.gd radius` goes, its readings gone with the car turn's field.
- **Each converted check fails when its behavior breaks**: the builder broke fourteen in turn; one new check that did
  not fail was dropped for the coverage suite's existing one.

## Verified

`tools/check.sh`, the field-read, test-only member, layer and typing checks, pycheck and lint pass; the 61 suites naming
a crowd class or rig pass; CI is green.
