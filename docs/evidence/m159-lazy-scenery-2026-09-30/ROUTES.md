# M159 — Coverage of the routes the game offers

The game's generated daily routes are the primary expected-workload model, as the player asks
in [gentle-swan](../../playtests/2026-09-30-gentle-swan.md). The alternatives are blocked or
discouraged; unrestricted base-map BFS is not an adequate substitute. This correction measures
the actual daily route objects after Main plans the day's closures and events. It leaves the
separate accepted preparation/memory experiment unchanged.

Across two seeds and days 1, 8 and 12, the union of the generated network plus home covers
**35.9–59.8% of prepared static ground** at the modeled viewport positions. Individual offered
options plus home and their calm entry cover **3.9–29.8%**. These are materially broader than
the earlier 3.4–8.0% BFS stand-ins. A player taking one option and retracing it does not visit
the union of every option. We assign no usage weights and claim no observed human trajectory.

| Seed | Day | Calm branches / options | Daily closures | Network + home ground / prepared | Coverage | Individual option ground range | Network + home building lots / prepared |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 4242 | 1 | 9 / 15 | 1 | 11,927 / 22,866 | 52.2% | 897–5,130 | 120 / 158 |
| 4242 | 8 | 9 / 15 | 3 | 11,430 / 22,866 | 50.0% | 977–3,420 | 115 / 158 |
| 4242 | 12 | 9 / 15 | 4 | 13,674 / 22,866 | 59.8% | 1,177–6,814 | 128 / 158 |
| 3265820891 | 1 | 8 / 12 | 1 | 12,771 / 23,083 | 55.3% | 1,081–6,768 | 115 / 150 |
| 3265820891 | 8 | 6 / 10 | 3 | 13,003 / 23,083 | 56.3% | 1,069–5,610 | 123 / 150 |
| 3265820891 | 12 | 5 / 8 | 4 | 8,285 / 23,083 | 35.9% | 1,073–3,348 | 86 / 150 |

Adding the calm entry tile to every option changes the all-options union to 11,957; 11,451;
13,690; 12,771; 13,034; 8,290 ground cells, respectively. Expanding the network+home viewport
by 46px in every direction gives 12,622; 12,139; 14,521; 13,571; 13,917; 8,944. This separate
look-ahead envelope is conservative for all facing directions; it is not a simulated camera.
The nominal percentages above do not include that expansion.

## What is measured

The production `RouteTree` grows one branch per eligible calm area and one or two route options
per branch: a loop-erased random walk toward home, then a distinct second route where possible.
Shared stretches are deliberate. Each stored option is an ordered sequence of 2×2 reachability
cells from the calm access cell toward home. The tree also owns a home connector and any task
spur; it is not a list of independent shortest paths. The
[grid design](../../decisions/2026-09-03-M69-reachability-is-a-grid-of-two-tile-cells.md) and
[home-connector design](../../decisions/2026-09-04-M64-the-doorstep-reaches-the-corridor-and-a-wrong-turn-can-be-taken.md)
carry those constraints. The live source, rather than an older depiction of the route lines,
determines this collector's semantics.

The probe boots real `scenes/main.tscn` with the requested seed/day and `--no-save`, completing
the two shader-warmup awaits synchronously just as the existing camera test does. Main then
owns route creation, region planning, street closures, seals, events and crowd initialization.
The probe reads that finished dawn state before active simulation. Each sample starts a fresh
process with scheduled day state and no fabricated history of settled calm areas or resistance
progress. These are representative generated dawns, not six played days in a continuous run.
Day 14 is omitted because the escape uses a different planner and is outside this daily-route
coverage correction.

For the **network**, camera centers are all open tile centers belonging to actual colored
ReachabilityGrid nodes in that day's RouteTree. A 2×2 cell can contain multiple disconnected
components, so the collector checks the exact node identity rather than assuming its whole
square is walkable. Daily `map.is_open()` is checked after closures. All sampled generated
candidate tiles are open; the zero blocked count is checked, not assumed. This does not certify
that every tile center is free of an event's body or safe under its field.

For **network + home**, add the actual generated home-frontage nodes and doorstep. Branch
routes intentionally end before the doorstep. Including all open home-frontage tile centers
provides a connector envelope without inventing a straight line across a road or a substitute
shortest route. The network includes connector/task-spur nodes even when absent from a stored
calm option.

For **each of the 75 stored options**, take its generated cell sequence and only matching
branch-colored node tiles, add the home-frontage envelope, then add the actual calm entry tile
selected by production `RouteLines._calm_endpoint_tile()`. The corresponding itinerary family
is outbound along that option and a return along the same option; retracing adds no new view
positions. It remains an envelope over positions within the generated cells, not a unique
tile-by-tile walk the planner never specified. Returning on another option, switching branches,
or wandering inside the calm area can add coverage. The union of all options is a separate
quantity and is never described as one route.

At each center the collector unions static ground cells intersecting a 640×360 world viewport
and building lots intersecting that viewport. This matches the initial study's counting unit:
water is separate, cells under buildings can be blank, and a building lot is not its exact art
bounds. There is no raster visibility/occlusion test, camera smoothing, movement, cost or survival
simulation. The 46px look-ahead envelope is separate. Roof overhang and full destination-area
exploration are not added to the nominal figures. Actual human choices and deliberately off-path
stress coverage remain unmeasured; the old unrestricted BFS examples are ancillary geometric
examples and are not relabeled as actual off-path player runs.

## Implication for nearby preparation

The actual offered network covers much more scenery than the stand-ins. Therefore those
stand-ins cannot support a claim that a normal run sees only 3.4–8.0% of prepared ground.
The generated options still support preparing a small moving neighborhood and evicting distant
visuals: even the widest network union is a lifetime opportunity across many choices, not a
simultaneous resident set. The measured preparation and allocation savings remain those of the
original detached-layer counterfactual. This coverage correction establishes no additional time,
memory, frame-rate or phone improvement and changes no route-planning behavior.

## Reproduction and validation

[routes.json](routes.json) retains all six network rows and all 75 option rows, exact commands,
source hashes and capture revision `25e34fa02a7b7271748f9a19634a879da545b29e`. Capture runs
serially on the same Apple M2/macOS/Godot 4.7.2 headless environment as the preparation study,
before the unrelated engine compilation. Source is tracked-clean at capture and hashes match
afterwards. This is geometric coverage; boot messages' incidental timings are not retained as
new performance measurements. Four integrity checks pass per boot, with no warnings/errors.
Every retained row is independently decoded and compared against its original scratch stream.

```sh
task_root=$(mktemp -d)
git fetch origin refs/pull/444/head
git worktree add --detach "$task_root/source" 25e34fa02a7b7271748f9a19634a879da545b29e
cd "$task_root/source"
export GODOT=/path/to/Godot
./tools/check.sh
python3 docs/evidence/m159-lazy-scenery-2026-09-30/measure_routes.py --output "$task_root/results" --godot "$GODOT"
```

The wrapper rejects a dirty tracked checkout or an existing output directory, supplies
`--no-save`, and applies an external 60-second limit to each of the six serial processes.
Seeds run 4242 then 3265820891; days run 1, 8, 12 per seed. Original raw streams stay in scratch
as `seed-<seed>-day-<day>.log`. Import/boot, focused probe checks, doc lint, whitespace checks,
wrapper help and unknown-option rejection pass. Local verification remains partial; full-suite
CI and independent review are separate gates.
