# Scene recipes

Saved JSON recipes describe exact development scenes. `SceneRecipe.load_file()` returns data
and diagnostics without engine errors for malformed input. `RecipeCityBuilder.build()` returns
the map, resolved world anchors, diagnostics and a construction manifest. The runtime validates
`setup` and `playback` separately before starting gameplay; construction acceptance alone does
not certify events, actors or a promised playback moment.

The `scene-recipes/` directory is local development input. Its `.gdignore` keeps the JSON files
available to the scene tools through `FileAccess` while excluding them from Godot's imported
resource set, and the Web export excludes the directory explicitly. `tools/audit-pck.sh --fatal`
checks the built package itself and fails if any development recipe path is present.

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
`--screenshots` also photographs each scene a tenth of a second in (`NAME-start.png`) and at its
`playback.capture_at` time. This is elapsed
simulation time after the full world and movement start: events, traffic, animation and the
camera advance together during this pre-roll. It is adjustable independently for every scene.
The default is 0.5 seconds. A still shows composition; the headless observations check action.

The trailer shot list's existing `in` is a separate adjustable recording cut-in: the recording
simulates from setup, then trims the picture and audio to that time. `capture_at` chooses a
screenshot moment, not a recording duration or a reset of the movement clock.
A trailer scene walks through an excluded lead-in, so its first retained frame is already moving
with a settled camera; its observations check what the cut shows, at the ticks it shows it. When
a trailer scene is re-staged, its observations are rewritten to the new staging, rather than the
staging bent back to satisfy an old observation: the checks follow the trailer.

The trailer uses `trailer-birds.json`, the selected westward walk into the park.
`trailer-park-circle.json` bounds its scene to park tiles and trees south of a large park's
playground. The mother completes the loop within the retained shot; streets, buildings and
the playground remain outside the authored extent.

## Activity and playback

`setup` accepts `day`, `parent` (`mother` or `father`), `player` (`at`, cardinal `facing`,
initial `excitement` and `sleep`), `background.crowd`, `signal_time`,
`progression`, named `events`, named `actors`, `posters`, `roof_fixtures`, `seals`,
`gates`, `barriers`, the day-13 `column` formation, and the day's resistance `task`.
`tutorial_complete: true` starts after the ordinary control lessons, clearing those prompts
while retaining gameplay warnings. Trailer scenes use this state so the lesson text does not
cover their subjects. Free play uses the same authored teaching state.
Positions name an anchor or give `[world_x,world_y]`. Background activity defaults off.
Only explicit selections install events. The normal event scheduler does not fill authored
scenes, in either free or scripted mode, and the director hands out nothing unless the recipe
rigs a route bag (`setup.route_bag`, below). `background.events: true` is rejected;
an omitted or false value selects no automatic events. Pedestrians and cars keep their normal
simulation independently of event selection. Unselected seals and region bodies remain absent.
`background.uniform_walkers: true` initially samples evenly along eligible sidewalk lanes
and gives pedestrian corridors equal selection weight on recycle. `background.walker_multiplier` scales only the recipe's pedestrian
population from the ordinary act count (1–4, default 1). Cars retain their normal count and
street weighting. Both require `crowd: true`; an ordinary day restores the default distribution.
Walker directions remain varied within each sidewalk lane. A uniform population that exceeds
the available valid sidewalk positions is rejected explicitly.
Uniform background crowd can accompany explicitly placed walkers; their ordinary lane, body
clearance and speed checks apply, and overlap with another walker is rejected. Other combinations
of background crowd and pinned actors are rejected.
Random background activity requires full extent; bounded and stretch scenes use authored activity
so their exterior does not acquire context-city actors or collisions.

`route_bag: {"marbles": [...], "pre_bag": [...], "owed": n, "first_after": seconds}` is what she
meets on her route, by the director's own rules from a bag the recipe rigs
(`EventDirector.start_recipe_route()`): `marbles` fills the ordinary bag, `pre_bag` is drawn from
first, `owed` is how many events her route is owed (both bags' marbles by default) and
`first_after` the seconds of walking before the first is due (the ordinary 11–26s roll by
default). Every marble names a row the director sites that day (`AHEAD_OF_PLAYER` or
`TOWARD_PLAYER`); the pacing after the first, where each is sited, the region doors' clear ground,
a row's `max_per_day` over the ordinary bag's rows and a rig a task asks for later are all the
game's own. A route bag also switches on the rest of what the director does while she walks, as in
a played day: a place a marble puts on her route is sited on her way, and on days 8 to 14, once the
baby sleeps and the walk home begins, the act III and IV return patrols are owed.

An event gives `name`, catalogue `row`, `at`, optional `route_seed`, `path` and `age`.
The ordinary scheduler's ground, route, spacing, protected-door and corridor checks accept
its site. An authored path must equal that production route. Director pursuers use the real
ahead-of-player siting. `age` may advance through the initial warning only; active movement is
simulated. Actors give `name`, `kind` (`walker` or `car`), `at`, cardinal `direction` and optional
`speed`; production lane, ground, speed and car-gap checks apply.

`task: {"mark":"mark"}` starts the day's own resistance task, the way a played day does, with
the chalk mark at the named position, **unread** as the scene begins, and her start a short walk
from it: touching the mark reads it, its words are announced and the task it unlocks is placed from
where she stands then by the director's own placement, with its red arrow from that moment. Before
she reads it no task is on offer and no arrow is drawn. The mark has to stand where a day's mark can, the centre
of an alley mouth's tile on open ground reachable from home; a mark anywhere else is refused, never
moved. Days 6 to 13 take `mark`; day 14's task, the power station's front door, has no mark and
takes `task: {}`, and the scene starts with the resistance goal met, since the last night is
offered only then. `neighbor` pins day 10's neighbor's start to a sidewalk tile the day's own draw
could choose (about `Tuning.NEIGHBOR_WALK_HOME_SECONDS` of their walk from home, and
`ResistanceDirector.NEIGHBOR_CLEAR_OF_HER`, 400px, or more from her where she reads the mark, which
the draw runs when she does); it is the one target drawn
from the whole city rather than placed near the mark or standing in a fixed place. Everything the
task brings comes with it: the target and any event it is or rides on, the guard robber at the
mark (and a roadblock's own guard), and the robber or guard a done task sends from off screen. What the day brings
besides the task does not: the neighbor walking to work, the raid, the market and the column stay
out, and day 12's park still closes once its swing is reached. The task's observation names are
`mark` (named from the start), and, once she has read the mark, `task` (its contact, where the red
arrow ends) and `rider` for a task riding a body: the man shouting, the van, the burnt shell, the
neighbor and a roadblock. An observation of `task` or `rider` belongs after the walk has reached the
mark, so one before it finds nothing and fails; the manifest's `task` records the tick she read the
mark (`read_tick`), where the target was put and where the arrow points. A task the director has
nowhere to place, once she has read the mark, stops the scene with the director's reasons.

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
region doors, including its two gatehouses and shared traffic-operated boom. A horizontal street
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

`playback` accepts a timed `walk` script (the same syntax as `--walk`), `smooth` (true: the
script's turns sweep gradually and still end exactly where the abrupt walk does, the same as
`--smooth-walk`; `WalkPlan` in `src/dev/walk_plan.gd` says how), `duration` in seconds,
`capture_at`, optional `camera` (`zoom`, `zoom_out`, `zoom_delay`, `landscape_margin`, and
`fixed`, which holds a scripted scene on its starting view, and optional `fixed_offset: [x,y]`,
which shifts that held view in world pixels), `settled_camera` (true: the camera starts settled on her with its look-ahead,
which the trailer needs before its moving lead-in; all cameras start at the placed player,
and this option additionally initializes the directional look-ahead), `caption`,
`title` and `observations`. `landscape_margin` grows only the zoom-out's final framing around the
finite map. In a full-city scene, exterior ground remains unwalkable and loads only when the camera
can see it. Each observation has a physics `tick`, named `subject` and `condition`:
`visible`, `moving`, `running`, `carrying`, `asleep` or `awake` (the baby's own state, which draws the
pram's zzz), `pursuing`, `near` or `beyond` with `at` and
`distance` (at most or at least that far), or `near_player` with `distance` (the subject is at most
that far from her), `off_screen` (no part of a box three tiles either side
and four up and down, `ResistanceDirector.TASK_HALF_EXTENT`, is in the picture), `clear_of_both_views` with `half` (`[half width, half height]` in px: no part
of that box round the subject is in the world the camera shows in the landscape window or in the
rotated portrait presentation, 640x360 and 360x640 at the game's zoom), and for `mark` or
`task` alone `offered`, `done`, `arrowed` (the red arrow ends on it) and `unarrowed` (no red arrow
is drawn). `appeared` says the subject's rendered body has overlapped the live camera viewport,
excluding the corners covered by joystick controls, at some tick up to this one; it lets a recipe
check a route event whose arrival follows the director's pacing rather than a fixed tick. `crowd`,
asked of `player`, takes `walkers` and `cars` and requires at least that many of each to be moving
in the picture. A `subject` of `row:<catalogue id>` names the first live instance of that row, for
what an event summons rather than what the recipe placed.
The manifest records the engine's physics rate (30 Hz in this project); render FPS does not
change that clock. Failed observations and interrupted gameplay exit unsuccessfully.
`--recipe-validate` builds and checks the initial live setup, then exits;
`--recipe-manifest FILE` retains initial actors, context, classification and observation results;
`--recipe-draft FILE` plays a scripted recipe on its whole city and writes the stretch it walked as
a recipe (`tools/scene-draft.sh`, "The task scenes" below).

## The task scenes

**Each task scene is one stretch of city, handcrafted.** *(polite-dolphin, inbox #555: "it should
be 1) only one stretch of a city with nothing (no ground!) off the path at all. and pedestrians etc
and deterioation and events should spawn like in a real game -- but authored"; "the whole point of
those scenes is that they are not seeded but handcrafted -- you can use a seed to create it. but
then everything should be placed manually. the events should still spawn using the same rules but
the marble bag should be rigged"; asked how wide the path is, "The streets she walks".)* A scene's
recipe has `extent: {"scope": "stretch"}` and a `stretch` object listing its ground and everything
placed on it; the scene shows that and nothing else.

**The stretch is the streets she walks**: every street segment her walk sets foot on, whole, both
sidewalks and the carriageway, with the junction box at each of its ends; a junction box she
crosses; off the streets, the ground she walks over and the tiles beside it, and the whole of an
alley she walks into; the corner of each place `setup.task` pins (the mark, day 10's neighbor's
start); and day 10's neighbor's way home, which the recipe pins and the whole city routes. Every
other tile but the lots of the buildings it lists (`stretch.buildings`, below) is void: no ground
is drawn there, no building, prop, decal, shadow or pit, and a wall stands along its edge, so she,
a pursuer and a nudge from the crowd stop there as at a frontage.

**The recipe lists what is placed**, and the scene draws only what it lists:

| Field | What it holds |
|---|---|
| `context` | explicit off-camera topology: row runs `[type, length]`, block arcs and layouts, home and station, regions, lots and trees; no generated witness |
| `stretch.tiles` | tile type name → `[y, x_from, x_to]` runs: every tile of the stretch, by the type it is |
| `stretch.buildings` | `{lot, district, variant, height, condition}`: each building fronting the stretch (a lot beside or across a corner from one of its tiles), drawn with that district, variant, wall height in tiles and condition |
| `stretch.trees` | the pit tile `[x, y]` of each street tree on the stretch |
| `stretch.props` | `{kind, at, variant, scale}`: trees in a park, a swing frame, bollards, sacks (`tree`, `playground_frame`, `bollard`, `sack`, `sack_pile`) |
| `stretch.litter` | `{kind, at}`: each piece of litter (`apple`, `newspaper`, `cup`, `bag`, `can`) |
| `stretch.cracks` | `[x, y, level, pattern]`: each cracked tile, level 0 (hairline) to 2 (broken); a tile not listed is whole |
| `setup.posters` | the sheets on the walls fronting it; a stretch pastes no dawn of its own |
| `setup.actors` | its starting walkers and cars |
| `setup.route_bag` | what she meets on her route, rigged |

**The saved `context` states the day's spatial rules.** It contains explicit tile rows, block
arcs and layouts, districts, region boundaries, the home and station, building footprints and
street trees. Runtime restores those lists directly, then overlays `stretch.tiles`,
`stretch.buildings` and `stretch.trees` as the authority for the visible scene. Every placement
is editable. A tile edit survives daily repainting; a moved building supplies its new collider
and roof footprint; an added tree supplies its pit and event clearance. Malformed data and
placements outside the declared stretch fail with a named error.

The ordinary route, region, task and event planners read that explicit map. Saved scenes never
run city generation and never compare their layout with a generated witness. `city.context_seed`
and its construction choices are drafting inputs only for stretches; changing them cannot
move or reject a saved layout. Runtime seed still controls event draws and moving actors.

**While she walks, the stretch is the whole world.** Every other question about the ground answers
a void tile as a wall, so the task's target is placed by the director's own rule on the streets the
scene has, which need not be where the whole city would put it. The walks are authored to reach the
target the scene puts out.

**The crowd is the street's own.** The starting walkers and cars are listed; the crowd's field is
the whole stretch and does not follow her. **Nothing appears or vanishes where she can see it**
*(the player's rule, PR #597)*: a walker or a car that reaches one of the stretch's ends, where a
street runs into the void, leaves there only when no part of it is in the landscape or the turned
portrait view, and comes back in at an end that is out of both, heading in. In her view the end is a
wall: a walker turns round at it, a car turns off before it or waits there until she has walked on.
A street that ends at a building is a wall and nobody enters there, and nor does anybody at a
junction's own arm into the void.

**A draft comes from a seed and a route.** `tools/scene-draft.sh --recipe FILE (--output FILE |
--in-place)` plays the recipe's own walk once on its whole construction city and writes everything
above: the stretch she walked, the buildings fronting it with their district, variant, height and
condition, its street trees, the props, litter and cracks on it as the day has them, the day's
posters on those walls, the walkers and cars a morning's crowd stands on it — each placed again as
the scene places it, and no car in her view at the start — and the day's ordinary route bag. The
draft is checked with `--recipe-validate` and is the author's to edit. Drafting a stretch recipe
again keeps its route bag, which is the author's rigging, and writes the rest afresh.

One scene per day whose task names a target, days 6 to 14, puts that target at the least distance
the task allows from where she reads the mark, which also tests that it is put out of her view
*(the player, inbox #502: "in the scene we can use the minimum distance which in turn also serves
as test whether it will be properly off screen")*. Days 6, 7, 8, 11 and 13 leave the placement to
the director, which puts the target where a path from her first reaches the 576px circle round her
(`ResistanceDirector.NEAR_THE_MARK`), on the stretch, out of her view. Day 8's burnt building stands
there for a run with no day-3 fire, its door a tile or two behind the shell. The targets whose
place is fixed — day 9's district door, day 12's swing and day 14's station door — have no such
rule, so their scenes put the mark or her start just past that same circle. Day 10's neighbor
starts at their own least distance, 400px from her. Days 6 to 13 start her a walk from the mark,
about 160px (5 tiles along a street, outside the 150px `ResistanceDirector.SEEN_DISTANCE` in which
she notices a mark) and with a clear way to it; the mark is unread and no task is on offer until
her walk touches it *(the player, inbox #555: "make them not start *on* the mark", answered
"Unread, walk to it")*. She reads it up to the mark's 36px reach away, so the target stands its
distance from where she read it, and the assertions measure from the mark with that 36px of slack.
The routes keep out of the robber's notice at the mark and, where the straight way to the target
runs past him, go round. Each scene saves its own explicit context and uses run seed 11, so it starts the same way every time.

Every task scene's route bag is the day's own ordinary bag with a cat in front of it, and each scene
asserts that she saw the cat (`appeared`) and that walkers, and on days 6 to 11 a car, are moving
in the picture at a stated tick (`crowd`). The cat is due 3s into the walk, except on day 9, where
the district door's clear ground refuses every siting on the street down to the door, so she walks
a block east along the cross street first and the cat is due 6s in, and at the station door's
corner, where she walks a few steps west and back before the corner's question and the cat is due
half a second in. `tests/test_scene_recipe_stretch_crowd.gd` plays every stretch scene to its end
and holds every observation, and that nothing in the crowd appears or vanishes in her view.

| Recipe | Day and target | She starts | The target, as the scene asserts it |
|---|---|---|---|
| `task-06-note.json` | 6, a note for the man shouting | 5 tiles west of the mark, on the street, the mark unread | the man shouting up the street west of the mark, 540–644px from the mark, with the arrow on him |
| `task-07-package.json` | 7, the package at the van | 5 tiles west of the mark, on the street, the mark unread | the van on the same street, 540–644px from the mark |
| `task-08-burnt-shell.json` | 8, the burnt building | 5 tiles west of the mark, on the street, the mark unread | the shell 540–644px from the mark, the arrow on the door behind it |
| `task-09-crossing.json` | 9, the crossing | 5 tiles west of the mark, the mark unread | the named district door's gatehouse, 540–676px from the mark; done by crossing the door |
| `task-10-neighbor.json` | 10, warning the neighbor | 5 tiles east of the mark on the street above it, the mark unread | the neighbor, 400px or more from where she reads the mark (about 455px from it), walking home |
| `task-11-mast.json` | 11, silencing a mast | 5 tiles west of the mark, on the street, the mark unread | a mast put up for the task, 540–644px from the mark |
| `task-12-swing.json` | 12, the swing | 5 tiles east of the mark on the street below it, the mark unread | the swing's base, 540–676px from the mark |
| `task-13-roadblock.json` | 13, into a roadblock's band | 5 tiles west of the mark, on the street, the mark unread | the roadblock, 540–644px from the mark, with the arrow on it |
| `task-14-last-night.json` | 14, the station's front door | on the sidewalk west of it | the door on the facade, 576–640px out |
| `station-door-corner.json` | 14, the station's front door | on the far outer corner of its sidewalk, walking a few steps west and back to it | the door, 57.7px away, outside its 50.6px reach |
| `fire-truck.json` | 3, the fire and the engine it calls in | on the sidewalk 496px east of the fire | the whole burning building, smoke included, out of both the landscape and the portrait view at the first tick; the engine parked at the kerb in front of it |

Every scene in this table but `fire-truck.json`, which is built on the whole context city with no
background crowd and only `burning_building` named, is a stretch.

Play one with `tools/run.sh --recipe scene-recipes/task-07-package.json` and walk to the target,
following the red arrow where there is one; the summary after a won day reloads the scene. Each
scene's headless assertion, in `tools/scene-recipes.sh`, checks at the first tick that the mark is
unread, no arrow is drawn and she stands outside the mark's notice, walks the recorded route to the
mark and checks that reading it completed the mark and offered the task, the arrow ends on the target,
the target is out of her view and at its stated distance, then walks on and
checks that reaching the target completed the task. The mark's robber stands where the day puts him and the walks keep out of his notice; once a
target is done, the robber or guard the task sends comes from off screen as in a played day and
catches her a little after the scene's last assertion; add `--invincible` to play on without a robber
ending it. Days 10 and 13 send nobody after the target: the neighbor's task has no pursuer, and the
roadblock keeps its own guard waiting in its band instead. Day 9 and the station door's corner send
nobody either: the stretch has no ground at the distance a sent robber starts from, so the day's
own draw finds nowhere for him to come from. At a door on a building's front — day 8's
burnt building and day 14's station — the robber usually comes from across the street, out of view,
and by the rule every other target uses, usually from beside her along her own street, only where
no start across it has a way to her.

`station-door-corner.json` is for the question whether the station's door is touched from the far
outer corners of the two sidewalk tiles in front of it (`ResistanceDirector.DOOR_REACH`, 50.6px,
against the corners' 57.7px): she starts on the west corner, where the door is not touched, walks a
few steps west and back to the corner, where it is still not touched, and one step east touches
it. No guard waits at the station's door, and touching it sends nobody in this
scene (above).
`fire-truck.json` starts on day 3 with `burning_building` named and nothing else, her start 496px
east of the fire, so that its lot, its rise and its smoke are out of both the landscape and the
portrait view at the first frame *(the player, inbox #557: "the
fire truck scene starts too close to the start -- the building is already on screen")*: once she has seen
the fire, its own `spawns_on_sight` calls the `fire_truck` in from off screen exactly as a played
day does, and the engine parks at the kerb in front of the fire for the rest of the day.
The scripted walk turns north after seeing the fire, then returns partway south to watch the
parked engine from farther away. It shows the moving engine during that retreat and manages
the ordinary noise exposure by walking; standing beside the engine remains dangerous.

## Construction schema

The root has `version: 1`, a nonempty `name`, integer `seed`, `extent`, `city`, and optional
`anchors`, `setup`, `playback`, `kind` (`city` or `escape`), `classification` (`normal` or
`fixture`), `expected_violations`, and `stretch` with its required explicit `context` (with a stretch scope, and only then; "The task
scenes" says what it holds). Unknown construction fields fail. Unsupported requests
are errors, never nearest-position substitutions.

For the whole-city view, `background.crowd_scope: "city"` populates production walkers and cars
across the full map at the ordinary crowd field's area density. It requires `crowd: true` and
full extent; the default `"player"` keeps the ordinary moving field. Recipe manifests report
initial, final and captured population and moving-car counts in each city quadrant. This is an
authored presentation choice for the bustling-city scene; ordinary game density is unchanged.

`seed` belongs to the runtime and background activity. For full and bounded scenes, the required `city.context_seed` fixes
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

Every anchor must lie inside the declared extent; in a stretch, on one of its tiles or on a
building it lists (`power_station_door` stands on the station's facade). Runtime placements may refer to the resolved
name. The manifest records the actual points, inputs, validation checks and bounds.

`extent: {"scope":"full"}` constructs and presents the complete city and requires its full
generator guarantees. `{"scope":"stretch"}` presents only the recipe's `stretch`, over its saved
`context` restored as it is: a stretch runs no construction ("The task scenes" above). `{"scope":"bounded","bounds":[x,y,width,height]}` presents only that
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
`skylight_b`, `vent_stack`, `water_tank`, `service_bulkhead`, `exhaust_fan`, or `pipe_manifold`.
Columns count from the west; row zero is the south
roof lip above the facade. The production interior-cell pool, including roof extensions,
district fixture choices and displayed equipment widths validate the complete replacement.
The public `duct_straight` reserves two horizontal cells and `duct_corner` one west/north elbow
cell; both use the mounted duct components. Their public names are independent of the internal
network enum. Water tanks, long skylights, access rooms and pipe manifolds reserve two columns;
scaled standalone fans fit one. Height rises north from the roof foot without changing collision.
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
