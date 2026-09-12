# Graphics catalogue

This catalogue answers two separate questions: what drawable art exists, and what code currently
uses it. A file is **live** only when a runtime source or scene binds it. **Prepared** means the art
has the size and registration needed by an open design, but no runtime caller yet. A filename or a
mention in a design document is not evidence that a picture appears in the game.

The SVG set below supplies the editable source graphics. Registered PNG replacements are used
by default where available; `--svg` or `?svg=1` forces SVGs. Every PNG asset needs an SVG first.

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
| Player cues | `src/player/stroller.gd` assembles the mother and pram, then places the baby-state texture above the pram and the alert texture above the mother. |
| HUD and touch controls | `src/ui/meter_bar.gd`, `home_arrow.gd`, `danger_edge.gd`, `mode_button.gd` and `touch_controls.gd` draw bars, labels, chevrons, button plates and touch focus shapes; the button glyphs named below are SVGs. |
| Excitement halo | `src/ui/entity_halo.gd` applies `assets/shaders/excitement_halo.gdshader` to a duplicated source drawing. This is shader output rather than an SVG asset. |

## Live SVG assets

### City ground and buildings

| Assets | Runtime binding and behaviour |
|---|---|
| The textures listed in `assets/ground_tileset.tres` | `scenes/world/city.tscn` binds this TileSet to the `Ground` layer, and `GroundTiles` chooses the source for roads, main-road lines, crossings, pavements and kerbs, alleys, open grounds, water edges and the city boundary. This indirect resource binding is why the tile filenames do not appear in the caller. `assets/tiles/mountain.svg` is also repeated directly by `src/city/city_edge.gd` above the north edge. `assets/tiles/{road,sidewalk,alley}_cracked_{hairline,cracked,broken}_{a,b}.svg` are eighteen further sources in the same set (ids 40–57): `GroundTiles._cracked()` swaps a plain road, sidewalk or alley tile for one of them from `Tuning.degradation_for(day)` and a fixed per-tile roll, never a kerb, line, crossing or main-road source — those keep their own markings. |
| `assets/buildings/wall.svg`, `wall_base.svg`, `wall_edge_{e,w}.svg`, `roof.svg`, `roof_edge_{n,s,e,w}.svg`, `window_{dark,lit}.svg`, `window_tall_{dark,lit}.svg`, `window_shuttered_{dark,lit}.svg` | `src/city/building.gd` composes and tints these wall, roof and window textures; no complete-building sprite exists. Each building rolls one of three upper-floor window styles once — plain, tall sash or shuttered — and a `BOARDED` block overrides the roll and forces the shuttered pair, dark. |
| `assets/props/industrial_vent.svg`/`industrial_vent_b.svg`, `roof_hvac_unit.svg`/`roof_hvac_unit_b.svg`, `roof_duct_straight.svg`/`roof_duct_corner.svg`, `roof_skylight.svg`/`roof_skylight_b.svg`, `roof_vent_stack.svg`, `roof_water_tank.svg` | `src/city/building.gd` seeds one roof-furniture table per `district` (the block's starting purpose) and paints the result on the building's own interior roof cells, above its roof tiles: vents/HVAC/a duct run on `INDUSTRIAL`, skylights on `CIVIC`, mostly water tanks with an occasional vent on `RESIDENTIAL`/`COMMERCIAL`. The vent alone animates, alternating `industrial_vent.svg` and `industrial_vent_b.svg` on a per-building timer. |
| `assets/buildings/storefront_{a,b,c,d}.svg`/`storefront_{a,b,c,d}_awning.svg`/`storefront_{a,b,c,d}_shuttered.svg` | `src/city/building.gd` gives each complete two-column span of a `COMMERCIAL` building one of the four 64×36px storefronts, as a substitution for `wall_base.svg`; each has a 26×34px entrance aligned to the shared ground line. Each facade uses seeded, shuffled groups of the four types, consuming each type once before repeating and avoiding an immediate repeat across groups; its order stays fixed across days. An odd final column remains ordinary wall, and a one-row facade keeps its wall base so the complete store fits. The storefront's opaque fill covers the ordinary windows under both columns. The shuttered variant replaces it outright on a `BOARDED` block, and — beneath the curve's own threshold — on a share of ordinary `LIVED_IN` commercial ground too; short of either, a seeded share gets the awning variant instead of the plain one. |
| `assets/buildings/fire_escape_a.svg`/`fire_escape_b.svg` | `src/city/building.gd` bolts one to a seeded share of `RESIDENTIAL` facades tall enough for it, as an overlay over the ground floor's two bottom rows — a composition change distinct from the storefront's, since an overlay draws after the wall rather than replacing one of its textures. |
| `assets/props/civic_portico.svg` | `src/city/building.gd` draws one at every `CIVIC` building's entrance, centred on the facade, as the same kind of overlay a fire escape is. |
| `assets/props/tree_{a,b}.svg` | `src/city/prop.gd` chooses a tree variant, scales it and may mirror it for park, forest and street trees. Street-tree beds are drawn separately on the ground layer. |
| `assets/props/tree_pit.svg` | `src/city/city_decals.gd` draws this tile-sized bed centered beneath the street tree, below buildings and upright entities. `src/city/street_trees.gd` decides placement on the residential/commercial street-tree runs. `City.refresh_street_trees()` refreshes both layers; a pit a fallen tree took is hidden for the day. |
| `assets/props/{swing_frame,bollard}.svg` | `src/city/prop.gd` draws playground swing frames and perimeter bollards. |
| `assets/props/litter_{apple,newspaper,cup,bag,can}.svg` | `src/city/litter.gd` (`Litter.placed()`, a pure function of `CityMap` and the day) rolls one decal per qualifying pavement, alley or square tile from `Tuning.degradation_for(day)`; `src/city/city_decals.gd` (`CityDecals`, the scene's `Decals` node, between `Ground` and `Buildings`) draws every one flat, with no body, field or y-sort. |
| `assets/props/garbage_sack.svg`/`garbage_sacks_pile.svg` | `src/city/garbage_sacks.gd` (`GarbageSacks.placed()`, a pure function of `CityMap` and the day) rolls a sack in alleys from `Tuning.DEGRADATION_FIRST_DAY` and beside building fronts a couple of days later; `src/city/city.gd` (`_place_garbage_sacks()`) adds each as a `Prop` (`Kind.SACK`/`SACK_PILE`) with a `GroundShape` for its shadow and no body. |
| `assets/props/{tunnel_mouth,bridge_deck,road_on}.svg` | `src/city/city_edge.gd` draws the tunnel, bridge and road continuation where a street meets the map boundary. |
| `assets/props/door.svg` | `src/city/city.gd` places the home door as a `Sprite2D`. |
| `assets/props/signal_head{,_back,_side}.svg` | `src/city/traffic_light.gd` chooses face-on, rear or edge-on traffic-light hardware by the arm's direction; code adds the lit lamp. |

### Player, crowd and interface

| Assets | Runtime binding and behaviour |
|---|---|
| `assets/rig/mother_{front,back,side}_{a,b}.svg`, `mother_{front,back}_diagonal_{a,b}.svg` | `src/player/stroller.gd` chooses among eight upright views and alternates the two gait frames. East-authored side and diagonal views mirror explicitly for west. Mother canvases are 24×46 cardinal front/back, 26×46 side/diagonal, all bottom-centre grounded. |
| `assets/rig/mother_carrying_{front,back,side,front_diagonal,back_diagonal}_{a,b}.svg` | `src/player/stroller.gd` draws these instead of the mother-and-pram pair, with no pram sprite at all, whenever `Stroller.carrying` is set — the escape scene's own rig, behind `--start-escape`. Same eight-view and two-gait selection and the same west mirrors as the ordinary set; the baby's own cue (`baby_{zzz,fuss,cry}.svg`) draws over the bundle at her own position rather than over a pram offset ahead of her. |
| `assets/rig/pram_{front,back,side}.svg`, `pram_{front,back}_diagonal.svg` | `src/player/stroller.gd` chooses the matching eight-direction pram view; east-authored side and diagonal views mirror explicitly for west. Pram canvases are 30×30 cardinal and 36×30 side/diagonal, bottom-centre grounded. |
| `assets/props/baby_{zzz,fuss,cry}.svg` | `src/player/stroller.gd` chooses sleeping, awake/fussing or crying state above the pram. |
| `assets/props/alert.svg`, `assets/props/alert_close.svg` | `src/player/stroller.gd` draws the exclamation over the player when an event is about her, using the close variant at the nearer threshold. |
| `assets/crowd/walker_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg`, `walker_{front,back,side,front_diagonal,back_diagonal}_{body,trim}_b.svg` | `src/crowd/crowd_agent.gd` chooses one of `EightDirection`'s eight sectors from the walker's own applied travel — its along-lane `velocity()` plus whatever its steering is doing across the lane this instant, not the lane axis alone — so a walker rounding a corner or nudged aside by `step_aside()` shows a diagonal view before its lane assignment itself turns, and a stopped walker (a give-way, a queue, a halt) keeps its last one. Each view also has a second gait frame, `_b`, the mother's own two-frame stride extended to the crowd: `_walker_gait_phase` advances by distance actually covered (`velocity().length()`, the same 0.09 rate `Stroller._walk_phase` uses) and `_walker_gait_frame()` alternates between the rest pose and feet passing while moving, holding the rest pose the instant `velocity()` drops to or below `WALKER_IDLE_SPEED` — the same give-way, queue or halt that holds the view. The `_b` frame changes only the legs and shoes in the trim layer, redrawn crossing; the front, back and side coats and heads lift a pixel with the stride the way the mother's own front/back/side `_b` frames do, while the two three-quarter views leave the coat and head untouched, matching the mother's own diagonal frames. Body and trim are bound with one transform apiece: tinted body first, untinted trim above it, both bottom-centre at the node, and one `stepping` lookup picks both layers' gait frame together so they can never disagree. West-of-centre sectors mirror their east-authored partner rather than being separately drawn. All five views and both gait frames share one 18×38 canvas and one (9, 38) feet anchor. |
| `assets/crowd/car_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses one of `EightDirection`'s eight sectors from the car's own `velocity()` — `heading()` (cardinal in a lane, the tangent of its own arc mid-turn) times its actual speed — so a turning car's picture sweeps through the diagonal for the length of the manoeuvre and a car stopped at a light, a gate or a give-way keeps its last view. Body and trim are bound with one transform: tinted body first, untinted trim above it. West-of-centre sectors mirror their east-authored partner. Side is 52×30 and needs no anchor correction, already grounded at its own canvas edge; front/back are 30×46 standing pictures anchored `CAR_STRIKE_HALF_LENGTH` (26px) south of the node, where the strike box's own south edge sits for a car pointed along that axis; the diagonals are 52×42, anchored at the strike box's own south corner rotated onto the screen (`(CAR_STRIKE_HALF_LENGTH + CAR_STRIKE_HALF_WIDTH) / sqrt(2)`, ≈28.28px) plus the 2px the canvas leaves between its alpha content and its own edge. The shadow capsule and the strike box stay independent of the picture — `_car_shadow_shape()`'s own 52×30 along/across measurement is unchanged, and both now orient with the same continuous heading the picture reads. `car_end_{body,trim}.svg`, the old two-view family's foreshortened top-down picture, is unbound — see the prepared table below. |
| `assets/ui/{pause,restart,continue,joystick,tap}.svg` | `src/ui/touch_controls.gd` draws `pause.svg`; `src/ui/mode_button.gd` selects the other four for pause, summary and control-mode buttons. |
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
| `hallway_floor_edge_{n,e,s,w}.svg`, `basement_floor_edge_{n,e,s,w}.svg`, `basement_floor.svg`, `stairwell_floor.svg`, `stair_flight_{e,w}.svg`, `stair_landing.svg` | `InteriorTileSet.build()` binds one atlas source per kind, keyed on `InteriorTile.Kind`'s own enum values; `InteriorScene.build()` paints a `TileMapLayer` cell for every position `InteriorMap` carries. `basement_floor.svg` grounds the narrow one-tile jogs between the basement's three brick-walled stretches. `hallway_floor.svg` is bound the same way but currently unused — every hallway, and the lobby, is only ever two tiles deep, so every row is one of the four edges above. |
| `hallway_wall.svg`, `hallway_wall_window.svg`, `wall_lamp.svg`, `basement_wall_brick.svg`, `lift_door_dead.svg`, `entrance_door.svg` | `InteriorScene._rebuild_walls()` draws these at their cell's north edge. The 34px lift and 42px entrance use their own half-width origins and draw after the repeating strips, so their wider frames remain centered and uncut; the basement omits brick tiles at its two walkable corridor mouths. |
| `entrance_barricade.svg` | Drawn in front of the lobby entrance in `InteriorMapPlan.entrance_tiles`; the lobby has no central chandelier, which keeps the piled furniture readable. |
| `apartment_threshold.svg`, `open_threshold.svg`, `stairwell_door.svg`, `emergency_exit_door.svg` | `InteriorMapPlan.locked_thresholds` places spaced locked apartment recesses, including the start, at the hallway south edge. `InteriorScene` draws hallway, lobby and basement-entry transitions as recessed open thresholds at that edge; doors attached to stairwell landings and the service exit stay upright, feet-anchored sprites. Both recesses draw the same shallow indent in the skirting and wall, floor colour visible at its back; the locked recess adds a brown bar across the indent's mouth, the bar being the only mark of closure — neither reads as a door seen from the front. |
| `stairwell_segment_backdrop.svg`, `stairwell_shaft_cap_{top,bottom}.svg`, `stair_flight_run_{e,w}.svg`, `stair_landing_{floor,turn}.svg`, `stair_rail_run_{e,w}.svg`, `stair_rail_run_{e,w}_rear.svg`, `stair_flight_short_e.svg`, `stair_rail_short_e.svg`, `stair_rail_short_e_rear.svg` | Each floor landing with a flight below receives a repeatable 9×8-tile shaft bay, capped above the top door and below the lobby landing. Floor landings draw a 96×32 strip over their door, landing and joining corner cells; turns draw a direction-selected 64×96 platform over their existing cleared corners. Every full flight receives a broad 160×160 deck registered at its top landing and a foreground rail. A floor-starting flight also has a rear rail in the structural layer; return flights leave that edge open at the turn, so an incoming foreground rail never crosses it. The basement entry receives its own shorter paired-rail deck over its two existing diagonal cells. The foreground rails' bottom-edge sort keys keep her behind them while leaving her feet and the treads visible. Each flight deck draws its treads as vertical lines clipped to the tread body, one per step and spaced along the run, thickening toward the bottom landing so the flight reads as descending. The tile-sized flight and landing sources remain the ground and walking registration; no visual overlay changes collision, slope redirection or the plan. |
| `chandelier.svg` | Hung at each hallway midpoint, where it lights the corridor without covering the lobby barricade. |
| `puddle.svg`, `basement_debris.svg`, `rat.svg` | Ground decals over `InteriorMapPlan.decals`, in the basement corridor. |

### Closures

`src/routes/closure_marker.gd` owns this entire family. These pictures describe roads removed from
the day's route graph; they are separate from the event pictures with similar nouns.

| Assets | Runtime behaviour |
|---|---|
| `assets/closures/barrier_{across,along}.svg` | Repeated on the two sides of a closed street, choosing the drawing by the closure's axis. |
| `assets/closures/sign_closed.svg` | Added at the end of the closure facing approaching traffic. |
| `assets/closures/roadworks.svg` | Centre marker for a roadworks closure. |
| `assets/closures/fallen_tree.svg` | Centre marker for a fallen-tree closure. |
| `assets/closures/crashed_car.svg` | Centre marker for a crash closure. |
| `assets/closures/rubble.svg` | Centre marker for a rubble closure. |

### Events and seal pictures

`src/events/event_instance.gd` preloads every asset in this table, selects it from
`EventDef.Look`, and also supplies the same row-specific silhouette to the screen-edge danger badge.
Every unqualified filename in this table is relative to `assets/events/`.
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
| Cat | `cat_{crouched,running}_{front,back,side,front_diagonal,back_diagonal}.svg` (the `side` pair is the existing `cat_{crouched,running}.svg`): crouched while telegraphing, running afterward, `EventInstance._select_view()` picking the view from the cat's own `_heading` the same way `CrowdAgent` picks a walker's. The running posture also has a `cat_running_{view}_b.svg` stride frame — legs only, no coat or head to lift on a quadruped's low silhouette — alternated by `_gait_stepping()` on the distance actually covered; the crouch holds one picture, since it is the telegraph, held still. |
| Mouse | `mouse.svg`: one side-on picture, mirrored east/west like `delivery_van` rather than switching pose — see `docs/EVENTS.md`'s `alley_mouse` row. `mouse_b.svg` is its own dash's second frame — the tail curls differently rather than crossing legs it has no room to draw at this scale — alternated by `_gait_stepping()`. The prepared `mouse_{front,back}[_diagonal].svg` family, and its own `_b` companions authored alongside it, stay unbound: `EventCatalogue._alley_mouse()`'s own docstring documents, with its reasoning, that the row is not given a second posture or a heading-selected picture. |
| Yeller; busker; poster crew | `yeller_{view}.svg`, `busker_{view}.svg`, `poster_crew_{view}.svg` (`{view}` is `front`, `back`, `side`, `front_diagonal` or `back_diagonal`): each a stationary figure whose view comes from its own site facing — the same `_heading` that used to only decide `_heading_is_west()`'s mirror of one picture, now read as a full octant through `EventInstance._select_view()`. The old unsuffixed `yeller.svg`/`busker.svg`/`poster_crew.svg` stay live only as `icon_for()`'s own screen-edge badge silhouette. The pacing yeller also has `yeller_{view}_b.svg`, a stride frame alternated by `_gait_stepping()` as he paces his beat; the busker has `busker_{view}_b.svg`, the strumming hand raised, alternated on a half-second timer (`_idle_stepping()`, `BUSKER_STRUM_PERIOD`) through `EventInstance._draw_busker()` rather than on distance, since he never moves. `poster_crew` keeps its single picture — this round gave nobody in that trio a second frame but the yeller and the busker. |
| Dog walker; loose dog | `person_{view}.svg` and `dog_{view}.svg` (`dog`'s `side` is the existing `dog.svg`): the walker composite draws both from the same selected view and mirror — the dog faces the walker's own travel, since it is being led rather than watching anything of its own — with the taut code-drawn lead unchanged; the loose dog draws `dog_{view}.svg` from its own travel with a trailing lead. The old unsuffixed `person.svg` stays live only as the dog walker's badge silhouette. Both bodies also carry a `_b.svg` stride frame (`person_{view}_b.svg`, `dog_{view}_b.svg`, and the loose dog's own `dog_b.svg` for its side view) — the walker's coat and head lift a pixel on the cardinal and side views the way the crowd walker's own do, the dog's legs only — and the walker and his dog read one shared `_gait_stepping()` phase, so they are never mid-stride at different instants of the same stride. |
| Café | `cafe_table.svg` and `cafe_sitter_{view}.svg`: repeated furniture and sitters across the frontage. Each sitter faces from its alternating chair position toward its own table: east/west for a horizontal frontage, south/north for a vertical one. The fixed screen-depth offset does not change that bearing. The old unsuffixed `cafe_sitter.svg` is unused once the named views cover it (no badge of its own; the café's icon is `cafe_table.svg`). Each sitter also has a `cafe_sitter_{view}_b.svg` idle frame — the seated body leans a couple of pixels above the table-owned seat, which stays put — alternated every `SITTER_IDLE_PERIOD` (a few seconds) by `_idle_stepping()`, offset per café by a hash of its own siting position so two frontages placed the same day do not lean in lockstep. The lean belongs to the whole frontage and the facing to each seat: `EventInstance._draw_cafe()` picks the frame table once per instance off that timer, then indexes it with the view each chair chooses. |
| Delivery van | `delivery_van_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `delivery_van.svg`): a stationary van parked at the kerb as a pavement obstacle, its view read through `EventInstance._draw_eight_view()` from the row's own placement heading — always due east, since `AT_THE_KERB` never turns it, so the row always draws the `side` view. Its `side` picture is authored facing west (`docs/evidence/svg-vehicles-2026-09-10/README.md`), so `_draw_eight_view`'s `side_faces_west` mirrors it for this always-east heading; the picture is now the mirror of what `_draw_simple` drew before this row was bound, a cosmetic change with no effect on its shape, shadow or obstruction. The old `delivery_van_end.svg` was never authored; this row never had one. |
| Roadworks event | `barrier_segment.svg` (22×22) and `barrier_segment_vertical.svg` (14×26) supply broad and narrow upright projections; `barrier_end.svg` supplies the end posts. The repeated span crosses the street or the alley's short axis. Drawing, collision and field distance share that axis. |
| Fire engine | `fire_engine_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `fire_engine.svg`): `fire_truck` is mobile, so its view is read from its actual travel heading (`_heading`, updated every frame it advances along its route) through `EventInstance._draw_eight_view()`, `side_faces_west` set since its `side` picture is west-authored. The old `fire_engine_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Burning building; burnt shell | `flame.svg` is repeated and scaled by the fire animation; `rubble.svg` is repeated across the burnt frontage. |
| Stall | `stall.svg` repeats across the frontage. |
| Leaf blower | `leaf_blower_{view}.svg`: one stationary figure whose view comes from its own site facing, the directional nozzle baked into each authored view. The old unsuffixed `leaf_blower.svg` stays live only as the badge silhouette. `leaf_blower_{view}_b.svg` gives him a stride frame too, read through `_gait_stepping()` the same way every other family in this table's row is; the row never actually moves today, so the lookup is never reached in play — wired for uniformity the way `lorry`'s own diagonal views are. |
| Birds | `pigeon_{view}.svg` and `pigeon_down_{view}.svg` (each `side` is the existing `pigeon.svg`/`pigeon_down.svg`): per-bird wing phases alternate as before, and each bird now also holds its own eight-view sector from its own `heading` — a flock is eleven bodies wheeling independently, not one actor with one facing, so the hold is per bird rather than shared with the instance. |
| Cyclist; charging dog | `cyclist_{view}.svg` and `charging_dog_{view}.svg` (each `side` is the existing `cyclist.svg`/`charging_dog.svg`): one moving picture per look, the view read from the rider's or the dog's own travel. Each also has a `_b.svg` stride frame — the cyclist's own two pedal positions swap (rider and bike are one picture, so one phase swaps both), the charging dog's legs shift — alternated by `_gait_stepping()`. |
| Ice-cream van; lorry | `ice_cream_van_{front,back,side,front_diagonal,back_diagonal}.svg` and `lorry_{front,back,side,front_diagonal,back_diagonal}.svg` (each `side` is the existing unsuffixed source): both stationary rows, drawn through `EventInstance._draw_eight_view()` from their own placement heading with no `side_faces_west` — both `side` pictures are already east-authored. `ice_cream_van` (`AT_THE_KERB`) is always due east like `delivery_van` above, so it always draws its `side` view unmirrored, exactly as `_draw_simple` drew it before. `lorry` (`reversing_lorry`, `AGAINST_THE_BUILDING`) faces due east or west only — `_wants_this_side` refuses any facing that is not purely horizontal — so its `front_diagonal`/`back_diagonal`/`front`/`back` views are never actually reached; the row keeps drawing exactly the `side` view, mirrored by which way it backs in, that it always did. |
| Chatting mother | `chatting_mother_{walking,talking}_{view}.svg`: switches when conversation begins, the view read from her own pacing travel. The old unsuffixed `chatting_mother_walking.svg` stays live only as the badge silhouette; `chatting_mother_talking.svg` is unused once the named views cover it. The walking posture also has `chatting_mother_walking_{view}_b.svg`, a stride frame alternated by `_gait_stepping()`; the talking posture stays single, since `is_chatting()` freezes her `_process()` for the whole of a conversation and the gait freezes with it. |
| Police car | `police_car_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `police_car.svg`): `police_patrol` is mobile and turns along its own patrol route, so `EventInstance._draw_eight_view()` reads its actual travel heading with no `side_faces_west` — its `side` picture is already east-authored — and this is the first vehicle row whose diagonal views are ordinarily reachable rather than a dead branch, since a patrol car actually turns corners. The old `police_car_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Roadblock (the impassable barrier row) | While its guards are posted: `roadblock_segment.svg` and `roadblock_end.svg`, repeated and capped by `_draw_spread()` — the same rail-with-caps construction the roadworks barrier below uses — so the band reads as one continuous barrier rather than a row of blocks. `checkpoint_block.svg` (kept from before the row was renamed) is now only the screen-edge badge's own icon. Once heated past `Tuning.HEAT_HUNTS_LEVEL` the guards leave the post and `EventInstance._draw_roadblock()` swaps the barrier for `guard_standing.svg` (closing to its stand-off) then `guard_lunging.svg` (giving chase) — the same pair the checkpoint kit below stands beside every hut. This is the impassable event row, not the traversable checkpoint kit below. |
| Checkpoint hut, gate, post (the region door structure) | Paths under `assets/checkpoints/`, not `assets/events/`. `checkpoint_hut` draws one of `hut_{north,south,east,west}.svg` chosen from `CityMap.pavement_inward()` at the tile it stands on, doorway facing the carriageway, plus `guard_standing.svg` beside it. `checkpoint_gate` draws `boom_gate_ns_{lowered,raised}.svg` or `boom_gate_ew_{lowered,raised}.svg` — `ns` for a north-south road, `ew` for an east-west one, read off the instance's own facing — raised or lowered from the shared `RegionPlanner.GateState`. `checkpoint_post` draws `guard_standing.svg` alone. All three use `EventInstance._draw_at_anchor()`, not `Sprites.draw_standing()`'s bottom-centre assumption, since the kit's own anchors are off-centre. |
| Abduction | `unmarked_van_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `unmarked_van.svg`) and `van_victim_{view}.svg`: the victim is placed beside the van during the abduction, its view read from the direction of the short walk toward it, which is always due east or west by construction. The van itself is drawn through the same `EventInstance._draw_eight_view()` every other vehicle family above uses, `side_faces_west` set since `unmarked_van.svg` is west-authored: idling (`is_waiting()`) its heading is always due east, so it always draws its `side` view, now mirrored from what `_draw_vehicle` drew before this row was bound — the same cosmetic, shape-preserving change `delivery_van` above gets, for the same reason. Once heated past `Tuning.HEAT_HUNTS_LEVEL` and hunting, its heading is the real chase direction and every one of the five views is reachable. The victim and the van share one `_view_sector` field on the instance, safe because `is_taking_a_victim()` is only ever true while the van is still waiting (heading due east) and the victim's own walk is always due east or west, 180° apart or exactly aligned with the van's — never a heading `EightDirection`'s hold could get wrong. The old `unmarked_van_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. The old unsuffixed `van_victim.svg` is unused once the named views cover it (no badge of its own). The victim also carries `van_victim_{view}_b.svg`, a stride frame for her short walk to the van — read off `_victim_gait_stepping()`, a query derived from her own walk's fixed speed and elapsed time rather than the ordinary distance-driven `_gait_phase`, since the walk is a scripted lerp on age rather than anything that touches `_path_travelled`. |
| Robber | `robber_{waiting,lunging}_{view}.svg`: switches from waiting to the attack pose. Once he has noticed her, `_chase()` already keeps `_heading` pointed at her for the telegraph and the lunge alike, so the lunging posture reads it directly; before that he has nothing else of his own to face, so the waiting posture reads `player_at` instead (`EventInstance._robber_waiting_heading()`) — a man only watching the street is worth nothing next to a man watching her. The old unsuffixed `robber_waiting.svg`/`robber_lunging.svg` stay live only as the badge silhouette (`ROBBER` returns `ROBBER_LUNGING`). The lunge also has `robber_lunging_{view}_b.svg`, a stride frame alternated by `_gait_stepping()`; the waiting posture stays single, since a man only watching the street has nothing to stride toward yet. |
| Night raid | `riot_van.svg` (side) plus `riot_van_{front,back,front_diagonal,back_diagonal}.svg`: `EventInstance._draw_body()` reads `RIOT_VAN_BY_VIEW` through the same shared `_draw_eight_view()` every other vehicle family above uses, `side_faces_west` set since `riot_van.svg` is west-authored like `unmarked_van.svg` and `army_truck.svg` above, so a hunting raid van chasing due east or west is drawn facing the way it is travelling rather than mirrored backwards. `riot_van_end.svg` remains unbound — it duplicates `riot_van_front.svg`, which the octant selection already draws for that heading. |
| Army truck | `army_truck_{front,back,side,front_diagonal,back_diagonal}.svg` (`side` is the existing `army_truck.svg`): `military_convoy` is mobile and follows its own street route, so `EventInstance._draw_eight_view()` reads its actual travel heading, `side_faces_west` set since its `side` picture is west-authored. The old `army_truck_end.svg`, drawn for both north and south headings alike, is superseded by the two-way `front`/`back` split and stays on disk unbound. |
| Barricade | `barricade_pile.svg`: repeated improvised debris across the obstruction. |
| Protest | `protester_{view}.svg`, its view read from the rank's own site facing, whenever there is nothing to point at — a mark step or no step at all, `_protester_texture()`'s own `PROTESTER` sentinel. The eight `protester_point_*` poses stay exactly as M65 bound them: unmirrored, selected by bearing to the resistance's own objective rather than by this family's view table, and single — they never gained a `_b` frame. The plain rank does: `protester_{view}_b.svg` is its own stride frame, alternated by `_gait_stepping()`; the row never actually moves today, so it is never reached in play, the same as the leaf blower's above. The old unsuffixed `protester.svg` is both that sentinel and the badge silhouette, so it stays live on both counts. |
| Firefight | `gunman.svg`: mirrored figures form both sides; muzzle flashes are drawn circles. The prepared `gunman_{front,back,front_diagonal,back_diagonal}.svg` stay unbound: the two shooters face along a fixed local axis by construction (the line between them), which the side view already draws, and `gunman_side.svg` is the same picture as `gunman.svg` — there is no heading a firefight's own composite could ever turn to reach the other three. |
| Fallen-tree seal | `fallen_tree.svg` and `fallen_tree_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction. |
| Car-accident seal | `car_accident.svg` and `car_accident_vertical.svg`, with matching `car_accident_shadow.svg` and `car_accident_vertical_shadow.svg`: authored scene and ground-contact shadow chosen by street axis. |
| Skip and scaffolding seals | `skip.svg` is one pavement picture; `scaffolding.svg` repeats across the other pavement frontage. |
| Burst-main seal | `burst_water_main.svg` and `burst_water_main_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction. |
| Moving-van pair | `moving_van.svg` and `moving_van_vertical.svg`: the vans stand parallel to their street; the street axis selects the side or end projection while preserving authored proportions, unchanged by this milestone. `moving_van_{front,back,front_diagonal,back_diagonal}.svg` stay prepared and unbound: the seal's own axis choice is a binary (parallel to the street or across it) with no heading that ever turns to a diagonal, and `moving_van_vertical.svg` already serves the "across" projection as its own authored scene — ramp down, doors open — rather than a generic end view, the same reason `gunman`'s own front/back/diagonal stay prepared. |
| Burnt-out-car seal | `burnt_out_car.svg` and `burnt_out_car_vertical.svg`: four wrecks form a hard seal across the whole street. Each car lies perpendicular to the street; its axis selects the side or end projection. |
| Collapsed-frontage seal | `collapsed_frontage.svg`: the debris segment repeats across one hard seal spanning the whole street, kerb to kerb. |

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
walked one 32×32 tile at a time rather than drawn as a single picture — the player rejected the
whole-module `stair_down.svg` in PLAYTEST-54 because a tile is what a `TileMapLayer` can make
walkable, and one picture cannot be (see
`docs/evidence/archive/rejected-graphics/stair-down-module-superseded-2026-09-10/README.md`, the
archived module and the reasoning). Exterior `fire_escape_{a,b}.svg` stays 48×64, with alternating
lateral flights parallel to the facade; that pair is unaffected by this milestone. The
[stair source and assembly review](evidence/svg-sideways-stairs-2026-09-10/README.md) documents
the retired module's own sources; the [M112 stair tile review](evidence/m112-stairs-2026-09-10/)
shows the kit at native and 3× scale and one assembled flight.

The [people source matrix](evidence/svg-people-2026-09-10/PEOPLE-MATRIX.md) names every body,
trim, gait and action source, its registration and intended live or prepared use. Native/3×
sheets show each layer and all eight composed facings. A pointing pose's suffix describes the
arm direction; ordinary movement suffixes describe the body's facing.

| Owning design | Prepared assets, dimensions and registration |
|---|---|
| M102 — The finale: out of the apartment, out of the city (interior) | `assets/interior/hallway_wall_window_flash.svg` — the brief illuminated window state from an off-screen explosion, sharing `hallway_wall_window.svg`'s own placement once M112's interior scene extends past the escape slice. `assets/events/steam.svg` is 32×48; `explosion_preview.svg` is a 40×40 optional burst. The rest of `assets/interior/` is now bound by M112, the escape scene, walkable — see "Interior (the escape scene)" above. |
| M100 — Small, real, and nobody's (chalk and alley review) | `assets/props/chalk_mark.svg` and `chalk_mark_touched.svg` are 32×32 centre-anchored decals; the touched version keeps the circle/cross and adds her small tick. `assets/tiles/alley_draft.svg` is a 32×32 paving alternative for comparison. Current code-drawn chalk and the live alley tile remain the runtime pictures. |
| M106 — Roofs, fronts and street trees | Every asset this milestone named is now live — see "City ground and buildings" above for the roof units, the fronts and the street tree's own pit. `assets/buildings/storefront_{a,b,c,d}_shuttered.svg` and `window_{tall,shuttered}_{dark,lit}.svg`, prepared here, are also now live — see the same section — bound by the city's own degradation rather than by this milestone. |
| M108 — Eight-direction entity graphics (vehicle diagonal sources) | `assets/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck}_{front,back}_diagonal.svg` are now live — see "Events and seal pictures" above. `moving_van_{front,back}_diagonal.svg` stays prepared and unbound: the seal's own side/vertical choice never turns to a diagonal, and `moving_van_vertical.svg` already serves the "across the street" projection as its own authored scene rather than a generic end view. Canvases are 56×50, bottom-centre anchor (28, 50); front diagonals face southeast and back diagonals northeast, west counterparts mirroring horizontally. |
| M108 — Eight-direction entity graphics (gunman) | `gunman_{front,back,front_diagonal,back_diagonal}.svg` stay prepared and unbound. Every other named view in the people matrix — `person`, `yeller`, `busker`, `poster_crew`, `cafe_sitter`, `van_victim`, `protester`, `leaf_blower`, `chatting_mother_{walking,talking}` and `robber_{waiting,lunging}` — is now live; see "Events and seal pictures" above. A firefight's two shooters always face along the fixed local axis between them, which the side view already draws (`gunman_side.svg` is the same picture as `gunman.svg`), so there is no heading the composite could ever turn to reach the other three. |
| M56 — The resistance is noticed (directional guards) | `assets/checkpoints/guard_{standing,lunging}_{front,back,side,front_diagonal,back_diagonal}.svg` supplies waiting and pursuit poses. Standing uses 22×44, anchor (11,44); lunging uses 36×44, anchor (17,44), including mirrored views. Heading selection and state transitions remain with the runtime owner. |
| M108 — Eight-direction entity graphics (vehicle end sources) | `assets/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck}_{front,back}.svg` are now live — see "Events and seal pictures" above; each supersedes that family's old single `_end.svg`, drawn for both north and south headings alike, which stays on disk unbound. `moving_van_{front,back}.svg` stays prepared and unbound for the same reason its diagonals do — see the row above. South-facing windscreens/headlights and north-facing cargo doors/rear lamps, each bottom-centre grounded. |
| M108 — Eight-direction entity graphics (cars) | `assets/events/police_car_{front,back,front_diagonal,back_diagonal}.svg` is live — see "Events and seal pictures" above — with the police identity and light bar baked per view. The crowd car's own eight-view binding (`car_{front,back,side,front_diagonal,back_diagonal}_{body,trim}.svg`) is live — see "Player, crowd and interface" above, not this prepared table; `car_end_{body,trim}.svg`, its old two-view family's foreshortened top-down picture, is prepared and unbound. |
| M100 — Small, real, and nobody's (mouse) | `assets/events/mouse.svg` is the east-facing 24×14 source, bound to the `alley_mouse` catalogue row through `EventDef.Look.MOUSE` and drawn by `EventInstance._draw_simple()`, mirrored east/west the same plain way `skip` is rather than through a directional family; its own `mouse_b.svg` dash frame is bound alongside it — see "Events and seal pictures" above. `mouse_{front,back}.svg` (18×18), `mouse_{front,back}_diagonal.svg` (24×18) and their own `_b` siblings stay prepared and unbound, since the row they would serve does not pick a picture by heading either — see `EventCatalogue._alley_mouse()`. Sound remains unbound. |
| M56 — The resistance is noticed (night-raid duplicate end view) | `assets/events/riot_van_end.svg`: 34×50, anchor (17, 50), a south-facing barred windscreen and headlights with wheel edges alongside the body — the same picture `riot_van_front.svg` draws. The night-raid drawing selects `riot_van_front.svg` for that heading instead (see "Events and seal pictures" above), so this duplicate stays unbound. |
| M65 — A protester points at the objective | `assets/events/protester_point_{n,ne,e,se,s,sw,w,nw}.svg`: eight 44×52 poses sharing feet anchor (22, 52). |
| M100 — Small, real, and nobody's | `assets/events/sound_pulse.svg`: 48×32 open arcs with source anchor (24, 32). `industrial_vent.svg` and `civic_portico.svg`, prepared here, are now live — see "City ground and buildings" above. |
| M102 — The finale: out of the apartment, out of the city (impact craters) | `assets/props/impact_crater_1x1.svg`: 32×32 with centre anchor (16, 16). `impact_crater_2x2.svg`: 64×64 with centre anchor (32, 32). `impact_crater_3x3.svg`: 96×96 with centre anchor (48, 48). Ground-centred decals for the finale's off-screen explosions, which leave a crater on the street; the finale's explosion row is the runtime owner once it exists, and any earlier event or city feature that needs a crater may reuse them. |

## Other unbound SVGs

The exact tracked SVGs outside the live and prepared tables are `assets/icon_stroller.svg` and
`assets/logo.svg`. Neither is loaded by the game or an export resource. They are editable identity
art counterparts: the active application icon is root `icon.svg`, while the README displays
`assets/logo.png` and the web metadata publishes `assets/social-card.png`.
The [comic identity record](evidence/comic-identity-2026-09-12/GENERATION.md) maps these raster
derivatives and both exported stroller icon sizes to their SVG sources. The social card is
the logo flattened onto opaque white; the rounded slate icon plate remains part of the mark.

## PNG replacements

`assets/illustrated/svg-transfer/tiles/` contains native 32×32 replacements for the outdoor
ground SVG family. `City._ground_tile_set_with_transfers()` substitutes textures without
changing TileSet source IDs or atlas regions, and `CityEdge` resolves the mountain texture
for its separate repeated drawing. The prepared `alley_draft` has a PNG but remains unbound.
The [generation record](evidence/style-transfer-tiles-2026-09-12/GENERATION.md) links source
pairings, exact prompts, raw outputs and repeated-tile comparisons.

`TextureResolver` selects a same-size PNG by default at
`assets/illustrated/svg-transfer/<family>/<name>.png` for a corresponding SVG. Missing or
differently sized PNGs fall back to the SVG. Existing draw transforms and animation still apply.

The live replacement family is `assets/illustrated/svg-transfer/rig/`: `mother_front_a.png`,
`mother_front_b.png`, `mother_back_a.png`, `mother_back_b.png` (24×46), `mother_side_a.png` and
`mother_side_b.png` (26×46), `pram_front.png` and `pram_back.png` (30×30), and `pram_side.png`
(36×30). `mother_{front,back}_diagonal_{a,b}.png` (26×46) and
`pram_{front,back}_diagonal.png` (36×30) supply the diagonal views; west views mirror their
east-authored partners. The carrying set adds
`mother_carrying_{front,back}_{a,b}.png` (24×46) and
`mother_carrying_{side,front_diagonal,back_diagonal}_{a,b}.png` (26×46), selected by the same
resolver during the escape scene. All use bottom-center anchors and retain their redrawn
silhouettes and true transparency. The [comic rig record](evidence/comic-rig-2026-09-12/GENERATION.md)
documents shared identity across both mother states, directions and frames, plus reproducible
registration within the native canvases.

`assets/illustrated/svg-transfer/props/` supplies `garbage_sack.png` (28×34) and
`garbage_sacks_pile.png` (42×34), bottom-center anchored, plus `litter_{can,apple,bag,newspaper,cup}.png`
(32×32), center anchored. These use the existing `Prop` and `CityDecals` drawing paths with
the comic redraw's own alpha. Their [generation record](evidence/comic-props-2026-09-12/GENERATION.md)
preserves shared material references and reproducible extraction and anchor registration.
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
