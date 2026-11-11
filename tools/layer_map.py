"""The layer map `tools/check_layers.py` holds the game's code to, as data.

The layers are designing-classes's "Code is designed by layer" (minty-quail's: data and configuration,
the domain model, the world, simulation, run flow, observers), with the screen's own view beside the
observers and the composition root at the top. A layer may name only what is on its own layer or
below, and the observers and the view, which stand at one level, name neither the other (the
player's, inbox #904 in freckled-moose);
the world and simulation layers are also handed what they read rather than fetching it through a
group, an autoload or a static holding state.

Every file under `src/` is in exactly one layer: its own entry in `FILES`, or else its folder's
in `FOLDERS` (the nearest folder that has one). A file in neither fails the check, so a new folder
is placed in a layer the day it appears.

`EXCEPTIONS` lists, by file and by what it names or fetches, every place that breaks the map on
`main` today, each group with one line saying why it still stands. It only shrinks: a new break
fails the check, and so does a listed one that is gone, so the pull request that fixes one deletes
its line.
"""

from __future__ import annotations

from dataclasses import dataclass

# Lowest first. Each names only its own layer and those before it (siblings aside, below).
LAYERS: tuple[str, ...] = ("data", "model", "world", "simulation", "flow", "observers", "view", "root")

# Layers at one level: both sit on top of the run flow and the simulation and read from below, and
# neither may name the other.
SIBLINGS: tuple[tuple[str, ...], ...] = (("observers", "view"),)

LAYER_TEXT: dict[str, str] = {
    "data": "data and configuration: the catalogue, the balance numbers, the run's configuration, the specs, the "
    "on-screen texts, the art's pages and the value types the rows are written in",
    "model": "the domain model: pure state and plans with no scene of their own -- the map and its interface "
    "(WorldMap and its records), its generation, the routes, the closures, the run's sub-states, the building's plan",
    "world": "the world: the navigator, passability, the draw layers, the screen cover and what the world can "
    "see, and the scene nodes that draw the world's own ground and furniture (the map interface and its "
    "records are the model's) and the rim a body draws round itself",
    "simulation": "simulation: everything that moves or happens -- her, the baby, the crowd, the events and "
    "their behaviours and looks, the resistance -- and the drawing of each, which it composes",
    "flow": "run flow: a day started and finished from its spec, the screens' order",
    "observers": "observers (a sibling of the view): the run log, GoatCounter, the save and the developer's "
    "readouts, which only listen",
    "view": "the view (a sibling of the observers): the screen's own furniture -- the HUD, the screens, the "
    "badges, the halo's lighting, the controls",
    "root": "the composition root and the rigs: main, which builds every layer and hands each what it needs, "
    "and the developer's rigs that drive the game from outside",
}

# The layers that are handed what they read: a group lookup, an autoload or a stateful static
# read there is a fetch.
HANDED: tuple[str, ...] = ("world", "simulation")

FOLDERS: dict[str, str] = {
    "src/autoload": "observers",
    "src/city": "world",
    "src/crowd": "simulation",
    "src/day": "flow",
    "src/dev": "root",
    "src/events": "simulation",
    "src/finale": "model",
    "src/interior": "world",
    "src/player": "simulation",
    "src/resistance": "simulation",
    "src/routes": "model",
    "src/run": "model",
    "src/telemetry": "observers",
    "src/ui": "view",
    "src/visuals": "data",
    "src/world": "world",
}

# Where a folder mixes layers, the files that are not its folder's.
FILES: dict[str, str] = {
    # src/ itself has no folder layer: each file is placed.
    "src/build_info.gd": "data",
    "src/drawn_frame.gd": "observers",  # the run log's screen and the rigs wait on it; it only listens
    "src/field.gd": "data",
    "src/frame_timing.gd": "data",
    "src/game_enums.gd": "data",
    "src/ground_shape.gd": "data",
    "src/main.gd": "root",
    "src/offscreen.gd": "data",
    "src/palette.gd": "data",
    "src/run_config.gd": "data",
    "src/run_trace.gd": "model",
    "src/sprites.gd": "world",
    "src/web_display.gd": "view",
    # autoload: the balance numbers are data, the signals are the model, and so is what a sitting
    # keeps across a scene reload, which the view and the observers are handed.
    "src/autoload/tuning.gd": "data",
    "src/autoload/event_bus.gd": "model",
    "src/autoload/sitting.gd": "model",
    # city: the map, its generation and its run-scoped state are the model; the scene and its
    # furniture (the folder's own layer) are the world.
    "src/city/block_layout.gd": "model",
    "src/city/block_plan.gd": "model",
    "src/city/city_generator.gd": "model",
    "src/city/city_map.gd": "model",
    "src/city/city_state.gd": "model",
    "src/city/garbage_sacks.gd": "model",
    "src/city/held_streets.gd": "model",
    "src/city/ground_tiles.gd": "model",
    "src/city/litter.gd": "model",
    "src/city/marble_bag.gd": "model",
    "src/city/pelican_state.gd": "model",
    "src/city/poster_state.gd": "model",
    "src/city/tile.gd": "model",
    "src/city/traffic_signals.gd": "model",
    "src/city/street_trees.gd": "model",
    "src/city/street_layout.gd": "model",
    "src/city/blackout.gd": "simulation",
    "src/city/poster_walls.gd": "simulation",
    "src/city/recipe_city_builder.gd": "root",
    "src/city/recipe_city_context.gd": "root",
    # crowd: the lanes' geometry is a function of the map and the lane numbers, so the generation and
    # the street trees that plan on it name it from the model.
    "src/crowd/crowd_lanes.gd": "model",
    # day: the spec is data, the loss rules are the model, the controller (the folder's) is flow.
    "src/day/day_spec.gd": "data",
    "src/day/loss_cause.gd": "model",
    # dev: the flag parser is configuration; the readouts observe; the rest are rigs.
    "src/dev/dev_flags.gd": "data",
    "src/dev/debug_layers.gd": "observers",
    "src/dev/debug_mode_note.gd": "observers",
    "src/dev/debug_readout.gd": "observers",
    "src/dev/route_lines.gd": "observers",
    # events: the rows and the specs they are written in are data; the plan-builders, pure
    # functions of the map and the day, are the model; the rest (the folder's) is simulation.
    "src/events/abduction_spec.gd": "data",
    "src/events/aftermath.gd": "data",
    "src/events/day_switch.gd": "data",
    "src/events/event_catalogue.gd": "data",
    "src/events/event_def.gd": "data",
    "src/events/event_scenery_parts.gd": "data",
    "src/events/hunt_spec.gd": "data",
    "src/events/notice_spec.gd": "data",
    "src/events/on_her_way.gd": "data",
    "src/events/placement_view.gd": "data",
    "src/events/pursuit_spec.gd": "data",
    "src/events/vehicle_spec.gd": "data",
    "src/events/calm_areas.gd": "model",
    "src/events/day_events.gd": "model",
    "src/events/day_locations.gd": "model",
    "src/events/day_reach.gd": "model",
    "src/events/event_scheduler.gd": "model",
    "src/events/location.gd": "model",
    "src/events/location_draw.gd": "model",
    "src/events/location_fit.gd": "model",
    "src/events/location_ground.gd": "model",
    "src/events/mast_sites.gd": "model",
    "src/events/roadblock_ground.gd": "model",
    "src/events/roadblock_phase.gd": "model",
    "src/events/scripted_phase.gd": "model",
    "src/events/street_locations.gd": "model",
    "src/events/street_invalidation.gd": "model",
    "src/events/street_rule.gd": "model",
    "src/events/street_rules/door_clearance_rule.gd": "model",
    "src/events/street_rules/one_notice_rule.gd": "model",
    "src/events/street_rules/pacing_opening_rule.gd": "model",
    "src/events/street_rules/route_junctions_rule.gd": "model",
    "src/events/street_rules/route_reach_rule.gd": "model",
    "src/events/street_rules/route_sidewalk_rule.gd": "model",
    "src/events/street_rules/unused_calm_rule.gd": "model",
    "src/events/street_rules/walk_open_rule.gd": "model",
    "src/events/view_bag.gd": "model",
    "src/events/walk_events.gd": "model",
    "src/events/walk_ground.gd": "model",
    # interior: the plan and its tiles are the model; the tileset and the scene are the world.
    "src/interior/interior_map.gd": "model",
    "src/interior/interior_map_plan.gd": "model",
    "src/interior/interior_tile.gd": "model",
    # resistance: the calendar is data.
    "src/resistance/resistance_steps.gd": "data",
    # routes: the barrier and fence panels are the world's furniture.
    "src/routes/closure_marker.gd": "world",
    "src/routes/park_fence_marker.gd": "world",
    # world: the map's interface, who asks it, and the records it keeps (what stands on its ground,
    # every mover's move) are what the domain's maps implement and hold -- CityMap and the
    # building's plan extend WorldMap -- so they sit with the maps in the model. The map's separation
    # pass is the geometry over its list of moves, which the map holds and which reads only that list.
    "src/world/blocked_layer.gd": "model",
    "src/world/move_proposal.gd": "model",
    "src/world/mover.gd": "model",
    "src/world/proposed_moves.gd": "model",
    "src/world/separation_pass.gd": "model",
    "src/world/world_map.gd": "model",
    # run: the day's director, the screens' flow and an authored scene's ask are flow.
    "src/run/authored_scene.gd": "flow",
    "src/run/day_director.gd": "flow",
    "src/run/run_flow.gd": "flow",
    # visuals: the art's pages are data; the ground's picture builder names the model's tile choice and is
    # called only by the scene nodes that draw the world's ground, so it stands with them.
    "src/visuals/ground_layers.gd": "world",
    # ui: the texts are data; the frame graph is a developer's readout; the halo's rim is the drawing
    # a body composes of itself, so it stands in the world beside the excitement source that holds it.
    "src/ui/entity_halo.gd": "world",
    "src/ui/source_rim.gd": "world",
    "src/ui/texts.gd": "data",
    "src/ui/frame_graph.gd": "observers",
}

# An autoload read as constants is data, not a fetch.
CONSTANT_AUTOLOADS: dict[str, str] = {
    "Tuning": "the shared balance numbers, read as constants and pure functions of them",
}

# A `static var` that holds no state: a table or a cache that depends on nothing a caller did.
# Every other `static var` is state, and reading it from the world or simulation layers is a fetch.
STATIC_CACHES: dict[str, str] = {
    "CityMap._WALKABLE": "a lookup table built from Tile's constants",
    "CityMap._CALM": "a lookup table built from Tile's constants",
    "Mover._shared": "interned movers, each a pure function of its layers and width",
    "LaneStrategy._closed_today": "a constant mover",
    "WalkerStrategy._walker_today": "a constant mover",
    "WalkerStrategy._soft_sealed_today": "a constant mover",
    "WalkerStrategy._bodies_today": "a constant mover",
    "CarStrategy._car_today": "a constant mover",
    "ResistanceSteps._all": "the calendar, built once from constants",
    "EventFootprints._warning_sizes": "sizes read off the baked pictures, the same on every read",
    "EventFootprints._warning_guard": "a size read off the baked pictures, the same on every read",
    "EntityHalo._shared_material": "one shader material every halo shares",
    "EventCatalogue._all": "the catalogue's rows, built once from constants",
    "EventCatalogue._hot": "derived rows, each built once from the catalogue",
    "EventCatalogue._building_fire": "a derived row, built once from the catalogue",
    "EventCatalogue._explosion_outside": "a derived row, built once from the catalogue",
    "EventCatalogue._lesson_dog": "a derived row, built once from the catalogue",
    "EventCatalogue._task_guard": "a derived row, built once from the catalogue",
    "EventCatalogue._out_of_the_car": "derived rows, each built once from the catalogue",
    "EventCatalogue._task_guard_sent": "a derived row, built once from the catalogue",
    "EventInstance._NO_BIRDS": "an empty list, never written",
    "EventExcitement._NO_WALLS": "open ground, never written",
    "AtlasTable._baked": "the baked region table, read once from the bake's file and never written",
}


@dataclass(frozen=True)
class Exception_:
    """Breaks of the map standing on `main`, one reason for the files listed."""

    rule: str  # "names" (a higher layer's class), "group", "autoload" or "static"
    name: str  # the class, group, autoload or `Class.member` named
    reason: str
    files: tuple[str, ...]
    # Files with more than one use of the name, and how many: a file's count is one unless it is here.
    more: tuple[tuple[str, int], ...] = ()


EXCEPTIONS: tuple[Exception_, ...] = (
    Exception_(
        "names",
        "Blackout",
        "the city scene builds the blackout itself, rather than the composition root handing it in",
        ("src/city/city.gd",),
        more=(("src/city/city.gd", 2),),
    ),
    Exception_(
        "names",
        "BlockLayout",
        "the calendar computes its own task targets on the map",
        ("src/resistance/resistance_steps.gd",),
    ),
    Exception_(
        "names",
        "City",
        "the scheduler reads the burnt frontage's scar name off the city scene",
        ("src/events/event_scheduler.gd",),
    ),
    Exception_(
        "names",
        "CityEdge",
        "the tunnel-or-bridge kind lives on the edge's drawing class",
        (
            "src/finale/finale_planner.gd",
            "src/ui/texts.gd",
        ),
        more=(
            ("src/finale/finale_planner.gd", 10),
            ("src/ui/texts.gd", 2),
        ),
    ),
    Exception_(
        "names",
        "CityGenerator",
        "the calendar computes its own task targets on the map",
        ("src/resistance/resistance_steps.gd",),
    ),
    Exception_(
        "names",
        "CityMap",
        "the calendar computes its own task targets on the map",
        ("src/resistance/resistance_steps.gd",),
    ),
    Exception_(
        "names",
        "Crowd",
        "the city scene builds the day's crowd itself, rather than the composition root handing it in",
        ("src/city/city.gd",),
        more=(("src/city/city.gd", 2),),
    ),
    Exception_(
        "names",
        "CrowdTiming",
        "the city scene hands the crowd its timing sink, since it builds the crowd",
        ("src/city/city.gd",),
    ),
    Exception_(
        "names",
        "CrowdView",
        "the city scene hands the crowd its view, since it builds the crowd",
        ("src/city/city.gd",),
    ),
    Exception_(
        "names",
        "DangerEdge",
        "telemetry to be handed what it reports",
        (
            "src/telemetry/run_session.gd",
            "src/telemetry/telemetry_observer.gd",
        ),
        more=(
            ("src/telemetry/run_session.gd", 2),
            ("src/telemetry/telemetry_observer.gd", 2),
        ),
    ),
    Exception_(
        "names",
        "DevRig",
        "a day's start asks the dev rig where a --spawn target is",
        ("src/run/day_director.gd",),
        more=(("src/run/day_director.gd", 2),),
    ),
    Exception_(
        "names",
        "DrawLayer",
        "the map interface adds a node to its world on a draw layer, the world's half of it",
        ("src/world/world_map.gd",),
    ),
    Exception_(
        "names",
        "DrawnView",
        "an event's look asks the view whether its picture is on the screen",
        (
            "src/events/views/event_look.gd",
            "src/events/views/roadblock_look.gd",
        ),
    ),
    Exception_(
        "names",
        "EventFootprints",
        "the day's planning reads the live events' picture geometry",
        (
            "src/events/event_scheduler.gd",
            "src/events/walk_ground.gd",
        ),
        more=(
            ("src/events/event_scheduler.gd", 2),
            ("src/events/walk_ground.gd", 3),
        ),
    ),
    Exception_(
        "names",
        "EventInstance",
        "the day's planning reaches into the live event for its placement rules",
        (
            "src/events/event_scheduler.gd",
            "src/events/walk_ground.gd",
        ),
        more=(
            ("src/events/event_scheduler.gd", 2),
            ("src/events/walk_ground.gd", 1),
        ),
    ),
    Exception_(
        "names",
        "EventManager",
        "the city scene builds the day's events itself, rather than the composition root handing them in",
        ("src/city/city.gd",),
        more=(("src/city/city.gd", 2),),
    ),
    Exception_(
        "names",
        "EventSpawner",
        "placement rules live on the spawner the city reaches into",
        ("src/city/city.gd",),
    ),
    Exception_(
        "names",
        "HelpText",
        "the texts compose the controls' token, and she tells the controls through their class",
        (
            "src/player/stroller.gd",
            "src/ui/texts.gd",
        ),
    ),
    Exception_(
        "names",
        "Navigator",
        "the map interface hands out its navigator, the world's half of it",
        ("src/world/world_map.gd",),
        more=(("src/world/world_map.gd", 3),),
    ),
    Exception_(
        "names",
        "PosterWalls",
        "the city scene builds the posters itself, rather than the composition root handing them in",
        ("src/city/city.gd",),
        more=(("src/city/city.gd", 3),),
    ),
    Exception_(
        "names",
        "Prop",
        "the street trees' planner names the tree props it places",
        ("src/city/street_trees.gd",),
    ),
    Exception_(
        "names",
        "RegionPlanner",
        "the calendar computes its own task targets on the map",
        ("src/resistance/resistance_steps.gd",),
    ),
    Exception_(
        "names",
        "ResistanceHappenings",
        "the run reads the day of the neighbor's raid (NEIGHBOR_DAY) to say whether she was taken",
        ("src/run/run_state.gd",),
    ),
    Exception_(
        "names",
        "ScreenOrientation",
        "her input is turned by the screen's rotation, read from the view",
        ("src/player/stroller.gd",),
    ),
    Exception_(
        "names",
        "SpawnSiting",
        "a row's lead is checked against the siting's least distance",
        ("src/events/event_def.gd",),
        more=(("src/events/event_def.gd", 2),),
    ),
    Exception_(
        "names",
        "Stroller",
        "her class's constants (the camera's look-ahead) and type tests are read where she is not handed in",
        (
            "src/city/city.gd",
            "src/events/event_scheduler.gd",
            "src/interior/interior_scene.gd",
            "src/world/visible_view.gd",
        ),
        more=(
            ("src/events/event_scheduler.gd", 3),
            ("src/interior/interior_scene.gd", 2),
        ),
    ),
    Exception_(
        "names",
        "WorldContext",
        "the map interface answers with its world's context, the world's half of it",
        ("src/world/world_map.gd",),
    ),
    Exception_(
        "autoload",
        "EventBus",
        "the world and simulation report on the global signal bus, not a domain-event sink they are handed",
        (
            "src/city/blackout.gd",
            "src/city/poster_walls.gd",
            "src/crowd/crowd.gd",
            "src/events/encounter_watch.gd",
            "src/events/event_instance.gd",
            "src/events/event_manager.gd",
            "src/events/event_spawner.gd",
            "src/events/events_ahead.gd",
            "src/player/baby.gd",
            "src/resistance/park_cordon.gd",
            "src/resistance/resistance_director.gd",
        ),
        more=(
            ("src/city/blackout.gd", 2),
            ("src/crowd/crowd.gd", 3),
            ("src/events/encounter_watch.gd", 5),
            ("src/events/event_instance.gd", 3),
            ("src/events/event_manager.gd", 5),
            ("src/events/event_spawner.gd", 4),
            ("src/events/events_ahead.gd", 2),
            ("src/player/baby.gd", 9),
            ("src/resistance/resistance_director.gd", 2),
        ),
    ),
    Exception_(
        "group",
        "HelpText.CONTROLS_GROUP",
        "she tells the on-screen controls to stand still through their group",
        ("src/player/stroller.gd",),
    ),
    Exception_(
        "group",
        "player",
        "the blackout and the posters find her through the player group, where the crowd is now handed her",
        (
            "src/city/blackout.gd",
            "src/city/poster_walls.gd",
        ),
    ),
    Exception_(
        "names",
        "GameSave",
        "the save indicator reads the save's state, rather than being handed it",
        ("src/ui/save_indicator.gd",),
        more=(("src/ui/save_indicator.gd", 2),),
    ),
)
