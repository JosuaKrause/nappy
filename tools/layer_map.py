"""The layer map `tools/check_layers.py` holds the game's code to, as data.

The layers are orchestrating's "Code is designed by layer" (minty-quail's: data and configuration,
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
    "records are the model's)",
    "simulation": "simulation: everything that moves or happens -- her, the baby, the crowd, the events and "
    "their behaviours and looks, the resistance -- and the drawing of each, which it composes",
    "flow": "run flow: a day started and finished from its spec, the screens' order",
    "observers": "observers (a sibling of the view): the run log, GoatCounter, the save and the developer's "
    "readouts, which only listen",
    "view": "the view (a sibling of the observers): the screen's own furniture -- the HUD, the screens, the "
    "badges, the halo, the controls",
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
    "src/drawn_frame.gd": "view",
    "src/field.gd": "data",
    "src/game_enums.gd": "data",
    "src/ground_shape.gd": "data",
    "src/main.gd": "root",
    "src/offscreen.gd": "data",
    "src/palette.gd": "data",
    "src/run_config.gd": "data",
    "src/run_trace.gd": "model",
    "src/sprites.gd": "world",
    "src/web_display.gd": "view",
    # autoload: the balance numbers are data, the run's registry and its signals are the model.
    "src/autoload/tuning.gd": "data",
    "src/autoload/event_bus.gd": "model",
    "src/autoload/game_state.gd": "model",
    # city: the map, its generation and its run-scoped state are the model; the scene and its
    # furniture (the folder's own layer) are the world.
    "src/city/block_layout.gd": "model",
    "src/city/block_plan.gd": "model",
    "src/city/city_generator.gd": "model",
    "src/city/city_map.gd": "model",
    "src/city/city_state.gd": "model",
    "src/city/garbage_sacks.gd": "model",
    "src/city/ground_tiles.gd": "model",
    "src/city/litter.gd": "model",
    "src/city/marble_bag.gd": "model",
    "src/city/pelican_state.gd": "model",
    "src/city/poster_state.gd": "model",
    "src/city/tile.gd": "model",
    "src/city/traffic_signals.gd": "model",
    "src/city/street_trees.gd": "model",
    "src/city/blackout.gd": "simulation",
    "src/city/poster_walls.gd": "simulation",
    "src/city/recipe_city_builder.gd": "root",
    "src/city/recipe_city_context.gd": "root",
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
    "src/events/pursuit_spec.gd": "data",
    "src/events/vehicle_spec.gd": "data",
    "src/events/event_scheduler.gd": "model",
    "src/events/mast_sites.gd": "model",
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
    # run: the day's director, its end, the screens' flow and an authored scene's ask are flow.
    "src/run/authored_scene.gd": "flow",
    "src/run/day_director.gd": "flow",
    "src/run/day_end.gd": "flow",
    "src/run/run_flow.gd": "flow",
    # ui: the texts are data; the frame graph is a developer's readout.
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
    "ReachabilityGrid._mask_components": "the components of a 2x2 mask, pure geometry",
    "ResistanceSteps._all": "the calendar, built once from constants",
    "EventFootprints._warning_sizes": "sizes read off the baked pictures, the same on every read",
    "EventFootprints._warning_guard": "a size read off the baked pictures, the same on every read",
    "PosterArt._torn": "the torn posters' textures, composed once from the baked page",
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
        "CrowdLanes",
        "the lane geometry's constants live on the crowd's class, and the city's generation needs them",
        (
            "src/city/city.gd",
            "src/city/city_generator.gd",
            "src/city/street_trees.gd",
        ),
        more=(
            ("src/city/city.gd", 2),
            ("src/city/city_generator.gd", 3),
        ),
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
            ("src/telemetry/telemetry_observer.gd", 3),
        ),
    ),
    Exception_(
        "names",
        "DayEnd",
        "the summary's model is built from the day's end, which sits with the run flow",
        ("src/run/summary_model.gd",),
        more=(("src/run/summary_model.gd", 2),),
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
        "DrawnFrame",
        "telemetry to be handed what it reports",
        ("src/autoload/telemetry.gd",),
        more=(("src/autoload/telemetry.gd", 2),),
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
        "EntityHalo",
        "each body composes the halo's rim and margin rather than the view drawing over it",
        (
            "src/crowd/crowd_agent.gd",
            "src/events/event_footprints.gd",
            "src/events/event_instance.gd",
            "src/events/views/event_look.gd",
        ),
        more=(
            ("src/crowd/crowd_agent.gd", 2),
            ("src/events/event_instance.gd", 5),
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
            ("src/events/event_scheduler.gd", 3),
            ("src/events/walk_ground.gd", 3),
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
        "placement rules live on the spawner the planner and the city both reach into",
        (
            "src/city/city.gd",
            "src/events/event_scheduler.gd",
        ),
    ),
    Exception_(
        "names",
        "FrameLedger",
        "the developer's frame timing is read from its record rather than handed a sink, as the crowd now is",
        (
            "src/city/building.gd",
            "src/city/building_shadows.gd",
            "src/city/city_decals.gd",
            "src/city/city_edge.gd",
            "src/city/prop.gd",
            "src/city/scenery_layer.gd",
            "src/city/scenery_residency.gd",
            "src/city/scenery_water.gd",
            "src/city/traffic_light.gd",
            "src/events/event_instance.gd",
            "src/player/stroller.gd",
            "src/resistance/contact_point.gd",
            "src/routes/closure_marker.gd",
            "src/routes/park_fence_marker.gd",
        ),
        more=(
            ("src/city/building.gd", 4),
            ("src/city/scenery_residency.gd", 10),
        ),
    ),
    Exception_(
        "names",
        "FrameRecord",
        "the developer's frame timing is read from its record rather than handed a sink, as the crowd now is",
        (
            "src/city/building.gd",
            "src/city/building_shadows.gd",
            "src/city/city_decals.gd",
            "src/city/city_edge.gd",
            "src/city/prop.gd",
            "src/city/scenery_layer.gd",
            "src/city/scenery_residency.gd",
            "src/city/scenery_water.gd",
            "src/city/traffic_light.gd",
            "src/events/event_instance.gd",
            "src/events/event_manager.gd",
            "src/player/baby.gd",
            "src/player/stroller.gd",
            "src/resistance/contact_point.gd",
            "src/routes/closure_marker.gd",
            "src/routes/park_fence_marker.gd",
        ),
        more=(
            ("src/city/building.gd", 8),
            ("src/city/building_shadows.gd", 2),
            ("src/city/city_decals.gd", 2),
            ("src/city/city_edge.gd", 2),
            ("src/city/prop.gd", 2),
            ("src/city/scenery_layer.gd", 2),
            ("src/city/scenery_residency.gd", 14),
            ("src/city/scenery_water.gd", 2),
            ("src/city/traffic_light.gd", 2),
            ("src/events/event_instance.gd", 7),
            ("src/events/event_manager.gd", 4),
            ("src/player/baby.gd", 4),
            ("src/player/stroller.gd", 2),
            ("src/resistance/contact_point.gd", 2),
            ("src/routes/closure_marker.gd", 2),
            ("src/routes/park_fence_marker.gd", 2),
        ),
    ),
    Exception_(
        "names",
        "GameSave",
        "the calendar hands the save the registry at a checkpoint and clears the save when a run ends",
        ("src/run/run_calendar.gd",),
        more=(("src/run/run_calendar.gd", 3),),
    ),
    Exception_(
        "names",
        "GroundTiles",
        "the ground's picture builder reads which tile a cell gets",
        ("src/visuals/ground_layers.gd",),
        more=(("src/visuals/ground_layers.gd", 4),),
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
        "the run's registry keeps the resistance's happenings as one of its parts",
        ("src/autoload/game_state.gd",),
    ),
    Exception_(
        "names",
        "ScreenOrientation",
        "her input is turned by the screen's rotation, read from the view",
        ("src/player/stroller.gd",),
    ),
    Exception_(
        "names",
        "SourceRim",
        "each body composes the halo's rim rather than the view drawing over it",
        (
            "src/crowd/crowd_agent.gd",
            "src/events/event_instance.gd",
        ),
        more=(("src/events/event_instance.gd", 3),),
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
        "StreetNetwork",
        "the calendar computes its own task targets on the map",
        ("src/resistance/resistance_steps.gd",),
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
        "Telemetry",
        "the ground's picture builder writes its timing to the run log inline",
        ("src/visuals/ground_layers.gd",),
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
        "static",
        "AtlasLibrary",
        "the baked pages are loaded and held in statics (hidden-statics)",
        (
            "src/city/building.gd",
            "src/city/city.gd",
            "src/city/city_decals.gd",
            "src/city/city_edge.gd",
            "src/city/poster_art.gd",
            "src/city/prop.gd",
            "src/city/scenery_water.gd",
            "src/city/traffic_light.gd",
            "src/crowd/car_look.gd",
            "src/crowd/crowd.gd",
            "src/crowd/walker_look.gd",
            "src/events/event_manager.gd",
            "src/events/event_scenery.gd",
            "src/events/views/event_pictures.gd",
            "src/interior/interior_scene.gd",
            "src/interior/interior_tileset.gd",
            "src/player/stroller.gd",
            "src/resistance/contact_point.gd",
            "src/resistance/cordon_officer.gd",
            "src/resistance/cordon_tape.gd",
            "src/routes/closure_marker.gd",
            "src/routes/park_fence_marker.gd",
        ),
        more=(
            ("src/city/building.gd", 33),
            ("src/city/city.gd", 8),
            ("src/city/city_decals.gd", 4),
            ("src/city/city_edge.gd", 8),
            ("src/city/poster_art.gd", 4),
            ("src/city/prop.gd", 11),
            ("src/city/scenery_water.gd", 3),
            ("src/city/traffic_light.gd", 4),
            ("src/crowd/car_look.gd", 5),
            ("src/crowd/crowd.gd", 2),
            ("src/crowd/walker_look.gd", 3),
            ("src/events/event_manager.gd", 2),
            ("src/events/event_scenery.gd", 4),
            ("src/events/views/event_pictures.gd", 2),
            ("src/interior/interior_scene.gd", 14),
            ("src/interior/interior_tileset.gd", 2),
            ("src/player/stroller.gd", 10),
            ("src/resistance/contact_point.gd", 3),
            ("src/resistance/cordon_officer.gd", 3),
            ("src/resistance/cordon_tape.gd", 7),
            ("src/routes/closure_marker.gd", 8),
            ("src/routes/park_fence_marker.gd", 4),
        ),
    ),
    Exception_(
        "static",
        "DrawnView",
        "the on-screen box is cached per frame in statics",
        (
            "src/events/views/event_look.gd",
            "src/events/views/roadblock_look.gd",
        ),
    ),
    Exception_(
        "static",
        "EventScheduler",
        "the scheduler keeps its kept-ground memo and judgement count in statics (hidden-statics)",
        ("src/events/day_planner.gd",),
        more=(("src/events/day_planner.gd", 2),),
    ),
    Exception_(
        "static",
        "FrameRecord",
        "the developer's frame timing is switched on in a static rather than handed a sink, as the crowd now is",
        (
            "src/city/building.gd",
            "src/city/building_shadows.gd",
            "src/city/city_decals.gd",
            "src/city/city_edge.gd",
            "src/city/prop.gd",
            "src/city/scenery_layer.gd",
            "src/city/scenery_residency.gd",
            "src/city/scenery_water.gd",
            "src/city/traffic_light.gd",
            "src/events/event_instance.gd",
            "src/events/event_manager.gd",
            "src/player/baby.gd",
            "src/player/stroller.gd",
            "src/resistance/contact_point.gd",
            "src/routes/closure_marker.gd",
            "src/routes/park_fence_marker.gd",
        ),
        more=(
            ("src/city/building.gd", 8),
            ("src/city/building_shadows.gd", 2),
            ("src/city/city_decals.gd", 2),
            ("src/city/city_edge.gd", 2),
            ("src/city/prop.gd", 2),
            ("src/city/scenery_layer.gd", 2),
            ("src/city/scenery_residency.gd", 13),
            ("src/city/scenery_water.gd", 2),
            ("src/city/traffic_light.gd", 2),
            ("src/events/event_instance.gd", 6),
            ("src/events/event_manager.gd", 3),
            ("src/player/baby.gd", 3),
            ("src/player/stroller.gd", 2),
            ("src/resistance/contact_point.gd", 2),
            ("src/routes/closure_marker.gd", 2),
            ("src/routes/park_fence_marker.gd", 2),
        ),
    ),
    Exception_(
        "static",
        "GroundLayers",
        "the ground's manifest is read once into statics (hidden-statics)",
        ("src/city/city.gd",),
    ),
    Exception_(
        "static",
        "SealPlanner",
        "the seal candidates are held in statics (hidden-statics)",
        ("src/events/day_planner.gd",),
        more=(("src/events/day_planner.gd", 2),),
    ),
    Exception_(
        "static",
        "Sprites",
        "the drawing pass's transform is a static, so no draw call has to carry it (its own comment says why)",
        (
            "src/city/building.gd",
            "src/city/prop.gd",
            "src/city/traffic_light.gd",
            "src/crowd/car_look.gd",
            "src/crowd/crowd_agent.gd",
            "src/crowd/walker_look.gd",
            "src/events/views/event_look.gd",
            "src/events/views/event_vehicle_look.gd",
            "src/events/views/figure_look.gd",
            "src/events/views/fire_look.gd",
            "src/events/views/flock_look.gd",
            "src/events/views/pursuer_look.gd",
            "src/events/views/rank_look.gd",
            "src/events/views/spread_look.gd",
            "src/player/stroller.gd",
            "src/resistance/cordon_officer.gd",
            "src/resistance/cordon_tape.gd",
            "src/routes/closure_marker.gd",
            "src/routes/park_fence_marker.gd",
            "src/sprites.gd",
        ),
        more=(
            ("src/city/building.gd", 7),
            ("src/city/prop.gd", 5),
            ("src/city/traffic_light.gd", 2),
            ("src/crowd/car_look.gd", 3),
            ("src/crowd/crowd_agent.gd", 2),
            ("src/crowd/walker_look.gd", 2),
            ("src/events/views/event_look.gd", 6),
            ("src/events/views/event_vehicle_look.gd", 2),
            ("src/events/views/figure_look.gd", 9),
            ("src/events/views/fire_look.gd", 3),
            ("src/events/views/pursuer_look.gd", 2),
            ("src/events/views/rank_look.gd", 4),
            ("src/events/views/spread_look.gd", 3),
            ("src/player/stroller.gd", 4),
            ("src/routes/closure_marker.gd", 5),
            ("src/routes/park_fence_marker.gd", 3),
        ),
    ),
    Exception_(
        "static",
        "StreetNetwork",
        "the lattice's graph is held in statics (hidden-statics)",
        (
            "src/crowd/crowd.gd",
            "src/crowd/crowd_pockets.gd",
            "src/crowd/lane_mover.gd",
            "src/crowd/walker_strategy.gd",
            "src/events/day_planner.gd",
            "src/resistance/happenings.gd",
        ),
    ),
    Exception_(
        "names",
        "FrameLedger",
        "the view times its own draw through the frame record, rather than being handed a timing sink",
        (
            "src/ui/danger_edge.gd",
            "src/ui/entity_halo.gd",
            "src/ui/home_arrow.gd",
            "src/ui/meter_bar.gd",
            "src/ui/mode_button.gd",
            "src/ui/touch_controls.gd",
        ),
    ),
    Exception_(
        "names",
        "FrameRecord",
        "the view times its own draw through the frame record, rather than being handed a timing sink",
        (
            "src/ui/danger_edge.gd",
            "src/ui/entity_halo.gd",
            "src/ui/excitement_halo.gd",
            "src/ui/home_arrow.gd",
            "src/ui/meter_bar.gd",
            "src/ui/mode_button.gd",
            "src/ui/touch_controls.gd",
        ),
        more=(
            ("src/ui/danger_edge.gd", 6),
            ("src/ui/entity_halo.gd", 2),
            ("src/ui/excitement_halo.gd", 4),
            ("src/ui/home_arrow.gd", 2),
            ("src/ui/meter_bar.gd", 2),
            ("src/ui/mode_button.gd", 2),
            ("src/ui/touch_controls.gd", 2),
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
