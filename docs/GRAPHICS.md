# Graphics catalogue

This catalogue answers two separate questions: what drawable art exists, and what code currently
uses it. A file is **live** only when a runtime source or scene binds it. **Prepared** means the art
has the size and registration needed by an open design, but no runtime caller yet. A filename or a
mention in a design document is not evidence that a picture appears in the game.

The SVG set below supplies the editable source graphics, under `art/`, which the engine ignores:
nothing here is loaded by the game, and every path in this document is an authoring path. What
the game draws is the baked atlas page a picture is on, under the region name its path gives it —
`art/tiles/road.svg` is the region `tiles/road`. Registered PNG replacements under
`art/illustrated/svg-transfer/` are what the default bake takes where one exists; every PNG asset
needs an SVG first.

## Shared drawing contract

`src/sprites.gd` owns the ground-plane contract used by the player, crowd, events and props:
`draw_standing()` puts the bottom centre of a texture at the node's world position and mirrors
about that point, while `draw_shadow()` draws the contact-shadow ellipse every point-shaped object
casts. `GroundShape` (`src/ground_shape.gd`) draws point shadows as vertically squashed circles,
segment shadows as capsules with circular ends along the ground axis, and building rectangles
with vertical squash after rotation. The generic shadow SVG is absent; the car-accident scenes
retain their authored ground-contact shadow textures. Unless a row below says otherwise, an actor
or prop SVG is bottom-centre anchored by `draw_standing()`.

Some visible graphics are code rather than image files:

| Drawing | Owner and current use |
|---|---|
| Ground selection | `src/city/ground_tiles.gd` maps city tile types and their exposed edges to TileSet source IDs; `src/city/city.gd` paints them into the `Ground` `TileMapLayer`. |
| Building assembly | `src/city/building.gd` repeats wall, roof, edge and window textures into each generated footprint and tints the wall and roof fields. |
| Danger carets | `Sprites.draw_caret()` supplies the shared filled chevron used above live events and crowd traffic. `src/ui/danger_edge.gd` separately draws screen-edge chevrons, a circular icon backing and an event's own silhouette. |
| Event composites | `src/events/event_instance.gd` arranges repeated barriers, café furniture, crowds, muzzle flashes, leads, shadows and state-dependent poses around each event's ground point. |
| Traffic lamps | `src/city/traffic_light.gd` combines one of three signal-head SVG views with red, amber or green rectangles driven by the signal phase. |
| Player cues | `src/player/stroller.gd` assembles the selected parent and pram, then places the baby-state texture above the pram and the alert texture above the parent. |
| HUD and touch controls | `src/ui/meter_bar.gd`, `home_arrow.gd`, `danger_edge.gd`, `mode_button.gd` and `touch_controls.gd` draw bars, labels, chevrons, button plates and touch focus shapes; the button glyphs named below are SVGs. |
| Excitement halo | `src/ui/entity_halo.gd` applies `assets/shaders/excitement_halo.gdshader` to a duplicated source drawing. This is shader output rather than an SVG asset. |

## Live SVG assets

### City ground and buildings

| Assets | Runtime binding and behaviour |
|---|---|
| The pictures named by `assets/ground_tileset.tres` | `scenes/world/city.tscn` binds this TileSet to the `Ground` layer, and `GroundTiles` chooses the source for roads, main-road lines, crossings, pavements and kerbs, alleys, open grounds, water edges and the city boundary. Each source carries its picture's baked region name (`tiles/road` for `art/tiles/road.svg`) rather than a texture, and `GroundLayers` composes the pixels out of the `ground` page; this indirect binding is why the tile filenames do not appear in the caller. `art/tiles/mountain.svg` is also repeated directly by `src/city/city_edge.gd` above the north edge. `art/tiles/{road,sidewalk,alley}_cracked_{hairline,cracked,broken}_{a,b}.svg` are eighteen further sources in the same set (ids 40–57): `GroundTiles._cracked()` swaps a plain road, sidewalk or alley tile for one of them from `Tuning.degradation_for(day)` and a fixed per-tile roll, never a kerb, line, crossing or main-road source — those keep their own markings. |
| `art/buildings/wall.svg`, `wall_base.svg`, `wall_edge_{e,w}.svg`, `roof.svg`, `roof_edge_{n,s,e,w}.svg`, `window_{dark,lit}.svg`, `window_tall_{dark,lit}.svg`, `window_shuttered_{dark,lit}.svg` | `src/city/building.gd` composes and tints these wall, roof and window textures; no complete-building sprite exists. Each building rolls one of three upper-floor window styles once — plain, tall sash or shuttered — and a `BOARDED` block overrides the roll and forces the shuttered pair, dark. The wall is brick in running bond and the roof weathered membrane, both in neutral greys, white where the variant's colour is multiplied in, and both seamless in both directions. The plinth is an untinted stone base course from y 26 to the ground line, and the corner and parapet overlays are a dark outline with translucent light and shade inside it, so they read on any tint and on the power station's cladding. The windows share their stone lintels and sills with the entrance door's surround: a pair of casements (plain), four sash panes under a keystone (tall sash) and closed louvred shutters in green-gray paint (shuttered), each in a painted frame with its sill's shadow on the brick. A lit window registers exactly with its dark one, and only the light changes. Every window stays between y 2 and y 31 of its cell, so the two-pixel lift over a storefront or a door keeps it inside its own row. |
| `art/props/industrial_vent.svg`/`industrial_vent_b.svg`, `roof_hvac_unit.svg`/`roof_hvac_unit_b.svg`, `roof_duct_straight.svg`/`roof_duct_corner.svg`, `roof_skylight.svg`/`roof_skylight_b.svg`, `roof_vent_stack.svg`, `roof_water_tank.svg` | `src/city/building.gd` seeds one roof-furniture table per `district` (the block's starting purpose) and paints the result on the building's own interior roof cells, above its roof tiles: vents/HVAC/a duct run on `INDUSTRIAL`, skylights on `CIVIC`, mostly water tanks with an occasional vent on `RESIDENTIAL`/`COMMERCIAL`. The vent alone animates, alternating `industrial_vent.svg` and `industrial_vent_b.svg` on a per-building timer. |
| `art/buildings/storefront_{a,b,c,d}.svg`/`storefront_{a,b,c,d}_awning.svg`/`storefront_{a,b,c,d}_shuttered.svg` | `src/city/building.gd` gives each complete two-column span of a `COMMERCIAL` building one of the four 64×36px storefronts, as a substitution for `wall_base.svg`; each has a 26×34px entrance aligned to the shared ground line. The four kinds are a grocer (`a`, green, produce crates), a cafe (`b`, dark wood and maroon, a warm room with lamps and a cake stand), a pharmacy (`c`, off-white and teal, lit shelves and a green cross) and a sign shop (`d`, oxblood and mustard, lettered boards and an arrow), drawn in one style with the entrance doors: outlined, a glazed shop door and side light in the entrance, a fascia sign with the kind's icon over a display window that reads as glass — the goods behind it, a sheen and reflections in front — above a stall riser. The awning variant puts a striped canopy with a scalloped valance in the kind's colours over the display bay, in place of the fascia and inside the picture's own footprint; the shuttered variant brings roller shutters down over both the entrance and the display, padlocked, with the paint dulled, a tag sprayed across the shutter and the fascia left up so the kind still reads. Each facade uses seeded, shuffled groups of the four types, consuming each type once before repeating and avoiding an immediate repeat across groups; its order stays fixed across days. An odd final column is blank wall rather than a window, and a one-row facade keeps its wall base so the complete store fits. The ground floor of a multi-story building draws no window to begin with (`_draws_window_at()`); the storefront's own opaque fill simply replaces the plinth the same way `wall_base.svg` does elsewhere. The shuttered variant replaces it outright on a `BOARDED` block, and — beneath the curve's own threshold — on a share of ordinary `LIVED_IN` commercial ground too; short of either, a seeded share gets the awning variant instead of the plain one. |
| `art/buildings/fire_escape_a.svg`/`fire_escape_b.svg`, `fire_escape_platform_a.svg`/`fire_escape_platform_b.svg` | `src/city/building.gd` stacks one on a seeded share of `RESIDENTIAL` facades three floors tall or more, one picture per floor, as overlays drawn after the wall rather than replacing one of its textures; a front seven columns wide or more that already carries one may stack a second, its own seeded share, at least four columns from the first. `fire_escape_{a,b}` is one floor of it: a railed balcony at a floor line on knee brackets, in front of that floor's window, with the flight hung from its east end running down parallel to the facade to the west, handrail and open treads over a stringer, to the balcony one floor below, which is drawn after it so its railing stands in front of the flight's foot. It is placed on every floor line from the top floor's down to the second floor's; `fire_escape_platform_{a,b}` is the same balcony with the flight taken out, derived path for path from it, on the first floor's floor line, so the ground floor carries only its brackets and nothing comes down to the sidewalk (`docs/playtests/PLAYTEST-124.md`, statements 13 to 17). All four are 48×64, anchor (24, 64) on the floor line of the floor below the balcony at its column's centre, reaching eight pixels into each neighboring column, in black-painted iron casting its shadow on the wall down and to the east. Every flight faces the same way, up a stack and across both variants: `a` has a potted plant and `b` is the same escape with nothing on it, not mirrored — which one shows is rolled balcony by balcony, a third of them `a` at random, rather than once for the whole escape, so both pictures are in play on every escape tall enough to show the mix (`docs/playtests/PLAYTEST-124.md`, statements 19 and 20). |
| `art/props/civic_portico.svg` | `src/city/building.gd` draws one at every `CIVIC` building's entrance, centred on the facade, as the same kind of overlay a fire escape is. 32×48, anchor (16, 48): a pediment and entablature on two columns over a dark porch with a fanlight and a pair of panelled wooden doors, and three steps down to the ground line, in the same stone as the entrance door's surround and the windows' lintels and sills. |
| `art/buildings/entrance_door.svg`/`entrance_door_industrial.svg` | `src/city/building.gd` draws one on every multi-story front that has no storefront, no portico and is not her own block (`Building.entrance_door_col()`): the steel one on an `INDUSTRIAL` block, the plain one — a stone surround and hood over a pair of panelled glazed doors — everywhere else. 32×36px, ground anchor (16, 36): one facade column wide, standing on the ground line at its column's centre as an overlay like the portico, transparent round its surround so the tinted wall shows, and rising four pixels into the row above as a storefront does, so that row's windows are lifted two pixels. |
| `art/buildings/power_station_{wall,base,clerestory,door,stack,yard}.svg` | `src/city/building.gd` draws the city's one power station (`CityMap.power_station`, dressed by `City._dress_the_power_station`) as two parts. The hall covers the door's block and the street the mass was built across: in place of the ordinary wall, windows and ground floor, its facade is `power_station_wall.svg` steel cladding cells over a `power_station_base.svg` ground course (hazard-striped band on a concrete plinth), with a `power_station_clerestory.svg` (32×64, top-left at the top wall row's cell) tall unlit window per column filling the top two wall rows — its own colours, never the variant's tint; the roof is the ordinary roof tiles. `power_station_door.svg` (64×64, ground anchor (32, 64), two facade columns) as an overlay on the ground line over `CityMap.power_station_door`, and two `power_station_stack.svg` (32×192, anchor (16, 192) at the plinth's foot) standing on its roof and rising past the lot's north edge. The other block is `power_station_yard.svg` (256×256, the block's own eight-tile lot, drawn with its bottom centre on the lot's south edge) in place of wall and roof — fenced gravel with transformers — mirrored when it lies west of the hall so its lines run toward it. The collision is the whole lot either way. |
| `art/props/tree_{a,b}.svg` | `src/city/prop.gd` chooses a tree variant, scales it and may mirror it for park, forest and street trees. Street-tree beds are drawn separately on the ground layer. |
| `art/props/tree_pit.svg` | `src/city/city_decals.gd` draws this tile-sized bed centered beneath the street tree, below buildings and upright entities. `src/city/street_trees.gd` decides placement on the residential/commercial street-tree runs. `City.refresh_street_trees()` refreshes both layers; a pit a fallen tree took is hidden for the day. |
| `art/props/{swing_frame,bollard}.svg` | `src/city/prop.gd` draws playground swing frames and perimeter bollards. |
| `art/props/litter_{apple,newspaper,cup,bag,can}.svg` | `src/city/litter.gd` (`Litter.placed()`, a pure function of `CityMap` and the day) rolls one decal per qualifying pavement, alley or square tile from `Tuning.degradation_for(day)`; `src/city/city_decals.gd` (`CityDecals`, the scene's `Decals` node, between `Ground` and `Buildings`) draws every one flat, with no body, field or y-sort. |
| `art/props/garbage_sack.svg`/`garbage_sacks_pile.svg` | `src/city/garbage_sacks.gd` (`GarbageSacks.placed()`, a pure function of `CityMap` and the day) rolls a sack in alleys from `Tuning.DEGRADATION_FIRST_DAY` and beside building fronts a couple of days later; `src/city/city.gd` (`_place_garbage_sacks()`) adds each as a `Prop` (`Kind.SACK`/`SACK_PILE`) with a `GroundShape` for its shadow and no body. |
| `art/props/{tunnel_mouth,bridge_deck,road_on}.svg` | `src/city/city_edge.gd` draws the tunnel, bridge and road continuation where a street meets the map boundary. |
| `art/props/door.svg` | `src/city/city.gd` places the home door as a `Sprite2D`. |
| `art/props/signal_head{,_back,_side}.svg` | `src/city/traffic_light.gd` chooses face-on, rear or edge-on traffic-light hardware by the arm's direction; code adds the lit lamp. |

### Player, crowd and interface

| Assets | Runtime binding and behaviour |
|---|---|
| `art/rig/{mother,father}_{front,back,side,front_diagonal,back_diagonal}_{a,b,c}.svg` | `src/player/stroller.gd` chooses among eight upright views in the run's selected family and plays A/C/B/C: opposite open contacts separated by the feet-together pose. Movement distance advances the loop; stopping selects C. East-authored side and diagonal views mirror explicitly for west. Both parents' canvases are 24×46 cardinal front/back, 26×46 side/diagonal, all bottom-center grounded. The father has short brown hair and a blue overshirt; the mother retains her red coat. |
| `art/rig/{mother,father}_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b,c}.svg` | `src/player/stroller.gd` selects the same parent's carrying family when `Stroller.carrying` is set, including the escape scene behind `--start-escape`. Three distinct poses play A, C, B, C: open contact, feet together, opposite contact, feet together. Movement distance advances the loop; stopping selects C. Five authored views supply eight directions through the same west mirrors as the pushing set. The baby's cue (`baby_{zzz,fuss,cry}.svg`) draws over the bundle at the parent's own position, with no pram sprite. |
| `art/rig/pram_{front,back,side}.svg`, `pram_{front,back}_diagonal.svg` | `src/player/stroller.gd` chooses the matching eight-direction pram view; east-authored side and diagonal views mirror explicitly for west. Native canvases are 30×30 cardinal and 36×30 side/diagonal. A uniform 7/6 drawing scale about the bottom-center anchor gives 35×35 and 42×35 rectangles, connecting the handle without lifting the wheels. The side views share the mother's ground baseline; other directions retain projected ground depth. |
| `art/props/baby_{zzz,fuss,cry}.svg` | `src/player/stroller.gd` chooses sleeping, awake/fussing or crying state above the pram. |
| `art/props/alert.svg`, `art/props/alert_close.svg` | `src/player/stroller.gd` draws the exclamation over the player when an event is about her, using the close variant at the nearer threshold. |
| `art/crowd/walker_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg`, `walker_{front,back,side,front_diagonal,back_diagonal}_{body,trim}_b.svg` | `src/crowd/crowd_agent.gd` chooses one of `EightDirection`'s eight sectors from applied travel, including steering across the lane. A stopped walker keeps its last view. `_walker_gait_phase` advances with traveled distance at the 0.09 rate also used by `Stroller._walk_phase`; `_walker_gait_frame()` alternates two crowd poses while moving and holds the rest pose at or below `WALKER_IDLE_SPEED`. The `_b` legs and shoes cross in the trim layer; front, back and side heads and coats rise one pixel, while diagonal upper bodies stay level. One `stepping` lookup selects both tinted body and untinted trim with matching transforms. West sectors mirror their east-authored partners. Every view and frame shares an 18×38 canvas and (9, 38) feet anchor. |
| `art/crowd/car_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses one of `EightDirection`'s eight sectors from the car's own `velocity()` — `heading()` (cardinal in a lane, the tangent of its own arc mid-turn) times its actual speed — so a turning car's picture sweeps through the diagonal for the length of the manoeuvre and a car stopped at a light, a gate or a give-way keeps its last view. Body and trim are bound with one transform: tinted body first, untinted trim above it. West-of-centre sectors mirror their east-authored partner. All five views are standing elevations whose bottom row is the car's nearest ground contact, so one registration rule serves the family: the drawn content's bottom edge lands on the strike box's own southernmost point, `CAR_STRIKE_HALF_LENGTH * |heading.y| + CAR_STRIKE_HALF_WIDTH * |heading.x|` south of the node — 26px along a vertical lane, 14px along a horizontal one, ≈28.28px at exactly 45°, and every value between while a car is on an arc — plus that canvas's own bottom alpha margin (`CrowdAgent.CAR_CANVAS_BOTTOM_MARGIN`: 2px for the 30×46 front/back and the 52×42 diagonals, none for the 52×30 side, whose content touches its own canvas edge). **It is read off the live heading rather than off the quantised view**, because the eight views swap at a sector boundary and a turn does not: a per-view anchor moved the body by the whole difference between two views' ground lines in the frame the texture changed. The shadow capsule and the strike box stay independent of the picture — `_car_shadow_shape()`'s own 52×30 along/across measurement is unchanged, and both orient with the same continuous heading the picture reads. **Because that heading is continuous, the redraw gate reads it too**: `CrowdAgent._redraw_if_the_picture_changed()` keys on the live heading, quantised by `CAR_HEADING_STEPS` to a step far under a pixel of anchor, alongside the sector, the mirror and the gait frame — a retained draw list invalidated on the quantised picture alone freezes a turned car's registration at the anchor it had at the last sector boundary, while the halo `EntityHalo` traces from the same body every frame stands where the car belongs. `car_end_{body,trim}.svg`, the old two-view family's foreshortened top-down picture, is unbound — see the prepared table below. |
| `art/ui/{pause,restart,continue,joystick,tap}.svg` | `src/ui/touch_controls.gd` draws `pause.svg`; `src/ui/mode_button.gd` selects the other four for pause, summary and control-mode buttons. |
| `art/ui/save.svg` | `src/ui/save_indicator.gd` draws it in the bottom-right corner of every screen, in its own blue/silver-gray/paper colours and faded (never tinted) by `SaveIndicator.flash()`, for a few seconds after each write `GameSave` actually makes. |
| `icon.svg` | `project.godot` uses the root SVG as the application icon, including the exported icon generated by Godot. |

### Interior (the escape scene, behind `--start-escape`)

`src/interior/interior_scene.gd` and `src/interior/interior_tileset.gd` own this entire family;
see `docs/ARCHITECTURE.md`, "`src/interior/`" for how the plan, the TileSet and the scene divide
the work. The building is one map holding seven parts — three hallways, two stairwells, the lobby,
the basement — spaced well apart and joined by doors that teleport rather than by shared floor; see
`InteriorMapPlan`'s own doc. Floor and wall modules are 32×32; standing sprites are bottom-centre
anchored at their own tile.

| Assets | Runtime binding and behaviour |
|---|---|
| `hallway_floor_edge_{n,e,s,w}.svg`, `basement_floor_edge_{n,e,s,w}.svg`, `basement_floor.svg`, `stairwell_floor.svg`, `stair_down.svg`, `stair_flight_{e,w}.svg`, `stair_landing.svg` | `InteriorTileSet.build()` binds one atlas source per kind, keyed on `InteriorTile.Kind`'s own enum values; `InteriorScene.build()` paints a `TileMapLayer` cell for every position `InteriorMap` carries. `stairwell_floor.svg` paints the corrected grammar's level `F` cells and the tread under each `D`. `stair_down.svg` is the basement's own entry stair: a 32×32 cell seen from the front, its treads narrowing away from her with an arrow the same way, laid as the single cell between the entry door and the corridor — the shape of the player's basement sketch, *"horizontal lines indicate a small stair leading down"*. One cell, because the picture draws a whole flight inside its own tile and two stacked read as two stairs. It is level walkable ground: `InteriorTile.flight_direction()` answers zero for it, so nothing redirects a sideways press along a slope there. The diagonal flight and landing sources remain available to the tileset but no map cell places them. `basement_floor.svg` grounds the narrow one-tile jogs between the basement's three brick-walled stretches. `hallway_floor.svg` is bound the same way but currently unused — every hallway, and the lobby, is only ever two tiles deep, so every row is one of the four edges above. |
| `hallway_wall.svg`, `hallway_wall_window.svg`, `hallway_wall_window_flash.svg`, `wall_lamp.svg`, `basement_wall_brick.svg`, `lift_door_dead.svg`, `entrance_door.svg` | `InteriorScene._rebuild_walls()` draws these at their cell's north edge. `hallway_wall_window_flash.svg` is the same window with the street outside it lit: `InteriorScene.flash_windows()` swaps it into **every** hallway window in the building at once for `Tuning.FINALE_WINDOW_FLASH_SECONDS`, and they all go dark together. There is one call and no way to light a subset — *"all windows always need to flash together. a single window cannot flash by itself"* — and both the near bangs and the far flashes between them make it; what tells them apart is how often they happen and what they cost, never which windows they reach. The 34px lift and 42px entrance use their own half-width origins and draw after the repeating strips, so their wider frames remain centered and uncut; the basement omits brick tiles at its two walkable corridor mouths. |
| `entrance_barricade.svg` | Drawn in front of the lobby entrance in `InteriorMapPlan.entrance_tiles`; the lobby has no central chandelier, which keeps the piled furniture readable. |
| `hallway_rubble.svg` | The ceiling down across the top floor, drawn by `InteriorScene._add_rubble()` over exactly the cells `InteriorMapPlan.rubble` closes — a 64×64 picture registered at the top-left of that two-by-two patch, in the wall layer with the barricade. One picture rather than one sprite per cell: a heap is a single mass, and four copies of one tile read as four crates. Its 64px depth is the corridor's whole depth, because a heap that left a row open would read as something to squeeze past. |
| `apartment_threshold.svg`, `open_threshold.svg`, `stairwell_door.svg`, `emergency_exit_door.svg` | `InteriorMapPlan.locked_thresholds` places spaced locked apartment recesses, including the start, at the hallway south edge. `InteriorScene` draws hallway, lobby and basement-entry transitions as recessed open thresholds at that edge; doors attached to stairwell landings and the service exit stay upright, feet-anchored sprites. Both recesses draw the same shallow indent in the skirting and wall, floor colour visible at its back; the locked recess adds a brown bar across the indent's mouth, the bar being the only mark of closure — neither reads as a door seen from the front. |
| `stairwell_segment_backdrop.svg`, `stairwell_shaft_cap_top.svg` | Four repeatable shaft-wall panels sit behind each corrected 10×26-cell grammar, with the top cap two rows above it. They are background only: a painted stair symbol is the sole source of floor and every `.` remains blocked. **A shaft is its ground cells and nothing else**: there is no deck, no landing overlay, no rail in front of or behind a run and no cap under the shaft. The sources those were drawn as are in `docs/evidence/archive/rejected-graphics/escape-interior-deck-and-rail-kit-2026-09-19/`, and `tests/test_interior.gd` holds the TileSet's stair sources to the kit that remains rather than naming the ones that left. |
| `m158_stair_side_{upper,lower,continue}_{e,w}.svg`, `m158_stair_side_block.svg` | `InteriorTileSet.build()` binds these 32×32 sources directly to the corrected grammar. `t`/`m` select the east upper/lower roles and `T`/`M` select their west mirrors; those four cells are the two-row walkable diagonal surface and report their direction to `Stroller`. `c`/`C` select the continuation triangles and are solid. The direction-neutral `b` is a solid tile with a 16px-deep gray rectangle at its top edge, matching the continuation triangle's 16px leg. `InteriorMap.STAIRWELL_ROWS` places all seven roles, the level `F` cells and the alternating `D` corridor transitions; `InteriorScene` builds collision from that same parsed map rather than from a presentation overlay. The reviewed native/3× role sources remain in `docs/evidence/m158-stair-tile-prototype-2026-09-19/`; the [normal-scale corrected left shaft](evidence/archive/session-captures/2026-09-19/rig-110853-seed3349946719-v0.11.1-38-g2663c361-dirty/m158-corrected-left.png) is retained with its complete run folder. |
| `chandelier.svg` | Hung at each hallway midpoint, where it lights the corridor without covering the lobby barricade. |
| `puddle.svg`, `basement_debris.svg`, `rat.svg` | Ground decals over `InteriorMapPlan.decals`, in the basement corridor. |

### Closures

`src/routes/closure_marker.gd` owns this entire family. These pictures describe roads removed from
the day's route graph; they are separate from the event pictures with similar nouns.

| Assets | Runtime behaviour |
|---|---|
| `art/closures/barrier_{across,along}.svg` | Repeated across both mouths of a closed street, choosing the drawing by the closure's axis: `across` (22×24) is laid edge to edge along a north-south street's mouth, `along` (14×26) is stacked down an east-west one, each stretched to its share of the street. Two white rails with amber diagonal stripes on posts — amber and white so a closure reads as civil rather than as the grey barricade an event leaves, two rails so it is not the roadworks event's single red board. `across` is broadside on, one post per panel; `along` is the same two rails end-on, one post's splayed foot per panel. The rails run edge to edge and the stripes repeat on a period that divides the panel, so the line reads as one continuous barrier. |
| `art/closures/sign_closed.svg` | Standing on the middle panel of each barrier line, facing the junction: a red plate with a white bar and a white reflective rim on a steel post. |
| `art/closures/roadworks{,_vertical}.svg` | Centre marker for a roadworks closure: a trench cut in the road with a ladder standing in it, its spoil heap with a shovel in it, a length of concrete pipe with its hollow mouth showing, and a traffic cone. `roadworks` (64×30) lies across a north-south street; `_vertical` (36×78) is the same dig cut north to south across an east-west one, the trench running down the screen with its far end wall lit and the ladder leaning out over it, the pipe's mouth turned to the camera. |
| `art/closures/fallen_tree{,_vertical}.svg` | Centre marker for a fallen-tree closure: the root plate torn up on edge, the trunk along the road with a snapped branch, and the crown on its side, the same clumped olive broadleaf as the illustrated street trees. `fallen_tree` (98×40) lies across a north-south street; `_vertical` (44×122) lies across an east-west one, the root plate at the far end with its torn face to the camera, the trunk down the screen and the crown at the near end. |
| `art/closures/crashed_car{,_vertical}.svg` | Centre marker for a crash closure: two crowd cars nose to nose, both fronts crushed, the red one's hood sprung, steam, glass, a bumper and a hubcap on the road. `crashed_car` (80×38) is the two profiles across a north-south street; `_vertical` (40×84) is the two in the crowd cars' end view, slewed, across an east-west one: the blue car far and facing the camera, the red one near and facing away. |
| `art/closures/rubble{,_vertical}.svg` | Centre marker for a rubble closure: a heap of fallen facade — a slab of brick wall, a window in its frame, a concrete slab, a timber beam, bent reinforcing bars and loose bricks over dusty concrete. `rubble` (86×34) lies across a north-south street; `_vertical` (44×106) is the heap lying north to south across an east-west one, its crest down the middle, lit on the left and shaded on the right, its near end facing the camera. |

`ClosureMarker.cause_picture()` picks a cause's picture by the street's axis: `CAUSES` for a
north-south street, `CAUSES_VERTICAL` for an east-west one. Each `_vertical` picture is drawn again
in the game's projection, never the across one turned, because turning it would lay its upright
parts on their sides. Every cause is drawn feet-anchored with its own shadow under it
(`ClosureMarker._draw_cause()`): across, a point shadow at the street's middle; down the screen, a
band down the screen. A `_vertical` picture lies along the bottom of its canvas over the same
length of road its across picture spans, and stands half that below the street's middle
(`ClosureMarker.cause_feet()`), so both are centred on the street they close.

### Events and seal pictures

`src/events/event_instance.gd` holds every asset in this table as a repository path, draws it as a
region of the baked `events` page (`AtlasLibrary.region()`), selects it from
`EventDef.Look`, and also supplies the same row-specific silhouette to the screen-edge danger badge.
Every unqualified filename in this table is relative to `art/events/`.
Most families with a front, back, side and two diagonal views share `EventInstance._draw_eight_view()`:
the view comes from the row's own travel heading if it is mobile or its placement heading if it is
stationary, and the mirror is `EightDirection.is_mirrored()` except for the few families whose side
picture is authored facing west rather than east, where `side_faces_west` corrects it (see that
function's own doc comment, and `docs/evidence/svg-vehicles-2026-09-10/facings.csv`). A handful of
rows with only one or two pictures still mirror a plain side view east/west (`mouse`, `skip`), and
the whole-street seal scenes and the moving-van pair still pick an east-west/vertical pair from the
street axis without rotating the pixels.

| Event look or composite | Live SVG assets and behaviour |
|---|---|
| Cat | `cat_{crouched,running}_{front,back,side,front_diagonal,back_diagonal}.svg` (the `side` pair is the existing `cat_{crouched,running}.svg`): crouched while telegraphing, running afterward, `EventInstance._select_view()` picking the view from the cat's own `_heading` the same way `CrowdAgent` picks a walker's. The running posture also has a `cat_running_{view}_b.svg` stride frame — legs only, no coat or head to lift on a quadruped's low silhouette — alternated by `_gait_stepping()` on the distance actually covered; the crouch holds one picture, since it is the telegraph, held still. Every view is the same gray tabby drawn in the dogs' idiom — outlined and shaded, dark stripes across the back, a pale chest and muzzle, yellow eyes, pink inner ears. Crouched, it is low and coiled with the head down and the tail laid along the ground; running, it is stretched long with the ears back and the tail streaming. `cat_crouched.svg` (30×20) faces east with its paws on the canvas bottom and `cat_running.svg` (46×20) faces east with its lowest paw a pixel off the ground, mid-dash; the cardinal views are 30×24 and the diagonals 38×24. The running side frame throws the legs front and back and its `_b` frame gathers them under the same body. |
| Mouse | `mouse.svg`: one side-on picture, mirrored east/west like `delivery_van` rather than switching pose — see `docs/EVENTS.md`'s `alley_mouse` row. `mouse_b.svg` is its own dash's second frame — the tail curls differently rather than crossing legs it has no room to draw at this scale — alternated by `_gait_stepping()`. The prepared `mouse_{front,back}[_diagonal].svg` family, and its own `_b` companions authored alongside it, stay unbound: `EventCatalogue._alley_mouse()`'s own docstring documents, with its reasoning, that the row is not given a second posture or a heading-selected picture. |
| Yeller; busker; poster crew | `yeller_{view}.svg`, `busker_{view}.svg`, `poster_crew_{view}.svg` (`{view}` is `front`, `back`, `side`, `front_diagonal` or `back_diagonal`): each a stationary figure whose view comes from its own site facing — the same `_heading` that used to only decide `_heading_is_west()`'s mirror of one picture, now read as a full octant through `EventInstance._select_view()`. The old unsuffixed `yeller.svg`/`busker.svg`/`poster_crew.svg` stay live only as `icon_for()`'s own screen-edge badge silhouette. The pacing yeller also has `yeller_{view}_b.svg`, a stride frame alternated by `_gait_stepping()` as he paces his beat; the busker has `busker_{view}_b.svg`, the strumming hand raised, alternated on a half-second timer (`_idle_stepping()`, `BUSKER_STRUM_PERIOD`) through `EventInstance._draw_busker()` rather than on distance, since he never moves. `poster_crew` has one second frame, `poster_crew_back_b.svg`: the back view with the paste brush raised to the wall, alternated on the idle timer (`POSTER_CREW_PASTE_PERIOD`) — a crew on her way always faces the wall it pastes, so the back view is the one that is drawn. |
| Poster crew on a square | `poster_crew_square_{view}.svg` (`{view}` is `front`, `back`, `side`, `front_diagonal` or `back_diagonal`), bound through `EventDef.Look.POSTER_CREW_SQUARE` and drawn by `EventInstance._draw_eight_view()` exactly as the sidewalk crew above is. Its own family rather than a second binding of that one: the square crew pastes onto a free-standing advertising column, which a square has instead of a wall, and the column is what a player can see the difference in. Canvas 44×44, bottom-centre anchor (22, 44) where the sidewalk crew's is 30×44 — the worker is that family's own figure on the same anchor, and the extra width is the column beside him, which carries its own baked contact shadow because the runtime draws one only under the row's 11px point body. The column is a cylinder, so it is the same picture in all five views and only the worker turns. `poster_crew_square.svg`, unsuffixed, is `icon_for()`'s badge silhouette for the row. The row is sited with no pavement side, so its facing stays due east and the `side` view is the one it always draws; the other four exist so the family is whole. |
| Dog walker; loose dog | `person_{view}.svg` and `dog_{view}.svg` (`dog`'s `side` is the existing `dog.svg`): the walker composite draws both from the same selected view and mirror — the dog faces the walker's own travel, since it is being led rather than watching anything of its own — with the taut lead drawn in code; the loose dog draws `dog_{view}.svg` from its own travel with a trailing lead. The old unsuffixed `person.svg` stays live only as the dog walker's badge silhouette. Both bodies also carry a `_b.svg` stride frame (`person_{view}_b.svg`, `dog_{view}_b.svg`, and the loose dog's own `dog_b.svg` for its side view) — the walker's coat and head lift a pixel on the cardinal and side views the way the crowd walker's own do, the dog's legs only — and the walker and his dog read one shared `_gait_stepping()` phase, so they are never mid-stride at different instants of the same stride. The dog is a pet in every view: a tan coat shaded darker underneath with a cream chest and muzzle, soft hanging ears, the tail carried up and a blue collar, outlined dark with the far legs a shade darker than the near ones. `dog.svg` (26×20) faces east with its paws on the canvas bottom; the four other views (30×28 cardinal, 38×28 diagonal) stand their nearest paw on the canvas bottom too, so the dog does not hop when it turns, and the loose dog's lead start (0, −8) and the walker's lead end (0, −6) from the anchor both fall on its body in every view. Its side frame spreads the legs and `dog_b.svg` brings them under the same body; the other views swap which diagonal pair of legs reaches. |
| Café | `cafe_table.svg` and `cafe_sitter_{view}.svg`: repeated furniture and sitters across the frontage. Each sitter faces from its alternating chair position toward its own table: east/west for a horizontal frontage, south/north for a vertical one. The fixed screen-depth offset does not change that bearing. The old unsuffixed `cafe_sitter.svg` is unused once the named views cover it (no badge of its own; the café's icon is `cafe_table.svg`). Each sitter also has a `cafe_sitter_{view}_b.svg` idle frame — the seated body leans a couple of pixels above the table-owned seat, which stays put — alternated every `SITTER_IDLE_PERIOD` (a few seconds) by `_idle_stepping()`, offset per café by a hash of its own siting position so two frontages placed the same day do not lean in lockstep. The lean belongs to the whole frontage and the facing to each seat: `EventInstance._draw_cafe()` picks the frame table once per instance off that timer, then indexes it with the view each chair chooses. |
| Delivery van | `delivery_van_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `delivery_van.svg`): a stationary van parked at the kerb as a pavement obstacle, its view read through `EventInstance._draw_eight_view()` from the row's own placement heading — always due east, since `AT_THE_KERB` never turns it, so the row always draws the `side` view. Its `side` picture is authored facing west (`docs/evidence/svg-vehicles-2026-09-10/README.md`), so `_draw_eight_view`'s `side_faces_west` mirrors it for this always-east heading; the picture is now the mirror of what `_draw_simple` drew before this row was bound, a cosmetic change with no effect on its shape, shadow or obstruction. The old `delivery_van_end.svg` was never authored; this row never had one. The `side` picture is the same boxy panel van as the other four views, in their colours and in profile: cab door and window at the front, a sliding cargo door, the rear doors' seam, hazards on. |
| Roadworks event | `barrier_segment.svg` (22×22) and `barrier_segment_vertical.svg` (14×26) supply broad and narrow upright projections; `barrier_end.svg` supplies the end posts. The repeated span crosses the street or the alley's short axis. Drawing, collision and field distance share that axis. The broad segment is a cream board with red diagonal stripes on one leg, broadside on; the narrow one is the same board end-on, a striped upright band over one splayed trestle. Both tile: the board runs edge to edge and its stripes repeat on a period that divides the segment (11px broad, 13px narrow), so `_draw_spread()`'s stretched copies meet on the same phase and read as one continuous barrier. The end post is a red-banded cream pole on a rubber foot under an amber lamp, the same lamp the burst main's barriers carry. |
| Fire engine | `fire_engine_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `fire_engine.svg`): `fire_truck` is mobile, so its view is read from its actual travel heading (`_heading`, updated every frame it advances along its route) through `EventInstance._draw_eight_view()`, `side_faces_west` set since its `side` picture is west-authored. The old `fire_engine_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Burning building; burnt shell | `flame.svg` is repeated and scaled by the fire animation; `rubble.svg` is repeated across the burnt frontage. |
| Stall | `stall.svg` repeats across the frontage: one trestle of a market, apples, oranges and greens in crates on a plank counter under a red-and-cream striped awning with a scalloped front. The awning spans the whole 26×36 canvas and its stripes start red and end cream, so `_draw_spread()`'s copies — narrower broadside on, shorter end-on — join into one continuous canopy. |
| Leaf blower | `leaf_blower_{view}.svg`: one stationary figure whose view comes from its own site facing, the directional nozzle baked into each authored view. The old unsuffixed `leaf_blower.svg` stays live only as the badge silhouette. `leaf_blower_{view}_b.svg` gives him a stride frame too, read through `_gait_stepping()` the same way every other family in this table's row is; the row never actually moves today, so the lookup is never reached in play — wired for uniformity the way `lorry`'s own diagonal views are. |
| Birds | `pigeon_{view}.svg` and `pigeon_down_{view}.svg` (each `side` is the existing `pigeon.svg`/`pigeon_down.svg`): each bird alternates its own wing phase — `pigeon_*` on the upstroke, `pigeon_down_*` on the downstroke and whenever it stands on the ground — and holds its own eight-view sector from its own `heading`: a flock is eleven bodies wheeling independently, not one actor with one facing, so the hold is per bird rather than shared with the instance. Every view is the same rock dove, outlined and shaded: blue-gray with a darker head, a green and purple sheen at the neck, two dark bars on each wing, a dark band at the end of the tail and pink feet. Within each view the two phases share the body, head, tail and feet paths exactly and only the wings move, so a flapping bird does not jump; the feet stand on the canvas bottom (18×14 side, facing east; 22×18 for the other views). |
| Cyclist; charging dog | `cyclist_{view}.svg` and `charging_dog_{view}.svg` (each `side` is the existing `cyclist.svg`/`charging_dog.svg`): one moving picture per look, the view read from the rider's or the dog's own travel. Each also has a `_b.svg` stride frame — the cyclist's own two pedal positions swap (rider and bike are one picture, so one phase swaps both), the charging dog's legs move under the same body — alternated by `_gait_stepping()`. The charging dog is drawn in the walked dog's idiom as a different animal: a heavier, dark coat with tan points, ears pinned back, hackles raised along the shoulders, the head carried low and level with the back, the tail straight out behind, and an open red jaw with white teeth — the only red on it, still showing past the cheek in the back diagonal. `charging_dog.svg` (40×22) faces east and gallops at full stretch, legs thrown front and back, with `charging_dog_b.svg` the same body gathered; the four other views (30×28 cardinal, 38×28 diagonal) stand their nearest paw on the canvas bottom too. |
| Ice-cream van; lorry | `ice_cream_van_{front,back,side,front_diagonal,back_diagonal}.svg` and `lorry_{front,back,side,front_diagonal,back_diagonal}.svg` (each `side` is the existing unsuffixed source): both stationary rows, drawn through `EventInstance._draw_eight_view()` from their own placement heading with no `side_faces_west` — both `side` pictures are already east-authored. `ice_cream_van` (`AT_THE_KERB`) is always due east like `delivery_van` above, so it always draws its `side` view unmirrored, exactly as `_draw_simple` drew it before. `lorry` (`reversing_lorry`, `AGAINST_THE_BUILDING`) faces due east or west only — `_wants_this_side` refuses any facing that is not purely horizontal — so its `front_diagonal`/`back_diagonal`/`front`/`back` views are never actually reached; the row keeps drawing exactly the `side` view, mirrored by which way it backs in, that it always did. |
| Chatting mother | `chatting_mother_{walking,talking}_{view}.svg`: switches when conversation begins, the view read from her own pacing travel. The old unsuffixed `chatting_mother_walking.svg` stays live only as the badge silhouette; `chatting_mother_talking.svg` is unused once the named views cover it. The walking posture also has `chatting_mother_walking_{view}_b.svg`, a stride frame alternated by `_gait_stepping()`; the talking posture stays single, since `is_chatting()` freezes her `_process()` for the whole of a conversation and the gait freezes with it. |
| Police car | `police_car_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `police_car.svg`): `police_patrol` is mobile and turns along its own patrol route, so `EventInstance._draw_eight_view()` reads its actual travel heading with no `side_faces_west` — its `side` picture is already east-authored — and this is the first vehicle row whose diagonal views are ordinarily reachable rather than a dead branch, since a patrol car actually turns corners. The old `police_car_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Roadblock (the impassable barrier row) | While its guards are posted: `roadblock_segment.svg` and `roadblock_end.svg`, repeated and capped by `_draw_spread()` — the same rail-with-caps construction the roadworks barrier below uses — so the band reads as one continuous barrier rather than a row of blocks. `checkpoint_block.svg` (kept from before the row was renamed) is now only the screen-edge badge's own icon. Once heated past `Tuning.HEAT_HUNTS_LEVEL` the guards leave the post and `EventInstance._draw_roadblock()` swaps the barrier for `guard_standing.svg` (closing to its stand-off) then `guard_lunging.svg` (giving chase) — the same pair the checkpoint kit below stands beside every hut. This is the impassable event row, not the traversable checkpoint kit below. |
| Checkpoint hut, gate, post (the region door structure) | Paths under `art/checkpoints/`, not `art/events/`. `checkpoint_hut` draws one of `hut_{north,south,east,west}.svg` chosen from `CityMap.pavement_inward()` at the tile it stands on, doorway facing the carriageway, plus `guard_standing.svg` beside it. `checkpoint_gate` draws `boom_gate_ns_{lowered,raised}.svg` or `boom_gate_ew_{lowered,raised}.svg` — `ns` for a north-south road, `ew` for an east-west one, read off the instance's own facing — raised or lowered from the shared `RegionPlanner.GateState`. `checkpoint_post` draws `guard_standing.svg` alone. All three use `EventInstance._draw_at_anchor()`, not `Sprites.draw_standing()`'s bottom-centre assumption, since the kit's own anchors are off-centre. |
| Abduction | `unmarked_van_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `unmarked_van.svg`) and `van_victim_{view}.svg`: the victim is placed beside the van during the abduction, its view read from the direction of the short walk toward it, which is always due east or west by construction. The van itself is drawn through the same `EventInstance._draw_eight_view()` every other vehicle family above uses, `side_faces_west` set since `unmarked_van.svg` is west-authored: idling (`is_waiting()`) its heading is always due east, so it always draws its `side` view, now mirrored from what `_draw_vehicle` drew before this row was bound — the same cosmetic, shape-preserving change `delivery_van` above gets, for the same reason. Once heated past `Tuning.HEAT_HUNTS_LEVEL` and hunting, its heading is the real chase direction and every one of the five views is reachable. The victim and the van share one `_view_sector` field on the instance, safe because `is_taking_a_victim()` is only ever true while the van is still waiting (heading due east) and the victim's own walk is always due east or west, 180° apart or exactly aligned with the van's — never a heading `EightDirection`'s hold could get wrong. The old `unmarked_van_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. The old unsuffixed `van_victim.svg` is unused once the named views cover it (no badge of its own). The victim also carries `van_victim_{view}_b.svg`, a stride frame for her short walk to the van — read off `_victim_gait_stepping()`, a query derived from her own walk's fixed speed and elapsed time rather than the ordinary distance-driven `_gait_phase`, since the walk is a scripted lerp on age rather than anything that touches `_path_travelled`. |
| Robber | `robber_{waiting,lunging}_{view}.svg`: switches from waiting to the attack pose. Once he has noticed her, `_chase()` already keeps `_heading` pointed at her for the telegraph and the lunge alike, so the lunging posture reads it directly; before that he has nothing else of his own to face, so the waiting posture reads `player_at` instead (`EventInstance._robber_waiting_heading()`) — a man only watching the street is worth nothing next to a man watching her. The old unsuffixed `robber_waiting.svg`/`robber_lunging.svg` stay live only as the badge silhouette (`ROBBER` returns `ROBBER_LUNGING`). The lunge also has `robber_lunging_{view}_b.svg`, a stride frame alternated by `_gait_stepping()`; the waiting posture stays single, since a man only watching the street has nothing to stride toward yet. |
| Night raid | `riot_van.svg` (side) plus `riot_van_{front,back,front_diagonal,back_diagonal}.svg`: `EventInstance._draw_body()` reads `RIOT_VAN_BY_VIEW` through the same shared `_draw_eight_view()` every other vehicle family above uses, `side_faces_west` set since `riot_van.svg` is west-authored like `unmarked_van.svg` and `army_truck.svg` above, so a hunting raid van chasing due east or west is drawn facing the way it is travelling rather than mirrored backwards. `riot_van_end.svg` remains unbound — it duplicates `riot_van_front.svg`, which the octant selection already draws for that heading. |
| Army truck | `army_truck_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `army_truck.svg`): `military_convoy` is mobile and follows its own street route, so `EventInstance._draw_eight_view()` reads its actual travel heading, `side_faces_west` set since its `side` picture is west-authored. The old `army_truck_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Barricade | `barricade_pile.svg`: repeated improvised debris across the obstruction. |
| Protest | `protester_{view}.svg`, its view read from the rank's own site facing, whenever there is nothing to point at — a mark step or no step at all, `_protester_texture()`'s own `PROTESTER` sentinel. The eight `protester_point_*` poses stay exactly as M65 bound them: unmirrored, selected by bearing to the resistance's own objective rather than by this family's view table, and single — they never gained a `_b` frame. The plain rank does: `protester_{view}_b.svg` is its own stride frame, alternated by `_gait_stepping()`; the row never actually moves today, so it is never reached in play, the same as the leaf blower's above. The old unsuffixed `protester.svg` is both that sentinel and the badge silhouette, so it stays live on both counts. |
| Firefight | `gunman.svg`: mirrored figures form both sides; muzzle flashes are drawn circles. The prepared `gunman_{front,back,front_diagonal,back_diagonal}.svg` stay unbound: the two shooters face along a fixed local axis by construction (the line between them), which the side view already draws, and `gunman_side.svg` is the same picture as `gunman.svg` — there is no heading a firefight's own composite could ever turn to reach the other three. |
| Fallen-tree seal | `fallen_tree.svg` and `fallen_tree_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction. A broadleaf down kerb to kerb, the same species and clumped olive crown as the illustrated street trees: the root plate torn out of one pavement, the trunk across the carriageway, and the crown filling the rest of the street to the other kerb. On a north-south street it lies broadside, root plate on edge; on an east-west street it has fallen towards the camera, root plate face-on at the far end and crown over the near half. Neither file carries a shadow; the row's own body shadow is drawn under it. |
| Car-accident seal | `car_accident.svg` and `car_accident_vertical.svg`, with matching `car_accident_shadow.svg` and `car_accident_vertical_shadow.svg`: authored scene and ground-contact shadow chosen by street axis. Two cars locked side by side across the carriageway, drawn in the crowd cars' projections — end-on on a north-south street, flanks crushed into each other; in profile on an east-west street, the far car's nose driven into the near car's tail — with glass, a bumper and coolant on the road, steam rising, and an onlooker on each pavement drawn as the event `person` figure turned towards the crash. The shadow files are the cars' and onlookers' ground contacts, and `EventCatalogue._car_accident_parts()` reads the cars' two contacts as the scene's two solid bodies, so the cars in the scenes stand exactly over them. |
| Skip and scaffolding seals | `skip.svg` is one pavement picture; `scaffolding.svg` repeats across the other pavement frontage. |
| Burst-main seal | `burst_water_main.svg` and `burst_water_main_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction — a crater of heaved asphalt with the split main in it, water fountaining out and spreading towards both kerbs, and a barrier at each end, broadside on a north-south street and in its narrow end-on projection on an east-west one. The ground is overhead and the fountain and barriers upright; neither file carries a shadow and the row draws none (`draws_body_shadow` off), because the crater is sunk into the road. |
| Moving-van pair | `moving_van.svg` and `moving_van_vertical.svg`: the vans stand parallel to their street; the street axis selects the side or end projection while preserving authored proportions, unchanged by this milestone. `moving_van_{front,back,front_diagonal,back_diagonal}.svg` stay prepared and unbound: the seal's own axis choice is a binary (parallel to the street or across it) with no heading that ever turns to a diagonal, and `moving_van_vertical.svg` already serves the "across" projection as its own authored scene — ramp down, doors open — rather than a generic end view, the same reason `gunman`'s own front/back/diagonal stay prepared. |
| Burnt-out-car seal | `burnt_out_car.svg` and `burnt_out_car_vertical.svg`: four wrecks form a hard seal across the whole street. Each car lies perpendicular to the street; its axis selects the side or end projection. |
| Collapsed-frontage seal | `collapsed_frontage.svg`: the debris segment repeats across one hard seal spanning the whole street, kerb to kerb. |
| Impact crater | `art/props/impact_crater_2x2.svg`, not `art/events/`: a 64×64 hole in the road drawn flat and **centred** on its own ground point through `EventInstance._draw_at_anchor()`, which is what makes it the one look in the catalogue that is ground rather than an object standing on ground. It carries **no drop shadow** for the same reason — a shadow under a hole reads as a mound. The `impact_crater_{1x1,3x3}.svg` sources stay prepared and unbound: `spawns_on_finish` names one row, so a second size would need a second explosion row to leave it, and three sizes of the same hole would be three looks nobody could tell apart on the screen-edge badge. |
| Masked pursuer | `art/checkpoints/guard_standing.svg` while the telegraph runs and `guard_lunging.svg` once he is coming — the same pair a heated `roadblock`'s guards take when they leave the post, on a row that was never a barrier. `guard_lunging.svg` is also this look's own badge silhouette, which is what keeps it distinct from `checkpoint_post`'s (`guard_standing.svg`). |
| Steam | `steam.svg`: one 32×48 picture standing on the ground it rises from, mirrored east/west like `mouse` and `skip` rather than switching pose, since a cloud has no front. |
| Loudspeaker mast | `mast.svg` (20×58, bottom-centre anchor): one standing picture, pole and horns, no heading to select — `EventInstance._draw_mast()` draws it through `_draw_simple()` the same way `mouse` and `steam` are. `mast_lamp.svg` (8×8, centre anchor) is a small overlay near the horn housing, tinted by `Sprites.draw_standing()`'s own `modulate` argument rather than baked as a second picture: `Palette.SIGNAL_AMBER` during the repeating telegraph, `Palette.SIGNAL_GREEN` while it speaks, undrawn when `silenced` — the player's 2026-09-23 amendment asking for a visible live/silenced and telegraph/speaking indicator. `sound_pulse.svg` (48×32, source anchor (24, 32)), prepared since M100 and unbound until now, is drawn above the lamp while the mast speaks — see "Sound lines" in `docs/EVENTS.md`, "The visual vocabulary". |

## Prepared SVG assets without runtime bindings

These files are intentionally available to their named designs, but a search of runtime sources,
scenes and resources finds no binding. Keep them here until the owning implementation selects them;
moving them into the live tables early would hide unfinished integration.

The [vehicle diagonal source sheet](evidence/svg-vehicle-diagonals-review-2026-09-10.png)
shows the authored front/rear diagonals at native size and 3× for human review. It is a source
comparison, not a gameplay capture.

The [complete vehicle, animal and rider source review](evidence/svg-vehicles-2026-09-10/README.md)
adds all eight facings, tint composites and wing phases. Its `facings.csv` records exact source
paths, mirrors, canvases, anchors and alpha bounds; several canonical van side pictures face west.

The [environment source review](evidence/svg-environment-2026-09-10/INVENTORY.md) lists every
prepared interior, ground, roof, frontage and prop source in `sources.csv`, with native canvases,
anchors and alpha bounds. It includes tile repetition, facade overlays and chalk on pavement.

The stair kit's own live binding is documented in "Interior (the escape scene)" above; this
paragraph is its history. Stair construction followed the supplied lateral-flight references,
`docs/reference/stairwell-switchback-interior-01.jpg` and `fire-escape-switchback-exterior-01.jpg`,
walked one 32×32 tile at a time rather than drawn as a single picture — the player rejected a
whole-module stair, a 64×64 picture of both flights and both landings of one shaft, in PLAYTEST-54
because a tile is what a `TileMapLayer` can make walkable, and one picture cannot be (see
`docs/evidence/archive/rejected-graphics/stair-down-module-superseded-2026-09-10/README.md`, the
archived module and the reasoning). **The archived module is also called `stair_down.svg` and is a
different picture from the live one**: the live tile is the 32×32 front-facing basement stair
listed above, the archived one is the 64×64 whole switchback. Exterior `fire_escape_{a,b}.svg` is a 48×64
facade overlay, one floor of a stacked fire escape, and is unaffected by this milestone. The
[stair source and assembly review](evidence/svg-sideways-stairs-2026-09-10/README.md) documents
the retired module's own sources; the [M112 stair tile review](evidence/m112-stairs-2026-09-10/)
shows the kit at native and 3× scale and one assembled flight.

The [people source matrix](evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md) names every body,
trim, gait and action source, its registration and intended live or prepared use. Native/3×
sheets show each layer and all eight composed facings. A pointing pose's suffix describes the
arm direction; ordinary movement suffixes describe the body's facing.

| Owning design | Prepared assets, dimensions and registration |
|---|---|
| M102 — The finale: out of the apartment, out of the city (interior) | `art/events/explosion_preview.svg` is a 40×40 optional burst and stays prepared and unbound: an explosion in the escape is off screen by definition and draws nothing at all, so a picture for one would be a burst nobody is ever in a position to see — see `EventCatalogue._finale_explosion()`. `art/interior/hallway_wall_window_flash.svg` and `art/events/steam.svg` are now live — see "Interior (the escape scene)" and "Events and seal pictures" above. The rest of `art/interior/` is bound by the escape scene itself, bar the handrail pieces `stair_rail_{e,w}.svg`, `stair_rail_level.svg` and `stair_newel.svg`, which stay prepared and unbound: the corrected grammar's tiles are a stairwell seen from the side and draw their own balustrade, so there is no run for a separate rail to be laid along. |
| M100 — Small, real, and nobody's (chalk and alley review) | `art/props/chalk_mark.svg` and `chalk_mark_touched.svg` are 32×32 centre-anchored decals; the touched version keeps the circle/cross and adds her small tick. `art/tiles/alley_draft.svg` is a 32×32 paving alternative for comparison. Current code-drawn chalk and the live alley tile remain the runtime pictures. |
| M106 — Roofs, fronts and street trees | Every asset this milestone named is now live — see "City ground and buildings" above for the roof units, the fronts and the street tree's own pit. `art/buildings/storefront_{a,b,c,d}_shuttered.svg` and `window_{tall,shuttered}_{dark,lit}.svg`, prepared here, are also now live — see the same section — bound by the city's own degradation rather than by this milestone. |
| M108 — Eight-direction entity graphics (vehicle diagonal sources) | `art/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck}_{front,back}_diagonal.svg` are now live — see "Events and seal pictures" above. `moving_van_{front,back}_diagonal.svg` stays prepared and unbound: the seal's own side/vertical choice never turns to a diagonal, and `moving_van_vertical.svg` already serves the "across the street" projection as its own authored scene rather than a generic end view. Canvases are 56×50, bottom-centre anchor (28, 50); front diagonals face southeast and back diagonals northeast, west counterparts mirroring horizontally. |
| M108 — Eight-direction entity graphics (gunman) | `gunman_{front,back,front_diagonal,back_diagonal}.svg` stay prepared and unbound. Every other named view in the people matrix — `person`, `yeller`, `busker`, `poster_crew`, `cafe_sitter`, `van_victim`, `protester`, `leaf_blower`, `chatting_mother_{walking,talking}` and `robber_{waiting,lunging}` — is now live; see "Events and seal pictures" above. A firefight's two shooters always face along the fixed local axis between them, which the side view already draws (`gunman_side.svg` is the same picture as `gunman.svg`), so there is no heading the composite could ever turn to reach the other three. |
| M56 — The resistance is noticed (directional guards) | `art/checkpoints/guard_{standing,lunging}_{front,back,side,front_diagonal,back_diagonal}.svg` supplies waiting and pursuit poses. Standing uses 22×44, anchor (11,44); lunging uses 36×44, anchor (17,44), including mirrored views. Heading selection and state transitions remain with the runtime owner. |
| M108 — Eight-direction entity graphics (vehicle end sources) | `art/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck}_{front,back}.svg` are now live — see "Events and seal pictures" above; each supersedes that family's old single `_end.svg`, drawn for both north and south headings alike, which stays on disk unbound. `moving_van_{front,back}.svg` stays prepared and unbound for the same reason its diagonals do — see the row above. South-facing windscreens/headlights and north-facing cargo doors/rear lamps, each bottom-centre grounded. |
| M108 — Eight-direction entity graphics (cars) | `art/events/police_car_{front,back,front_diagonal,back_diagonal}.svg` is live — see "Events and seal pictures" above — with the police identity and light bar baked per view. The crowd car's own eight-view binding (`car_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg`) is live — see "Player, crowd and interface" above, not this prepared table; `car_end_{body,trim}.svg`, its old two-view family's foreshortened top-down picture, is prepared and unbound. |
| M100 — Small, real, and nobody's (mouse) | `art/events/mouse.svg` is the east-facing 24×14 source, bound to the `alley_mouse` catalogue row through `EventDef.Look.MOUSE` and drawn by `EventInstance._draw_simple()`, mirrored east/west the same plain way `skip` is rather than through a directional family; its own `mouse_b.svg` dash frame is bound alongside it — see "Events and seal pictures" above. `mouse_{front,back}.svg` (18×18), `mouse_{front,back}_diagonal.svg` (24×18) and their own `_b` siblings stay prepared and unbound, since the row they would serve does not pick a picture by heading either — see `EventCatalogue._alley_mouse()`. Sound remains unbound. |
| M56 — The resistance is noticed (night-raid duplicate end view) | `art/events/riot_van_end.svg`: 34×50, anchor (17, 50), a south-facing barred windscreen and headlights with wheel edges alongside the body — the same picture `riot_van_front.svg` draws. The night-raid drawing selects `riot_van_front.svg` for that heading instead (see "Events and seal pictures" above), so this duplicate stays unbound. |
| M65 — A protester points at the objective | `art/events/protester_point_{n,ne,e,se,s,sw,w,nw}.svg`: eight 44×52 poses sharing feet anchor (22, 52). |
| M100 — Small, real, and nobody's | `industrial_vent.svg` and `civic_portico.svg`, prepared here, are now live — see "City ground and buildings" above. `art/events/sound_pulse.svg`, also prepared here, is now live too — see "Events and seal pictures" above, the loudspeaker mast's own row. |
| M102 — The finale: out of the apartment, out of the city (impact craters) | `art/props/impact_crater_1x1.svg`: 32×32 with centre anchor (16, 16). `impact_crater_3x3.svg`: 96×96 with centre anchor (48, 48). Both stay prepared and unbound; `impact_crater_2x2.svg` is the one the `impact_crater` row draws — see "Events and seal pictures" above — and any other event or city feature that needs a crater may reuse the other two. |

## Other unbound SVGs

The exact tracked SVGs outside the live and prepared tables are `assets/icon_stroller.svg` and
`assets/logo.svg`. Neither is loaded by the game or an export resource. They are editable identity
art counterparts: the active application icon is root `icon.svg`, while the README displays
`assets/logo.png` and the web metadata publishes `assets/social-card.png`.
The [comic identity record](evidence/comic-identity-2026-09-12/GENERATION.md) maps these raster
derivatives and both exported stroller icon sizes to their SVG sources. The social card is
the logo flattened onto opaque white; the rounded slate icon plate remains part of the mark.

## PNG replacements

`art/illustrated/svg-transfer/tiles/` contains native 32×32 replacements for the outdoor
ground SVG family. `GroundLayers` builds the city's presentation TileSet by composing regions of
the baked `ground` page, retaining source IDs and native cell geometry. `CityEdge` draws the mountain from the
`ground` atlas group's own baked region (`AtlasLibrary.region(&"tiles/mountain")`, acquired and
released alongside `street_kit`) for its separate repeated drawing. The prepared `alley_draft` has
a PNG but remains unbound.
The [generation record](evidence/style-transfer-tiles-2026-09-12/GENERATION.md) links source
pairings, exact prompts, raw outputs and repeated-tile comparisons.

The default bake takes the same-size PNG at
`art/illustrated/svg-transfer/<family>/<name>.png` wherever one exists beside its SVG; a PNG
whose size disagrees with its source fails the bake by name rather than being quietly swapped
for the SVG, since the game has no second copy to fall back to. Existing draw transforms and
animation still apply.

The live replacement families are in `art/illustrated/svg-transfer/rig/`.
The names below use `mother`; the complete male counterpart uses `father` with the same
dimensions, poses, states and registration. `GameState.start_run()` makes an equal two-way
choice through its independent seeded `player-presentation` stream, and `Main._make_player()`
binds that choice before every ordinary or escape player enters the tree. Days, retries, pauses,
carrying changes and texture resolution never reroll it. **Each complete family has a baked page
of its own — `mother` and `father` — and a run loads only the one it draws**, since the choice
is fixed for the run; the pram they share is the `stroller` page, and the wife/event NPC artwork
is independent.

`mother_{front,back}_{a,b,c}.png` (24×46), `mother_side_{a,b,c}.png` (26×46),
`pram_front.png` and `pram_back.png` (30×30), and `pram_side.png`
(36×30). `mother_{front,back}_diagonal_{a,b,c}.png` (26×46) and
`pram_{front,back}_diagonal.png` (36×30) supply the diagonal views; west views mirror their
east-authored partners. The carrying set adds
`mother_carrying_{front,back}_{a,b,c}.png` (24×46) and
`mother_carrying_{side,front_diagonal,back_diagonal}_{a,b,c}.png` (26×46), drawn the same way
during the escape scene. All use bottom-center anchors and retain their redrawn
silhouettes and true transparency. **P2 — Three-pose push** and its grounded contact sheets are
documented in the [pushing stride record](evidence/comic-pushing-strides-2026-09-12/GENERATION.md).
The female carrying family is **F — Hip motion**; its SVG sources, three whole-figure poses,
closed idle frame, registration and eight-direction GIF recipe are in the
[carrying hip-motion record](evidence/comic-carrying-hip-motion-2026-09-12/GENERATION.md).
The [graphics recipe index](evidence/README.md#graphics-recipes) also locates the named comparison
versions and their preserved rollouts.
The [player authoring directory](graphics-creation/player/README.md) holds the high-fidelity SVG
generation targets and their runtime/PNG pairings. The runtime SVG catalogue supplies vector
artwork for contact and together poses. The female PNG presentation uses the accepted F and P2
textures. The [male player recipe](evidence/male-player-2026-09-19/GENERATION.md) preserves its
SVG-first sources, two generated sheets, native extraction and complete eight-facing comparisons.
The [stroller view recipe](evidence/stroller-view-assignment-2026-09-12/GENERATION.md) defines the
final illustrated facing contract: N/NE/NW show the baby and canopy opening; S/SE/SW show the
outside of the hood; E/W retain the original side image. These names mean travel direction.
Rebuild from frozen originals; do not swap the runtime textures again based on source filenames.
The [north-diagonal contact recipe](evidence/stroller-diagonal-contact-2026-09-12/GENERATION.md)
records the downward NE/NW correction across all pushing poses. The continuous adjustment vanishes
at cardinal directions and throughout the southern half; SE/SW grounding takes priority over
closing the remaining hand gap.
The [southern wheel arrangement](evidence/stroller-southern-wheel-swap-2026-09-12/GENERATION.md)
owns the final SE/SW wheel pixels. Final SE uses the frozen input's displayed SW wheels; final
SW uses its displayed SE wheels. Each body, canopy, handle and grounded height stays fixed.
Rebuild from the hash-checked frozen source only, never exchange the installed wheels again.
In SW, the leftmost wheel is shadowed and the other two show red axles on their right sides.
In SE, the rightmost wheel is shadowed and the other two show red axles on their left sides.

Ground components live under `art/illustrated/svg-transfer/tiles/layers/`, paired with SVGs
under `art/tiles/layers/`. The component manifest, `assets/ground_layers.json`, maps each ground source to a shared sidewalk,
asphalt or alley base and transparent curbstones, red edge paint, yellow lines, crosswalks or
damage. The engine composites those layers when building the TileSet. Clear overlay pixels
leave the base intact, so neighboring variants share the same floor material.
The asphalt and soft grass bases are prepared offline by equally blending four quarter-turn
orientations. Parks and forests use that soft green base and three extracted clumps; the engine makes sparse arrangements
and selects them deterministically from the city seed and cell coordinates.
The [component recipe](evidence/layered-ground-2026-09-12/GENERATION.md) preserves the source
artwork, stencils and base preparation. The
[engine layout recipe](evidence/layered-ground-layout-2026-09-12/GENERATION.md) reviews composed
tiles in generated streets, junctions and parks.

Each bake's `ground` page holds what that bake draws. A default one carries the 31 layers and
the twelve whole tiles the recipe composes nothing for, and no whole picture of a composed
source — so the cracked tiles, `tiles/grass` and `tiles/forest` are not in a default build at
all, and a source whose composition fails is a `push_error` rather than a quiet fall back to its
whole authored tile. A `tools/bake-atlases.sh --svg` bake gives the authored vector tiles whole,
carries no layer, and composes nothing but the route-kerb tint.
Baked damage-and-floor PNGs are excluded from runtime assets; the accepted source artwork lives
in the component recipe's frozen inputs. Runtime damage uses transparent stencils over the base.
Hairline, cracked and broken damage each share a variation pool across all three surfaces,
selected deterministically by city seed and cell. The
[damage atlas review](evidence/shared-damage-2026-09-12/GENERATION.md) shows every combination.
The [paving joint recipe](evidence/paving-boundary-joints-2026-09-12/GENERATION.md) preserves the
accepted sidewalk material and complete boundary joints across all rectangular paving. It owns
the final runtime registration after the quiet-square and plaza material generation steps below.
The [stoop step-face recipe](evidence/stoop-bottom-face-2026-09-12/GENERATION.md) adds its bottom
brown riser from an existing band and compresses the taller image back to 32×32. Its verifier
checks that derivative and the rest of the unchanged registered paving together.

`art/illustrated/svg-transfer/tiles/quiet_square.png` supplies muted cool-stone paving with
large slab joints. Its [generation and registration recipe](evidence/quiet-square-2026-09-12/GENERATION.md)
preserves the SVG subject, style references, raw image and repeated-tile comparisons beside the
shared ground bases.

`art/illustrated/svg-transfer/tiles/plaza.png` supplies darker muted stone with the plaza's
larger slab layout. Its [generation and registration recipe](evidence/plaza-paving-2026-09-12/GENERATION.md)
retains the raw artwork, SVG subject, quiet-square material reference and neighboring floor inputs.

`art/illustrated/svg-transfer/props/` supplies `garbage_sack.png` (28×34) and
`garbage_sacks_pile.png` (42×34), bottom-center anchored, plus `litter_{can,apple,bag,newspaper,cup}.png`
(32×32), center anchored. These use the existing `Prop` and `CityDecals` drawing paths with
the comic redraw's own alpha. Their [generation record](evidence/comic-props-2026-09-12/GENERATION.md)
preserves shared material references and reproducible extraction and anchor registration.
The same replacement directory contains `tree_a.png` (40×46), `tree_b.png` (40×52),
`bollard.png` (12×12), `tree_pit.png` (32×32), `roof_water_tank.png` (32×48),
`roof_hvac_unit.png`, `roof_hvac_unit_b.png`, `roof_skylight.png`, `roof_skylight_b.png`,
`roof_vent_stack.png`, `roof_duct_corner.png` (all 32×32), and
`roof_duct_straight.png` (64×32). `Prop` resolves the trees and overhead bollard cap;
`CityDecals` draws the opaque tree bed on the ground; `Building` resolves the rooftop equipment.
Standing canvases use bottom-center anchors; the tree bed uses its center. Their
[generation record](evidence/comic-city-props-2026-09-12/GENERATION.md) preserves source
pairings, transparent sprite extraction, fixed ground-tile extraction and review sheets.
Unconverted families retain SVG textures.

[VISUALS.md](VISUALS.md) defines reference authority and the visual acceptance gate.
[The generation record](evidence/style-transfer-2026-09-10/GENERATION.md) preserves raw outputs,
registration measurements and reproduction commands. The rejected graphics archive holds
historical evidence only; it does not supply runtime textures or style guidance.

## Keeping the catalogue true

The [SVG art skill](../.claude/skills/svg-art/SKILL.md) describes authoring, rendering, visual
review and integration. Use it when creating or revising the SVG families catalogued here.

When adding a graphic, record its exact path, anchor and owning design here. Keep it **prepared**
until code, a scene or a resource actually binds it. When binding or removing one, search runtime
sources as well as `assets/ground_tileset.tres`, `scenes/` and `project.godot`; the TileSet and
application icon are deliberately indirect. For state, direction or animation families, keep a
glob only when it names every member of the family and no unrelated file.

## Posters

`art/events/posters/` holds the four poster kinds M180, posters she notices, and loudspeakers
that are somewhere, asks for. Every file below but `poster_wanted_crossed.svg` is **bound**: baked
on the `buildings` page and drawn by `Building._draw_posters()` on blank ground-floor wall cells,
from what `PosterWalls` says is pasted there; `PosterArt` names the regions. The crossed copy stays
prepared and unbound: it is for a run whose day 10 task was failed, and M181, the resistance has a
reason, and a task is one day, has not built day 10 yet, so the neighbor's slot is drawn as the
plain placeholder face on every wanted notice.

Each is a 32×32 canvas matching a wall tile's own grid, so a later placement can register
straight onto a wall cell the way `wall_base.svg` already does. Every poster is a 20×22px sheet
(62.5% × 69% of the tile) at x 6–26, y 3–25: a gap on all four sides of its tile, and the foot
clear of the plinth `wall_base.svg` draws from y 26. A poster goes on blank wall, never over a
window (`docs/playtests/PLAYTEST-123.md`, statements 13 and 25), so a front that carries posters
needs visible plain wall — stretches with no window at all that break the window rhythm — not a
window cell with the window left out.

| Asset | What it draws |
|---|---|
| `poster_leader.svg` | The leader's portrait: a nameless, jowly, scowling middle-aged man — hair receding at the temples, heavy brows over a hard stare, a dark suit with the white of a collar — on a warm gray backing inside a thin cream border, over a large dark band carrying no letters. Flat fills with a clean dark outline. |
| `poster_rules.svg` | The rules: a pale printed notice under an inset dark header bar, four entries — each a 2×3px dark bar, a 1px gap, then two 1px gray print lines two pixels apart, the second shorter — and a round red stamp, a ring crossed by a thick diagonal band, over the lower right. |
| `poster_curfew.svg` | The curfew sheet: the same header, a large clock with a dark rim, twelve tick marks and its hands at four, then two of the rules' entries and the same stamp, for day 6 onward. |
| `poster_uniform.svg` | The dark uniform sheet: a cream emblem invented for this game, like the letter phi on a base — a tall ring, a vertical bar through it standing out above and below, on a flat foot bar — matching no real flag, party, state or movement mark. |
| `poster_wanted.svg` | The wanted notice: gray-beige paper under an inset dark header, four 7×5 mugshot frames in two rows of two, each a dark head-and-shoulders silhouette in a thin dark frame with one gray print line beneath it — a different style from the leader's coloured portrait. This copy has one X: a red X over the top-right face, a face that is never the neighbor's. The bottom-left frame, the SVG group `neighbor_slot` (top-left corner at 8,16), is a placeholder adult standing in for the neighbor from M181, the resistance has a reason, and a task is one day, day 10, who is not drawn yet — the slot a later slice swaps for their figure. |
| `poster_wanted_crossed.svg` | The same sheet with two Xs: that face and the `neighbor_slot` face, for a run whose day 10 task was not done on the day she won. |
| `poster_tear_a_mask.svg`, `poster_tear_a_overlay.svg` | Tear A, prepared for "she tears a poster down by pushing against its wall" (M180's second item): the top and upper left of the sheet stay pasted, plus a scrap of the bottom-right corner. |
| `poster_tear_b_mask.svg`, `poster_tear_b_overlay.svg` | Tear B: a strip across the top stays pasted, plus a scrap of the bottom-right corner; the overlay adds a flap peeled from the lower left, hanging off the strip with its blank back showing, the crease dark at the fold and a shadow on the wall. |
| `poster_tear_c_mask.svg`, `poster_tear_c_overlay.svg` | Tear C: a ragged strip down the left edge stays pasted, plus a small scrap in the top-right corner. |

**A torn poster is any intact kind with a tear applied**, so every kind tears three ways and no
torn file carries print. Each tear is two files on the same 20×22 sheet box: a mask, opaque
where the paper stays (its colour is unused), and an overlay carrying no print — the faint
shadow and pale paper-core fringe along each tear, and the bare wall where the sheet was, a
faint shade darker (cut around the kept paper with an even-odd fill, so the remnant is not
darkened), with glue marks and paper crumbs. The recipe, per pixel, with the poster, the mask
and the overlay rendered at the same scale and registration:

1. `torn.rgb = poster.rgb`, `torn.a = poster.a × mask.a`;
2. the overlay is drawn over `torn` with ordinary source-over blending;
3. the result is drawn on the wall cell like any intact poster.

`PosterArt.prepare()` composes the fifteen torn sheets exactly this way once, from the baked
page's own pixels, when the city is built; a torn sheet on a wall is one of those.

**A sheet pasted over an older one with an offset** (`PosterArt.UNDER_OFFSET`, `OVER_OFFSET`)
draws the older one 4px to one side and 2px up and the newer one 4px to the other, so two fifths
of the older sheet shows and both stay inside the cell with a gap on every side.

A mask stays inside the sheet box, so the result registers on a wall cell exactly as the intact
poster does; overlay B's hanging flap and its shadow reach about a pixel past the box's left
edge, still inside the tile.

No sheet carries readable words — every print line, header and stamp is a colour block or a gray
line, never a letter (`docs/NARRATIVE.md`, tone rule 1: nobody explains the politics).

The intact kinds follow the player's poster reference sheet (`docs/style-references/posters-01.jpg`) in shape and palette; at 20×22px
the wanted notice keeps one print line under each frame where the reference has two.

[The poster review sheet](evidence/poster-art-review-2026-09-23-plain-walls.png) shows the
intact kinds and every tear applied to each of them by that recipe, on blank ground-row wall
cells at game scale (2×, the camera's own zoom) and at 4× that; each mask and overlay alone; and
three building fronts assembled from the real `art/buildings/` wall, window, edge and plinth
textures, multiplied by a building colour and each act's own cast (`Palette.act_tint()`), at
the day 4/day 8/day 12 densities M180's own table asks for. On those fronts, stretches of plain
wall two or three columns wide with no window on any floor break the window rhythm, and posters
go only there — some of it bare, and three torn sheets on day 12.
