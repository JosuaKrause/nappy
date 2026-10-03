# Scene recipes

Saved JSON recipes describe exact development scenes. `SceneRecipe.load_file()` returns data
and diagnostics without engine errors for malformed input. `RecipeCityBuilder.build()` returns
the map, resolved world anchors, diagnostics and a construction manifest. The runtime validates
`setup` and `playback` separately before starting gameplay; construction acceptance alone does
not certify events, actors or a promised playback moment.

Validity means the explicit checks already performed by city construction pass. The builder
reuses those checks; it does not prove that some ordinary seed produces an arbitrary complete
arrangement or invent additional generation-probability requirements.

The checked-in `scene-recipes/power-station-hall.json` and `power-station-yard.json` construct
an actual dead-end wall adjoining the station. The first lets the hall cover its facade; the
second keeps the facade beside the fenced yard. Both pass the production placement checks.

## Running and photographing a scene

`tools/run.sh --recipe scene-recipes/trailer-choice.json` starts normal interactive play.
Add `--recipe-mode scripted` to replay the recipe's movement and camera. Both start from the
same setup; free play keeps physical input, the ordinary camera and no recipe deadline. Recipes
disable saves. Day results apply normally; continuing the summary reloads the saved setup,
including its authored day. Escape retry restores that setup too.

`tools/scene-recipes.sh` runs every scene's scripted assertions headlessly and retains logs and
JSON manifests. Repeated `--recipe FILE` selects a subset; `--output DIR` chooses their folder.
`--screenshots` also photographs each scene at its `playback.capture_at` time. This is elapsed
simulation time after the full world and movement start: events, traffic, animation and the
camera advance together during this pre-roll. It is adjustable independently for every scene.
The default is 0.5 seconds. A still shows composition; the headless observations check action.

The trailer shot list's existing `in` is a separate adjustable recording cut-in: the recording
simulates from setup, then trims the picture and audio to that time. `capture_at` chooses a
screenshot moment, not a recording duration or a reset of the movement clock.
The action scenes check movement at their configured cut-in ticks; the title and initial
doorstep framing deliberately start at time zero.

## Activity and playback

`setup` accepts `day`, `parent` (`mother` or `father`), `player` (`at`, cardinal `facing`,
initial `excitement` and `sleep`), `background.crowd`, `signal_time`,
`progression`, named `events`, named `actors`, `posters`, `roof_fixtures`, `seals`,
`gates`, `barriers`, and the day-13 `column` formation.
`tutorial_complete: true` starts after the ordinary control lessons, clearing those prompts
while retaining gameplay warnings. Trailer scenes use this state so the lesson text does not
cover their subjects. Free play uses the same authored teaching state.
Positions name an anchor or give `[world_x,world_y]`. Background activity defaults off.
Only explicit selections install events. The normal event scheduler and director do not fill
authored scenes, in either free or scripted mode. `background.events: true` is rejected;
an omitted or false value selects no automatic events. Pedestrians and cars keep their normal
simulation independently of event selection. Unselected seals and region bodies remain absent.
`background.uniform_walkers: true` gives pedestrian corridors equal selection weight,
including on recycle. `background.walker_multiplier` scales only the recipe's pedestrian
population from the ordinary act count (1–4, default 1). Cars retain their normal count and
street weighting. Both require `crowd: true`; an ordinary day restores the default distribution.
Random crowd cannot accompany pinned crowd actors.
Random background activity requires full extent; bounded scenes use authored activity so their
plain exterior does not acquire context-city actors or collisions.

An event gives `name`, catalogue `row`, `at`, optional `route_seed`, `path` and `age`.
The ordinary scheduler's ground, route, spacing, protected-door and corridor checks accept
its site. An authored path must equal that production route. Director pursuers use the real
ahead-of-player siting. `age` may advance through the initial warning only; active movement is
simulated. Actors give `name`, `kind` (`walker` or `car`), `at`, cardinal `direction` and optional
`speed`; production lane, ground, speed and car-gap checks apply.

`column: {"at":[1904,2064],"direction":"north"}` starts the real three-truck army formation
in its actual main-road lane. Its ordinary formation spacing and rear-truck stopping logic
come from `ResistanceHappenings`; unrelated catalogue spacing does not apply to that formation.
Its observation names are `truck_1`, `truck_2` and `truck_3`. It requires a full day-13 city.
Only the real happening installs the trucks. Their count stays outside the catalogue budget,
as it does in ordinary play.

`seals: [{"segment":[5,4,0],"candidate":"cafe_pair"}]` selects an existing production
seal picture and its exact street. Ordinary day eligibility, off-route street, home and spine
exclusions and tree placement apply. The existing placement supplies both sides of a soft pair.
There is no automatic seal fill or thinning of these explicitly selected pairs.
`gates: [{"segment":[5,5,0]}]` selects an existing checkpoint from the context's eligible
region doors, including its two huts and shared traffic-operated boom. A horizontal street
uses the standard vertical gate. `barriers: [{"segment":[3,5,0],"end":"b"}]` places the
existing roadblock band at that mouth of an off-route street, on an eligible later day.
These fields place production components; they introduce no new scenery or event types.

`posters` gives exact existing wall cells, each with `at` and a day-eligible `kind` (`leader`,
`rules`, `curfew`, `uniform`, `wanted`). The runtime uses production wall eligibility and
`PosterState.paste`; duplicate cells, non-wall ground and kinds unavailable that day fail.
`kind: "escape"`, day 14 and `progression.escape_part: "city"` use the actual escape controller,
carrying pose, two escape routes and heated guard variants. Generated finale seals are not
installed: the recipe selects its own events. `progression.blackout` turns
off the street signals. Supported escape pins are trucks, abduction, roadblocks and explosions.

`playback` accepts a timed `walk` script (the same syntax as `--walk`), `duration` in seconds,
`capture_at`, optional `camera` (`zoom`, `zoom_out`, `zoom_delay`), `caption`, `title` and
`observations`. Each observation has a physics `tick`, named `subject` and `condition`:
`visible`, `moving`, `running`, `carrying`, `pursuing`, or `near` with `at` and `distance`.
The manifest records the engine's physics rate (30 Hz in this project); render FPS does not
change that clock. Failed observations and interrupted gameplay exit unsuccessfully.
`--recipe-validate` builds and checks the initial live setup, then exits;
`--recipe-manifest FILE` retains initial actors, context, classification and observation results.

## Construction schema

The root has `version: 1`, a nonempty `name`, integer `seed`, `extent`, `city`, and optional
`anchors`, `setup`, `playback`, `kind` (`city` or `escape`), `classification` (`normal` or
`fixture`), and `expected_violations`. Unknown construction fields fail. Unsupported requests
are errors, never nearest-position substitutions.

For the whole-city view, `background.crowd_scope: "city"` populates production walkers and cars
across the full map at the ordinary crowd field's area density. It requires `crowd: true` and
full extent; the default `"player"` keeps the ordinary moving field. Recipe manifests report
initial, final and captured population and moving-car counts in each city quadrant. This is an
authored presentation choice for the bustling-city scene; ordinary game density is unchanged.

`seed` belongs to the runtime and background activity. The required `city.context_seed` fixes
the independent construction witness. The generator makes exactly one attempt with that
context; a failed attempt reports its diagnostic rather than searching other city seeds.
Required choices enter the production stage that owns them, before painting or derived
metadata. All unpinned choices use that explicit context. The ordinary no-recipe generator
keeps its existing sequence and retry behavior.

| Field | Meaning |
|---|---|
| `city.main_road` | Exact vertical corridor, with ordinary three-corridor edge clearance. |
| `city.precincts` | Exactly two `[axis,corridor,start,end]` spans, shore first, then inland; axis 0 is horizontal. Ordinary length, boundary and spine exclusions apply. |
| `city.lots` | `[{blocks:[x,y,width,height],purpose:"park"}]` reserves exact lots before random filling. Starting purposes are `residential`, `civic`, `commercial`, `industrial`, `park`, `forest`, `quiet_square`, `courtyard`; multi-block footprints use the ordinary calm-zone shapes or square apartment complex. Counts, home clearance, spine/precinct clearance and calm separation remain production constraints. |
| `city.layouts` | `[{block:[x,y],seed:integer}]` supplies a block builder's own deterministic layout stream; absorbed or replaced pins fail. |
| `city.dead_ends` | `[{segment:[x,y,axis],end:"a"}]` pins an eligible segment and its wall end; `b` chooses the other end. The ordinary generator fills remaining quota. |
| `city.power_station` | `{blocks:[x,y,2,1],door_block:[x,y]}` pins the horizontal landmark and its ordinary eligible door. Industrial ranking, reference-tree exclusion, calm reachability and region separation still apply. |
| `city.closures` | `[{segment:[x,y,axis],kind:"roadworks"}]` authors the day's closures; other kinds are `fallen_tree`, `crash`, `cordon`, `rubble`. An explicit `setup.day` supplies eligibility context. |
| `city.tree_moves` | `[{from:[tile_x,tile_y],to:[tile_x,tile_y]}]` moves an existing street tree and its pit to the opposite curb of the same street. Sources must exist and destinations must be open, clear of the home door and other tree footprints. |

A segment is keyed by its lower-numbered junction and axis (0 horizontal, 1 vertical).
Its `a` end is west or north; `b` is east or south. Positions use the production tile lattice;
world coordinates are pixels, x right and y down. A tile position resolves to its center.

Closure checks reuse the day's candidate pool, kind availability, quota, tree and region
exclusions, and the tile reachability invariant. A fallen-tree closure also requires the
standing tree it removes. A recipe day computes its tree and region context and installs
only its authored closures, leaving activity installation to the recipe runtime.

## Anchors and extent

`anchors` maps names to one of these forms:

- `"doorstep"` or `"power_station_door"` names the production landmark position.
- `{"tile":[x,y]}` or `{"world":[x,y]}` pins an exact point.
- `{"junction":[x,y],"side":"northwest"}` names the sidewalk corner. The other sides
  are `northeast`, `southwest` and `southeast`.

Every anchor must lie inside the declared extent. Runtime placements may refer to the resolved
name. The manifest records the actual points, inputs, validation checks and bounds.

`extent: {"scope":"full"}` constructs and presents the complete city and requires its full
generator guarantees. `{"scope":"bounded","bounds":[x,y,width,height]}` presents only that
tile rectangle. Bounds cannot cut a building footprint. The explicit full construction
witness supplies the global dependencies used by the existing station and closure checks;
the manifest distinguishes this witness from the bounded authored scene. Construction and
route checks run before the exterior projection is enabled.

Outside bounded scenes, plain alley texture is walkable experimental ground. No city boundary
body or camera clamp stops travel out and back. Buildings, shadows, props and litter outside
the extent are omitted. This exterior is neither a generated street nor evidence for any
route guarantee. The data retains its context for dependent validation, while gameplay queries
outside the authored bounds see only the fallback surface.

The runtime sets `map.recipe_frame_locked` before building scripted scenes. Scenery preparation
then completes the camera's whole loading area synchronously and ignores the ordinary CPU
preparation budget, including during a zoom. Free play leaves ordinary streaming enabled.
This removes wall-clock load from scenery readiness; it does not promise frame equality
across engines, renderers, assets or game revisions.

## Deliberate fixtures

Normal recipes accept no waived checks. A fixture must name each exact expected
`city.guarantee:<diagnostic>` string. Every undeclared violation and every declared violation
that does not occur fails. Syntax errors, unsupported fields, broken references, illegal
placement pins and closure refusals cannot be waived. The fixture classification remains in
the manifest even when its expected diagnostics match; it never becomes normal gameplay.
Only generator guarantee diagnostics are fixture-capable in this schema.

`setup.roof_fixtures` replaces the fixtures on individually named production roofs. Each entry
has `lot: [tile_x,tile_y,width,height]` and a `fixtures` array; each fixture has `cell: [column,row]`
and an existing `kind`: `vent`, `hvac_a`, `hvac_b`, `duct_straight`, `duct_corner`, `skylight_a`,
`skylight_b`, `vent_stack`, or `water_tank`. Columns count from the west; row zero is the south
roof lip above the facade. The production interior-cell pool, including roof extensions,
district fixture choices and two-cell straight-duct footprint validate the complete replacement.
Duplicate lots, edge cells, overlapping fixtures and unknown kinds fail. An empty array clears
that roof's fixtures; omitted roofs keep their seeded furniture. Streaming restores the same
authored layout. Power-station fixtures retain their specialized production layout.

Escape recipes reject ordinary `seals`, `gates`, `barriers` and `city.closures`; their supported
explicit objects are the finale `events`. Bounded recipes require every selected structure's
whole street segment inside the authored extent, so a gate or barrier is never installed only
in part. Capture collection retains relevant PNGs, manifests and compact logs without copying
the telemetry run's additional maps or automatic stills.

Run `tools/test.sh scene_recipe` for construction, parser rejection, ordinary eligibility,
independent seeds, actual City roof coverage and bounded fallback checks. Use the runtime's
focused suite for argument rejection, input, save isolation and observation failure behavior.
