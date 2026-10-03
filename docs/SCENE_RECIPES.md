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

## Construction schema

The root has `version: 1`, a nonempty `name`, integer `seed`, `extent`, `city`, and optional
`anchors`, `setup`, `playback`, `kind` (`city` or `escape`), `classification` (`normal` or
`fixture`), and `expected_violations`. Unknown construction fields fail. Unsupported requests
are errors, never nearest-position substitutions.

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

Run `tools/test.sh scene_recipe` for construction, parser rejection, ordinary eligibility,
independent seeds, actual City roof coverage and bounded fallback checks. Use the runtime's
focused suite for activity, observations, restart and scripted/free-play behavior.
