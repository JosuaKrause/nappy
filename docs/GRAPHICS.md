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
| The textures listed in `assets/ground_tileset.tres` | `scenes/world/city.tscn` binds this TileSet to the `Ground` layer, and `GroundTiles` chooses the source for roads, main-road lines, crossings, pavements and kerbs, alleys, open grounds, water edges and the city boundary. This indirect resource binding is why the tile filenames do not appear in the caller. `assets/tiles/mountain.svg` is also repeated directly by `src/city/city_edge.gd` above the north edge. Prepared alternatives are catalogued separately below. |
| `assets/buildings/wall.svg`, `wall_base.svg`, `wall_edge_{e,w}.svg`, `roof.svg`, `roof_edge_{n,s,e,w}.svg`, `window_{dark,lit}.svg` | `src/city/building.gd` composes and tints these wall, roof and window textures; no complete-building sprite exists. Prepared facade alternatives are catalogued separately below. |
| `assets/props/industrial_vent.svg`/`industrial_vent_b.svg`, `roof_hvac_unit.svg`/`roof_hvac_unit_b.svg`, `roof_duct_straight.svg`/`roof_duct_corner.svg`, `roof_skylight.svg`/`roof_skylight_b.svg`, `roof_vent_stack.svg`, `roof_water_tank.svg` | `src/city/building.gd` seeds one roof-furniture table per `district` (the block's starting purpose) and paints the result on the building's own interior roof cells, above its roof tiles: vents/HVAC/a duct run on `INDUSTRIAL`, skylights on `CIVIC`, mostly water tanks with an occasional vent on `RESIDENTIAL`/`COMMERCIAL`. The vent alone animates, alternating `industrial_vent.svg` and `industrial_vent_b.svg` on a per-building timer. |
| `assets/buildings/storefront_{a,b,c,d}.svg`/`storefront_{a,b,c,d}_awning.svg` | `src/city/building.gd` gives every ground-floor column of a `COMMERCIAL` building one of the four storefronts, an awning variant on a seeded share, as a plain substitution for `wall_base.svg` — the storefront's own opaque fill covers the ordinary window drawn under it the same way the plinth always sat over the wall. |
| `assets/buildings/fire_escape_a.svg`/`fire_escape_b.svg` | `src/city/building.gd` bolts one to a seeded share of `RESIDENTIAL` facades tall enough for it, as an overlay over the ground floor's two bottom rows — a composition change distinct from the storefront's, since an overlay draws after the wall rather than replacing one of its textures. |
| `assets/props/civic_portico.svg` | `src/city/building.gd` draws one at every `CIVIC` building's entrance, centred on the facade, as the same kind of overlay a fire escape is. |
| `assets/props/tree_{a,b}.svg` | `src/city/prop.gd` chooses a tree variant, scales it and may mirror it for park and forest props, and for a street tree over `tree_pit.svg` (unscaled, tile-sized) at the same choice of trunk. |
| `assets/props/tree_pit.svg` | `src/city/prop.gd` draws it centred under a street tree, `src/city/street_trees.gd` (a pure function of `CityMap`, no scene) decides where — one per pit along `RESIDENTIAL`/`COMMERCIAL` pavements, kerb-side, at a seeded spacing. |
| `assets/props/{swing_frame,bollard}.svg` | `src/city/prop.gd` draws playground swing frames and perimeter bollards. |
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
| `assets/crowd/walker_{front,back,side}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses a facing, tints the body per walker and overlays the untinted trim. Side views mirror. |
| `assets/crowd/car_{side,end}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses side or end projection, tints the body and overlays trim. |
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
| `hallway_floor_edge_{n,e,s,w}.svg`, `basement_floor_edge_{n,e,s,w}.svg`, `basement_floor.svg`, `stairwell_floor.svg`, `stair_flight_{e,w}.svg`, `stair_landing.svg` | `InteriorTileSet.build()` binds one atlas source per kind, keyed on `InteriorTile.Kind`'s own enum values; `InteriorScene.build()` paints a `TileMapLayer` cell for every position `InteriorMap`'s plan carries. `basement_floor.svg` grounds the narrow one-tile jogs between the basement's three brick-walled stretches. `hallway_floor.svg` is bound the same way but currently unused — every hallway, and the lobby, is only ever two tiles deep, so every row is one of the four edges above. |
| `hallway_wall.svg`, `hallway_wall_window.svg`, `wall_lamp.svg`, `basement_wall_brick.svg`, `lift_door_dead.svg`, `entrance_door.svg` | `InteriorScene._rebuild_walls()` draws one of these per position in `InteriorMapPlan.walls`, at that cell's own north edge — every hallway's, the lobby's and the basement's three stretches' own wall, not only one hallway's. |
| `entrance_barricade.svg` | Drawn in front of the lobby's own entrance, one of `InteriorMapPlan.entrance_tiles`. |
| `stairwell_door.svg`, `emergency_exit_door.svg` | `InteriorScene._add_standing()` draws these as ordinary feet-anchored sprites at every door's own tile and the basement's exit tile, in the y-sorted layer the player joins too — one texture for every door regardless of what it leads to. |
| `stair_rail_{e,w,level}.svg`, `stair_newel.svg` | `InteriorScene._add_stairwell_rails()` draws a rail over every flight and landing tile and a newel at each landing (a switchback's own floor landings and its turns alike), in the same y-sorted layer — see that function's own doc for why each rail's sort key is pinned to its tile's south edge. The flight tiles' own tread motif already spans a full 32×32 tile at 45°, so placing them on the diagonal grid `InteriorMap._lay_flight()` lays joins them with no seam; the rails, drawn corner to corner, do the same. |
| `chandelier.svg` | Hung at each hallway's and the lobby's own midpoint. |
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
Side views usually mirror east/west. A side/end pair is selected from movement direction; an
east-west/vertical pair is selected from the street axis without rotating the pixels.

| Event look or composite | Live SVG assets and behaviour |
|---|---|
| Cat | `cat_{crouched,running}.svg`: crouched while telegraphing, running afterward. |
| Yeller; busker; poster crew | `yeller.svg`, `busker.svg`, `poster_crew.svg`: one standing picture per look. |
| Dog walker; loose dog | `person.svg` and `dog.svg`: the walker composite draws both with a taut code-drawn lead; the loose dog draws `dog.svg` with a trailing lead. |
| Café | `cafe_table.svg` and `cafe_sitter.svg`: repeated furniture and sitters across the frontage. |
| Delivery van | `delivery_van.svg`: one stationary van parked at the kerb as a pavement obstacle. |
| Roadworks event | `barrier_segment.svg` and `barrier_end.svg`: repeated across the event's obstruction span. |
| Fire engine | `fire_engine.svg` and `fire_engine_end.svg`: side and end projections selected from heading. |
| Burning building; burnt shell | `flame.svg` is repeated and scaled by the fire animation; `rubble.svg` is repeated across the burnt frontage. |
| Stall; leaf blower | `stall.svg` repeats across the frontage; `leaf_blower.svg` is one standing picture. |
| Birds | `pigeon.svg` and `pigeon_down.svg`: per-bird wing phases alternate while code moves and shadows the flock. |
| Cyclist; ice-cream van; lorry; charging dog | `cyclist.svg`, `ice_cream_van.svg`, `lorry.svg`, `charging_dog.svg`: one moving picture per look. |
| Chatting mother | `chatting_mother_{walking,talking}.svg`: switches when conversation begins. |
| Police car | `police_car.svg` and `police_car_end.svg`: side and end projections selected from heading. |
| Roadblock (the impassable barrier row) | While its guards are posted: `roadblock_segment.svg` and `roadblock_end.svg`, repeated and capped by `_draw_spread()` — the same rail-with-caps construction the roadworks barrier below uses — so the band reads as one continuous barrier rather than a row of blocks. `checkpoint_block.svg` (kept from before the row was renamed) is now only the screen-edge badge's own icon. Once heated past `Tuning.HEAT_HUNTS_LEVEL` the guards leave the post and `EventInstance._draw_roadblock()` swaps the barrier for `guard_standing.svg` (closing to its stand-off) then `guard_lunging.svg` (giving chase) — the same pair the checkpoint kit below stands beside every hut. This is the impassable event row, not the traversable checkpoint kit below. |
| Checkpoint hut, gate, post (the region door structure) | Paths under `assets/checkpoints/`, not `assets/events/`. `checkpoint_hut` draws one of `hut_{north,south,east,west}.svg` chosen from `CityMap.pavement_inward()` at the tile it stands on, doorway facing the carriageway, plus `guard_standing.svg` beside it. `checkpoint_gate` draws `boom_gate_ns_{lowered,raised}.svg` or `boom_gate_ew_{lowered,raised}.svg` — `ns` for a north-south road, `ew` for an east-west one, read off the instance's own facing — raised or lowered from the shared `RegionPlanner.GateState`. `checkpoint_post` draws `guard_standing.svg` alone. All three use `EventInstance._draw_at_anchor()`, not `Sprites.draw_standing()`'s bottom-centre assumption, since the kit's own anchors are off-centre. |
| Abduction | `unmarked_van.svg`, `unmarked_van_end.svg` and `van_victim.svg`: heading selects the van projection; the victim is placed beside it during the abduction. |
| Robber | `robber_{waiting,lunging}.svg`: switches from waiting to the attack pose. |
| Night raid | `riot_van.svg` (side) plus `riot_van_{front,back,front_diagonal,back_diagonal}.svg`: `EventInstance._draw_riot_van()` selects the nearest of eight `_heading` octants, mirroring three of them, so a hunting raid van chasing any heading is drawn facing it rather than always side-on. `riot_van_end.svg` remains unbound — it duplicates `riot_van_front.svg`, which the octant selection already draws for that heading. |
| Army truck | `army_truck.svg` and `army_truck_end.svg`: side and end projections selected from heading. |
| Barricade | `barricade_pile.svg`: repeated improvised debris across the obstruction. |
| Protest | `protester.svg`: repeated into the live protest crowd. The directional pointing family below is not yet selected. |
| Firefight | `gunman.svg`: mirrored figures form both sides; muzzle flashes are drawn circles. |
| Fallen-tree seal | `fallen_tree.svg` and `fallen_tree_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction. |
| Car-accident seal | `car_accident.svg` and `car_accident_vertical.svg`, with matching `car_accident_shadow.svg` and `car_accident_vertical_shadow.svg`: authored scene and ground-contact shadow chosen by street axis. |
| Skip and scaffolding seals | `skip.svg` is one pavement picture; `scaffolding.svg` repeats across the other pavement frontage. |
| Burst-main seal | `burst_water_main.svg` and `burst_water_main_vertical.svg`: authored whole-street scenes chosen by street axis and fitted to the obstruction. |
| Moving-van pair | `moving_van.svg` and `moving_van_vertical.svg`: the vans stand parallel to their street; the street axis selects the side or end projection while preserving authored proportions. |
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
| M105 — The city degrades | `assets/tiles/{road,sidewalk,alley}_cracked_{hairline,cracked,broken}_{a,b}.svg` supplies two 32×32 patterns per damage level. `assets/props/litter_{apple,newspaper,cup,bag,can}.svg` uses 32×32 centre-anchored transparent canvases with visible geometry at most 10px wide/high. `garbage_sack.svg` is 28×34 and `garbage_sacks_pile.svg` 42×34, bottom-centre anchored. All placement and TileSet selection remain unbound. |
| M106 — Roofs, fronts and street trees | Every asset this milestone named is now live — see "City ground and buildings" above for the roof units, the fronts and the street tree's own pit. `assets/buildings/storefront_{a,b,c,d}_shuttered.svg` and `window_{tall,shuttered}_{dark,lit}.svg` stay unbound: the shuttered states are M105's, the city's own degradation, and the tall/shuttered window overlays are not named by this milestone. |
| M108 — Eight-direction entity graphics (vehicle diagonal sources) | `assets/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck,moving_van}_{front,back}_diagonal.svg`: separate front, flank and roof planes, retaining each vehicle's identifying equipment and cargo. Front diagonals face southeast and back diagonals northeast; west counterparts mirror horizontally. Canvases are 56×50, bottom-centre anchor (28, 50). Live vehicle bindings still use their original source views. `riot_van_{front,back}_diagonal.svg` is the exception — M56 binds it through `EventInstance._draw_riot_van()`'s heading selection; see "Events and seal pictures" above. |
| M108 — Eight-direction entity graphics (people) | `assets/crowd/walker_{front,back}_diagonal_{body,trim}.svg` adds the two 18×38 diagonal layer pairs. For `assets/events/{person,yeller,busker,poster_crew,cafe_sitter,van_victim,protester,gunman,leaf_blower}`, add `_{front,back,side,front_diagonal,back_diagonal}.svg`; the same five views apply to `chatting_mother_{walking,talking}` and `robber_{waiting,lunging}`. The people matrix records each canvas, composite and state. These named event views are unbound; their unsuffixed sources remain live. |
| M56 — The resistance is noticed (directional guards) | `assets/checkpoints/guard_{standing,lunging}_{front,back,side,front_diagonal,back_diagonal}.svg` supplies waiting and pursuit poses. Standing uses 22×44, anchor (11,44); lunging uses 36×44, anchor (17,44), including mirrored views. Heading selection and state transitions remain with the runtime owner. |
| M108 — Eight-direction entity graphics (vehicle end sources) | `assets/events/{delivery_van,fire_engine,ice_cream_van,lorry,unmarked_van,army_truck,moving_van}_{front,back}.svg`: south-facing windscreens/headlights and north-facing cargo doors/rear lamps, each bottom-centre grounded. These named projections are prepared; original side/end textures retain their live bindings. `riot_van_{front,back}.svg` is bound instead, through the same heading selection as the diagonal sources above. |
| M108 — Eight-direction entity graphics (cars) | `assets/crowd/car_{front,back,front_diagonal,back_diagonal}_{body,trim}.svg` keeps tintable paint separate from fixed windows, tyres and lights. `assets/events/police_car_{front,back,front_diagonal,back_diagonal}.svg` adds the police identity and light bar. All are bottom-centre grounded; east-authored diagonals permit west mirroring. Original crowd and police-car sources remain live. |
| M108 — Eight-direction entity graphics (cats and dogs) | `assets/events/{cat_crouched,cat_running,dog,charging_dog}_{front,back,front_diagonal,back_diagonal}.svg` supplies distinct approaching and departing postures. Each uses the shared bottom-centre ground anchor; east-authored diagonals mirror west. Existing cat/dog side sources and code-drawn leads remain the live binding. |
| M108 — Eight-direction entity graphics (birds and cyclist) | `assets/events/{pigeon,pigeon_down,cyclist}_{front,back,front_diagonal,back_diagonal}.svg`: pigeon wing phases share 22×18 canvases; cyclist ends are 30×44 and diagonals 40×44. Bottom-centre anchors and horizontal mirrors supply all headings; the original side sources remain live. |
| M100 — Small, real, and nobody's (mouse) | `assets/events/mouse.svg` is the east-facing 24×14 source; `mouse_{front,back}.svg` are 18×18, and `mouse_{front,back}_diagonal.svg` are 24×18. Bottom-centre grounded with horizontal mirror reuse; placement, scurrying and sound remain unbound. |
| M56 — The resistance is noticed (night-raid duplicate end view) | `assets/events/riot_van_end.svg`: 34×50, anchor (17, 50), a south-facing barred windscreen and headlights with wheel edges alongside the body — the same picture `riot_van_front.svg` draws. The night-raid drawing selects `riot_van_front.svg` for that heading instead (see "Events and seal pictures" above), so this duplicate stays unbound. |
| M65 — A protester points at the objective | `assets/events/protester_point_{n,ne,e,se,s,sw,w,nw}.svg`: eight 44×52 poses sharing feet anchor (22, 52). |
| M100 — Small, real, and nobody's | `assets/events/sound_pulse.svg`: 48×32 open arcs with source anchor (24, 32). `industrial_vent.svg` and `civic_portico.svg`, prepared here, are now live — see "City ground and buildings" above. |
| M102 — The finale: out of the apartment, out of the city (impact craters) | `assets/props/impact_crater_1x1.svg`: 32×32 with centre anchor (16, 16). `impact_crater_2x2.svg`: 64×64 with centre anchor (32, 32). `impact_crater_3x3.svg`: 96×96 with centre anchor (48, 48). Ground-centred decals for the finale's off-screen explosions, which leave a crater on the street; the finale's explosion row is the runtime owner once it exists, and any earlier event or city feature that needs a crater may reuse them. |

## Other unbound SVGs

The exact tracked SVGs outside the live and prepared tables are `assets/icon_stroller.svg` and
`assets/logo.svg`. Neither is loaded by the game or an export resource. They are editable identity
art counterparts: the active application icon is root `icon.svg`, while the README displays
`assets/logo.png` and the web metadata publishes `assets/social-card.png`.

## PNG replacements

`TextureResolver` selects a same-size PNG by default at
`assets/illustrated/svg-transfer/<family>/<name>.png` for a corresponding SVG. Missing or
differently sized PNGs fall back to the SVG. Existing draw transforms and animation still apply.

The live replacement family is `assets/illustrated/svg-transfer/rig/`: `mother_front_a.png`,
`mother_front_b.png`, `mother_back_a.png`, `mother_back_b.png` (24×46), `mother_side_a.png` and
`mother_side_b.png` (26×46), `pram_front.png` and `pram_back.png` (30×30), and `pram_side.png`
(36×30). `mother_{front,back}_diagonal_{a,b}.png` (26×46) and
`pram_{front,back}_diagonal.png` (36×30) supply the diagonal views; west views mirror their
east-authored partners. Each preserves native SVG alpha. Other families retain SVG textures.

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
