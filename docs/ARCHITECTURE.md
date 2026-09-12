# Nappy — Architecture

Godot 4.7, GDScript. 2D scene tree with y-sorting for the 2.5D look.

## Directory layout

```
project.godot
icon.svg
docs/                     design documentation (this folder)
scenes/
  main.tscn               root: boots GameState, holds World + HUD
  world/city.tscn         generated city container
  player/stroller.tscn    the mother + stroller CharacterBody2D
  ui/hud.tscn             meters, clock, nerves
  ui/day_summary.tscn     between-day screen
  ui/title_screen.tscn    the screen a run opens on
  ui/pause_screen.tscn    the pause
  ui/touch_controls.tscn  the pointer scheme's overlay
src/
  main.gd                 boot: generate the city, drop the player on the doorstep, then the HUD
  game_enums.gd           shared enums (see below)
  autoload/
	tuning.gd             all balance constants           (autoload: Tuning)
	event_bus.gd          global signals                  (autoload: EventBus)
	telemetry.gd          the run log; inert until asked   (autoload: Telemetry)
	game_state.gd         run/day/nerves/resistance       (autoload: GameState)
  player/
	stroller.gd           movement, input, speed state
	baby.gd               the two meters + baby state machine
  city/
	city_map.gd           tile data, queries (is_calm, is_alley, walkable)
	city_generator.gd     seeded generation
	city.gd               the scene: ground, buildings, props, boundary
	block_plan.gd         one block's arc, planned at generation
	block_layout.gd       one block's carves, also fixed at generation
	city_state.gd         run-scoped: how far along each arc the run has got
	building.gd           one lot, assembled from 32px facade and roof tiles
	ground_tiles.gd       which ground tile a cell gets
	tile.gd               TileType enum + per-tile metadata
	city_edge.gd          where the main road leaves the map: the tunnel, the bridge, the spine's ends
	prop.gd               small scenery, feet-anchored so it y-sorts against the player
	traffic_signals.gd    which arm of a signalled junction is let through, and when
	traffic_light.gd      one signal head on a junction corner, facing the arm it controls
  routes/
	street_network.gd     the lattice as a graph: junctions, streets, distinct-route counts
	reachability_grid.gd  the tile graph contracted into two-tile cells; is there a walkable path
	road_closure.gd       one street shut for one day, and what shut it
	closure_planner.gd    picks the day's closures; enforces the two-routes invariant
    closure_marker.gd     one barrier panel, sign or piece of wreckage
	route_tree.gd         the day's corridor: one branch per calm area, grown on the grid
	corridor.gd           the tree translated to a tile question: inside, rim, away, how deep
	seal_planner.gd       seals every street off the day's route tree
	region_planner.gd     partitions the lattice into regions; turns the day's tree into a wall with doors, and stands the checkpoint structure and gate state at every door
  crowd/
	crowd.gd              owns the day's agents; sums their excitement
	crowd_agent.gd        one walker or one car
	crowd_lanes.gd        the lane geometry of the street grid
	crowd_field.gd        the box around the player the crowd is simulated in
	car_turn.gd           the arc a car follows out of one lane and into another
	traffic_index.gd      where the cars are, lane by lane, so a turn can check for room
  events/
	event_def.gd          authored event data
	event_instance.gd     runtime node: position, lifetime, telegraph, emission
	event_catalogue.gd    every event, defined in code
	event_scheduler.gd    builds a day's event set from seed + day
	event_manager.gd      owns the live instances; answers total_excitement_at
	event_director.gd     sites the budgeted one-shots in front of her as she walks
  day/
	day_controller.gd     the clock, the two phases, the four ways a day ends
  resistance/
	resistance_director.gd  places the day's contact; the guard and the deadline
	resistance_steps.gd     the eleven steps (five tasks, two beats each, plus the finale)
	contact_point.gd        touch to complete — a chalk mark, or a task's own event instance
  telemetry/
	telemetry_log.gd      one run's ordered lines, and the file they go to
	telemetry_observer.gd watches the player: turns, runs, crossings, encounters, where she
	                      went and which events she met
	telemetry_map.gd      the tile grid as a picture, drawn at dawn and again at dusk
  world/
	world_context.gd      the only questions the baby may ask the world
  interior/               the escape scene's building, behind --start-escape
	interior_tile.gd      the tile-kind enum and which kinds are walkable
	interior_map_plan.gd  the whole building's plan: tiles, walls, doors, decals, waypoints
	interior_map.gd       lays all seven parts (three hallways, two stairwells, the lobby, the
	                      basement) into one plan, 64 tiles apart, and the switchback layout
	interior_tileset.gd   the interior's own TileSet, built in code from the SVGs it binds
	interior_scene.gd     the WorldContext node: paints the building once, and every door's
	                      fade-teleport-fade transition and the exit-to-title transition
  ui/
	hud.gd                the clock, the two bars, the teach line and the status line
	meter_bar.gd
	home_arrow.gd         the one moment the game says "this way", while she carries a sleeper home
	danger_edge.gd        the screen-edge badge: what is coming while it is still off screen
	excitement_halo.gd    which sources earn a halo this frame, and how each rim reads
	entity_halo.gd        the ring shared by EventInstance and CrowdAgent for the excitement halo
	title_screen.gd       the screen a run opens on and goes back to; asks which control scheme
	day_summary.gd        the screen between days, and the one at the end of a run
	pause_screen.gd       the pause
	mode_button.gd        a circular icon-only button, drawn from a StyleBox and an icon
	touch_controls.gd     the pointer scheme in its two modes, and the pause button
	controls_mode.gd      which aiming origin a press is measured from
	touch_input.gd        whether this device has a touchscreen, answered once
	screen_orientation.gd the one rotation applied when the window is portrait
	quit_option.gd        whether the game can quit itself, answered once
  visuals/                PNG selection with SVG override; see the illustrated-png skill
	texture_resolver.gd   cached same-size PNG selection, with SVG fallback
	eight_direction.gd    the eight-sector heading selector the stroller and the crowd both draw by
  dev/
	auto_screenshot.gd    render N frames, save a PNG, quit
	dev_flags.gd          every dev command-line flag, gated behind OS.is_debug_build()
	dev_rig.gd            the flag-acting half: --spawn/--follow/--overview/--meters/--day-length
	                       against the live City, testable without booting main
	debug_layers.gd       the fields, shadows and bounding-box overlays, one number key apiece
  palette.gd              colours the code still chooses; the art's own are in the SVGs
  sprites.gd              feet-anchored draw helpers (standing sprite, contact shadow)
  ground_shape.gd         one ground shape per object (point, segment or rectangle); the shadow, the body and the excitement field are all derived from it
assets/
  tiles/                  ground tiles, 32x32 SVG
  buildings/              facade and roof tiles, 32x32 SVG
  rig/                    the mother and the pram, per direction
  props/                  trees, the swing frame, the bollard, the door
  events/                 one body per EventDef.Look
  closures/               barriers, the sign, and what is lying in the road
  crowd/                  walkers and cars, body plus colour trim
  ui/                     the title's two mode discs, continue, restart, pause
  shaders/                the excitement halo's silhouette rim
  illustrated/svg-transfer/  native-size PNG replacements, mirroring SVG family paths
  ground_tileset.tres     one TileSetAtlasSource per ground tile
  logo.*, icon_stroller*, social-card.png  the wordmark and the stroller on its own: the README
                          header, the social card the deploy publishes, store and social-media
                          headers. The game itself loads none of them
tools/
  check.sh                import + headless boot, fails on any script error
  test.sh                 the headless suite, sharded; a filter runs one process and says PARTIAL RUN
  lint.sh                 the governed docs, for sentences that go stale on their own
  pycheck.sh              ruff, mypy and the unit tests for the Python here
  run.sh                  play; rebuilds the import cache first when a pull left it stale
  shot.sh                 render the game to a PNG
  telemetry.sh            show a run log; stats.sh aggregates them
  clip.sh / clip.py       convert an animation burst to an MP4 beside its frames
  reference.sh / reference.py  bring a photo or video into docs/reference/, shrunk and stripped
  remove-checkerboard.py  extract painted pixels from a checkerboard-background PNG
  export-web.sh           headless Web export into build/web/ -- release by default, or `debug`
  serve-web.sh            export-web.sh debug, then serve build/web/ over plain HTTP and print the URL
  release.sh              cut a version tag, which is what deploys
  codex-hooks.py          adapts Codex's hook payloads to the shared hooks in .claude/hooks/
  test_*.py               the unit tests pycheck.sh runs
```

### `GameEnums`

An autoload's name cannot also be a `class_name`, so the enums that signals and exports
need to annotate (`BabyState`, `DayResult`, `Ending`, `EventKind`, `TileType`, `District`)
live in `src/game_enums.gd` rather than on `GameState`.

### Verifying visuals

A headless run never calls `_draw()`, so `tools/check.sh` passing says nothing about
whether the game renders correctly. `tools/shot.sh out.png [frames]` runs the game
windowed, saves the viewport after N frames and quits.

### Dev flags and release builds

`DevFlags` (`src/dev/dev_flags.gd`) parses `--seed`, `--day`, `--spawn`, `--follow`, `--meters`,
`--overview`, `--day-length`, `--ending`, `--controls`, `--layers` and `--start-escape` (also
reachable as `?escape=1`). `--start-escape` takes an optional value — `stairwell:left`,
`stairwell:right`, `lobby`, `basement` or `floor:2`/`floor:1` — that teleports straight to that
part of the escape scene's one building-wide map instead of starting at her own door on the third
floor; `main._escape_start_part()` maps the word onto `InteriorScene.part_world_position()`.
`src/dev/auto_screenshot.gd`
parses `--screenshot` and the flags nested under it (`--after`, `--walk`, `--flee`, `--press`,
`--tap`) itself, and gates its own entry point the same way rather than moving that parsing out.
Both read `OS.is_debug_build()`,
which is `false` for an exported release template, so none of this furniture — nor the snapshot
key `main.gd` reads directly — can be reached from a public build regardless of what is on the
command line. `--no-telemetry` is not part of this: it is a documented player-facing opt-out (see
docs/TELEMETRY.md), not developer furniture, and stays live in every build. `main.gd`'s own
right-hand readout (seed, frame rate, the meter's incoming/decay/net arithmetic) is gated the same
way, into a member (`_debug`) rather than asked of the OS inside `_process()` every frame, so the
string is never assembled outside a debug build rather than merely hidden behind an invisible
label.

### The debug view

`DebugLayers` (`src/dev/debug_layers.gd`) draws three world-space overlays over the live game
state — a field's inner and outer falloff boundary, the ground extent a shadow is drawn over, and
every collision body's own outline — read from `EventInstance`, `CrowdAgent`, `Building`, `Prop`
and `Stroller` rather than drawn by any of them. Each of the three, plus the readout, is a numbered
layer (`1`-`4`) `main._unhandled_input()` toggles on raw keycodes rather than an input-map action,
so `project.godot` carries no binding a release build could ever reach. `DevFlags.layers_override()`
(`--layers 1,3` or the page's own `?layers=1,3`) sets which of the three geometry layers start on;
the readout defaults on regardless, so an unflagged debug run looks exactly as it always has. See
docs/TELEMETRY.md, "The debug view", for the key mapping and what each layer draws.

### Quitting on the web

`SceneTree.quit()` does nothing on a Web export — the tab stays open — so `Q` is only offered
where it works. `QuitOption` (`src/ui/quit_option.gd`) answers with `OS.has_feature("web")`, the
platform axis rather than the build one, since a debug Web build has the same dead quit as a
release one — the same axis `Telemetry.begin_run()` already uses to stay silent on the web.
`TitleScreen` and `PauseScreen` each read it once into their own `_can_quit`, so their hint text
and their `Q` handler always agree, and so a test — never itself a web export — can set the member
and drive both platform shapes. A debug build can preview the web shape without a real export:
`--web` forces `QuitOption.available()` false, the same role `TouchInput`'s own `--touch` plays
for its platform fact.

### Playing on a touch device

`TouchInput` (`src/ui/touch_input.gd`) answers `DisplayServer.is_touchscreen_available()` rather
than `OS.has_feature("mobile")`, because the game ships as one Web export that runs unchanged on a
phone browser and a desktop browser — `has_feature("mobile")` is a tag baked in at export time and
cannot vary with the device that opens the page, while `is_touchscreen_available()` asks the
browser what the visiting device actually has. `TitleScreen`, `PauseScreen`, `DaySummary` and
`TouchControls` each read it once into their own `_touch`, the same shape `_can_quit` uses, so a
test can drive both platform shapes. **This is a hardware fact only.** It decides whether a real
`InputEventScreenTouch` is on offer at all — and so whether a same-instant emulated
`InputEventMouseButton` from that same finger has to be ignored rather than read as a second,
doubling press — and nothing about where a heading is measured from.

### Choosing the controls

`ControlsMode` (`src/ui/controls_mode.gd`) is the player's own choice of aiming origin, independent
of `_touch`: a touchscreen can be set to `TAP` and a mouse can be set to `JOYSTICK`. `TitleScreen`'s
two `ModeButton`s (`Symbol.JOYSTICK`/`Symbol.TAP`) are the only pointer way into a run — a press
that lands anywhere else on the screen does nothing — and a direction key or `space` begins one in
`Mode.TAP` instead, on the reasoning that a player pressing a key has told the screen nothing about
a thumb. `main._add_touch_controls()` gives `TouchControls` a starting mode from
`ControlsMode.resolve()` (the command line's `--controls joystick|tap`, then the page's own
`?controls=`, then `TAP`) before the title screen exists at all — the answer a rig gets if it skips
the title (`--no-title`, a screenshot rig) — and `main._on_title_start()` overrides it the moment a
player actually presses a button. Both `resolve()`'s own doors stay behind `DevFlags.enabled()`.

`TouchControls` (`src/ui/touch_controls.gd`) is the whole of the pointer scheme, and the two modes
disagree about where a heading is measured from. `Mode.TAP` sets a direction toward its own world
position, aimed from wherever she currently stands, and a press within `STOP_RADIUS` of her stops
her instead. `Mode.JOYSTICK` instead aims from whichever of two fixed points, `FOCUS_LEFT` or
`FOCUS_RIGHT`, is nearer the press — each drawn as a ring at `STOP_RADIUS` with a knob at the
currently-held direction — and is stopped by a press on either focus or in a band down the middle
of the screen (`is_in_stop_band()`) rather than by a press near her own position, which does not
stop her in this mode at all. Either way the direction locked in is walked with nothing held down
until the next press changes it, and a double press holds `run` until the next press changes or
releases it. Held down and moved, a finger or a mouse button keeps re-aiming continuously —
`_on_drag()` — always at one speed, since `set_direction()` always normalises and no input path may
press a vector shorter than one. It also draws a pause button top right, shown only when
`get_tree().paused` is false, which keeps it off the title, the pause and the between-days summary
without a wire from `main` telling it so on each: that flag is the one thing all three already set.
`PauseScreen` and `DaySummary` also handle a touch or a left click directly alongside `ui_accept`
(through `TouchInput.is_press()`), so either advances each of them the way `space` does —
`TitleScreen` does not, since only its two buttons may begin a run by pointer.

A press or a drag computes a heading — `(target - origin)`, normalised — and presses it through
`_set_axis()`, one signed value onto a pair of opposite actions. There is no target and nothing to
arrive at: she walks the heading until the next press or motion event changes it. A double press
needs both a time window (`DOUBLE_TAP_SECONDS`) and a distance window (`DOUBLE_TAP_DISTANCE`) to
read as a modifier on the same direction rather than a new one, and holds `run` until the next
press changes the direction or stops her; a drag that started on a doubled press keeps holding
`run` through every motion event. The screen press itself is mapped to a world position with
`get_viewport().get_canvas_transform().affine_inverse()` — the reverse of what `DangerEdge` and
`HomeArrow` already do forwards every frame — so it tracks the camera, the zoom and the rotated
presentation for free. Which focus is nearer, and whether a press lands on a focus or in the stop
band, are asked in **design space** instead, through `ScreenOrientation.to_design_space()`, since
that is where "half the screen" and "the middle of the screen" mean what they say — the chosen
focus then makes the same design→presented→world trip a raw touch's own position already takes, in
reverse, before it can be subtracted from or used as the heading's own origin. **The pause button's
own corner is the other place this remap is needed**: a touch there is subtracted from the aiming
surface, but only while the button is actually showing, against the fixed `PAUSE_CENTRE` — a mouse
click never needs the remap for anything else, since the button (and so the corner) is drawn for it
too now that every device shows the same pair of controls.

A real touch device emulates a mouse click from every tap it makes, so every mouse branch in
`TouchControls`, `TitleScreen`, `PauseScreen` and `DaySummary` is gated on `not TouchInput.available()`
— without that gate a single real tap would fire twice, once through each event, and read as its
own double tap (or a doubled button press). `--tap X Y` (`src/dev/auto_screenshot.gd`) sends one
synthetic touch the same way a finger would, which is what makes the direction it sets
photographable — `tools/shot.sh out.png 3 --touch --tap 640 420`.

## Autoloads

### `Tuning`
Pure constants + `validate_event()`. No state. Everything balance-related lives here so a
designer touches one file.

### `EventBus`
Global signal hub. Decouples systems that should not know about each other.

```gdscript
signal excitement_changed(value: float)
signal sleepiness_changed(value: float)
signal baby_state_changed(state: Baby.State)
signal day_started(day: int)
signal event_telegraphed(instance: EventInstance)
signal event_activated(instance: EventInstance)
signal hard_fail_triggered(reason: String)
signal resistance_progress_changed(value: int)
```

### `Telemetry`
The run log: one plain-text file per run, written as it happens. **Inert until
`begin_run()`**, which only `main.gd` calls — so the test suite, which never calls it, writes
no files and pays nothing. `begin_run()` is also inert on a web export
(`OS.has_feature("web")`), since `user://` there is a stranger's browser storage that nothing
ever prunes — **unless the page's own `?telemetry=1` asks otherwise**, which is the one telemetry
switch not gated behind `DevFlags.enabled()`, because the deployed page has no command line for
that gate to read. See `docs/TELEMETRY.md` for the format and what belongs in it.

The rule that governs it is one line long: **telemetry must not touch gameplay.** No RNG, no
`day_rng()` stream, nothing that changes a placement or a roll. Where a system logs a random
outcome it hoists the existing roll into a variable to print it; it never adds one.
`tests/test_telemetry.gd` plans all fourteen days with the log off and again with it on and
requires the two plans to be identical, because that hoist is exactly the edit that could
quietly consume one extra value and break determinism for every other guarantee here.

### `GameState`
The run. Owns `run_seed`, `day`, `nerves`, `resistance_progress`, `consumed_one_shots`.
Handles day transitions and ending selection. Serialisable for save/continue.

## WorldContext

`Baby` never learns what a tile or an event is. It asks a `WorldContext` three questions —
`is_calm_zone()`, `is_alley()`, `total_excitement_at()` — and that is the entire surface
between the meters and the world. The debug world answers with hand-placed test data; the generated
city and the event manager answer for real. `InteriorScene` (`--start-escape`) is a third
implementor that overrides nothing at all: the base class's own defaults (1.0 recovery everywhere,
no excitement sources) are exactly the "meters idle" the escape scene wants, since it has no
events and no crowd. Adding an event type therefore never touches the meter code, and the meters
can be unit-tested against a fake world.

## Excitement aggregation

`Baby` does not know about event types. Each frame it asks the world for total stimulus:

```gdscript
# EventManager keeps a list of active EventInstances
func total_excitement_at(pos: Vector2) -> float:
	var sum := 0.0
	for inst in _active:
		sum += inst.contribution_at(pos)
	return sum
```

`EventInstance.contribution_at()` implements the falloff from `docs/MECHANICS.md` and
applies the telegraph fraction if the instance is still in its telegraph phase. Adding an
event type never requires touching `Baby`.

The scan is linear. An earlier draft of this document called for a uniform spatial hash;
the day's live event count never grows past a few dozen, so a hash would have been more
code and more ways to be wrong in exchange for nothing measurable. Revisit if an act ever
wants hundreds of sources.

## Determinism

Two independent RNG streams, both derived from `run_seed`:

- `RNG_CITY = RNG(run_seed)` — used once, at run start, for layout.
- `RNG_DAY = RNG(hash(run_seed, day_index))` — re-created every day for event selection.

Nothing gameplay-relevant may use the global `randi()`. A day replayed with the same seed
and day index produces the identical event set — required for the "learn the run" design.

Cosmetic-only randomness (leaf flutter, NPC idle animation) may use the global RNG, and is
kept strictly out of anything that touches the meters.

## Rendering / 2.5D

- `city.tscn` has two y-sorted layers: `Buildings` (z 1) and `Entities` (z 2). Everything that
  stands on the ground goes in the second. **Buildings never sort against entities** — a
  building's mass extends a block north of the origin y-sort compares, and nothing walkable is
  ever inside a lot, so the comparison could only ever be wrong. See docs/CITY.md, "Rendering".
- Ground: a `TileMapLayer` fed by `GroundTiles`, which is the only place that decides which
  tile a cell gets. Source ids in `assets/ground_tileset.tres` are positional and
  `ground_tiles.gd` mirrors them by hand — adding a tile means appending to both, in order.
- Buildings: `StaticBody2D` whose collision is the whole lot, plus a `_draw()` that
  assembles that same lot out of 32px tiles — a front wall (the southern `height` px) and a
  roof (the remainder). Fitting the mass inside the lot keeps extrusions off the *ground* she
  walks on, which is not the same as keeping them off *her* — see the layer note above. A taller building therefore shows more wall and less roof, which is
  what an oblique view of a taller building should look like.
- Building heights are quantised to whole tiles, because a tiled facade cannot honour a
  float height without stretching a tile. `Building` clamps the requested height itself, so
  a caller cannot ask for a wall that eats the roof.
- Fills are authored near-white and drawn with the variant colour as `draw_texture`'s
  modulate; windows, plinth and parapets are overlays drawn at full colour on top. One set
  of assets therefore covers every building colour.
- The player's `position` is the *feet*, and drawing is offset upward from there. This
  keeps y-sort and collision consistent. `Sprites.draw_standing()` is the single place that
  rule is written down; everything that stands on the ground goes through it, along with
  `Sprites.draw_shadow()` for the contact shadow.
- A single `Camera2D` on the player, with `position_smoothing_enabled` and a small
  look-ahead in the movement direction.

## Testing

`tools/test.sh` runs `tests/tests.tscn` headless. It is run as a *scene*, not via
`--script`: `--script` replaces the main loop, which skips the autoloads, and every test
needs `Tuning`. The runner loads every `tests/test_*.gd`, calls its `run(t)`, and exits
non-zero on any failure.

- `test_meters.gd` — falloff shape, the telegraph fairness contract, and every meter rule
  in docs/MECHANICS.md, driven at a fixed timestep against a fake world. *(done)*
- `test_generator.gd` — 200 seeds: connectivity, park count/spread, home-to-park distance,
  exact building coverage, and route redundancy under street closures. *(done)*
- `test_events.gd` — catalogue fairness, the emission model (telegraph damping, pulse
  envelope, duration, paths, hard-fail gating), and scheduler determinism, placement,
  one-shot consumption and the usable-park rule.
- `test_event_manager.gd` — the manager against a real generated city: retirement,
  successors, summed excitement. Wiring bugs live here and are invisible to data tests.
- `test_blocks.gd` — block purposes and arcs: arcs only move forward, enough calm survives
  the whole run, a cause only fires where its arc expects it, and — the one that matters —
  pushing every block to the end of its arc moves no walkable tile.
- `test_crowd.gd` — the crowd against a real city: population per act, determinism, agents
  staying on the right surface through a corner, and the emergent noise floor (a busy street
  never lets the meter fall; a back street does; a park is out of earshot).
- `test_acts.gd` — act gating, city-wide sources, protest growth,
  scar persistence, and walkability under accumulated street closures.
- `test_day_loop.gd` — the two phases, all four day outcomes, nerves, ending selection.
- `test_resistance.gd` — the step table, touch-completion, a perform step riding on an
  `EventInstance`, the seeded guard, the expiring step, and the sabotage silencing the city.
- `test_full_run.gd` — three seeds played through all 14 days with the real City,
  EventManager and ResistanceDirector, with time actually advancing. This is the check
  that catches "day 12 throws", which no amount of unit coverage does.

These are the places a bug is invisible until it ruins a run, so they are the places with
tests. Anything a screenshot would catch is checked with `tools/shot.sh` instead.

`tools/test.sh crowd balance` runs only the suites whose file name contains one of those words,
which is seconds rather than the whole run. A filtered run says `PARTIAL RUN` under its count,
because a partial pass that could be mistaken for a green build is worse than no filter at all —
a commit still rests on the unfiltered run.

**A rig that steps the parts is not running the whole.** Several suites walk the crowd by hand so
that a minute of traffic does not take a minute; what that skips is the frame *around* the agents,
which is where the traffic queue is resolved and the `TrafficIndex` emptied. `Crowd.step()` is that
frame, and it is what a rig calls — see the **verify** skill for what stepping only the
agents cost, in both time and truth.
