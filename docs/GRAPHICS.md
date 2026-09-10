# Graphics catalogue

This catalogue answers two separate questions: what drawable art exists, and what code currently
uses it. A file is **live** only when a runtime source or scene binds it. **Prepared** means the art
has the size and registration needed by an open design, but no runtime caller yet. A filename or a
mention in a design document is not evidence that a picture appears in the game.

The default presentation is the SVG set below. The illustrated PNG presentation remains an opt-in
comparison; its active manifests are linked separately rather than mixing generated source sheets
into the SVG inventory.

## Shared drawing contract

`src/sprites.gd` owns the ground-plane contract used by the player, crowd, events and props:
`draw_standing()` puts the bottom centre of a texture at the node's world position and mirrors
about that point, while `draw_shadow()` draws the contact-shadow ellipse every point-shaped object
casts. There is no shadow SVG any more: `GroundShape` (`src/ground_shape.gd`) draws every shadow in
code, from the object's own ground shape — a point everywhere the object's shape is a point, and a
capsule (a rotated ellipse at each end of the object's spine, hulled together) wherever it is a
spread or a wide vehicle. Unless a row below says otherwise, an actor or prop SVG is bottom-centre
anchored by `draw_standing()`.

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
| `assets/tiles/*.svg` | Every SVG in this folder is an external texture in `assets/ground_tileset.tres`. `scenes/world/city.tscn` binds that TileSet to the `Ground` layer, and `GroundTiles` chooses the source for roads, main-road lines, crossings, pavements and kerbs, alleys, open grounds, water edges and the city boundary. This indirect resource binding is why the tile filenames do not appear in the caller. `mountain.svg` is also repeated directly by `src/city/city_edge.gd` above the north edge. |
| `assets/buildings/*.svg` | `src/city/building.gd` uses the complete folder: `wall.svg`, `wall_base.svg`, `wall_edge_{e,w}.svg`, `roof.svg`, `roof_edge_{n,s,e,w}.svg` and `window_{dark,lit}.svg`. The code composes and tints them; no complete-building sprite exists. |
| `assets/props/tree_{a,b}.svg` | `src/city/prop.gd` chooses a tree variant, scales it and may mirror it for park and forest props. |
| `assets/props/{swing_frame,bollard}.svg` | `src/city/prop.gd` draws playground swing frames and perimeter bollards. |
| `assets/props/{tunnel_mouth,bridge_deck,road_on}.svg` | `src/city/city_edge.gd` draws the tunnel, bridge and road continuation where a street meets the map boundary. |
| `assets/props/door.svg` | `src/city/city.gd` places the home door as a `Sprite2D`. |
| `assets/props/signal_head{,_back,_side}.svg` | `src/city/traffic_light.gd` chooses face-on, rear or edge-on traffic-light hardware by the arm's direction; code adds the lit lamp. |

### Player, crowd and interface

| Assets | Runtime binding and behaviour |
|---|---|
| `assets/rig/mother_{front,back,side}_{a,b}.svg` | `src/player/stroller.gd` chooses a facing and alternates the two gait frames. The side pair mirrors for west. |
| `assets/rig/pram_{front,back,side}.svg` | `src/player/stroller.gd` chooses a facing; the side view mirrors with the mother. |
| `assets/props/baby_{zzz,fuss,cry}.svg` | `src/player/stroller.gd` chooses sleeping, awake/fussing or crying state above the pram. |
| `assets/props/alert.svg`, `assets/props/alert_close.svg` | `src/player/stroller.gd` draws the exclamation over the player when an event is about her, using the close variant at the nearer threshold. |
| `assets/crowd/walker_{front,back,side}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses a facing, tints the body per walker and overlays the untinted trim. Side views mirror. |
| `assets/crowd/car_{side,end}_{body,trim}.svg` | `src/crowd/crowd_agent.gd` chooses side or end projection, tints the body and overlays trim. |
| `assets/ui/{pause,restart,continue,joystick,tap}.svg` | `src/ui/touch_controls.gd` draws `pause.svg`; `src/ui/mode_button.gd` selects the other four for pause, summary and control-mode buttons. |
| `icon.svg` | `project.godot` uses the root SVG as the application icon, including the exported icon generated by Godot. |

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
| Roadblock (the impassable barrier row) | `checkpoint_block.svg`: repeated poured-concrete blocks across its obstruction. Despite the filename — kept from before the row was renamed — this is the impassable event row, not the traversable checkpoint kit below. |
| Checkpoint hut, gate, post (the region door structure) | Paths under `assets/checkpoints/`, not `assets/events/`. `checkpoint_hut` draws one of `hut_{north,south,east,west}.svg` chosen from `CityMap.pavement_inward()` at the tile it stands on, doorway facing the carriageway, plus `guard_standing.svg` beside it. `checkpoint_gate` draws `boom_gate_ns_{lowered,raised}.svg` or `boom_gate_ew_{lowered,raised}.svg` — `ns` for a north-south road, `ew` for an east-west one, read off the instance's own facing — raised or lowered from the shared `RegionPlanner.GateState`. `checkpoint_post` draws `guard_standing.svg` alone. All three use `EventInstance._draw_at_anchor()`, not `Sprites.draw_standing()`'s bottom-centre assumption, since the kit's own anchors are off-centre. |
| Abduction | `unmarked_van.svg`, `unmarked_van_end.svg` and `van_victim.svg`: heading selects the van projection; the victim is placed beside it during the abduction. |
| Robber | `robber_{waiting,lunging}.svg`: switches from waiting to the attack pose. |
| Night raid | `riot_van.svg`: one side view used by M56 — The resistance is noticed. There is no riot-van end-view asset. |
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

| Owning design | Prepared assets, dimensions and registration |
|---|---|
| M102 — The finale: out of the apartment, out of the city | `assets/rig/mother_carrying_{front,back,side}_{a,b}.svg`: six frames of the existing mother carrying the baby in her arms, with no stroller. Front/back canvases are 24×46 with feet anchor (12, 46); side canvases are 26×46 with feet anchor (13, 46). Each facing has the existing two gait frames; the side view faces east and mirrors for west. Front/profile show the supported baby; the back view occludes most of the bundle. No runtime binding yet; the finale's player rig is the milestone's. |
| M56 — The resistance is noticed (the checkpoint's own hunting posture) | `assets/checkpoints/guard_lunging.svg`: 36×44, ground anchor (17, 44), authored east and mirrorable west, matching `guard_standing.svg`'s scale — see the live checkpoint kit in "Events and seal pictures" above. M56 assigns this pose to the proposed waiting/departing guard response for a `HUNTS`-heated checkpoint, if that design is accepted; no runtime binding yet. |
| M65 — A protester points at the objective | `assets/events/protester_point_{n,ne,e,se,s,sw,w,nw}.svg`: eight 44×52 poses sharing feet anchor (22, 52). |
| M100 — Small, real, and nobody's | `assets/props/industrial_vent.svg`: 32×32 roof unit. `assets/props/civic_portico.svg`: 32×48 entrance with ground anchor (16, 48). `assets/events/sound_pulse.svg`: 48×32 open arcs with source anchor (24, 32). |
| M102 — The finale: out of the apartment, out of the city (impact craters) | `assets/props/impact_crater_1x1.svg`: 32×32 with centre anchor (16, 16). `impact_crater_2x2.svg`: 64×64 with centre anchor (32, 32). `impact_crater_3x3.svg`: 96×96 with centre anchor (48, 48). Ground-centred decals for the finale's off-screen explosions, which leave a crater on the street; the finale's explosion row is the runtime owner once it exists, and any earlier event or city feature that needs a crater may reuse them. |

## Other unbound SVGs

The exact tracked SVGs outside the live and prepared tables are `assets/icon_stroller.svg` and
`assets/logo.svg`. Neither is loaded by the game or an export resource. They are editable identity
art counterparts: the active application icon is root `icon.svg`, while the README displays
`assets/logo.png` and the web metadata publishes `assets/social-card.png`.

## Illustrated opt-in

The legacy SVG presentation remains the default. With `--illustrated`, or `?illustrated=1` on the
web, `src/player/stroller.gd` adds `ModularPerson` and `src/crowd/crowd_agent.gd` adds
`ModularWalker`. The active player sheets and registration data are
`assets/illustrated/modular/mother-parts-v3.png` with
`mother-parts-v3.manifest.json`, and `pram-layered-v3-draft-transparent.png` with
`pram-layered-v3.manifest.json`. The active walker set is the three PNGs named by
`assets/illustrated/walkers/MANIFEST.json`. These manifests own crops, pivots, anchors, layer order
and attachment data; the SVG inventory does not duplicate them.

`src/visuals/illustrated_street_review.gd` uses the four `assets/illustrated/street/*-v2.png`
layers only in the dedicated street review scene. It is not a live replacement for the TileSet or
building renderer. The remaining generated sheets, contact images, source pictures and generation
records are inputs and review evidence catalogued by the README or generation record in their own
`assets/illustrated/` folder, rather than alternate runtime bindings.

## Keeping the catalogue true

The [SVG art skill](../.claude/skills/svg-art/SKILL.md) describes authoring, rendering, visual
review and integration. Use it when creating or revising the SVG families catalogued here.

When adding a graphic, record its exact path, anchor and owning design here. Keep it **prepared**
until code, a scene or a resource actually binds it. When binding or removing one, search runtime
sources as well as `assets/ground_tileset.tres`, `scenes/` and `project.godot`; the TileSet and
application icon are deliberately indirect. For state, direction or animation families, keep a
glob only when it names every member of the family and no unrelated file.
