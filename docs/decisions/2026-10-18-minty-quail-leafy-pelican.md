# minty-quail — The city's test-only members go internal · 2026-11-12

**The ask.** A public member only its own class and the tests use becomes internal, its tests checking what the class
does from outside, one staying public only where nothing outside can confirm the behavior, with its reason written
down (curly-rabbit #1098); a member nothing in the game reads gets a reader, is tested through what the game shows, or
is deleted (curly-rabbit #1095). This pass takes the city's twenty-five lines, and the scenery layer's two fields
`field-reads.md` names.

## What was built

- **Private, twenty**: the block layout's `playground` and `has()`, the building's `front_drawer`, `roof_drawer`,
  `neighbor_taken` and `shape`, the shadows' `skip_draw`, the decals' `atlas` and `drawer`, the city edge's and the
  traffic light's `atlas`, the generator's `validate()`, the map's `dead_ends` and `is_held()`, the city state's
  `trace`, the poster art's `sheet()`, the poster walls' `art`, the scenery layer's `frame_b` and `drawer`, and the
  water's `elapsed`. The tests read outward behavior: drawers and atlases handed in through the game's hand-ins, the
  collision child physics reads, what a recording drawer is asked to draw, the ripple shader's parameter.
- **Deleted**: `MarbleBag.sizes()`; the bag's checks read `left()` around drawing it empty.
- **Kept, with reasons on their lines**: the residency's `budget_usec` (a one-microsecond budget is the only way to make
  each update run one job, so the spill-over can be counted without timing the machine), the water's `cells` (drawn
  straight on its own canvas through no drawer), and the street trees' `runs()` (a run's tree-less street is missing
  from the planted trees, so the run shape cannot be read back).
- **Checks removed as holding nothing** once their member is private, five, each named in the description.
- **Left open**: `CityMap.copy()`, whose only user is the tests' per-process city cache; its `[no reader]` line stands
  while the choice is put to the player (a kept line, deleting it at a cost in suite time, or a game reader).
- **The queue item's paragraph on the scenery layer's two fields goes.**

## Verified

The builder broke eight behaviors and saw each converted check fail; `tools/check.sh`, the field-read, test-only
member, layer and typing checks and lint pass; the 43 touched and city suites pass; CI is green.
