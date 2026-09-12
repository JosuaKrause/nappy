class_name EventInstance
extends Node2D
## One live event in the world: its lifetime, its telegraph phase, its excitement field and
## its drawing.
##
## The excitement model is entirely a *query* — `contribution_at()`. Nothing pushes a value
## at the baby, so there is no ordering to get wrong, events compose by simple addition, and
## the whole thing is testable without a scene.

const CAT_CROUCHED := preload("res://assets/events/cat_crouched.svg")
const CAT_RUNNING := preload("res://assets/events/cat_running.svg")
## The single east-facing picture, mirrored west — see `EventCatalogue._alley_mouse()` for why the
## prepared directional family (`mouse_{front,back}[_diagonal].svg`) stays unbound here.
const MOUSE := preload("res://assets/events/mouse.svg")
## The only generic here, and it is not a look: it is the *walker* half of a dog walker, which is a
## picture of somebody holding a lead rather than a picture of nobody in particular. Every row draws
## something of its own.
const PERSON := preload("res://assets/events/person.svg")
const YELLER := preload("res://assets/events/yeller.svg")
const BUSKER := preload("res://assets/events/busker.svg")
const POSTER_CREW := preload("res://assets/events/poster_crew.svg")
const ROBBER_WAITING := preload("res://assets/events/robber_waiting.svg")
const ROBBER_LUNGING := preload("res://assets/events/robber_lunging.svg")
const PROTESTER := preload("res://assets/events/protester.svg")
## The eight pointing poses, one per 45° bearing sector — see `_protester_texture()`. Ordered
## clockwise from north to match `TelemetryLog.compass()`'s own bearing convention.
const PROTESTER_POINT_N := preload("res://assets/events/protester_point_n.svg")
const PROTESTER_POINT_NE := preload("res://assets/events/protester_point_ne.svg")
const PROTESTER_POINT_E := preload("res://assets/events/protester_point_e.svg")
const PROTESTER_POINT_SE := preload("res://assets/events/protester_point_se.svg")
const PROTESTER_POINT_S := preload("res://assets/events/protester_point_s.svg")
const PROTESTER_POINT_SW := preload("res://assets/events/protester_point_sw.svg")
const PROTESTER_POINT_W := preload("res://assets/events/protester_point_w.svg")
const PROTESTER_POINT_NW := preload("res://assets/events/protester_point_nw.svg")
const GUNMAN := preload("res://assets/events/gunman.svg")
## The unsuffixed source is every family's own side view — see `docs/GRAPHICS.md`'s side-facing
## convention, `docs/evidence/svg-vehicles-2026-09-10/facings.csv`. The four-way suffixed sets below
## it are each family's front, back and two diagonals, bound through `_draw_eight_view()`; the old
## `_end.svg` single foreshortened picture each of these four rows drew for *both* north and south
## headings is superseded by the two-way `_front`/`_back` split and stays on disk unbound (see
## `docs/GRAPHICS.md`, the events table).
const DELIVERY_VAN := preload("res://assets/events/delivery_van.svg")
const DELIVERY_VAN_FRONT := preload("res://assets/events/delivery_van_front.svg")
const DELIVERY_VAN_BACK := preload("res://assets/events/delivery_van_back.svg")
const DELIVERY_VAN_FRONT_DIAGONAL := preload("res://assets/events/delivery_van_front_diagonal.svg")
const DELIVERY_VAN_BACK_DIAGONAL := preload("res://assets/events/delivery_van_back_diagonal.svg")
const FIRE_ENGINE := preload("res://assets/events/fire_engine.svg")
const FIRE_ENGINE_FRONT := preload("res://assets/events/fire_engine_front.svg")
const FIRE_ENGINE_BACK := preload("res://assets/events/fire_engine_back.svg")
const FIRE_ENGINE_FRONT_DIAGONAL := preload("res://assets/events/fire_engine_front_diagonal.svg")
const FIRE_ENGINE_BACK_DIAGONAL := preload("res://assets/events/fire_engine_back_diagonal.svg")
const POLICE_CAR := preload("res://assets/events/police_car.svg")
const POLICE_CAR_FRONT := preload("res://assets/events/police_car_front.svg")
const POLICE_CAR_BACK := preload("res://assets/events/police_car_back.svg")
const POLICE_CAR_FRONT_DIAGONAL := preload("res://assets/events/police_car_front_diagonal.svg")
const POLICE_CAR_BACK_DIAGONAL := preload("res://assets/events/police_car_back_diagonal.svg")
const UNMARKED_VAN := preload("res://assets/events/unmarked_van.svg")
const UNMARKED_VAN_FRONT := preload("res://assets/events/unmarked_van_front.svg")
const UNMARKED_VAN_BACK := preload("res://assets/events/unmarked_van_back.svg")
const UNMARKED_VAN_FRONT_DIAGONAL := preload("res://assets/events/unmarked_van_front_diagonal.svg")
const UNMARKED_VAN_BACK_DIAGONAL := preload("res://assets/events/unmarked_van_back_diagonal.svg")
const VAN_VICTIM := preload("res://assets/events/van_victim.svg")
## The night raid's van: `_draw_eight_view()` reads `RIOT_VAN_BY_VIEW` below through the same
## octant/mirror convention `EightDirection` gives every other family. Its side picture is
## authored facing west, the same as `unmarked_van` and `army_truck` below
## (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`), so it takes the same `side_faces_west`
## override those two do.
const RIOT_VAN := preload("res://assets/events/riot_van.svg")
const RIOT_VAN_FRONT := preload("res://assets/events/riot_van_front.svg")
const RIOT_VAN_BACK := preload("res://assets/events/riot_van_back.svg")
const RIOT_VAN_FRONT_DIAGONAL := preload("res://assets/events/riot_van_front_diagonal.svg")
const RIOT_VAN_BACK_DIAGONAL := preload("res://assets/events/riot_van_back_diagonal.svg")
const ARMY_TRUCK := preload("res://assets/events/army_truck.svg")
const ARMY_TRUCK_FRONT := preload("res://assets/events/army_truck_front.svg")
const ARMY_TRUCK_BACK := preload("res://assets/events/army_truck_back.svg")
const ARMY_TRUCK_FRONT_DIAGONAL := preload("res://assets/events/army_truck_front_diagonal.svg")
const ARMY_TRUCK_BACK_DIAGONAL := preload("res://assets/events/army_truck_back_diagonal.svg")
const FLAME := preload("res://assets/events/flame.svg")
const BARRIER_SEGMENT := preload("res://assets/events/barrier_segment.svg")
const BARRIER_END := preload("res://assets/events/barrier_end.svg")
const RUBBLE := preload("res://assets/events/rubble.svg")
const CHECKPOINT_BLOCK := preload("res://assets/events/checkpoint_block.svg")
const ROADBLOCK_SEGMENT := preload("res://assets/events/roadblock_segment.svg")
const ROADBLOCK_END := preload("res://assets/events/roadblock_end.svg")
## A hunting roadblock's own shadow once it draws as a guard rather than as the band: person-scale,
## matching `alley_robbery`'s own `GroundShape.point(9.0)` rather than `def.shape` — the band's 60px
## capsule, which is still what the collision body and the cold picture are built from.
const _GUARD_SHADOW_RADIUS := 9.0
const BARRICADE_PILE := preload("res://assets/events/barricade_pile.svg")
const CAFE_TABLE := preload("res://assets/events/cafe_table.svg")
const CAFE_SITTER := preload("res://assets/events/cafe_sitter.svg")
const DOG := preload("res://assets/events/dog.svg")
const CYCLIST := preload("res://assets/events/cyclist.svg")
const STALL := preload("res://assets/events/stall.svg")
const LEAF_BLOWER := preload("res://assets/events/leaf_blower.svg")
const PIGEON := preload("res://assets/events/pigeon.svg")
const PIGEON_DOWN := preload("res://assets/events/pigeon_down.svg")
const ICE_CREAM_VAN := preload("res://assets/events/ice_cream_van.svg")
const ICE_CREAM_VAN_FRONT := preload("res://assets/events/ice_cream_van_front.svg")
const ICE_CREAM_VAN_BACK := preload("res://assets/events/ice_cream_van_back.svg")
const ICE_CREAM_VAN_FRONT_DIAGONAL := preload(
		"res://assets/events/ice_cream_van_front_diagonal.svg")
const ICE_CREAM_VAN_BACK_DIAGONAL := preload(
		"res://assets/events/ice_cream_van_back_diagonal.svg")
const LORRY := preload("res://assets/events/lorry.svg")
const LORRY_FRONT := preload("res://assets/events/lorry_front.svg")
const LORRY_BACK := preload("res://assets/events/lorry_back.svg")
const LORRY_FRONT_DIAGONAL := preload("res://assets/events/lorry_front_diagonal.svg")
const LORRY_BACK_DIAGONAL := preload("res://assets/events/lorry_back_diagonal.svg")
const CHARGING_DOG := preload("res://assets/events/charging_dog.svg")
const CHATTING_MOTHER_WALKING := preload("res://assets/events/chatting_mother_walking.svg")
const CHATTING_MOTHER_TALKING := preload("res://assets/events/chatting_mother_talking.svg")
## Seal pictures — see `SealPlanner` and `docs/DECISIONS.md`, "Eight seal pictures".
const FALLEN_TREE := preload("res://assets/events/fallen_tree.svg")
const CAR_ACCIDENT := preload("res://assets/events/car_accident.svg")
const CAR_ACCIDENT_SHADOW := preload("res://assets/events/car_accident_shadow.svg")
const SKIP := preload("res://assets/events/skip.svg")
const SCAFFOLDING := preload("res://assets/events/scaffolding.svg")
const BURST_MAIN := preload("res://assets/events/burst_water_main.svg")
const MOVING_VAN := preload("res://assets/events/moving_van.svg")
const MOVING_VAN_VERTICAL := preload("res://assets/events/moving_van_vertical.svg")
const BURNT_OUT_CAR := preload("res://assets/events/burnt_out_car.svg")
const BURNT_OUT_CAR_VERTICAL := preload("res://assets/events/burnt_out_car_vertical.svg")
const COLLAPSED_FRONTAGE := preload("res://assets/events/collapsed_frontage.svg")
## Directional siblings for the three whole-street scenes. Vehicles and upright props are authored
## in the street's projection rather than rotating every pixel of the horizontal composition.
const FALLEN_TREE_VERTICAL := preload("res://assets/events/fallen_tree_vertical.svg")
const CAR_ACCIDENT_VERTICAL := preload("res://assets/events/car_accident_vertical.svg")
const CAR_ACCIDENT_VERTICAL_SHADOW := preload(
		"res://assets/events/car_accident_vertical_shadow.svg")
const BURST_MAIN_VERTICAL := preload("res://assets/events/burst_water_main_vertical.svg")

# ---------------------------------------------------------- eight-view families ---
# Every family below shares the crowd walker's own convention (`docs/GRAPHICS.md`, "the crowd
# walkers"; `CrowdAgent.WALKER_VIEW_BY_SECTOR`): N back, NE/NW back_diagonal, E/W side, SE/SW
# front_diagonal, S front, the three west sectors mirroring their east-authored partner about the
# feet anchor (`EightDirection.is_mirrored()`). `EIGHT_VIEW_BY_SECTOR` is that same table, copied
# rather than shared — an event and a walker have no common base to hang one array on — and
# `_select_view()` below is `CrowdAgent._update_walker_view()`'s own shape applied generally: one
# held sector per instance, since only one `Look` is ever live on a given instance.
const EIGHT_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]

const PERSON_BY_VIEW := {
	"front": preload("res://assets/events/person_front.svg"),
	"back": preload("res://assets/events/person_back.svg"),
	"side": preload("res://assets/events/person_side.svg"),
	"front_diagonal": preload("res://assets/events/person_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/person_back_diagonal.svg"),
}
const YELLER_BY_VIEW := {
	"front": preload("res://assets/events/yeller_front.svg"),
	"back": preload("res://assets/events/yeller_back.svg"),
	"side": preload("res://assets/events/yeller_side.svg"),
	"front_diagonal": preload("res://assets/events/yeller_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/yeller_back_diagonal.svg"),
}
const BUSKER_BY_VIEW := {
	"front": preload("res://assets/events/busker_front.svg"),
	"back": preload("res://assets/events/busker_back.svg"),
	"side": preload("res://assets/events/busker_side.svg"),
	"front_diagonal": preload("res://assets/events/busker_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/busker_back_diagonal.svg"),
}
const POSTER_CREW_BY_VIEW := {
	"front": preload("res://assets/events/poster_crew_front.svg"),
	"back": preload("res://assets/events/poster_crew_back.svg"),
	"side": preload("res://assets/events/poster_crew_side.svg"),
	"front_diagonal": preload("res://assets/events/poster_crew_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/poster_crew_back_diagonal.svg"),
}
const CAFE_SITTER_BY_VIEW := {
	"front": preload("res://assets/events/cafe_sitter_front.svg"),
	"back": preload("res://assets/events/cafe_sitter_back.svg"),
	"side": preload("res://assets/events/cafe_sitter_side.svg"),
	"front_diagonal": preload("res://assets/events/cafe_sitter_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/cafe_sitter_back_diagonal.svg"),
}
const VAN_VICTIM_BY_VIEW := {
	"front": preload("res://assets/events/van_victim_front.svg"),
	"back": preload("res://assets/events/van_victim_back.svg"),
	"side": preload("res://assets/events/van_victim_side.svg"),
	"front_diagonal": preload("res://assets/events/van_victim_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/van_victim_back_diagonal.svg"),
}
const PROTESTER_BY_VIEW := {
	"front": preload("res://assets/events/protester_front.svg"),
	"back": preload("res://assets/events/protester_back.svg"),
	"side": preload("res://assets/events/protester_side.svg"),
	"front_diagonal": preload("res://assets/events/protester_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/protester_back_diagonal.svg"),
}
const LEAF_BLOWER_BY_VIEW := {
	"front": preload("res://assets/events/leaf_blower_front.svg"),
	"back": preload("res://assets/events/leaf_blower_back.svg"),
	"side": preload("res://assets/events/leaf_blower_side.svg"),
	"front_diagonal": preload("res://assets/events/leaf_blower_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/leaf_blower_back_diagonal.svg"),
}
const ROBBER_WAITING_BY_VIEW := {
	"front": preload("res://assets/events/robber_waiting_front.svg"),
	"back": preload("res://assets/events/robber_waiting_back.svg"),
	"side": preload("res://assets/events/robber_waiting_side.svg"),
	"front_diagonal": preload("res://assets/events/robber_waiting_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/robber_waiting_back_diagonal.svg"),
}
const ROBBER_LUNGING_BY_VIEW := {
	"front": preload("res://assets/events/robber_lunging_front.svg"),
	"back": preload("res://assets/events/robber_lunging_back.svg"),
	"side": preload("res://assets/events/robber_lunging_side.svg"),
	"front_diagonal": preload("res://assets/events/robber_lunging_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/robber_lunging_back_diagonal.svg"),
}
const CHATTING_MOTHER_WALKING_BY_VIEW := {
	"front": preload("res://assets/events/chatting_mother_walking_front.svg"),
	"back": preload("res://assets/events/chatting_mother_walking_back.svg"),
	"side": preload("res://assets/events/chatting_mother_walking_side.svg"),
	"front_diagonal": preload("res://assets/events/chatting_mother_walking_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/chatting_mother_walking_back_diagonal.svg"),
}
const CHATTING_MOTHER_TALKING_BY_VIEW := {
	"front": preload("res://assets/events/chatting_mother_talking_front.svg"),
	"back": preload("res://assets/events/chatting_mother_talking_back.svg"),
	"side": preload("res://assets/events/chatting_mother_talking_side.svg"),
	"front_diagonal": preload("res://assets/events/chatting_mother_talking_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/chatting_mother_talking_back_diagonal.svg"),
}

## The animal/rider families below reuse the existing unsuffixed constant as `"side"` rather than
## preloading a second copy of the same picture: `docs/evidence/svg-vehicles-2026-09-10/
## facings.csv` marks every one of them "existing canonical source" rather than a new drawing, and
## `docs/GRAPHICS.md` says to replace a preload only where the suffixed source is a different
## picture from the one already live. `mouse` is the one family in this evidence set left out —
## `EventCatalogue._alley_mouse()`'s own docstring documents, with its own reasoning, that the row
## stays on `_draw_simple(MOUSE, ...)` rather than joining this table.
const CAT_CROUCHED_BY_VIEW := {
	"front": preload("res://assets/events/cat_crouched_front.svg"),
	"back": preload("res://assets/events/cat_crouched_back.svg"),
	"side": CAT_CROUCHED,
	"front_diagonal": preload("res://assets/events/cat_crouched_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/cat_crouched_back_diagonal.svg"),
}
const CAT_RUNNING_BY_VIEW := {
	"front": preload("res://assets/events/cat_running_front.svg"),
	"back": preload("res://assets/events/cat_running_back.svg"),
	"side": CAT_RUNNING,
	"front_diagonal": preload("res://assets/events/cat_running_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/cat_running_back_diagonal.svg"),
}
const DOG_BY_VIEW := {
	"front": preload("res://assets/events/dog_front.svg"),
	"back": preload("res://assets/events/dog_back.svg"),
	"side": DOG,
	"front_diagonal": preload("res://assets/events/dog_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/dog_back_diagonal.svg"),
}
const CHARGING_DOG_BY_VIEW := {
	"front": preload("res://assets/events/charging_dog_front.svg"),
	"back": preload("res://assets/events/charging_dog_back.svg"),
	"side": CHARGING_DOG,
	"front_diagonal": preload("res://assets/events/charging_dog_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/charging_dog_back_diagonal.svg"),
}
const CYCLIST_BY_VIEW := {
	"front": preload("res://assets/events/cyclist_front.svg"),
	"back": preload("res://assets/events/cyclist_back.svg"),
	"side": CYCLIST,
	"front_diagonal": preload("res://assets/events/cyclist_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/cyclist_back_diagonal.svg"),
}
const PIGEON_BY_VIEW := {
	"front": preload("res://assets/events/pigeon_front.svg"),
	"back": preload("res://assets/events/pigeon_back.svg"),
	"side": PIGEON,
	"front_diagonal": preload("res://assets/events/pigeon_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/pigeon_back_diagonal.svg"),
}
const PIGEON_DOWN_BY_VIEW := {
	"front": preload("res://assets/events/pigeon_down_front.svg"),
	"back": preload("res://assets/events/pigeon_down_back.svg"),
	"side": PIGEON_DOWN,
	"front_diagonal": preload("res://assets/events/pigeon_down_front_diagonal.svg"),
	"back_diagonal": preload("res://assets/events/pigeon_down_back_diagonal.svg"),
}
## The vehicle-scale families below share the same five-view shape as every family above, but not
## all of them share its mirror convention: `docs/evidence/svg-vehicles-2026-09-10/README.md` — "the
## existing delivery van, fire engine, unmarked van, riot van, army truck and moving van side
## pictures visibly place the cab at the left" — so their single `"side"` picture is authored facing
## **west**, backwards from every side picture above. `_draw_eight_view()`'s own `side_faces_west`
## parameter is the one bit that reads, per family, from `facings.csv`'s `mirror_x` column rather
## than being assumed; every front, back and diagonal view is unaffected; each is its own picture
## for its own compass point regardless of which way the side view faces.
const DELIVERY_VAN_BY_VIEW := {
	"front": DELIVERY_VAN_FRONT,
	"back": DELIVERY_VAN_BACK,
	"side": DELIVERY_VAN,
	"front_diagonal": DELIVERY_VAN_FRONT_DIAGONAL,
	"back_diagonal": DELIVERY_VAN_BACK_DIAGONAL,
}
const FIRE_ENGINE_BY_VIEW := {
	"front": FIRE_ENGINE_FRONT,
	"back": FIRE_ENGINE_BACK,
	"side": FIRE_ENGINE,
	"front_diagonal": FIRE_ENGINE_FRONT_DIAGONAL,
	"back_diagonal": FIRE_ENGINE_BACK_DIAGONAL,
}
## East-authored, like `CYCLIST_BY_VIEW` above — no `side_faces_west` override at the call site.
const ICE_CREAM_VAN_BY_VIEW := {
	"front": ICE_CREAM_VAN_FRONT,
	"back": ICE_CREAM_VAN_BACK,
	"side": ICE_CREAM_VAN,
	"front_diagonal": ICE_CREAM_VAN_FRONT_DIAGONAL,
	"back_diagonal": ICE_CREAM_VAN_BACK_DIAGONAL,
}
## East-authored — see `ICE_CREAM_VAN_BY_VIEW` above.
const LORRY_BY_VIEW := {
	"front": LORRY_FRONT,
	"back": LORRY_BACK,
	"side": LORRY,
	"front_diagonal": LORRY_FRONT_DIAGONAL,
	"back_diagonal": LORRY_BACK_DIAGONAL,
}
const UNMARKED_VAN_BY_VIEW := {
	"front": UNMARKED_VAN_FRONT,
	"back": UNMARKED_VAN_BACK,
	"side": UNMARKED_VAN,
	"front_diagonal": UNMARKED_VAN_FRONT_DIAGONAL,
	"back_diagonal": UNMARKED_VAN_BACK_DIAGONAL,
}
const ARMY_TRUCK_BY_VIEW := {
	"front": ARMY_TRUCK_FRONT,
	"back": ARMY_TRUCK_BACK,
	"side": ARMY_TRUCK,
	"front_diagonal": ARMY_TRUCK_FRONT_DIAGONAL,
	"back_diagonal": ARMY_TRUCK_BACK_DIAGONAL,
}
## East-authored — see `ICE_CREAM_VAN_BY_VIEW` above.
const POLICE_CAR_BY_VIEW := {
	"front": POLICE_CAR_FRONT,
	"back": POLICE_CAR_BACK,
	"side": POLICE_CAR,
	"front_diagonal": POLICE_CAR_FRONT_DIAGONAL,
	"back_diagonal": POLICE_CAR_BACK_DIAGONAL,
}
## `_draw_eight_view(RIOT_VAN_BY_VIEW, _heading, canvas, true)` — west-authored like
## `UNMARKED_VAN_BY_VIEW` and `ARMY_TRUCK_BY_VIEW` above, see that pair's own doc comment — so the
## side view mirrors on **east** to match `facings.csv`'s recorded `mirror_x`, corrected from M56's
## own hand-written octant match, which had it backwards.
const RIOT_VAN_BY_VIEW := {
	"front": RIOT_VAN_FRONT,
	"back": RIOT_VAN_BACK,
	"side": RIOT_VAN,
	"front_diagonal": RIOT_VAN_FRONT_DIAGONAL,
	"back_diagonal": RIOT_VAN_BACK_DIAGONAL,
}

## The region door's own kit — see `RegionPlanner` and `docs/CITY.md`, "Regions and the wall".
const HUT_NORTH := preload("res://assets/checkpoints/hut_north.svg")
const HUT_SOUTH := preload("res://assets/checkpoints/hut_south.svg")
const HUT_EAST := preload("res://assets/checkpoints/hut_east.svg")
const HUT_WEST := preload("res://assets/checkpoints/hut_west.svg")
const GUARD_STANDING := preload("res://assets/checkpoints/guard_standing.svg")
const GUARD_LUNGING := preload("res://assets/checkpoints/guard_lunging.svg")
const BOOM_GATE_NS_LOWERED := preload("res://assets/checkpoints/boom_gate_ns_lowered.svg")
const BOOM_GATE_NS_RAISED := preload("res://assets/checkpoints/boom_gate_ns_raised.svg")
const BOOM_GATE_EW_LOWERED := preload("res://assets/checkpoints/boom_gate_ew_lowered.svg")
const BOOM_GATE_EW_RAISED := preload("res://assets/checkpoints/boom_gate_ew_raised.svg")
## Each asset's own documented ground anchor, read out of the SVG's own comment rather than
## assumed — neither is `Sprites.draw_standing`'s bottom-centre: the hut's doorway sits a few
## pixels short of the canvas's own bottom edge. See `_draw_at_anchor`.
const _HUT_ANCHOR := Vector2(28.0, 52.0)
const _GUARD_ANCHOR := Vector2(11.0, 44.0)

## A boom's two posts, as the ground point each of them stands on in its own canvas — the near
## post is the `ground anchor` the SVG documents, the far one is the receiving post at the other
## end of the arm, read off the same post box and base plate the near one is read off. Both states
## of each boom put its posts in exactly these places, which is what keeps a raised bar registered
## with the lowered one it replaces.
const _BOOM_NS_NEAR_POST := Vector2(84.0, 59.0)
const _BOOM_NS_FAR_POST := Vector2(5.0, 55.0)
const _BOOM_EW_NEAR_POST := Vector2(21.0, 88.0)
const _BOOM_EW_FAR_POST := Vector2(18.5, 12.0)
## **A boom hangs from its body's ground point midway between its two posts, not from one of
## them.** A gate is sited on the middle of the carriageway — `RegionPlanner._add_door_bodies`
## puts it on the road's own centre line between the two huts — and a picture hung by the near
## post alone puts its whole arm to one side of that point: on the kerb, with the lanes it exists
## to bar left open underneath it. Anchored between the posts, each post lands just outside a kerb
## and the arm crosses the lanes, which is the shape the picture was drawn as.
const _BOOM_NS_ANCHOR := (_BOOM_NS_NEAR_POST + _BOOM_NS_FAR_POST) * 0.5
const _BOOM_EW_ANCHOR := (_BOOM_EW_NEAR_POST + _BOOM_EW_FAR_POST) * 0.5
## The lowered arm's own extent inside each canvas — the striped bar itself, not the posts or the
## sockets. Only `boom_arm_span()` reads them: where the bar lands across the road is the thing a
## test can check and `_draw()` cannot.
const _BOOM_NS_ARM := Rect2(4.0, 43.0, 79.0, 7.0)
const _BOOM_EW_ARM := Rect2(15.0, 7.0, 9.0, 76.0)

## The one silhouette that stands for a look, at any size.
##
## It lives here rather than in `DangerEdge` for the same reason the caret lives in `Sprites`: a
## cue that belongs to the vocabulary does not belong to a class, and the screen-edge badge's whole
## job is to draw *the thing's own picture* — a second table of which picture that is, kept in the
## UI, is how a badge ends up showing a generic van for a fire engine. `tests/test_events.gd`
## asserts every visible row has one and that no two looks return the same texture, which is the
## half of the one-picture-per-row rule that a `look` field cannot enforce by itself.
static func icon_for(look: EventDef.Look) -> Texture2D:
	match look:
		EventDef.Look.CAT: return CAT_RUNNING
		EventDef.Look.MOUSE: return MOUSE
		EventDef.Look.YELLER: return YELLER
		EventDef.Look.DOG_WALKER: return PERSON
		EventDef.Look.CAFE: return CAFE_TABLE
		EventDef.Look.DELIVERY_VAN: return DELIVERY_VAN
		EventDef.Look.BUSKER: return BUSKER
		EventDef.Look.ROADWORKS: return BARRIER_SEGMENT
		EventDef.Look.FIRE_ENGINE: return FIRE_ENGINE
		EventDef.Look.BURNING_BUILDING: return FLAME
		EventDef.Look.BURNT_SHELL: return RUBBLE
		EventDef.Look.LOOSE_DOG: return DOG
		EventDef.Look.STALL: return STALL
		EventDef.Look.LEAF_BLOWER: return LEAF_BLOWER
		EventDef.Look.BIRDS: return PIGEON
		EventDef.Look.CYCLIST: return CYCLIST
		EventDef.Look.ICE_CREAM_VAN: return ICE_CREAM_VAN
		EventDef.Look.LORRY: return LORRY
		EventDef.Look.CHARGING_DOG: return CHARGING_DOG
		EventDef.Look.CHATTING_MOTHER: return CHATTING_MOTHER_WALKING
		EventDef.Look.POLICE_CAR: return POLICE_CAR
		EventDef.Look.POSTER_CREW: return POSTER_CREW
		EventDef.Look.ROADBLOCK: return CHECKPOINT_BLOCK
		EventDef.Look.UNMARKED_VAN: return UNMARKED_VAN
		EventDef.Look.ROBBER: return ROBBER_LUNGING
		EventDef.Look.RIOT_VAN: return RIOT_VAN
		EventDef.Look.ARMY_TRUCK: return ARMY_TRUCK
		EventDef.Look.BARRICADE: return BARRICADE_PILE
		EventDef.Look.PROTEST: return PROTESTER
		EventDef.Look.FIREFIGHT: return GUNMAN
		EventDef.Look.FALLEN_TREE: return FALLEN_TREE
		EventDef.Look.CAR_ACCIDENT: return CAR_ACCIDENT
		EventDef.Look.SKIP: return SKIP
		EventDef.Look.SCAFFOLDING: return SCAFFOLDING
		EventDef.Look.BURST_MAIN: return BURST_MAIN
		EventDef.Look.MOVING_VAN: return MOVING_VAN
		EventDef.Look.BURNT_OUT_CAR: return BURNT_OUT_CAR
		EventDef.Look.COLLAPSED_FRONTAGE: return COLLAPSED_FRONTAGE
		EventDef.Look.CHECKPOINT_HUT: return HUT_SOUTH
		EventDef.Look.CHECKPOINT_GATE: return BOOM_GATE_NS_LOWERED
		EventDef.Look.CHECKPOINT_POST: return GUARD_STANDING
		_: return null

## Whether a def's instance draws itself as a **spread** — segments or a whole scene fitted
## across `def.obstructs_radius`, laid along whichever axis `_spread_is_vertical` picks for the
## street it stands on. That is `_draw_spread`, `_draw_cafe` or `_draw_wide_scene`, nothing else in
## `_draw_body`'s dispatch: `ROADWORKS`, `BURNT_SHELL`, `STALL`, `ROADBLOCK`, `BARRICADE`,
## `SCAFFOLDING` and `COLLAPSED_FRONTAGE` go to the first, `CAFE` to the second. The three seal
## pictures wide enough to span the whole street (`FALLEN_TREE`, `CAR_ACCIDENT`, `BURST_MAIN`) use
## `_draw_wide_scene`, which fits one scene to the obstruction and anchors vertical scenes at the
## far end so their centre sits on the ground point. Each has an authored east-west asset selected
## by `_wide_scene_texture`.
## `PROTEST` and `FIREFIGHT` also fill
## `obstructs_radius`-worth of ground but draw it with their own functions that never call
## `_spread_is_vertical` or `_spread_at` — a protest rank and a firefight's cover are laid along
## local X unconditionally, so a corner costs them nothing and they are rightly outside this test.
##
## **This is the test `EventScheduler._open_ground_for` asks before it will offer a corner as a
## site.** See that function and `docs/DECISIONS.md`, "a spread on a corner is placed as if the
## corner were nothing" — a junction has no single street for `_spread_is_vertical` or
## `_centred_on_the_pavement_band` to answer about, so only a row that actually asks either
## question has anything to lose by standing on one.
static func has_a_spread(def: EventDef) -> bool:
	match def.look:
		EventDef.Look.ROADWORKS, EventDef.Look.BURNT_SHELL, EventDef.Look.STALL, \
				EventDef.Look.ROADBLOCK, EventDef.Look.BARRICADE, EventDef.Look.CAFE, \
				EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN, \
				EventDef.Look.SCAFFOLDING, EventDef.Look.COLLAPSED_FRONTAGE:
			return true
		_:
			return false

## Which texture a "whole scene" seal picture (`FALLEN_TREE`, `CAR_ACCIDENT`, `BURST_MAIN`) draws,
## given whether the street it stands on rotates the spread onto local Y (`_spread_vertical`).
##
## **A separate directional asset, not a runtime rotation of the one texture.**
## The spread axis remap only relabels which texture dimension is "along" the obstruction; it never
## turns pixels. `_wide_scene_texture` therefore supplies an authored composition for each street
## axis, so cars keep the right projection and people and barriers remain upright. Repeatable
## segments are close enough to square for the dimension swap itself. `EventDef.look` and
## `_spread_vertical` together pick the texture, with no field on the def.
static func _wide_scene_texture(look: EventDef.Look, vertical: bool) -> Texture2D:
	match look:
		EventDef.Look.FALLEN_TREE: return FALLEN_TREE_VERTICAL if vertical else FALLEN_TREE
		EventDef.Look.CAR_ACCIDENT: return CAR_ACCIDENT_VERTICAL if vertical else CAR_ACCIDENT
		EventDef.Look.BURST_MAIN: return BURST_MAIN_VERTICAL if vertical else BURST_MAIN
		_: return null

## A crash scene has several separate contacts with the ground, so it carries a matching shadow
## picture rather than painting one ellipse across the entire closed street.
static func _wide_scene_shadow(texture: Texture2D) -> Texture2D:
	if texture == CAR_ACCIDENT:
		return CAR_ACCIDENT_SHADOW
	if texture == CAR_ACCIDENT_VERTICAL:
		return CAR_ACCIDENT_VERTICAL_SHADOW
	return null

## The selected picture for a stationary vehicle. The row keeps one look because both files
## depict the same vehicle rather than two catalogue entries.
static func _stationary_vehicle_texture(look: EventDef.Look, side_view: bool) -> Texture2D:
	match look:
		EventDef.Look.MOVING_VAN:
			return MOVING_VAN if side_view else MOVING_VAN_VERTICAL
		EventDef.Look.BURNT_OUT_CAR:
			return BURNT_OUT_CAR if side_view else BURNT_OUT_CAR_VERTICAL
		_:
			return null

## Preserves the authored end-on projection instead of stretching it to the circular collision
## diameter. Side views are fitted to that diameter because their long silhouette is the width the
## solid row claims on the axis where that picture is used.
static func _stationary_vehicle_extent(texture: Texture2D, side_view: bool,
		side_width: float) -> Vector2:
	var size := texture.get_size()
	if not side_view:
		return size
	return Vector2(side_width, size.y * side_width / size.x)

var def: EventDef
## Waypoints for a mobile event, in world space. Empty for a stationary one.
var path: PackedVector2Array = PackedVector2Array()

var age := 0.0
var is_finished := false

## Where the player is, in world space, or `INF` for nowhere.
##
## Written once per frame by `EventManager`, which is the one place that already knows. An instance
## looking her up itself would be thirty lookups a frame for one answer, and — more to the point —
## `EventInstance` has never had to know the player exists, and this keeps that true: it is handed
## a point, and everything it does with the point is a distance.
##
## Two things want it, and neither is a reference to her: a pursuer walks toward it, and anything
## that is *leaving* uses it to know when it is out of sight. `ExcitementHalo` writes the same
## value again every frame through `set_player_at()`, part of the duck type it reads back for the
## caret — the two writers agree because both read `_player.global_position` the same frame.
var player_at := Vector2.INF

## Part of `ExcitementHalo`'s duck type — see that class's doc. `EventManager` already keeps
## `player_at` current for the chase and the leaving check; this is the same field, told from the
## other direction so `expected_impact_at()` does not need a second channel to the player.
func set_player_at(at: Vector2) -> void:
	player_at = at

## Whether she is running right now. Written beside `player_at` and by the same pass, because the
## one thing that reads it asks both together: a pursuer gives up because **she ran**, which is a
## fact about her and not about the gap. See `_chase`.
var player_running := false

## Whether the baby is awake right now. Written once a frame by `EventManager` alongside
## `player_at`, and read by exactly one row: `chatting_mother`'s conversation is the only thing in
## the catalogue whose contribution differs by the baby's own state, and this is how it can without
## ever writing to `Baby.excitement` — the read happens here, in `current_intensity()`, so
## excitement stays a pure query. `true` with nobody to ask, which is the harmless default a
## data-level test gets.
var baby_awake := true

## The shared boom state a `checkpoint_gate` draws raised or lowered from — `RegionPlanner.
## GateState`, set by `EventManager._stream_in` from `Planned.gate_state`. `null` for every look
## but `CHECKPOINT_GATE`, and read as lowered while it is: a gate that has not been wired to
## `Crowd` yet (or a data-level rig with no crowd at all) draws exactly the safe default.
var gate_state: RegionPlanner.GateState = null

## Facing, for art with a front and a back. Only a mobile event ever changes it.
var _heading := Vector2.RIGHT

## The eight-view sector this instance is currently drawn in, for whichever family reads
## `EIGHT_VIEW_BY_SECTOR` instead of a single side-mirrored picture — see `_select_view()`. Reset
## in `setup()` to the exact nearest sector for the instance's own siting, the same "no prior-view
## hold on a fresh placement" rule `EightDirection.nearest()`'s own doc names.
var _view_sector := 2
var _path_travelled := 0.0
var _telegraph_announced := false
var _activation_announced := false

## The city, for the one question a chase needs answered that nothing here ever asked before:
## whether the ground a step would land on is somewhere anybody can stand. `null` in every
## data-level test that builds an instance without one — a rig that walks a straight line on
## purpose gets exactly the unclamped movement it always has — and always set by
## `EventManager._create`, the only real caller. See `_walkable_step`.
var _map: CityMap

## The solid body `_build_obstruction()` made, or `null` before it exists and after
## `_process()` has dropped it. See `is_solid()`.
var _obstruction: StaticBody2D

## The child that re-draws this event's own body in a ring of offsets — see `EntityHalo`, the
## class shared with `CrowdAgent` that owns the ring, the shared shader material and the drawing.
## Built in `_ready()`, same as `_obstruction`, so it is never `null` once the instance is live.
var _halo: EntityHalo

## `[when, points]` entries landed on her from this event, `when` stamped from `_clock` in
## seconds, for whatever is still inside `ExcitementHalo.WINDOW` — a true sliding sum rather than
## a decayed average, so a burst reads as itself for the whole window and then drops. Lazily
## grown: an event that has never landed anything keeps this empty. Duck-typed with `CrowdAgent`'s
## own copy — see `ExcitementHalo`'s class doc for the whole shape. See `accumulate_landed()` and
## `landed()`.
var _landed_history: Array = []

## This event's own simulation clock, in seconds, advanced by `delta` in `_process()` while the
## event is still live. `landed()` is measured against this rather than `Time.get_ticks_msec()` so
## that a paused game does not empty the halo, and so a rig can measure the window on simulated
## time by advancing this directly instead of waiting on the wall clock. Frozen once `is_finished`
## — see `_process()` — so a spent instance's history simply stops moving rather than continuing
## to drain toward zero after nothing more can land on it.
var _clock := 0.0

## Whether `_draw_spread` and `_draw_cafe` lay their segments along local Y rather than local X.
## Decided once, in `setup()`, from the street the instance stands on — see `_spread_is_vertical`.
## Never a per-row field: two rows on the same street face the same way for the same reason, and a
## row that had to say so itself could disagree with the street it was actually placed on.
var _spread_vertical := false
## Whether a stationary vehicle shows its side. The moving van sits along the street while the
## burnt car lies across it; a junction, off-street ground or data-level rig follows its facing.
var _stationary_vehicle_side := true

## `face` is where a *stationary* event was sited looking. A mobile one overwrites it from the
## direction it is travelling on its first step, which is why the default is harmless.
func setup(definition: EventDef, at: Vector2, route: PackedVector2Array = PackedVector2Array(),
		face := Vector2.RIGHT, map: CityMap = null) -> void:
	def = definition
	path = route
	var start := route[0] if route.size() > 0 else at
	if map and not definition.mobile and definition.obstructs_radius > 0.0 \
			and definition.pavement_side == EventDef.Pavement.ANY:
		start = _centred_on_the_pavement_band(map, start)
	position = start
	_heading = face
	_view_sector = EightDirection.nearest(face)
	_map = map
	_spread_vertical = _spread_is_vertical(map, position)
	_stationary_vehicle_side = _stationary_vehicle_uses_side(definition.look, map, position, face)
	if definition.look == EventDef.Look.MOUSE:
		# `alley_mouse` is `MAP`-placed rather than director-sited, so it arrives here with no
		# route at all (`EventScheduler._build_placement`'s default case) — this is the one place
		# its own dash gets built, from the alley it actually landed in rather than a flat offset.
		path = _alley_crossing_path(map, position)

## **A pavement is one piece of walkable ground, not two lanes a body has to fit inside one of.**
## `EventScheduler` places a stationary body at `map.tile_to_world(tile)` — the centre of whichever
## of the pavement's two lanes the scheduler happened to choose, 16px from that lane's own edge and
## 48px from the far one — so a body sized against the *pavement* rather than the *lane* overhangs
## by exactly the asymmetry between those two numbers. Playtest 19's own words are about the offset,
## not the width: *"they're all placed with an offset that makes them clip into other things."*
##
## The fix is the position, not a smaller radius: this shifts a stationary, unpinned body from the
## lane tile the scheduler chose to the middle of the two-lane band it belongs to, so a body may be
## up to the full `SIDEWALK_WIDTH * TILE_SIZE` (64px) wide and exactly fill the pavement, the way
## `construction`'s own docstring always said it did.
##
## **Exempt: anything `pavement_side` pins to an edge on purpose.** `delivery_van` belongs at the
## kerb and `reversing_lorry` belongs against the building — re-centring either would undo the one
## thing `pavement_side` exists to do. Both stay exactly where `EventScheduler._build_placement`
## put them, still measured against the same 64px band: a kerbed `VEHICLE_BODY` (44px) leaves a
## 26px gap to the frontage, narrower than the 28px pram, which is `docs/HANDOFF.md`'s own reading
## of that placement — a van at the kerb is *also* "no line to walk," on purpose.
static func _centred_on_the_pavement_band(map: CityMap, at: Vector2) -> Vector2:
	var tile := map.world_to_tile(at)
	if map.pavement_inward(tile) == Vector2i.ZERO:
		# Not a pavement tile at all, or a junction belonging to both corridors at once — nothing
		# here has one band to be centred on.
		return at
	var x_offset := CityMap.corridor_offset(tile.x)
	var offset := x_offset if x_offset >= 0 else CityMap.corridor_offset(tile.y)
	var band_offset := Tuning.SIDEWALK_WIDTH * 0.5 if offset < Tuning.SIDEWALK_WIDTH \
			else float(Tuning.STREET_WIDTH) - Tuning.SIDEWALK_WIDTH * 0.5
	var shift := (band_offset - offset - 0.5) * Tuning.TILE_SIZE
	return at + (Vector2.RIGHT if x_offset >= 0 else Vector2.DOWN) * shift

## **A spread's rotation is a property of the street it stands on**, not a field on the row: a
## barrier that lies correctly across a north-south street lies along the kerb — parallel to the
## traffic, blocking nothing — on an east-west one, unless the direction it spreads in changes with
## the street. `CityMap.corridor_offset` answers which axis a tile's corridor runs on without
## caring what the tile's *type* is, so a `ROAD` tile (`checkpoint`, the barricade a stopped convoy
## leaves) is asked exactly the way a `SIDEWALK` tile is, with no second lookup for either.
##
## A tile whose two coordinates are **both** inside a corridor band is a junction — belonging to
## two streets at once, with no single direction to be wrong about — and a tile whose coordinates
## are **neither** is off any corridor at all: a square, a park, a courtyard. Both keep the spread's
## long-standing lay along local X, which is what every row drew before this rule existed and is the
## smallest answer for ground that was never a street to lie across in the first place.
static func _spread_is_vertical(map: CityMap, at: Vector2) -> bool:
	if not map:
		return false
	var tile := map.world_to_tile(at)
	var on_a_north_south_street := CityMap.corridor_offset(tile.x) >= 0
	var on_an_east_west_street := CityMap.corridor_offset(tile.y) >= 0
	return on_an_east_west_street and not on_a_north_south_street

## The `Rect2i` (from `CityMap.alley_rects`) that `at` falls inside, in **world** space, or an
## empty `Rect2` when it is not inside any of them — a data-level rig with no map, or a placement
## that has fallen off the lattice. `corridor_offset` cannot answer this the way `_spread_is_vertical`
## does above: an alley is cut into the middle of a block rather than laid on the periodic street
## pattern that function reads, so its own tiles are never on a corridor at all.
static func _alley_rect_at(map: CityMap, at: Vector2) -> Rect2:
	if not map:
		return Rect2()
	var tile := map.world_to_tile(at)
	for rect in map.alley_rects:
		if rect.has_point(tile):
			return map.tile_rect_to_world(rect)
	return Rect2()

## A two-point dash across the **short** side of the alley `at` sits in, for `alley_mouse` — see
## `EventCatalogue._alley_mouse()`. `_alley_rect_at` gives the alley's own rect rather than a
## direction guessed from the street lattice, so the choice of axis is exact: `ALLEY_WIDTH_TILES`
## (2) is always the narrower side of a real alley, and she can only be walking the longer one, so
## crossing the narrower side is crossing her path by construction rather than by luck.
##
## Falls back to a short fixed dash along local X when there is no rect to ask — `_alley_rect_at`
## returning empty — which `validate()` and a real `MAP` placement never let happen; this is only
## for a data-level rig that calls `setup()` with no map at all.
static func _alley_crossing_path(map: CityMap, at: Vector2) -> PackedVector2Array:
	var rect := _alley_rect_at(map, at)
	if rect.size == Vector2.ZERO:
		return PackedVector2Array([at - Vector2(32.0, 0.0), at + Vector2(32.0, 0.0)])
	if rect.size.y > rect.size.x:
		# Narrower in X: a vertical alley, walked along Y, crossed along X.
		return PackedVector2Array([Vector2(rect.position.x, at.y),
				Vector2(rect.position.x + rect.size.x, at.y)])
	# Narrower in Y, or square (never happens at `ALLEY_WIDTH_TILES` 2 against a block-length
	# alley, but ties go the same way `_spread_is_vertical` ties do): a horizontal alley, walked
	# along X, crossed along Y.
	return PackedVector2Array([Vector2(at.x, rect.position.y),
			Vector2(at.x, rect.position.y + rect.size.y)])

## Whether a stationary vehicle is seen side-on at this point. The moving van faces along the
## street and the burnt car lies perpendicular to it. A junction or ground outside the lattice has
## no single street axis, so the vehicle's own facing supplies the coherent default.
static func _stationary_vehicle_uses_side(look: EventDef.Look, map: CityMap, at: Vector2,
		face: Vector2) -> bool:
	if not map:
		return absf(face.x) >= absf(face.y)
	var tile := map.world_to_tile(at)
	var on_a_north_south_street := CityMap.corridor_offset(tile.x) >= 0
	var on_an_east_west_street := CityMap.corridor_offset(tile.y) >= 0
	if on_a_north_south_street != on_an_east_west_street:
		var parallel_side := on_an_east_west_street
		return not parallel_side if look == EventDef.Look.BURNT_OUT_CAR else parallel_side
	return absf(face.x) >= absf(face.y)

func _ready() -> void:
	EventBus.event_telegraphed.emit(self)
	_telegraph_announced = true
	if def.obstructs_radius > 0.0:
		_build_obstruction()
	if def.flock_size > 0:
		_build_the_flock()
	_build_halo()

## Some events are physically in the way. The body is a child so it travels with a mobile
## event and disappears with the instance.
##
## Built from `def.parts()` — one `CollisionShape2D` per piece, a `CircleShape2D` for a point and a
## `CapsuleShape2D` for a segment — so the collision resources agree with whatever `_draw_body()`
## actually drew: the same datum, read twice. A capsule stands along local Y by default;
## `_solid_axis()` says which of this instance's own axes the spine actually lies along, and each
## `CollisionShape2D` is rotated to match.
##
## **One body, several shapes.** A row that declares no parts gets exactly one piece at the origin
## (see `EventDef.parts()`), which is the single shape this always built; the crash gets one per
## car, offset along the spread axis by the piece's own reading of whichever picture is in use. One
## `StaticBody2D` holds them all, so nothing downstream — the debug view's bounding-box layer, which
## walks the physics tree, or `is_solid()` — has to learn that a row may have more than one.
func _build_obstruction() -> void:
	var body := StaticBody2D.new()
	for piece in def.parts():
		var collision := CollisionShape2D.new()
		collision.shape = piece.shape.collision_shape()
		collision.position = _spread_at(piece.offset_for(_spread_vertical))
		if piece.shape.half_length > 0.0:
			collision.rotation = _solid_axis().angle() - PI * 0.5
		body.add_child(collision)
	add_child(body)
	_obstruction = body

## Where each of this instance's solid pieces stands, in world space — paired index for index with
## `solid_part_shapes()` below, the same two-parallel-arrays shape `flock_offsets()` and
## `flock_velocities()` already hand `DebugLayers`.
##
## **This is what a per-tile solid record iterates.** M110's record of which tiles a body holds
## (the one the crowd reads to walk round a seal) is not on `main` yet; when it lands it steps these
## pieces rather than one disc of `obstructs_radius`, which is the whole point of the crash being
## solid in parts — the crowd steps round the cars and walks the debris.
func solid_part_centres() -> PackedVector2Array:
	var centres := PackedVector2Array()
	for piece in def.parts():
		centres.append(global_position + _spread_at(piece.offset_for(_spread_vertical)))
	return centres

## The `GroundShape` of each solid piece, index for index with `solid_part_centres()`. Each lies
## along `solid_axis()`, the same axis its collision shape and its shadow are rotated by.
func solid_part_shapes() -> Array[GroundShape]:
	var shapes: Array[GroundShape] = []
	for piece in def.parts():
		shapes.append(piece.shape)
	return shapes

## Built once for every instance, whether or not `ExcitementHalo` ever picks it — a `city_wide`
## source is excluded by kind (see `ExcitementHalo.select_sources()`) and simply never draws, which
## is cheaper to leave true by construction than to special-case here. `EntityHalo` gets `self`'s
## own `_draw_body` and `_current_bob` so its ring rides the same lift `_draw()` gives the body.
func _build_halo() -> void:
	_halo = EntityHalo.new(_draw_body, _current_bob)
	add_child(_halo)

## Whether this instance is solid right now. True from `_ready()` for anything with
## `obstructs_radius`, false once a pursuer that had a body stops waiting — see `_process()`.
func is_solid() -> bool:
	return _obstruction != null

func _process(delta: float) -> void:
	if is_finished:
		return
	_clock += delta
	age += delta

	if not _activation_announced and not is_telegraphing():
		_activation_announced = true
		EventBus.event_activated.emit(self)

	if is_leaving:
		_leave(delta)
		_fly_the_flock(delta)
		queue_redraw()
		return

	if is_chatting():
		# The one thing that runs while she is otherwise frozen. Her own controls are locked by
		# `Stroller.detain()`, called the frame `start_chat()` fires; here it is only a clock, held
		# apart from `_has_expired()` because `duration` means something else for every other row.
		_chat_seconds_left = maxf(0.0, _chat_seconds_left - delta)
		# `redetains` is the one thing that skips `_be_done()` here: a checkpoint's hut or post
		# stays exactly where it is, still solid, ready for `EventManager` to arm it again the
		# instant she is released and clear of `detain_distance()` — see `EventDef.redetains`.
		# `chatting_mother` has none of this: her conversation ending is what starts her own
		# departure, `_be_done()`'s ordinary meaning for anything that is not a fixture.
		if _chat_seconds_left <= 0.0 and def.redetains:
			# The frame the hold's own clock runs out — before `EventManager` has teleported her,
			# which is why the camera eases toward her *live* position rather than a captured one,
			# see `Stroller.release_camera_focus()`.
			_leave_inspection()
		if _chat_seconds_left <= 0.0 and not def.redetains:
			_be_done()
		queue_redraw()
		return

	_fly_the_flock(delta)
	if def.pursues:
		# **A pursuer that has a route runs it until it notices her.** No field says so — see
		# `EventDef.at_heat()`'s own note on `PRESSES` — it is read off the two flags a mobile
		# pursuer already carries: while it is only `is_waiting()` it has not decided anything about
		# her yet, so it patrols its path exactly as a plain mobile row would; `_chase` below is what
		# turns it round the frame it notices. A stationary pursuer (`alley_robbery`) has no path to
		# run and this is simply never true of it.
		if is_waiting() and def.mobile and path.size() > 1:
			_advance_along_path(delta)
		_chase(delta)
	elif def.pursues_within > 0.0:
		# The same waiting state a pursuer gets, for a row that only waits and then runs its own
		# path rather than turning to chase her once noticed — see `_check_for_notice()` and
		# `EventDef.pursues_within`'s own note that the field is not only for a pursuer any more.
		_check_for_notice()
		if not is_waiting() and def.mobile and path.size() > 1 and not is_telegraphing_still():
			_advance_along_path(delta)
	elif def.mobile and path.size() > 1 and not is_telegraphing_still():
		_advance_along_path(delta)

	if _obstruction and def.pursues and not is_waiting():
		# **Anything that stands still is solid at the width it is drawn, and nothing else is.**
		# `_walkable_step`'s own note says why a moving pursuer may not keep a body: "giving a
		# pursuer one would let a moving wall pin her against a building on a two-tile pavement."
		# A hunting `abduction` is solid exactly while it is parked — the instant it stops waiting
		# it is coming for her, and the body comes down the same frame.
		_obstruction.queue_free()
		_obstruction = null

	if def.look == EventDef.Look.UNMARKED_VAN:
		_update_the_take()

	if _has_expired():
		_be_done()
	queue_redraw()

# ------------------------------------------------------------------- the chat ---
# `chatting_mother`'s whole mechanic: a trigger rather than a field. `EventManager` decides *when*
# — it is the one place holding the `Stroller` reference `detain()` needs — and everything about
# *what happens once it has* lives here, the same split `_chase` draws between "what decides" and
# "what plays out".

## Whether she has ever had her one conversation. Checked by `EventManager` before it will ever
## call `start_chat()` again: once true, this instance can never detain a second time, whatever
## she does — she is spent as a detainer the moment the first one starts.
var _has_chatted := false
## Seconds left in the conversation currently running, or `0.0` when none is.
var _chat_seconds_left := 0.0

## Whether a conversation is running right now. Freezes pacing (see `_process`) and switches the
## posture from strolling to talking (see `_draw_chatting_mother`) — the only two things about her
## that a conversation changes, since the lock on the player's own movement lives on `Stroller`.
func is_chatting() -> bool:
	return _chat_seconds_left > 0.0

## Whether the guard this instance draws is inside with her for its own hold right now — he is the
## one taking her in, so he is not also standing in the street, see
## `Stroller.hide_for_inspection()`. `def.redetains` is the flag only the three region-door rows
## carry, so `chatting_mother` — same mechanism, no `redetains` — keeps her ordinary talking
## posture for the whole of her own conversation instead.
func is_its_guard_inside() -> bool:
	return def.redetains and is_chatting()

## Whether a checkpoint's own hold suppresses *every* drawing of this instance, halo included.
##
## **True only where the guard is the whole of what this row draws.** `checkpoint_post` is one
## man at an alley mouth and nothing else, so when he goes in there is nothing left to draw; a hut
## is a building and a gate is a boom across a road, and *(PLAYTEST-57: "the checkpoint house
## disappears ... all this is incorrect".)* A structure that blinks out while she is inside it
## reads as the door having been removed rather than as her having gone through it, which is the
## opposite of what the hold is for.
##
## Read by `_draw()`, by `_draw_body()` (the halo's own re-draw entry point — see that function's
## doc for why the halo needs its own guard rather than inheriting `_draw()`'s), and by a test, so
## the three can never drift apart from each other.
func is_suppressed_by_its_own_hold() -> bool:
	return is_its_guard_inside() and def.look == EventDef.Look.CHECKPOINT_POST

## Whether this instance has ever detained anybody. See `_has_chatted`.
func has_chatted() -> bool:
	return _has_chatted

## Starts the one conversation this instance will ever have. Called by `EventManager` the frame it
## decides the player has come within `def.detain_distance()` of an instance that has not chatted
## yet — see
## `EventManager._check_detentions()`. Spends the instance as a detainer immediately, before the
## clock has run a single frame, so a second call before this one finishes can never restart it.
func start_chat() -> void:
	_has_chatted = true
	_chat_seconds_left = def.detain_seconds
	if def.redetains:
		_enter_inspection()

## The checkpoint's own *"gone inside"* — reached only by `start_chat()` above, and only for a
## `redetains` row, so `chatting_mother`'s one conversation is untouched. `EventInstance` holds no
## `Stroller` reference of its own; the `player` group is the same lookup `Crowd`, `HUD` and the
## resistance director already use to reach her from outside the player scene.
func _enter_inspection() -> void:
	var stroller := get_tree().get_first_node_in_group("player") as Stroller
	if not stroller:
		return
	stroller.hide_for_inspection()
	stroller.focus_camera_on(global_position)

## The other half, called from `_process()` the frame the hold's own clock runs out.
func _leave_inspection() -> void:
	var stroller := get_tree().get_first_node_in_group("player") as Stroller
	if not stroller:
		return
	stroller.show_after_inspection()
	stroller.release_camera_focus()

## Whether the chase ended because she shook it off rather than because the clock ran out. Read by
## the telemetry, which is the only thing that can tell the two apart from outside.
var gave_up := false
## How long the gap to her has been opening, in seconds. The chase ends when it reaches
## `Tuning.PURSUIT_SHAKEN_OFF`; anything that closes the gap puts it back to zero. See `_chase`.
var _outrun_for := 0.0
## The gap on the previous frame, so `_chase` can tell opening from closing. `INF` before the first.
var _last_range := INF
## For a pursuer with `pursues_within`: the age at which she came close enough for it to take an
## interest, or `INF` while it is still only standing there. Its telegraph and its chase are both
## measured from here rather than from birth. See `is_waiting()`. Carried across a stream-out by
## `resume()`'s own `from_noticed_at`, so a notice made before an instance left the world is not
## made twice.
var _noticed_at := INF
## True once she has come inside the stand-off during the telegraph, which ends the telegraph
## there and then.
##
## **The lunge is fired by her, not by a clock**, and the two alternatives each fail in their own
## way. A pursuer reaches its stand-off in about a third of a second and then has the rest of a
## 2.4s telegraph to spend while she keeps walking into it — so *holding a distance* means backing
## away from her, and a dog that reverses down the street in front of you is not a dog that is
## about to charge. **Standing still instead** is worse: she closes the last hundred pixels
## herself, reaches it **before** the clock lets it fire, and it kills her from a standing start on
## the first lethal frame.
##
## Firing on proximity gives both halves at once: it never reverses, and the chase always starts at
## the stand-off however she approached it — which is the whole content of the contract, since
## `Tuning.pursuit_standoff()` is the distance that leaves her `PURSUIT_REACTION` to answer.
var _lunged := false

## Comes after her — the one kind of thing running is the answer to. See `EventDef.pursues` and
## `Tuning.validate_pursuit`.
##
## **It comes through its own telegraph**, the way a fire engine does, and that is the whole of
## why a pursuer can force a run at all. A telegraph it spends standing still is a head start she
## can simply walk away with: at `pursue_speed` against `WALK_SPEED` it closes about 56px a
## second, so two seconds of politeness hands her more ground than the entire chase can take
## back. The notice is *the sight of it coming*, and `Tuning.PURSUIT_MIN_NOTICE` is how much of
## that she is owed before it is allowed to end her day.
##
## **But it closes to a stand-off and holds it, rather than arriving.** The paragraph above buys the
## notice in seconds and says nothing about *where* the pursuer spends them: sited across her line a
## couple of hundred pixels ahead — which is where she was already walking — it closes the gap in
## three quarters of a second and then stands **inside its own lethal radius** for the rest of a
## telegraph it is not yet allowed to kill her during. The moment it is, it does, from a standing
## start. Every line of `validate_pursuit` passes while that happens, because every line of it is
## about speeds and durations and a pursuit is played out in distances.
##
## `Tuning.pursuit_standoff()` is the same contract restated as a distance, and holding it is what
## makes the notice real from *any* approach geometry — including the one the director produces.
##
## **And it gives up when it is being outrun, not when a gap has reached a size.** The pursuer is
## faster than a walk and slower than a run by construction, so "the gap is opening" is a statement
## the player can only make by running — which is why it can carry the whole of the design. Walking
## away cannot end a chase at any distance, and running away always ends one in
## `Tuning.PURSUIT_SHAKEN_OFF` seconds regardless of how big the thing chasing her is.
##
## A pursuer may also be a **place** before it is a moment: something that raises the meter on
## sight, and comes for her if she gets close. While
## it is waiting it emits at full strength, is not lethal and does not move; `pursues_within` is
## where that stops. Everything below then runs exactly as it does for a dog sited in front of her,
## started later.
func _chase(delta: float) -> void:
	if player_at == Vector2.INF or is_telegraphing_still():
		return
	var toward := player_at - global_position
	var range_to_her := toward.length()
	if range_to_her < 1.0:
		return
	if is_waiting():
		if range_to_her <= def.pursues_within:
			_noticed_at = age
			# It turns to face her on the frame it notices, which is the whole of the cue: a man who
			# was looking down the alley is now looking at you.
			_heading = toward.normalized()
		return
	_heading = toward.normalized()
	var standoff := Tuning.pursuit_standoff(def.pursue_speed, def.inner_radius)
	# **She ran, so it backs off.** Counting seconds of the *gap actually opening* is the same
	# sentence said about the geometry instead of about the player, and in play it is a different
	# rule: a run opens the gap at 38px/s against the day-3 dog, a fifth of a pixel a frame, so a
	# corner, a kerb, a body in the way or the 0.37s it takes to reverse a walk all reset the timer
	# and the dog keeps coming while she is plainly running from it. The rule here is the one a
	# player can state and therefore learn: **run and it gives up.**
	#
	# `_last_range` is still tracked because the leaving phase reads it; nothing decides on it.
	if player_running:
		_outrun_for += delta
	else:
		_outrun_for = 0.0
	_last_range = range_to_her
	# `PURSUIT_MIN_NOTICE` is the floor under it, so a chase can never be over before it was a
	# threat: a player already running when it lunges would otherwise shake off a thing that never
	# got to say what it was.
	if _outrun_for >= Tuning.PURSUIT_SHAKEN_OFF and chase_age() >= Tuning.PURSUIT_MIN_NOTICE:
		gave_up = true
		_be_done()
		return
	# Straight at her, and no faster than its own speed: the contract is the speed, so nothing
	# here may quietly exceed it.
	var step := minf(def.pursue_speed * delta, range_to_her)
	if is_telegraphing():
		# **It closes to the stand-off, holds it, and lunges when she reaches it.** The lunge is
		# fired by *her* rather than by the clock, whichever comes first — see `_lunged`.
		if range_to_her <= standoff:
			_lunged = true
		else:
			step = minf(step, range_to_her - standoff)
	var moved := _walkable_step(_heading * step)
	position += moved
	# Ground covered, not ground gained: backing off is still moving, and the bob is driven by
	# distance so that a thing holding its ground still reads as alive.
	_path_travelled += moved.length()

## `_chase()`'s own notice check, folded out for anything that waits on `pursues_within` without
## also `pursues` — a row that runs its own path once noticed rather than turning to chase her.
## `alley_mouse` is the first: `EventScheduler` places it on an `ALLEY` tile at dawn, well outside
## `Tuning.VIEW_HALF_EXTENT`, so telegraphing from the moment it exists dashed and finished off
## screen long before she ever walked into the alley — the review finding this exists to fix.
##
## Turns to face her the same way `_chase()` does, which costs nothing here: `_advance_along_path`
## overwrites `_heading` from the path's own direction the instant it starts moving, so this only
## shows for whatever is left of the frame it happens on.
func _check_for_notice() -> void:
	if player_at == Vector2.INF or not is_waiting():
		return
	var toward := player_at - global_position
	if toward.length() > def.pursues_within:
		return
	_noticed_at = age
	_heading = toward.normalized()

## Clamps a chase's own step so it can never end standing on ground the city says nobody can. A
## pursuing instance moves by setting its own position, and nothing above this function has ever
## asked the map anything — harmless while every mobile row travelled a route the scheduler had
## already checked, and not harmless the moment something steers freely at the player. Everything
## above this function decides *how far and which way* to move; this is the one place that gets to
## say no.
##
## **Not a body.** `obstructs_radius` is for something that stands still — see "Solid things are
## solid" in docs/EVENTS.md — and giving a pursuer one would let a moving wall pin her against a
## building on a two-tile pavement, exactly what `dog_walker`'s own exemption exists to avoid. What
## was missing here is smaller than a body: the position `_chase` sets every frame never asked the
## map anything at all, so a straight line toward her cut through whatever stood between the two of
## them.
##
## **Slides along whichever single axis is still open** rather than stopping dead the instant it
## grazes a corner, because a chase that gives up meters before the wall does is not one that was
## ever really following her round it. Tried larger component first, so a pursuer coming at a wall
## nearly square-on slides along it rather than snagging on whichever axis happens to be smaller.
func _walkable_step(delta_pos: Vector2) -> Vector2:
	if not _map or delta_pos.is_zero_approx():
		return delta_pos
	if _map.is_walkable(_map.world_to_tile(global_position + delta_pos)):
		return delta_pos
	var along_x := Vector2(delta_pos.x, 0.0)
	var along_y := Vector2(0.0, delta_pos.y)
	var first := along_x if absf(delta_pos.x) >= absf(delta_pos.y) else along_y
	var second := along_y if first == along_x else along_x
	for candidate in [first, second]:
		if not candidate.is_zero_approx() \
				and _map.is_walkable(_map.world_to_tile(global_position + candidate)):
			return candidate
	return Vector2.ZERO

## How far along its route this instance has got, so streaming it out and back in can resume it
## instead of rewinding it. See `EventManager._stream_in`.
func path_travelled() -> float:
	return _path_travelled

## How fast and which way this thing is actually travelling, in px/s.
##
## Asked by `EventManager._warn_about_the_ground_she_is_on`, which has to know whether a lethal
## thing is coming *at her* rather than merely near her — walking orthogonally away from a cyclist
## must take the mark down, because there is no way it can reach her.
##
## Zero while a pursuer is telegraphing, and that is the interesting case rather than an omission:
## it is holding its stand-off, so it is not closing, and a mark that said otherwise would be
## warning her about a thing that is deliberately waiting.
func travel_velocity() -> Vector2:
	if is_finished or is_leaving:
		return Vector2.ZERO
	if def.pursues:
		if is_waiting() or is_telegraphing():
			return Vector2.ZERO
		return _heading * def.pursue_speed
	if def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		return _heading * def.speed
	return Vector2.ZERO

## `travel_velocity()`'s own answer, except for a pursuer that has been noticed and is holding
## its telegraph's stand-off: the caret's projection asks where this is *going*, which is
## `pursue_speed` toward her the instant it has decided to come, not the moment its lunge is
## allowed to fire. `travel_velocity()` itself has to stay zero there — the exclamation mark's
## "it is not closing" reads that answer literally, and a mark that said otherwise would warn her
## about a thing that is deliberately holding still — so this is a second query for the caret
## alone rather than a change to the first one.
##
## **A waiting pursuer still has no course.** `is_waiting()` means nobody has been noticed yet, so
## there is nothing here to project toward; only the moment it decides changes the answer, exactly
## as `travel_velocity()` already has it.
func _caret_velocity() -> Vector2:
	if is_finished or is_leaving:
		return Vector2.ZERO
	if def.pursues:
		if is_waiting():
			return Vector2.ZERO
		return _heading * def.pursue_speed
	return travel_velocity()

## Which way this instance was sited facing (`setup()`'s own `face`), unmoved for anything
## stationary that never turns. A door body's own facing is the street's along-axis rather than
## the direction it is drawn — `RegionPlanner` sites every `checkpoint_hut`/`checkpoint_gate`/
## `checkpoint_post` at a crossing facing the same way — so `EventManager`'s detention teleport can
## read this back as which side of the crossing she is on, whichever of the three bodies actually
## detained her.
func facing_now() -> Vector2:
	return _heading

## Puts an instance back where a previous incarnation of the same plan had got to. Restores the
## age as well as the distance, so the telegraph, the pulse phase and the duration all continue
## rather than starting again — an event that streams in and out must not become immortal by
## being visited twice.
##
## `from_noticed_at` is the same restore for `_noticed_at`, and it is general over every
## `pursues_within` row rather than particular to whichever one exposed the gap: a fresh instance
## always starts `is_waiting()` (`_noticed_at == INF`), so a row streamed out after it had already
## noticed her came back standing where the day planted it, having forgotten the chase. Defaulted
## to `INF` so a caller that only ever restored age and distance — every caller before this field
## existed — keeps restoring exactly what it always restored, still `is_waiting()` unless told
## otherwise.
func resume(from_age: float, from_travelled: float, from_noticed_at := INF) -> void:
	if from_age <= 0.0:
		return
	age = from_age
	_path_travelled = from_travelled
	_noticed_at = from_noticed_at
	if def.mobile and path.size() > 1:
		_advance_along_path(0.0)

# ------------------------------------------------------------------- the take ---
# `abduction`'s own scene: a bystander walked to the van and taken, the first time she comes close
# enough to see it happen. Drawing and telemetry only — nothing here reaches into the crowd, and
# nothing here changes `contribution_at()`. See docs/TODO.md, M56, "the van draws its own victim".

## How long the walk to the van takes, once it starts.
const VICTIM_TAKEN_OVER := 2.5
## How far to the side of the van the victim stands before the walk begins.
const VICTIM_STANDING_OFFSET := 32.0

## Age the take began, or `INF` before it has and after a hunting van abandons one mid-walk. Not
## restored by `resume()`, which carries `age`, `travelled` and `_noticed_at` but stops there — and
## it is harmless for a reason `_noticed_at` does not share: the whole scene is under three
## seconds, far short of anything that gets an instance streamed out and back in.
var _victim_taken_at := INF
## Whether the one telemetry entry for this take has already been written, so a frame that finds
## the walk finished twice in a row cannot log it twice.
var _victim_logged := false

## How long this instance has left before it is simply gone, or `INF` where the question does not
## yet apply. A pursuer that is still only waiting has no expiry of its own — `_has_expired()`
## returns false for the whole time — so its life is unbounded until she gives it a reason to end.
func _victim_time_left() -> float:
	if is_waiting() or def.duration <= 0.0:
		return INF
	return (def.telegraph_time + def.duration) - chase_age()

## Runs the scene: starts it, times it, and tells the log when it finishes.
##
## **Begins the first time she can see it happen.** `def.outer_radius` rather than some smaller
## trigger, because the design's own sentence is that the take "only means anything where she can
## see it happen" — a van she never came near never runs it. `player_at` is the same write
## `_chase` reads, which is what lets a data-level rig drive this scene by hand.
##
## **Never starts without enough of the van's own life left to finish in.** A take cut short by the
## van disappearing mid-walk would read as a bug rather than as an abduction.
##
## **A hunting van has other business.** The instant it stops waiting it is coming for her rather
## than idling at the kerb, so an in-progress take is abandoned rather than finished: no victim is
## drawn again, taken or not, and nothing is logged for a take that never completed.
func _update_the_take() -> void:
	if def.pursues and not is_waiting():
		_victim_taken_at = INF
		return
	if _victim_taken_at == INF:
		if player_at == Vector2.INF \
				or global_position.distance_to(player_at) > def.outer_radius \
				or _victim_time_left() < VICTIM_TAKEN_OVER:
			return
		_victim_taken_at = age
		return
	if _victim_logged or age - _victim_taken_at < VICTIM_TAKEN_OVER:
		return
	_victim_logged = true
	Telemetry.note("taken", "'%s' takes a bystander" % def.id)

## Whether the scene is running right now, for `_draw_abduction` and for a test to drive by hand
## without reaching into a private field.
func is_taking_a_victim() -> bool:
	return _victim_taken_at != INF and (age - _victim_taken_at) < VICTIM_TAKEN_OVER

# ------------------------------------------------------------------ the flock ---
# **A flock drawn as one picture repeated is a flock that freezes.** Offsets derived from the
# instance's own position keep the shape from boiling between frames, which is right for a still and
# is exactly what stops the birds ever moving apart; a single `rise` term that reaches 1.0 at the
# end of the telegraph and then holds sends the flock up in one movement and hangs it in the air,
# motionless, for the whole burst that is supposed to *be* the event.
#
# So each bird is its own body: its own place on the pavement, its own heading, its own speed, its
# own height, its own wingbeat, and its own contribution to the excitement. Three things follow and
# each is load-bearing:
#
# - **The excitement is still a pure query, and it is now a query over eleven sources.** `Baby` asks
#   the world, the world sums `contribution_at()`, and this one sums over its birds — which is the
#   invariant working exactly as written rather than an exception to it. It is also what makes the
#   flock *dangerous* in the way a route-planning game can use: the middle of it stacks four or five
#   overlapping fields and the edge of it stacks one, so walking round it is cheap and walking
#   through it is the most expensive thing on an act I pavement.
# - **The birds stay inside `flock_spread` of the middle**, which is what keeps the telegraph
#   fairness contract true. The contract is stated over `outer_radius` from the instance's own
#   position; `flock_spread + _bird_outer()` is `outer_radius`, so the union of eleven moving fields
#   is a subset of the one disc `Tuning.validate_event` checked. Widening the wheel without shrinking
#   the per-bird radius would quietly move the field the contract was written about.
# - **They wheel rather than fly straight.** A bird that flies straight leaves, and a flock that
#   leaves is a flock that is over — so being over is said with `is_leaving`, and only then do they
#   all pick the same direction.

## One bird. Deliberately not a node: eleven Node2Ds per flock, y-sorted against a city, to draw
## eleven 18px sprites that are always within 60px of each other, is a great deal of tree for a
## picture that one `_draw()` produces correctly. `RefCounted` rather than `Node` so it cannot leak.
class Bird extends RefCounted:
	## Where it is on the ground plane, relative to the flock's own origin.
	var at := Vector2.ZERO
	## How far off that ground, in px. Zero while it is standing on the pavement.
	var lift := 0.0
	var heading := Vector2.RIGHT
	var speed := 0.0
	## Radians per second, signed. What makes it wheel instead of flying out of its own event.
	var turn := 0.0
	## How high this one goes, and how fast it gets there.
	var ceiling := 0.0
	var climb := 0.0
	## Wingbeats per second, and where in one it currently is.
	var beat := 0.0
	var phase := 0.0
	## This bird's own held eight-view sector — one per bird rather than one shared with the
	## instance's own `_view_sector`, since a flock is eleven bodies wheeling independently rather
	## than one actor with one facing. See `EventInstance._select_view()`, the same hold applied
	## per bird by `_draw_birds()`.
	var view_sector := 2

var _flock: Array[Bird] = []

## How fast a bird crosses the ground once it is up, and how slowly it shuffles before it is.
const BIRD_FLIGHT_SPEED := 96.0
const BIRD_GROUND_SPEED := 7.0
## How much faster a bird that is getting out of here goes than one that is wheeling.
const BIRD_DEPARTURE_GAIN := 2.1

## Scatters the flock across the pavement it is standing on.
##
## Seeded from the instance's own position rather than from an RNG, and that is not laziness: the
## determinism invariant says nothing gameplay-relevant may call the global `randi()`, and the day's
## RNG is not reachable from here — nor should it be, since streaming this event out and back in
## would then consume from it twice and move every event planned after it. A hash of where it stands
## gives the same flock every time the same flock is built, which is the property that matters.
func _build_the_flock() -> void:
	_flock.clear()
	var count := def.flock_size
	for i in count:
		var bird := Bird.new()
		# Spread round the middle rather than scattered independently, so eleven birds read as a
		# flock rather than as eleven birds who happen to be near each other.
		var angle := TAU * (float(i) + 0.35 * _flock_roll(i, 1)) / float(count)
		var reach := def.flock_spread * (0.3 + 0.7 * _flock_roll(i, 2))
		bird.at = Vector2(cos(angle), sin(angle) * GROUND_SQUASH) * reach
		bird.heading = Vector2.from_angle(TAU * _flock_roll(i, 3))
		bird.view_sector = EightDirection.nearest(bird.heading)
		bird.speed = BIRD_GROUND_SPEED
		# Half of them wheel each way, or the flock rotates as a body and reads as a carousel.
		bird.turn = (1.2 + 1.4 * _flock_roll(i, 4)) * (1.0 if i % 2 == 0 else -1.0)
		bird.ceiling = 20.0 + 34.0 * _flock_roll(i, 5)
		bird.climb = 34.0 + 40.0 * _flock_roll(i, 6)
		bird.beat = 6.0 + 5.0 * _flock_roll(i, 7)
		bird.phase = TAU * _flock_roll(i, 8)
		_flock.append(bird)

## The oblique view: a circle on the ground is drawn as an ellipse, so the flock's footprint is
## squashed on Y exactly as every shadow in the game is.
const GROUND_SQUASH := 0.55

## A deterministic 0..1 from the flock's own position, its index and a salt. One salt per property,
## or every bird's speed would be a function of its own heading.
func _flock_roll(index: int, salt: int) -> float:
	var mixed := int(global_position.x) * 73856093 + int(global_position.y) * 19349663 \
			+ index * 83492791 + salt * 2971215073
	return float(absi(mixed) % 4096) / 4096.0

## Steps every bird. Three phases, and they are the whole event: **on the pavement** while it
## telegraphs, which is the part she can see from down the street and walk around; **up and
## wheeling** for the duration, which is the part that costs; and **away** once it is over.
func _fly_the_flock(delta: float) -> void:
	if _flock.is_empty():
		return
	var grounded := is_telegraphing()
	for bird in _flock:
		bird.phase += bird.beat * TAU * delta
		if grounded:
			# Pecking about. It has to move — a bird standing perfectly still is the bug being
			# fixed, one phase earlier — but slowly enough that the flock is plainly still on the
			# ground and plainly still avoidable.
			bird.speed = BIRD_GROUND_SPEED
			bird.heading = bird.heading.rotated(bird.turn * 0.5 * delta)
			bird.lift = 0.0
		elif is_leaving:
			# Everybody the same way now, and climbing hard. What is over says so by leaving, and a
			# flock that was still wheeling would read as still happening.
			bird.heading = _steer(bird.heading, _heading, BIRD_TURN_IN, delta)
			bird.speed = move_toward(bird.speed, BIRD_FLIGHT_SPEED * BIRD_DEPARTURE_GAIN,
					260.0 * delta)
			bird.lift += bird.climb * delta
		else:
			bird.heading = bird.heading.rotated(bird.turn * delta)
			bird.speed = move_toward(bird.speed, BIRD_FLIGHT_SPEED, 320.0 * delta)
			bird.lift = move_toward(bird.lift, bird.ceiling, bird.climb * delta)
			# Turned back before the edge of its own event, not at it. A bird's own wheel is wider
			# than the flock at every speed either of them wants, so without this they simply fly
			# out of the field they are supposed to be, and take the fairness contract with them.
			#
			# **From half way out** rather than from the boundary, because a turn is not free: at
			# `BIRD_FLIGHT_SPEED` and `BIRD_TURN_IN` the tightest circle a bird can fly has a radius
			# of about 21px, so a bird that is still heading outwards when it reaches the edge is
			# already outside by the time it has come round. Starting at half the spread leaves it
			# the room the turn costs.
			if bird.at.length() > def.flock_spread * 0.5:
				bird.heading = _steer(bird.heading, -bird.at.normalized(), BIRD_TURN_IN, delta)
		bird.at += bird.heading * bird.speed * Vector2(1.0, GROUND_SQUASH) * delta
		if not is_leaving and bird.at.length() > def.flock_spread:
			# The steering above is what a bird turning back *looks* like; this is the line that
			# makes it a **guarantee**, and the fairness contract needs one rather than a tendency:
			# `_bird_outer()` is `outer_radius - flock_spread` precisely so that a bird at the rim
			# reaches exactly as far as the event was validated to. Steering from half way out means
			# it shaves a pixel or two when it fires at all, so nothing visible rides on it.
			bird.at = bird.at.normalized() * def.flock_spread

## Turns `heading` toward `wanted` at up to `rate` radians a second.
##
## **Rotating rather than interpolating, and that is not a style choice.** The first version was
## `heading.lerp(wanted, k)`, which cannot turn a vector round: interpolating between a unit vector
## and its opposite runs *down the same line* to zero and back out the way it came, so normalising
## the result gives the heading it started with. A bird flying directly out of its own flock was
## therefore the one case the containment could not fix, and it is the case that matters — it flew
## 202px out of a 62px wheel while the code that was supposed to hold it ran every frame.
func _steer(heading: Vector2, wanted: Vector2, rate: float, delta: float) -> Vector2:
	var difference := angle_difference(heading.angle(), wanted.angle())
	return heading.rotated(clampf(difference, -rate * delta, rate * delta))

## How hard a bird can turn, in radians a second. Fast enough that the wheel it flies fits inside
## the flock — see the note in `_fly_the_flock` — and slow enough to read as a bird banking.
const BIRD_TURN_IN := 4.6

## The radius one bird emits over. The rest of the field is the room the flock takes up: a bird at
## the far edge of the wheel reaches exactly as far as the event says it does and no further.
func _bird_outer() -> float:
	return maxf(def.inner_radius + 1.0, def.outer_radius - def.flock_spread)

## `_bird_outer()`, read by `DebugLayers` so a flock's own fields layer draws the exact radius
## `_flock_contribution_at()` sums over rather than a second formula that could drift from it.
func flock_outer_radius() -> float:
	return _bird_outer()

## Each live bird's own ground-plane offset from this instance's origin — empty for anything
## without a flock. The one place `DebugLayers` reads into `_flock`, which otherwise has no public
## accessor: see that class for why the fields layer draws one pair of radii per bird rather than
## one for the whole instance.
func flock_offsets() -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for bird in _flock:
		offsets.append(bird.at)
	return offsets

## Each live bird's own `heading * speed`, parallel to `flock_offsets()` — the velocity
## `_flock_contribution_at()` already reads per bird, exposed so the debug view's fields layer can
## draw the same eccentric boundary rather than a circle standing in for it.
func flock_velocities() -> Array[Vector2]:
	var velocities: Array[Vector2] = []
	for bird in _flock:
		velocities.append(bird.heading * bird.speed)
	return velocities

# --------------------------------------------------------------- going away ---
# **Nothing vanishes while you are looking at it.** An event that ends by `_finish()` wherever it
# happens to be standing ends, for the two shortest-lived rows in the game, directly in front of
# her: the cat's route is one street wide and ends in the open, and the pigeons hang in the air for
# a fifth of a second. The end of an event is a **departure**, not a deletion.
#
# What is deliberately *not* here: a fade. A thing that fades out is still a thing that disappears,
# and it disappears in a way nothing in the world could explain. The cat runs on, the flock climbs
# away, the dog that lost interest trots off — and each of them is gone because it left.

## True once it has stopped being an event and is only getting out of shot. It emits nothing, it
## cannot end the day, and it carries no cue: whatever it was, it is over.
var is_leaving := false
var _leaving_for := 0.0

## The most it may spend on the way out. A backstop rather than a timing: with no player to be out
## of sight of — a headless rig, a streamed-out day — nothing else would ever end it.
const LEAVING_GIVES_UP := 6.0

## The end of an event: it leaves if it has anywhere to go, and stops existing if it has not.
##
## Two things never leave, and both would break something that reads the finishing position. An
## event with a `spawns_on_finish` stops **where the thing it leaves belongs** — a fire engine's
## fire is at the building, not two streets past it. And anything with no departure speed has no
## way to go anywhere; a café that closes has always simply been over.
func _be_done() -> void:
	if is_finished or is_leaving:
		return
	if def.departure_speed() <= 0.0 or def.spawns_on_finish != "":
		_finish()
		return
	is_leaving = true
	_leaving_for = 0.0
	# Something on a route carries on the way it was going; anything else goes away from her,
	# which is the only direction a flushed flock or a dog that has lost interest can mean.
	if not (def.mobile and path.size() > 1) and player_at != Vector2.INF \
			and not global_position.is_equal_approx(player_at):
		_heading = (global_position - player_at).normalized()

func _leave(delta: float) -> void:
	_leaving_for += delta
	var step := def.departure_speed() * delta
	position += _heading * step
	_path_travelled += step
	var gone := player_at != Vector2.INF \
			and global_position.distance_to(player_at) > Tuning.OUT_OF_SIGHT
	if gone or _leaving_for >= LEAVING_GIVES_UP:
		_finish()

func _advance_along_path(delta: float) -> void:
	# Movement starts when the telegraph does, so an approaching siren is audible and
	# visible while it is still far away — which is what makes the warning usable.
	_path_travelled += def.speed * delta
	var remaining := _path_travelled
	# **A beat rather than a journey.** The distance covered is folded back and forth over
	# the route, so the same walk up and down happens for ever and the end of the path is never
	# reached — which is what stops a fixture that moves from departing like something that was
	# passing through. Folded rather than reset, so streaming it out and back in resumes it mid-beat
	# exactly as `resume()` promises.
	var back := false
	if def.paces:
		var beat := _path_length()
		if beat <= 0.0:
			return
		var cycle := fmod(_path_travelled, beat * 2.0)
		back = cycle > beat
		remaining = beat * 2.0 - cycle if back else cycle
	for i in range(1, path.size()):
		var segment := path[i] - path[i - 1]
		var length := segment.length()
		if remaining <= length:
			_heading = segment.normalized()
			# Facing the way it is actually walking. Without this a man pacing a pavement moons
			# along it backwards for half of every beat, which is worse than not moving at all.
			if back:
				_heading = -_heading
			position = path[i - 1] + segment.normalized() * remaining
			return
		remaining -= length
	position = path[path.size() - 1]
	if def.paces:
		return
	# A mobile event that has driven off the end of its route is done, whatever its
	# nominal duration says — and it keeps going until it is out of sight, rather than stopping
	# dead on the pavement she is walking down. See "going away" above.
	_be_done()

## The length of the whole route, in px.
func _path_length() -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i].distance_to(path[i - 1])
	return total

func _has_expired() -> bool:
	if is_waiting():
		# It has not happened yet, and it is not going to until she walks up to it.
		return false
	return def.duration > 0.0 and chase_age() >= def.telegraph_time + def.duration

func _finish() -> void:
	if is_finished:
		return
	is_finished = true

# ------------------------------------------------------------------ emission ---

## True while the event is visible but has not yet reached full strength.
##
## A pursuer has a second way out of it, and it is the one that usually happens: `_lunged`, when
## she walked up to the stand-off before the clock ran out.
func is_telegraphing() -> bool:
	if is_waiting():
		return false
	if _lunged:
		return false
	return chase_age() < def.telegraph_time

## True for a pursuer that is only standing there, because she has not come near enough for it to
## take an interest. It emits at full strength, it is not lethal, and it does not move.
## See `EventDef.pursues_within`.
func is_waiting() -> bool:
	return def.pursues_within > 0.0 and _noticed_at == INF

## How long this has been *happening*, which is not always how long it has existed.
##
## For everything in the catalogue but one it is the age. For a pursuer that waits, the clock starts
## when it notices her — a telegraph spent at dawn, four streets away, is not a notice, and
## `telegraph_time` and `duration` are both promises about the encounter rather than about the day.
func chase_age() -> float:
	if def.pursues_within <= 0.0:
		return age
	return 0.0 if _noticed_at == INF else age - _noticed_at

## Current peak intensity at the centre, after the telegraph damping and the pulse envelope.
func current_intensity() -> float:
	if is_finished or is_leaving:
		# On the way out it is scenery. Emitting while it goes would mean the excitement of an
		# event trailing after her for as long as it took the thing to get off screen.
		return 0.0
	if is_chatting():
		# A flat rate for the whole conversation rather than a falloff: she is inside `inner_radius`
		# by construction (`detain_distance() < inner_radius`), so there is no distance to shape.
		# Gated on `baby_awake`, read and never written — see the field's own comment — which is
		# what makes "asleep, it is a pure time loss" true of the meter and not only of the words:
		# nothing here scales through `Tuning.SLEEPING_SENSITIVITY`, it emits exactly zero.
		return (Tuning.CHAT_EXCITEMENT / def.detain_seconds) if baby_awake else 0.0
	var value := def.intensity
	if not is_equal_approx(def.intensity_ramp, 1.0) and def.duration > 0.0:
		var through := clampf((age - def.telegraph_time) / def.duration, 0.0, 1.0)
		value *= lerpf(1.0, def.intensity_ramp, through)
	if def.pulse_period > 0.0:
		# 0.25..1.0, so a pulsing event is never entirely silent between beats.
		var phase := TAU * age / def.pulse_period
		value *= 0.25 + 0.75 * (0.5 - 0.5 * cos(phase))
	# The damping says *this has not started yet*. A pursuer that waits has been standing there
	# since she came round the corner — what has not started is the lunge, not the man — so its
	# notice is the only telegraph in the game that does not quieten what it is warning about.
	if is_telegraphing() and def.pursues_within <= 0.0:
		value *= Tuning.TELEGRAPH_INTENSITY_FRACTION
	return value

## `current_intensity()` with the telegraph's own damping undone — the rate this row will
## actually carry once it is live, which is what the caret's own projection has to sum rather
## than the fraction a telegraph is reading right now. Everything else `current_intensity()`
## accounts for — the ramp, the pulse, chatting — still applies; only the final multiplier is
## skipped, by dividing it back out of the same call rather than a second copy of the ramp and
## pulse logic above it.
##
## Only `expected_impact_at()`'s own projection reads this. Every other caller of
## `contribution_at()` — the halo, the exclamation mark, the meter itself — wants what a source is
## actually doing right now, damped or not, because it is asking about the present rather than
## about the course this thing is on. Without this, a `cyclist` ridden straight at a standing
## player through its own 2s telegraph reads at `TELEGRAPH_INTENSITY_FRACTION` (15%) the whole
## time, and `expected_impact_at()` under-counts the approach by the same fraction.
func _caret_intensity() -> float:
	var value := current_intensity()
	if is_telegraphing() and def.pursues_within <= 0.0:
		value /= Tuning.TELEGRAPH_INTENSITY_FRACTION
	return value

## Duck-typed with `CrowdAgent`'s own copy — see `ExcitementHalo`'s class doc. `points` is not
## recomputed here: `Baby._update_excitement()` traces it back from the meter's own sum as this
## event's exact share of what landed this frame — `contribution × sensitivity × delta` — so the
## halo can never disagree with what the bar actually did. *(2026-09-08, the player: "don't derive
## it from the source numbers but trace an increase in excitement back to its constituents".)*
## Stamped with `_clock`, this event's own simulation clock, rather than the wall clock, so a
## paused game does not empty the halo and a rig can measure the window on simulated time.
func accumulate_landed(points: float) -> void:
	_prune_landed_history()
	if points > 0.0:
		_landed_history.append([_clock, points])

## The sum of every entry still inside `ExcitementHalo.WINDOW`. Pruned here too, not only on
## write, so a source nobody has visited in a while reports honestly the moment it is asked rather
## than waiting for its next landing.
func landed() -> float:
	_prune_landed_history()
	var total := 0.0
	for entry in _landed_history:
		total += entry[1]
	return total

func _prune_landed_history() -> void:
	var cutoff := _clock - ExcitementHalo.WINDOW
	while not _landed_history.is_empty() and _landed_history[0][0] < cutoff:
		_landed_history.pop_front()

## Excitement per second this event contributes at a point.
##
## `intensity_override` replaces `current_intensity()` for this one call when given (`< 0.0`
## means "not given" — every intensity this def can carry is positive). The only caller that ever
## passes one is `expected_impact_at()`'s own projection, asking for `_caret_intensity()` — the
## row's live rate — in place of whatever a telegraph has this one currently damped to; every
## other caller gets the answer it always got.
##
## `velocity_override` replaces `travel_velocity()` for the field's own kernel, the same way, when
## given (`Vector2.INF` means "not given"). The only caller is `expected_impact_at()` too, and for
## the same reason: its projection translates the *sample point* by `_caret_velocity()` rather than
## moving the source, and the ellipse the translated point is measured against has to be oriented by
## that same velocity or the two disagree about which way this thing is going. A pursuer holding its
## telegraph stand-off is the case that matters — `travel_velocity()` is zero there (it is holding
## still) while `_caret_velocity()` is the lunge it is about to make.
func contribution_at(world_position: Vector2, intensity_override := -1.0,
		velocity_override := Vector2.INF) -> float:
	if is_finished or is_leaving:
		return 0.0
	var intensity := intensity_override if intensity_override >= 0.0 else current_intensity()
	# A city-wide source has no falloff: there is nowhere in the city it does not reach.
	if def.city_wide:
		return intensity
	if not _flock.is_empty():
		return _flock_contribution_at(world_position, intensity)
	var velocity := velocity_override if velocity_override != Vector2.INF else travel_velocity()
	return Tuning.falloff(_field_distance(world_position, velocity),
			intensity, def.inner_radius, def.outer_radius)

## The distance `contribution_at()` prices this row's field at — `GroundShape.field_distance()`
## over this row's own shape (D1's `body ⊕ disc` stationary, D2's `point ⊕ ellipse` moving), or the
## same kernel with no body at all for the handful of emitting rows with no shape (`playground`,
## whose look is drawn by the park itself rather than by `EventInstance`).
func _field_distance(world_position: Vector2, velocity: Vector2) -> float:
	if def.shape != null:
		return def.shape.field_distance(global_position, _solid_axis(), velocity, world_position)
	return GroundShape.eccentric_distance(global_position, velocity, world_position)

## A flock is its birds, summed.
##
## The same shape as `City.total_excitement_at` one level down: nothing is pushed anywhere, the
## sources compose by plain addition, and there is no ordering to get wrong. Each bird carries an
## equal share of the event's intensity over a radius that leaves room for the wheel, so the middle
## of the flock — where four or five fields overlap — comes out at about what the event says it is
## and the edge of it at a fraction. That gradient is the whole reason to do it this way: the price
## of a flock should depend on whether you walked through it or round it, and one disc centred on
## nothing in particular cannot say that.
##
## **Each bird is its own point kernel**, eccentric by its own `heading * speed` rather than the
## instance's own `travel_velocity()` (always zero for a flock — it is not itself `mobile` or
## `pursues`) — a cheap read off `Bird`, already carried for the wheel, so a bird diving toward her
## costs more than one peeling away exactly as any other moving point in the game does. The bodies
## stay points either way: a flock's own field was never a capsule, and eleven of them is not where
## the general capsule-and-ellipse sum earns its cost.
func _flock_contribution_at(world_position: Vector2, intensity := -1.0) -> float:
	var total_intensity := intensity if intensity >= 0.0 else current_intensity()
	var share := total_intensity / float(_flock.size())
	var outer := _bird_outer()
	var total := 0.0
	for bird in _flock:
		var d := GroundShape.eccentric_distance(global_position + bird.at, bird.heading * bird.speed,
				world_position)
		total += Tuning.falloff(d, share, def.inner_radius, outer)
	return total

## True when a point is inside the radius that ends the day, for a hard-fail event that is
## no longer merely telegraphing.
func is_lethal_at(world_position: Vector2) -> bool:
	if is_finished or is_leaving or is_waiting() or not def.hard_fail or is_telegraphing():
		return false
	return global_position.distance_to(world_position) <= def.inner_radius

## Points this event is projected to land on her over `Tuning.EXPECTED_IMPACT_HORIZON`, **her
## position held fixed and only this event moving** — the halo's own quantity (`landed()`, what
## actually reached the meter) read forward instead of back. Duck-typed with `CrowdAgent`'s own
## copy; see `ExcitementHalo`'s class doc for the shared shape and `wants_a_mark()` for what a
## result at or above `Tuning.EXPECTED_IMPACT_POINTS` does with the answer.
##
## **Her stillness is the whole of the direction the caret answers to.** *(2026-09-08, the player:
## "I don't want a caret when walking into a car from the side".)* A stationary source's own field
## does not change under this projection, so the sum below always equals `current_rate ×
## EXPECTED_IMPACT_HORIZON` and the subtraction cancels it to zero exactly — a café she is standing
## in expects nothing, which is the halo's job to say, not the caret's, from the moment she is in
## reach at all.
##
## **Projected at `_caret_velocity()` and `_caret_intensity()`, not `travel_velocity()` and
## `current_intensity()`.** The row's *live* course and rate, because the caret is asking what
## this thing is on its way to doing rather than what a telegraph currently has it doing: a
## telegraphing `cyclist` is already moving at its route speed (`travel_velocity()` already
## answers that), but reads at 15% of its own field the whole time it telegraphs — projecting the
## damped rate would keep the sum under the line until the telegraph is nearly over, the same gap
## a pursuer holding its stand-off would have if the caret read its own zeroed
## `travel_velocity()`. `current_rate` below is deliberately still the real, possibly-damped
## `contribution_at()` — what she is actually being charged right now — so the subtraction is the
## live approach minus the honest present, not the live approach minus itself.
##
## **Skipped without sampling once the reach cannot close inside the horizon.** `_caret_velocity()`
## is zero for anything genuinely waiting — nobody has been noticed yet, so there is no course to
## project — which is what keeps most of a live day's events, and every waiting pursuer, out of
## the loop below; only what could actually arrive pays for the twenty samples.
func expected_impact_at(player_position: Vector2) -> float:
	if is_finished or is_leaving or def.city_wide:
		return 0.0
	var velocity := _caret_velocity()
	var reach := velocity.length() * Tuning.EXPECTED_IMPACT_HORIZON + def.field_reach()
	if global_position.distance_to(player_position) > reach:
		return 0.0
	if velocity.is_zero_approx():
		return 0.0
	var current_rate := contribution_at(player_position)
	var live_intensity := _caret_intensity()
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	var landed := 0.0
	for i in steps:
		# Projecting the *source* forward by `velocity * t` and querying its field at her fixed
		# position is the same number as holding the source still and asking for its field at
		# `player_position - velocity * t` instead — `contribution_at` is already the query every
		# other caller uses, translated, so nothing here recomputes a falloff or a flock sum of
		# its own. `velocity` is passed a second time, as the override, so the ellipse the
		# translated point is measured against is oriented the same way the translation itself is —
		# see `contribution_at()`'s own doc for why the two must agree.
		landed += contribution_at(player_position - velocity * (float(i + 1) * dt), live_intensity,
				velocity) * dt
	return landed - current_rate * Tuning.EXPECTED_IMPACT_HORIZON

## Whether this event's own current course puts her inside the radius that ends the day at some
## point before `Tuning.EXPECTED_IMPACT_HORIZON`, her position held fixed — the same geometry
## `is_lethal_at()` tests, asked at every step of the same projection `expected_impact_at()`
## takes, rather than only at the position she is standing at now. The doubled caret's own
## question.
##
## **`is_lethal_at()`'s guards, minus its own telegraph gate.** A telegraphing `hard_fail` row
## cannot fire *yet* — that gate is exactly right for `is_lethal_at()`'s own callers, which ask
## whether it is lethal **right now** — but the caret is asking whether its course, once the
## telegraph clears, puts her inside the radius that ends the day, which a telegraphing row can
## answer just as truly as a live one: a `cyclist` ridden straight at her through its whole
## telegraph has to read red, or the doubled caret only ever appears in the last fraction of a
## second. `is_waiting()`, `is_finished` and `is_leaving` still refuse it — a waiting pursuer has
## not decided anything about her yet, so there is no course to be lethal on.
func will_be_lethal(player_position: Vector2) -> bool:
	if is_finished or is_leaving or is_waiting() or not def.hard_fail:
		return false
	var velocity := _caret_velocity()
	if velocity.is_zero_approx():
		return global_position.distance_to(player_position) <= def.inner_radius
	var dt := 0.25
	var steps := int(round(Tuning.EXPECTED_IMPACT_HORIZON / dt))
	for i in steps + 1:
		var future_at := global_position + velocity * (float(i) * dt)
		if future_at.distance_to(player_position) <= def.inner_radius:
			return true
	return false

# ------------------------------------------------------------------ drawing ---

func _draw() -> void:
	if is_finished:
		return
	if is_suppressed_by_its_own_hold():
		return
	var bob := _current_bob()
	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2.ONE)
	_draw_body()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_mark()

## Whether it is holding still through its telegraph — a crouching cat is not walking.
func is_telegraphing_still() -> bool:
	return def.still_while_telegraphing and is_telegraphing()

## The bob a moving event rides on: a stride's worth of lift, once per stride's worth of ground.
## Sized against a walking pace rather than a running one — 34px is roughly a step.
const BOB_PER_PX := PI / 34.0
const BOB_HEIGHT := 2.5

## **A moving event has to look like it is moving.** Without a gait a dog walker at 32px/s — a
## tile a second, against the player's three — slides along without a leg moving and reads as
## parked, which gets reported as *the dog walkers are not moving* when the movement is fine.
##
## A bob rather than a stride, because the art has legs drawn into it and a sprite cannot swing
## its own. Driven by **distance covered**, not by time, so it is the movement itself that shows:
## something stopped is still, and something fast bobs faster.
##
## Pulled out of `_draw()` so `EntityHalo` can ride the same lift: a walking entity's ring of
## re-drawn bodies has to bob with it, or the outline slides off the sprite it is meant to trace.
func _current_bob() -> float:
	if def.pursues or is_leaving:
		return -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	if def.mobile and def.speed > 0.0 and path.size() > 1 and not is_telegraphing_still():
		return -absf(sin(_path_travelled * BOB_PER_PX)) * BOB_HEIGHT
	return 0.0

# ------------------------------------------------------------------ the halo ---
# The ring itself is `EntityHalo`'s job now, shared with `CrowdAgent` — see that class for the
# offsets, the shared material, and why a `canvas_item` shader on this entity's own sprite could
# not have bloomed outward on its own.

## The drop shadow under an entity, drawn for the entity itself and skipped for its halo.
##
## *(2026-09-07, the player: "the halo should not include the shadow".)* `EntityHalo` re-runs
## `_draw_body()` on its own canvas to trace the silhouette, and the shadow is the first thing
## `_draw_body()` puts down — so without this the ellipse got traced too, putting a soft amber lobe
## on the pavement beside every glowing entity. **The shadow is not part of the thing**: it is the
## ground under it, and a cue that means *this is charging you* has nothing to say about the ground.
##
## Routed through here rather than guarded at each of the fifteen call sites, so a `_draw_*` helper
## added later gets the rule by using the same function every other one uses.
func _draw_shadow(canvas: CanvasItem, at: Vector2, radius: float) -> void:
	if canvas == _halo:
		return
	Sprites.draw_shadow(canvas, at, radius)

## The shadow for a row read off its own `GroundShape` rather than a fixed radius — every
## spread-drawn row (`_draw_spread`, `_draw_cafe`, `_draw_protest`, `_draw_firefight`,
## `_draw_wide_scene`'s own fallback) and the stationary vehicles (`_draw_stationary_vehicle`).
## Same halo guard as `_draw_shadow` above, routed through `shape.draw_shadow()` along
## `_solid_axis()` — a point shape ignores the axis, same as `GroundShape.draw_shadow()` does.
func _draw_shape_shadow(canvas: CanvasItem, shape: GroundShape, at: Vector2 = Vector2.ZERO) -> void:
	if canvas == _halo:
		return
	shape.draw_shadow(canvas, at, _solid_axis())

## This row's own body shadow: one `GroundShape` shadow per solid piece, at the piece's own offset
## along the spread axis. The single ellipse or capsule every row drew before, for anything that
## declares no parts; two patches under two cars for the one row that does, so the ground under a
## crash is dark where the cars are and lit where the picture leaves a way through.
func _draw_body_shadow(canvas: CanvasItem) -> void:
	for piece in def.parts():
		_draw_shape_shadow(canvas, piece.shape, _spread_at(piece.offset_for(_spread_vertical)))

## The ground-plane direction a spread-shaped shadow sweeps along — local Y when the street this
## instance stands on is east-west (`_spread_vertical`), local X otherwise. The same axis
## `_spread_at()` already lays the drawn body along.
func _spread_axis() -> Vector2:
	return Vector2.DOWN if _spread_vertical else Vector2.RIGHT

## The ground-plane direction this instance's own solid body's spine lies along, for whichever of
## the two families ever has a segment shape: a spread-drawn row (`_spread_axis()`, above) or the
## one stationary-vehicle row wide enough to be a segment (`moving_van` — see `GroundShape.band()`
## on that row), which lies along whichever of the street's axes `_stationary_vehicle_side` already
## draws it on. Never asked of a point shape, where an axis means nothing.
func _solid_axis() -> Vector2:
	if has_a_spread(def) or def.look == EventDef.Look.PROTEST or def.look == EventDef.Look.FIREFIGHT:
		return _spread_axis()
	return Vector2.RIGHT if _stationary_vehicle_side else Vector2.DOWN

## `_solid_axis()`, read by `DebugLayers` so its shadow and bounding-box layers rotate a segment
## the same way `_draw_shape_shadow()` and `_build_obstruction()` already do, rather than guessing
## an axis of their own.
func solid_axis() -> Vector2:
	return _solid_axis()

## Forwards to `_halo`'s own `set_glow()` — see `EntityHalo`'s class doc for the duck-typed shape
## `CrowdAgent` shares. Called by `ExcitementHalo` once a frame for every live instance — above
## zero for the handful `select_sources()` picked, zero for everything else. Refuses a nonzero
## glow once the event is finished, the same guard the halo's own drawing used to carry, because
## a finished event still sits in `EventManager.instances()` for one more frame than its
## `contribution_at()` (already zero) would otherwise buy it.
func set_halo_strength(strength: float, colour: Color) -> void:
	_halo.set_glow(0.0 if is_finished else strength, colour)

# ------------------------------------------------------------------ the mark ---
# **Nothing draws a field.** A ring communicates a falloff radius, which is a number, and a number
# is not a threat. What stands over an entity instead is a small mark, and it earns its place by
# three rules.

## How far above the entity the mark floats, and how big it is at full strength.
const MARK_HEIGHT := 44.0
const MARK_WIDTH := 15.0
const MARK_FLASHES_PER_SECOND := 3.0

## The caret's own answer, 0 (none), 1 (amber) or 2 (doubled red), computed once and cached
## against `age` — `wants_a_mark()`, `mark_colour()` and `_draw_mark()` all ask in the same frame,
## and each is a fresh sampling loop over `expected_impact_at()` or `will_be_lethal()` if they do
## not share one. **Cache per frame, the way the halo already does its own once-a-frame work**,
## rather than pricing the projection three times over for every visible source every draw.
var _caret_strength_age := -1.0
var _caret_strength_cache := 0

func _caret_strength() -> int:
	if _caret_strength_age == age:
		return _caret_strength_cache
	_caret_strength_age = age
	_caret_strength_cache = 0
	# A floor under the whole city has nothing to stand over — that is the HUD's job — and a
	# permanent feature of a fixed map never appears, so there is no moment to mark: the same
	# reason the fairness contract exempts an `AMBIENT` row.
	if not (is_finished or is_leaving or def.city_wide or def.kind == GameEnums.EventKind.AMBIENT):
		if will_be_lethal(player_at):
			_caret_strength_cache = 2
		elif expected_impact_at(player_at) >= Tuning.EXPECTED_IMPACT_POINTS:
			_caret_strength_cache = 1
	return _caret_strength_cache

## Whether this event is worth a mark at all.
##
## **The mark is raised by what a thing is projected to do to her, held still, and by nothing
## else.** *(2026-09-08, the player: "carets shouldn't be chosen by source value but by expected
## impact value".)* A row's own declared cost does not decide it — `expected_impact_at()` and
## `will_be_lethal()` do, at wherever she is
## actually standing and however this thing is actually moving, so the same row is marked at one
## moment and not at the next: a café she is standing in is unmarked, and a cyclist whose line
## reaches her is marked while one passing wide of her is not.
##
## **A stationary thing never earns a caret.** Held still, nothing about it changes under the
## projection — see `expected_impact_at()` — which is the halo's job from the moment she is in its
## field, not the caret's.
func wants_a_mark() -> bool:
	return _caret_strength() > 0

## How hard the mark is breathing, 0..1, from what the event is emitting right now.
##
## **This is the one thing the ring did that a symbol does not get for free**, and it is
## load-bearing: a pulsing event can be timed and slipped past between beats, and a mark that
## sat there at a constant size would turn the pulse envelope from something to play against
## into something random.
func mark_swell() -> float:
	if def.intensity <= 0.0:
		return 1.0
	return clampf(current_intensity() / def.intensity, 0.0, 1.0)

## What colour the mark is, and it means exactly one thing: **how bad this is.**
##
## **Colour is the wrong channel for a *phase*.** Amber while telegraphing and red once live is a
## good sentence and a cue nobody can read, because of **streaming**: `EVENT_STREAM_RADIUS` is 900px
## and no telegraph in the catalogue is longer than four seconds, so all but the `AHEAD_OF_PLAYER`
## rows finish telegraphing before they are anywhere near the screen. In play that makes amber mean
## *near* and red mean *far*, which is a colour carrying no information and being read as something
## else.
##
## **Follows the strength `_caret_strength()` computed, not `def.hard_fail`.** *(2026-09-08, the
## player: "we can keep the double red == lethal", then "and not all lethal things need a caret
## either".)* A `hard_fail` row still reads doubled red exactly when its own current course would
## put her inside the radius that ends the day — `will_be_lethal()` — and reads amber like anything
## else the rest of the time: a robber waiting in an alley she is not in carries no mark at all
## until he stands up and comes.
##
## So the colour is the scale and the **flash** — visible whether or not she was there when the
## event started — is what says it has not happened yet. See `_draw_mark`.
func mark_colour() -> Color:
	return Palette.MARK_LETHAL if _caret_strength() == 2 else Palette.MARK_COSTLY

## A caret over anything worth looking at, breathing with what it is currently emitting.
##
## What is deliberately *not* here: any drawing of where the danger reaches. Nothing draws a field.
func _draw_mark() -> void:
	if not wants_a_mark():
		return
	# **The flash is the phase**, and the only channel that can carry it: it flashes while
	# telegraphing — *this has not happened yet* — and is steady once it has. The colour cannot do
	# this, because a telegraph is usually over before the event is on screen; a flash is a property
	# of the mark rather than of a moment she had to be present for.
	if is_telegraphing() and fmod(age * MARK_FLASHES_PER_SECOND, 1.0) > 0.55:
		return

	var swell := mark_swell()
	# Never all the way to nothing: between beats the mark shrinks, it does not vanish, or a
	# pulsing event would read as flickering in and out of existence.
	var scale := 0.55 + 0.45 * swell
	var at := Vector2(0.0, -(MARK_HEIGHT + 10.0 * swell))
	Sprites.draw_caret(self, at, MARK_WIDTH * scale, mark_colour())
	if _caret_strength() == 2:
		# Doubled, so lethal reads at a glance and never has to be told apart by hue.
		Sprites.draw_caret(self, at - Vector2(0.0, MARK_WIDTH * scale * 0.85),
				MARK_WIDTH * scale, mark_colour())

## The single body-drawing entry point `_draw()` calls for the primary render and `EntityHalo`
## calls, repeatedly at a ring of offsets, for the halo — see `_build_halo()`. Gating it here
## rather than only in `_draw()` is what actually hides an alley post's own halo during its hold:
## `EntityHalo` never asks `_draw()`, it re-runs this function directly, and its own alpha fades
## over `EntityHalo.FADE_OUT_SECONDS` (0.8s) rather than cutting, which would have left a fading
## ring around a man who is not there for most of a two-second hold if this guard lived only in
## `_draw()`. Drawing nothing is instant either way; the fade timer keeps running underneath, so
## the ring reappears at whatever brightness it already had rather than fading back in. A hut or a
## gate keeps both its picture and its ring, because it never left.
func _draw_body(canvas: CanvasItem = self) -> void:
	if is_suppressed_by_its_own_hold():
		return
	match def.look:
		EventDef.Look.CAT:
			_draw_cat(canvas)
		EventDef.Look.MOUSE:
			_draw_simple(MOUSE, canvas)
		EventDef.Look.YELLER:
			_draw_eight_view(YELLER_BY_VIEW, _heading, canvas)
		EventDef.Look.DOG_WALKER:
			_draw_dog_walker(canvas)
		EventDef.Look.CAFE:
			_draw_cafe(canvas)
		EventDef.Look.DELIVERY_VAN:
			# Always sited facing east — `AT_THE_KERB` never overrides `EventScheduler.Planned.
			# facing`'s own default — so `side_faces_west` now mirrors the parked van where
			# `_draw_simple`'s old `_heading_is_west()` check never did: that check assumed every
			# side picture faces east, and `delivery_van.svg` is one of the ones that does not (see
			# `docs/evidence/svg-vehicles-2026-09-10/README.md`). A cosmetic change to an
			# already-shipped picture, not a bug fix to gameplay: nothing about its shape, shadow or
			# obstruction moves.
			_draw_eight_view(DELIVERY_VAN_BY_VIEW, _heading, canvas, true)
		EventDef.Look.BUSKER:
			_draw_eight_view(BUSKER_BY_VIEW, _heading, canvas)
		EventDef.Look.ROADWORKS:
			_draw_spread(BARRIER_SEGMENT, BARRIER_END, canvas)
		EventDef.Look.FIRE_ENGINE:
			_draw_eight_view(FIRE_ENGINE_BY_VIEW, _heading, canvas, true)
		EventDef.Look.BURNING_BUILDING:
			_draw_fire(canvas)
		EventDef.Look.BURNT_SHELL:
			_draw_spread(RUBBLE, null, canvas)
		EventDef.Look.LOOSE_DOG:
			_draw_loose_dog(canvas)
		EventDef.Look.STALL:
			_draw_spread(STALL, null, canvas)
		EventDef.Look.LEAF_BLOWER:
			_draw_eight_view(LEAF_BLOWER_BY_VIEW, _heading, canvas)
		EventDef.Look.BIRDS:
			_draw_birds(canvas)
		EventDef.Look.CYCLIST:
			_draw_eight_view(CYCLIST_BY_VIEW, _heading, canvas)
		EventDef.Look.ICE_CREAM_VAN:
			# East-authored: always sited facing east, same as `DELIVERY_VAN` above, but
			# `ice_cream_van.svg` is one of the sources that already faces east, so no
			# `side_faces_west` override and no change to the picture it draws.
			_draw_eight_view(ICE_CREAM_VAN_BY_VIEW, _heading, canvas)
		EventDef.Look.LORRY:
			# `reversing_lorry`'s own facing is always exactly east or west — `AGAINST_THE_BUILDING`
			# sets it to `-pavement_inward`, which `_wants_this_side` already refuses unless it is
			# purely horizontal — so the diagonal and front/back views this table adds are never
			# actually reachable; the row keeps drawing exactly the side view it always did.
			_draw_eight_view(LORRY_BY_VIEW, _heading, canvas)
		EventDef.Look.CHARGING_DOG:
			_draw_eight_view(CHARGING_DOG_BY_VIEW, _heading, canvas)
		EventDef.Look.CHATTING_MOTHER:
			_draw_chatting_mother(canvas)
		EventDef.Look.POLICE_CAR:
			# East-authored — see `ICE_CREAM_VAN` above — and now a real octant: `police_patrol` is
			# mobile and turns corners along its own patrol route, so this is the first vehicle row
			# whose diagonal views are ordinarily reachable rather than a dead branch.
			_draw_eight_view(POLICE_CAR_BY_VIEW, _heading, canvas)
		EventDef.Look.POSTER_CREW:
			_draw_eight_view(POSTER_CREW_BY_VIEW, _heading, canvas)
		EventDef.Look.ROADBLOCK:
			_draw_roadblock(canvas)
		EventDef.Look.UNMARKED_VAN:
			_draw_abduction(canvas)
		EventDef.Look.ROBBER:
			_draw_robber(canvas)
		EventDef.Look.RIOT_VAN:
			# West-authored, like `unmarked_van` and `army_truck` — see `RIOT_VAN_BY_VIEW`'s own doc
			# comment above for why the side view needs the `side_faces_west` override to match
			# `facings.csv` rather than M56's hand-written octant match, which had it backwards.
			_draw_eight_view(RIOT_VAN_BY_VIEW, _heading, canvas, true)
		EventDef.Look.ARMY_TRUCK:
			_draw_eight_view(ARMY_TRUCK_BY_VIEW, _heading, canvas, true)
		EventDef.Look.BARRICADE:
			_draw_spread(BARRICADE_PILE, null, canvas)
		EventDef.Look.PROTEST:
			_draw_protest(canvas)
		EventDef.Look.FIREFIGHT:
			_draw_firefight(canvas)
		EventDef.Look.FALLEN_TREE:
			_draw_wide_scene(_wide_scene_texture(EventDef.Look.FALLEN_TREE, _spread_vertical), canvas)
		EventDef.Look.CAR_ACCIDENT:
			_draw_wide_scene(_wide_scene_texture(EventDef.Look.CAR_ACCIDENT, _spread_vertical), canvas)
		EventDef.Look.BURST_MAIN:
			_draw_wide_scene(_wide_scene_texture(EventDef.Look.BURST_MAIN, _spread_vertical), canvas)
		EventDef.Look.COLLAPSED_FRONTAGE:
			_draw_spread(COLLAPSED_FRONTAGE, null, canvas)
		EventDef.Look.SCAFFOLDING:
			_draw_spread(SCAFFOLDING, null, canvas)
		EventDef.Look.SKIP:
			_draw_simple(SKIP, canvas)
		EventDef.Look.MOVING_VAN:
			_draw_stationary_vehicle(EventDef.Look.MOVING_VAN, def.obstructs_radius * 2.0, canvas)
		EventDef.Look.BURNT_OUT_CAR:
			_draw_stationary_vehicle(EventDef.Look.BURNT_OUT_CAR, def.obstructs_radius * 2.0, canvas)
		EventDef.Look.CHECKPOINT_HUT:
			_draw_checkpoint_hut(canvas)
		EventDef.Look.CHECKPOINT_GATE:
			_draw_checkpoint_gate(canvas)
		EventDef.Look.CHECKPOINT_POST:
			# The guard's own picture is person-scale, but his shape is the checkpoint's own —
			# one body covers the whole 64px alley mouth, same as `checkpoint_hut`'s hut. See
			# `EventCatalogue._checkpoint_post`.
			_draw_body_shadow(canvas)
			_draw_at_anchor(canvas, GUARD_STANDING, _GUARD_ANCHOR)
		EventDef.Look.NONE:
			pass

## A shadow and a sprite, facing the way it is going. What most looks are, and having it once is
## what keeps a dozen near-identical three-line functions from existing.
func _draw_simple(texture: Texture2D, canvas: CanvasItem = self) -> void:
	_draw_body_shadow(canvas)
	Sprites.draw_standing(canvas, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())

## The five-view generalisation of `_draw_simple`, for a family that has the full
## front/back/side/diagonal set — `_select_view()` picks the view from `heading` and
## `EightDirection.is_mirrored()` says whether it mirrors, for every sector but one.
##
## **`side_faces_west` is the one bit `EightDirection` cannot answer, because it is a property of
## the art rather than of the geometry.** `is_mirrored()` mirrors exactly the three west sectors on
## the assumption every family's `"side"` picture is authored facing east, which holds for most —
## `police_car`, `ice_cream_van`, `lorry` and every person/animal/rider family bound before this one
## — but not for `delivery_van`, `fire_engine`, `unmarked_van` and `army_truck`, whose side pictures
## place the cab at the left (`docs/evidence/svg-vehicles-2026-09-10/README.md`). Passing `true`
## flips the mirror flag for the `"side"` view alone; every diagonal and front/back view already
## mirrors the same way regardless, since each is authored facing its own specific compass point
## rather than shared between two.
##
## `night_raid`'s van reaches this same helper through `RIOT_VAN_BY_VIEW` with the
## `side_faces_west` override set, the same as `delivery_van`, `fire_engine`, `unmarked_van` and
## `army_truck` above — see that const's own doc comment.
##
## `_draw_simple` itself is untouched and keeps drawing every row that has no directional family at
## all: `mouse` and `skip`.
func _draw_eight_view(by_view: Dictionary, heading: Vector2, canvas: CanvasItem = self,
		side_faces_west := false) -> void:
	_draw_body_shadow(canvas)
	var view := _select_view(heading)
	var mirror := EightDirection.is_mirrored(_view_sector)
	if view == "side" and side_faces_west:
		mirror = not mirror
	Sprites.draw_standing(canvas, by_view[view], Vector2.ZERO, Vector2.ZERO, mirror)

## A stationary vehicle projected along the axis of the street it occupies. Its side silhouette
## may mirror with its facing; an end-on silhouette keeps its authored proportions and orientation.
## Its shadow is `def.shape` — a point for `burnt_out_car`, a capsule along the street for
## `moving_van`, whose `obstructs_radius` clears `GroundShape.BAND_RADIUS` — rather than a
## hand-picked radius of its own.
func _draw_stationary_vehicle(look: EventDef.Look, side_width: float,
		canvas: CanvasItem = self) -> void:
	var texture := _stationary_vehicle_texture(look, _stationary_vehicle_side)
	var extent := _stationary_vehicle_extent(texture, _stationary_vehicle_side, side_width)
	_draw_body_shadow(canvas)
	Sprites.draw_standing(canvas, texture, Vector2.ZERO, extent,
			_stationary_vehicle_side and _heading_is_west())

## The dog, and the lead it is no longer on.
##
## Read against `_draw_dog_walker()`, which draws the lead *taut between two bodies*: that is
## the span it owns and the reason to cross the street. Here the same lead trails on the ground
## behind one body, and the difference between the two pictures is the whole event.
func _draw_loose_dog(canvas: CanvasItem = self) -> void:
	var behind := Vector2(26.0 if _heading_is_west() else -26.0, 0.0)
	_draw_body_shadow(canvas)
	# On the ground and slack, not held up at hip height. Nobody is holding it. The lead's own
	# offset stays a plain east/west span — a composite the picture underneath it does not own,
	# same as `_draw_dog_walker`'s taut one.
	canvas.draw_line(Vector2(0.0, -8.0), behind + Vector2(0.0, -2.0), Palette.OUTLINE, 2.0)
	var view := _select_view(_heading)
	Sprites.draw_standing(canvas, DOG_BY_VIEW[view], Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## Every bird, drawn where it actually is.
##
## There is no `rise` term and no shared phase any more — see "the flock" above. What is left here
## is only the picture: each bird on its own beat, each with a shadow on the pavement under it that
## shrinks and fades as it climbs, and the whole flock painted back to front so a bird in front
## overlaps the one behind rather than fighting it for the same pixel every frame.
##
## The shadow is what sells the height, and it is the reason a bird 40px up does not simply read as
## a bird standing 40px further north.
func _draw_birds(canvas: CanvasItem = self) -> void:
	var order: Array[int] = []
	for i in _flock.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return _flock[a].at.y < _flock[b].at.y)
	for i in order:
		var bird := _flock[i]
		if bird.lift < BIRD_SHADOW_CEILING:
			# Smaller and fainter the higher it is, and gone by the time it is over the rooftops.
			var faded := 1.0 - bird.lift / BIRD_SHADOW_CEILING
			_draw_shadow(canvas, bird.at, 5.0 * faded)
		# Each bird holds its own sector — a flock is eleven bodies wheeling independently, not one
		# actor with one facing — through the same hold `_select_view()` gives the instance itself.
		bird.view_sector = EightDirection.update(bird.view_sector, bird.heading)
		var view: String = EIGHT_VIEW_BY_SECTOR[bird.view_sector]
		var mirror := EightDirection.is_mirrored(bird.view_sector)
		var wings: Texture2D = PIGEON_BY_VIEW[view] if sin(bird.phase) >= 0.0 else PIGEON_DOWN_BY_VIEW[view]
		if bird.lift <= 0.0:
			# Standing. The upstroke is a bird in flight, and a pavement full of them is a flock
			# that has already gone — which is the thing the telegraph exists to show her instead.
			wings = PIGEON_DOWN_BY_VIEW[view]
		Sprites.draw_standing(canvas, wings, bird.at - Vector2(0.0, bird.lift), Vector2.ZERO, mirror)

## How high a bird's shadow survives to. Roughly first-floor height: above it, there is nothing on
## the pavement to cast one onto that the player can see.
const BIRD_SHADOW_CEILING := 46.0

func _draw_cat(canvas: CanvasItem = self) -> void:
	# Crouched while telegraphing, stretched out once it bolts. The crouch *is* the
	# telegraph, so the two silhouettes have to differ at a glance, not by a scale factor.
	var by_view := CAT_CROUCHED_BY_VIEW if is_telegraphing() else CAT_RUNNING_BY_VIEW
	_draw_body_shadow(canvas)
	var view := _select_view(_heading)
	Sprites.draw_standing(canvas, by_view[view], Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## Hood up and hands in the coat while he is only somewhere; leaning out over a forward leg once
## he has taken an interest.
##
## The same rule as the cat above, at the one row where reading it wrong ends the run: the two
## postures are the two states `EventDef.pursues_within` invented, and `is_waiting()` is exactly
## the line between them. What the player has to be able to see from an alley mouth is not "there
## is a man there" but *which of the two men that is* — so the change of posture happens on the
## frame he notices her, before the telegraph has finished and well before he moves.
func _draw_robber(canvas: CanvasItem = self) -> void:
	_draw_body_shadow(canvas)
	var by_view := ROBBER_WAITING_BY_VIEW if is_waiting() else ROBBER_LUNGING_BY_VIEW
	# Once he has noticed her, `_chase()` already keeps `_heading` pointed at her for every frame of
	# the telegraph and the lunge alike — `_draw_body()`'s ordinary reading, `_heading`. Before that
	# he has nothing of his own to face except the alley he was sited in, and a man only watching
	# the street is worth nothing next to a man watching *her* — see `_robber_waiting_heading()`.
	var heading := _robber_waiting_heading() if is_waiting() else _heading
	var view := _select_view(heading)
	Sprites.draw_standing(canvas, by_view[view], Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## Which way the waiting posture faces: her, from the moment a caller has told this instance where
## she is (`set_player_at()`), since that is the one thing worth turning toward before he has
## actually noticed her — `_chase()`'s own `is_waiting()` branch does not move `_heading` until she
## is inside `pursues_within`, see that function's doc. Falls back to the site's own authored
## facing where no player position is known at all, the harmless default a data-level rig gets.
func _robber_waiting_heading() -> Vector2:
	if player_at != Vector2.INF:
		var toward := player_at - global_position
		if toward.length_squared() > 0.0001:
			return toward
	return _heading

## The band while its guards are still posted, a guard once they leave — `is_waiting()` is the same
## switch `_draw_robber()` reads above, then `is_telegraphing()` again within that for which of the
## two guard postures: `guard_standing.svg` while it is closing to its stand-off, `guard_lunging.svg`
## once it actually gives chase. Below `Tuning.HEAT_HUNTS_LEVEL`, `def.pursues` is always false, so
## a cold or under-threshold roadblock only ever reaches the band.
##
## **The band stays exactly as it is until the guards leave, and nothing is left standing once they
## have.** `def.shape` — the band's own 60px capsule — is what both the drawn barrier and its
## collision body (`_build_obstruction()`) are built from; the generic pursuer rule in `_process()`
## frees that same body the frame `is_waiting()` turns false, so the picture and the physical street
## agree throughout: manned and solid, then neither.
func _draw_roadblock(canvas: CanvasItem = self) -> void:
	if def.pursues and not is_waiting():
		_draw_shadow(canvas, Vector2.ZERO, _GUARD_SHADOW_RADIUS)
		var texture := GUARD_STANDING if is_telegraphing() else GUARD_LUNGING
		Sprites.draw_standing(canvas, texture, Vector2.ZERO, Vector2.ZERO, _heading_is_west())
		return
	_draw_spread(ROADBLOCK_SEGMENT, ROADBLOCK_END, canvas)

## Flames scaled by what the event is currently emitting, so a fire visibly roars.
func _draw_fire(canvas: CanvasItem = self) -> void:
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.2, 1.0)
	_draw_body_shadow(canvas)
	for i in 5:
		var offset := (i - 2.0) * 11.0
		var flicker := 1.0 + 0.25 * sin(age * 9.0 + i * 1.7)
		var height := (34.0 + i % 2 * 14.0) * strength * flicker
		Sprites.draw_standing(canvas, FLAME, Vector2(offset, 0.0), Vector2(18.0, height))

## A point `offset` along whichever axis `_spread_vertical` says this instance spreads on — local X
## by default, local Y on an east-west street. See `_spread_is_vertical`.
func _spread_at(offset: float) -> Vector2:
	return Vector2(0.0, offset) if _spread_vertical else Vector2(offset, 0.0)

## The draw size for one slice of a spread: `along` is its length down the axis it spreads on,
## `thickness` is its extent across that axis, swapped into `(x, y)` for whichever axis that is —
## so a segment stays as tall as the art says on a north-south street and as wide as the art says
## on an east-west one, whichever axis "tall" turns out to be.
func _spread_extent(along: float, thickness: float) -> Vector2:
	return Vector2(thickness, along) if _spread_vertical else Vector2(along, thickness)

## A blocking object is drawn at exactly the width it obstructs, by repeating a segment
## across it. Anything else would be a lie about where the player can walk.
##
## **The end cap is inset by half its own width, for the same reason.** A cap centred at `±half`
## hangs half its own width past the obstruction — `barrier_end.svg` is 6px wide, so a `construction`
## barrier obstructs 64px and used to draw 70 — which is the picture claiming ground the collision
## does not hold. Insetting so the cap's *outer* edge lands on `±half` instead makes the drawn extent
## equal the obstructed one, matching the segments above rather than overhanging them.
func _draw_spread(segment_texture: Texture2D, cap: Texture2D = null, canvas: CanvasItem = self) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	_draw_body_shadow(canvas)
	var segment := segment_texture.get_size()
	var along_natural := segment.y if _spread_vertical else segment.x
	var thickness := segment.x if _spread_vertical else segment.y
	var segments := maxi(1, ceili(half * 2.0 / along_natural))
	var width := half * 2.0 / segments
	for i in segments:
		Sprites.draw_standing(canvas, segment_texture,
				_spread_at(-half + width * (i + 0.5)), _spread_extent(width, thickness))
	if not cap:
		return
	var cap_size := cap.get_size()
	var cap_along := cap_size.y if _spread_vertical else cap_size.x
	var cap_thickness := cap_size.x if _spread_vertical else cap_size.y
	for side in [-1.0, 1.0]:
		Sprites.draw_standing(canvas, cap, _spread_at(_cap_offset(half, cap_along, side)),
				_spread_extent(cap_along, cap_thickness))

## A whole-scene picture is one body, including on an east-west street. Its vertical asset is
## fitted to the obstruction's diameter, so its standing point moves to the far end of the
## obstruction: `Sprites.draw_standing` anchors the bottom edge, while this scene must span both
## sides of the ground point. Only the three wide scenes use this path; segmented looks keep the
## repeated standing anchors above unchanged.
func _draw_wide_scene(texture: Texture2D, canvas: CanvasItem = self) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	var size := texture.get_size()
	var thickness := size.x if _spread_vertical else size.y
	var extent := _spread_extent(half * 2.0, thickness)
	var anchor := _wide_scene_anchor(_spread_vertical, half)
	var shadow := _wide_scene_shadow(texture)
	if shadow and canvas != _halo:
		canvas.draw_texture_rect(TextureResolver.resolve(shadow),
				Rect2(anchor - Vector2(extent.x * 0.5, extent.y), extent),
				false, Palette.SHADOW)
	else:
		# No authored ground-contact art for this axis (only `car_accident` has one either way) —
		# the shape's own capsule shadow follows the same span as the body, `-half` to `half`
		# along the spread axis.
		_draw_body_shadow(canvas)
	Sprites.draw_standing(canvas, texture, anchor, extent)

static func _wide_scene_anchor(vertical: bool, half: float) -> Vector2:
	return Vector2(0.0, half) if vertical else Vector2.ZERO

## The along-axis offset for one end cap, inset from `±half` by half the cap's own extent on that
## axis so its outer edge lands on the obstruction boundary rather than past it — see `_draw_spread`.
## A pure function so a test can assert the arithmetic directly, against the same asset size and
## `obstructs_radius` the drawing itself uses, rather than by parsing what `draw_texture_rect`
## painted.
static func _cap_offset(half: float, cap_along: float, side: float) -> float:
	return side * (half - cap_along * 0.5)

## The tables, and the people at them.
##
## **Both halves have to be drawn**: the tables are what obstructs and the conversation is what it
## emits, so a café drawn as furniture alone is the loudest pleasant thing in act I looking like
## something somebody left out. The spread is `_draw_spread`'s, so the width is exactly the width in
## the way; the sitters are drawn *first* and a little behind, because the table is the part she
## cannot walk through and the picture has to agree with that.
##
## Alternate tables are mirrored, which turns a rank of clones into pairs facing each other — the
## same reason a spoiled park rolls a different def per cell. The chair's own shift stays *along*
## the spread axis, same as the table it sits beside; the −7 lift is a fixed screen-depth nudge that
## puts a sitter visibly behind their table whichever way the row runs, so it stays a plain Y offset
## rather than turning with the spread.
func _draw_cafe(canvas: CanvasItem = self) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	_draw_body_shadow(canvas)
	# Every sitter shares one view and one mirror — the frontage is sited once and never turns, and
	# a party at the same table facing in different directions is not a picture this row ever drew.
	var view := _select_view(_heading)
	var sitter: Texture2D = CAFE_SITTER_BY_VIEW[view]
	var mirror := EightDirection.is_mirrored(_view_sector)
	var segment := CAFE_TABLE.get_size()
	var along_natural := segment.y if _spread_vertical else segment.x
	var thickness := segment.x if _spread_vertical else segment.y
	var segments := maxi(1, ceili(half * 2.0 / along_natural))
	var width := half * 2.0 / segments
	for i in segments:
		var along := -half + width * (i + 0.5)
		# The chair is drawn at one end of the table sprite and turns round with it.
		var chair_along := along + width * (0.26 if i % 2 == 1 else -0.26)
		Sprites.draw_standing(canvas, sitter, _spread_at(chair_along) + Vector2(0.0, -7.0),
				Vector2.ZERO, mirror)
	for i in segments:
		var along := -half + width * (i + 0.5)
		Sprites.draw_standing(canvas, CAFE_TABLE,
				_spread_at(along), _spread_extent(width, thickness), i % 2 == 1)

## The eight pointing poses, in the bearing order `_protester_texture()` indexes into: north
## first, then clockwise. Kept beside the poses themselves rather than built in the function, so
## the table is one thing to read rather than eight `match` arms.
const _POINTING_POSES: Array[Texture2D] = [
	PROTESTER_POINT_N, PROTESTER_POINT_NE, PROTESTER_POINT_E, PROTESTER_POINT_SE,
	PROTESTER_POINT_S, PROTESTER_POINT_SW, PROTESTER_POINT_W, PROTESTER_POINT_NW,
]

## The plain rank, or whichever of the eight `protester_point_*` poses points closest to
## `objective` from `from`. `Vector2.INF` is "nothing to point at" — a chalk-mark step or no step
## at all — and draws the same plain `PROTESTER` the row always used. *(2026-09-11, the player:
## "the mark is findable now -- I don't think we need pointing for that. but the other tasks are
## not as easy and need pointing.")*
##
## The bearing is `TelemetryLog.compass()`'s own arithmetic — clockwise from north (`-y`), through
## east (`+x`) at 90° — rounded to the nearest of the eight 45° sectors the poses were drawn for.
static func _protester_texture(from: Vector2, objective: Vector2) -> Texture2D:
	if objective == Vector2.INF:
		return PROTESTER
	var toward := objective - from
	if toward.length_squared() < 0.0001:
		return PROTESTER
	var bearing := rad_to_deg(atan2(toward.x, -toward.y))
	var sector := roundi(bearing / 45.0) % 8
	if sector < 0:
		sector += 8
	return _POINTING_POSES[sector]

## The resistance director's own read-only `pointable_objective()`, found the same way `Baby`
## finds `WorldContext` and `ResistanceDirector` finds the player — a group looked up once and
## cached, since nothing here is handed a reference by whoever built the scene. `Vector2.INF` with
## no director in the tree, which a bare test rig simply never has: `_draw_protest` already treats
## that as "nothing to point at".
var _resistance: ResistanceDirector

func _protest_objective() -> Vector2:
	if not (_resistance and is_instance_valid(_resistance)):
		var tree := get_tree()
		if tree == null:
			return Vector2.INF
		_resistance = tree.get_first_node_in_group("resistance") as ResistanceDirector
	if not _resistance:
		return Vector2.INF
	return _resistance.pointable_objective()

## A rank of placards as wide as the ground it takes.
##
## The catalogue used to say of this row: *"one person's worth, because one person is what it
## draws… the art is the fix."* This is the fix, and the body follows it rather than the other way
## round — a protest that fills a square is the whole content of the event, and it could not have
## one until there was a picture of one.
##
## Two ranks rather than one, offset, so it reads as a crowd with depth instead of a queue; the
## back rank is drawn first and higher up the screen. Nothing here grows with `intensity_ramp` —
## the caret over it already breathes with what it is emitting, and a crowd that visibly recruits
## would be a second cue saying the same thing.
##
## **Every body in the rank shares one pose.** They stand within a few tens of pixels of each
## other and the objective is blocks away, so the bearing from any one of them to it is the same
## bearing to within a sector; asking once for the whole rank is the same picture a per-body ask
## would draw, for a fortieth of the cost.
func _draw_protest(canvas: CanvasItem = self) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	_draw_body_shadow(canvas)
	var texture := _protester_texture(global_position, _protest_objective())
	var mirror := false
	# `PROTESTER` is `_protester_texture()`'s own sentinel for "nothing to point at" — a mark step
	# or no step at all — which is exactly a stationary actor with no target: the rank's own site
	# facing picks its view instead, the same as `busker` or `poster_crew`. Left as a sentinel check
	# rather than a change to `_protester_texture()` itself, so `tests/test_protest.gd`'s own
	# contract (a plain pose is exactly `EventInstance.PROTESTER`) keeps holding: the eight
	# `protester_point_*` poses stay exactly as M65 bound them, unmirrored, since each is its own
	# authored direction rather than a member of the mirrored five-view family.
	if texture == PROTESTER:
		var view := _select_view(_heading)
		texture = PROTESTER_BY_VIEW[view]
		mirror = EightDirection.is_mirrored(_view_sector)
	# Spaced off the body rather than off the sprite, so the rank ends where the ground it takes
	# ends. A crowd drawn at its own natural spacing overhangs its own body by most of a person,
	# which is the lie `_draw_spread` exists to avoid in the other direction. Off `texture`'s own
	# width rather than the plain pose's, because a pointing pose's placard arm doubles it.
	var across := maxi(2, roundi(half * 2.0 / (texture.get_size().x * 0.8)))
	var step := half * 2.0 / across
	for rank in 2:
		var back := rank == 0
		var lift := -14.0 if back else 0.0
		var shift := step * 0.5 if back else 0.0
		for i in across - (1 if back else 0):
			var x := -half + step * (i + 0.5) + shift
			Sprites.draw_standing(canvas, texture, Vector2(x, lift), Vector2.ZERO, mirror)

## People behind cover, shooting at each other. Not a building on fire, which is what it drew for
## fourteen milestones — the same five flames as `burning_building`, on the one event in the
## catalogue whose content is that there are *people* doing this.
##
## The flashes are drawn rather than authored, because a muzzle flash is a light and not an object,
## and they are timed off the pulse envelope so they land on the beat the meter is already moving
## on. Between beats there is nothing but two shapes behind sandbags, which is the point: it is a
## thing to time a run past, and `can_be_timed()` already says so.
func _draw_firefight(canvas: CanvasItem = self) -> void:
	var half := maxf(11.0, def.obstructs_radius)
	_draw_body_shadow(canvas)
	var strength := 1.0
	if def.intensity > 0.0:
		strength = clampf(current_intensity() / def.intensity, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		var at := Vector2(side * half * 0.62, 0.0)
		Sprites.draw_standing(canvas, GUNMAN, at, Vector2.ZERO, side > 0.0)
		# Sized off the current emission and jittered per side, so the two are never in step.
		var flare := strength * (0.6 + 0.4 * sin(age * 17.0 + side * 2.1))
		if flare <= 0.25:
			continue
		var muzzle := at + Vector2(side * 15.0, -12.0)
		canvas.draw_circle(muzzle, 3.0 + 4.0 * flare, MUZZLE_FLASH)
		canvas.draw_circle(muzzle, 1.5 + 2.0 * flare, Color.WHITE)

## A muzzle flash is a *light*, and it must not borrow the amber the danger vocabulary uses for its
## marks. Two things that mean different things must not share a constant, or a rebalance of one
## silently repaints the other.
const MUZZLE_FLASH := Color("e8b64a")

## The person, the dog, and the lead between them.
##
## The lead is drawn because it is the mechanic: what makes a dog walker worth crossing the
## street for is the span it owns, and a span you cannot see is a span you walk into. The dog
## leads on the side the walker is heading, so the pair reads as being dragged along.
func _draw_dog_walker(canvas: CanvasItem = self) -> void:
	var reach := def.inner_radius * 0.8
	# The lead's own span stays a plain east/west offset — a composite the walker's own picture
	# does not own, unaffected by which of the eight views that picture now is.
	var to_the_dog := Vector2(-reach if _heading_is_west() else reach, 0.0)
	_draw_body_shadow(canvas)
	# The dog's own shadow, not the row's shape — a two-body composite has no single shape to be
	# either of its bodies, so this one is a per-part point like the abduction's victim.
	_draw_shadow(canvas, to_the_dog, 9.0)
	# Slack in the middle, so it reads as a lead rather than as a bar.
	canvas.draw_line(Vector2(0.0, -26.0), to_the_dog + Vector2(0.0, -6.0), Palette.OUTLINE, 2.0)
	# The dog faces the walker's own travel — the same heading, the same view, the same mirror —
	# since it is being led rather than watching anything of its own.
	var view := _select_view(_heading)
	var mirror := EightDirection.is_mirrored(_view_sector)
	Sprites.draw_standing(canvas, PERSON_BY_VIEW[view], Vector2.ZERO, Vector2.ZERO, mirror)
	Sprites.draw_standing(canvas, DOG_BY_VIEW[view], to_the_dog, Vector2.ZERO, mirror)

## The van, and the bystander it is taking while there is one to draw.
##
## `_draw_dog_walker` above is the precedent for a second figure with its own offset; here the
## second figure has a scene rather than a fixed span, sliding from `VICTIM_STANDING_OFFSET` to
## the van's own position over `VICTIM_TAKEN_OVER` — see `_update_the_take()`, the only place that
## ever sets `_victim_taken_at`. Drawn first so the van's own silhouette is what she is left
## looking at once the walk ends, the same order `_draw_cafe` draws its sitters before its tables.
##
## The van itself goes through `_draw_eight_view` rather than `_draw_simple`: a parked van never
## needed more than one side-on picture, but a hunting one steers straight at her and that is not
## always down a pavement, so it draws the full front/back/side/diagonal set the same way `police_car`
## does once it turns off its own axis.
## The victim and the van share one `_view_sector` field — safely, because both headings are always
## exactly east or west by construction while they can ever be drawn together. `is_taking_a_victim()`
## is only ever true while the van `is_waiting()` (`_update_the_take()` abandons it the instant a
## `HUNTS`-heated copy starts hunting), and idling the van's own `_heading` is `Planned.facing`'s
## untouched default, always due east — so the van's own `_select_view(_heading)` call below, after
## the victim's, only ever asks for exactly the sector the victim's own call left it on (both facing
## the same way) or its exact opposite (180° apart, always past `EightDirection`'s hold), never
## anything a stale hold could get wrong.
func _draw_abduction(canvas: CanvasItem = self) -> void:
	if is_taking_a_victim():
		var through := (age - _victim_taken_at) / VICTIM_TAKEN_OVER
		var standing := Vector2(
				-VICTIM_STANDING_OFFSET if _heading_is_west() else VICTIM_STANDING_OFFSET, 0.0)
		var at := standing.lerp(Vector2.ZERO, through)
		_draw_shadow(canvas, at, 8.0)
		# She faces the van, which is the only place she is walking to — a pure east/west direction
		# by construction (`standing` never has a Y component), so this always resolves to the same
		# side view `_heading_is_west()` picked before, now read off the shared table.
		var view := _select_view(-standing)
		Sprites.draw_standing(canvas, VAN_VICTIM_BY_VIEW[view], at, Vector2.ZERO,
				EightDirection.is_mirrored(_view_sector))
	# West-authored, like `delivery_van` and `fire_engine` above — see `_draw_eight_view()`'s own
	# doc comment on `side_faces_west`.
	_draw_eight_view(UNMARKED_VAN_BY_VIEW, _heading, canvas, true)

## Another mother with a pram — one picture, two postures. Strolling is what she looks like for the
## whole of her beat; talking is what she looks like for exactly the `detain_seconds` of a
## conversation, and it is the only telegraph that mechanic gets — there is no exclamation mark,
## because she is a cost rather than a threat and that mark is spoken for. See
## `docs/EVENTS.md`, "The visual vocabulary".
func _draw_chatting_mother(canvas: CanvasItem = self) -> void:
	_draw_body_shadow(canvas)
	var by_view := CHATTING_MOTHER_TALKING_BY_VIEW if is_chatting() else CHATTING_MOTHER_WALKING_BY_VIEW
	var view := _select_view(_heading)
	Sprites.draw_standing(canvas, by_view[view], Vector2.ZERO, Vector2.ZERO,
			EightDirection.is_mirrored(_view_sector))

## Which way a mobile event is travelling, for art that has a front and a back. A
## stationary event never flips.
func _heading_is_west() -> bool:
	return _heading.x < 0.0

## Advances `_view_sector` from `heading` and returns the view name to read out of whichever
## family's own `_BY_VIEW` table is live — `CrowdAgent._update_walker_view()`'s own shape, copied
## rather than shared since an event and a walker have no common base to hang one field on. No
## idle floor of its own: every `heading` a caller below feeds in is already a unit vector that is
## never actually zero — a moving actor's `_heading` is only ever overwritten by an actual step or
## an actual notice, and a stationary one's is its own fixed siting — the same reason `Stroller`
## never passes one either (`EightDirection.update()`'s own doc). Safe to call more than once a
## frame with the same heading: `EntityHalo` redraws `_draw_body()` once per ring, and asking
## `EightDirection.update()` twice from the same starting sector always answers the same way.
func _select_view(heading: Vector2) -> String:
	_view_sector = EightDirection.update(_view_sector, heading)
	return EIGHT_VIEW_BY_SECTOR[_view_sector]

# ------------------------------------------------------------- the region door ---
# The checkpoint kit: `docs/GRAPHICS.md` binds each row to the file it draws. See `RegionPlanner`
# for where the bodies stand and `EventManager` for the detention and the teleport.

## Draws `texture` so its own ground anchor lands at `at` (local space, default the body's own
## origin) — `Sprites.draw_standing`'s bottom-centre assumption is wrong for this kit: a boom
## gate's anchor sits between its two posts rather than under the middle of the canvas, and the
## hut's doorway is a few pixels short of the canvas's own bottom edge. No mirroring, unlike
## `Sprites.draw_standing` — nothing in the kit that draws this way ever needs to flip.
func _draw_at_anchor(canvas: CanvasItem, texture: Texture2D, anchor: Vector2,
		at: Vector2 = Vector2.ZERO) -> void:
	texture = TextureResolver.resolve(texture)
	canvas.draw_texture_rect(texture, Rect2(at - anchor, texture.get_size()), false)

## The hut's own doorway direction, read off `CityMap.pavement_inward()` at the tile it actually
## stands on rather than stored: the placement never turns, so there is nothing to cache, and this
## is the same geometry every other row that cares which way a pavement faces already asks —
## `EventDef.Pavement.AGAINST_THE_BUILDING`'s own facing is `-pavement_inward`, and the doorway
## faces the carriageway for the same reason a lorry backing into a yard faces out of the wall
## behind it. `Vector2i.DOWN` (south) with no map, the harmless default a data-level rig gets.
func _hut_doorway() -> Vector2i:
	if _map:
		var tile := _map.world_to_tile(global_position)
		var inward := _map.pavement_inward(tile)
		if inward != Vector2i.ZERO:
			return -inward
	return Vector2i.DOWN

func _hut_texture(doorway: Vector2i) -> Texture2D:
	if doorway == Vector2i.UP:
		return HUT_NORTH
	if doorway == Vector2i.LEFT:
		return HUT_WEST
	if doorway == Vector2i.RIGHT:
		return HUT_EAST
	return HUT_SOUTH

## The hut, doorway facing the carriageway, with a guard posted beside it on the pavement rather
## than in the doorway itself — offset along whichever axis the doorway does not face, so the two
## never overlap whichever of the four the doorway turns out to be.
##
## **The guard is the only part of it that goes inside for a hold.** The hut is a building: it
## stays exactly where it is, casting the same shadow, so the two seconds read as her having gone
## in rather than as the checkpoint having vanished.
func _draw_checkpoint_hut(canvas: CanvasItem = self) -> void:
	var doorway := _hut_doorway()
	_draw_body_shadow(canvas)
	_draw_at_anchor(canvas, _hut_texture(doorway), _HUT_ANCHOR)
	if is_its_guard_inside():
		return
	var beside := Vector2(0.0, 22.0) if doorway.x == 0 else Vector2(22.0, 0.0)
	# The guard's own shadow, not the row's shape — a per-part point beside the hut, same as the
	# dog beside a dog walker.
	_draw_shadow(canvas, beside, 8.0)
	_draw_at_anchor(canvas, GUARD_STANDING, _GUARD_ANCHOR, beside)

## The boom, raised or lowered from `gate_state` (`null` reads as lowered, the safe default before
## `Crowd` has ever touched it), over whichever axis of road `facing_now()` says this door's street
## runs — `_heading` is the street's own along-axis here, not a direction this stationary body ever
## turns to face, see `facing_now()`'s own doc.
func _draw_checkpoint_gate(canvas: CanvasItem = self) -> void:
	var raised: bool = gate_state != null and gate_state.raised
	var runs_north_south := gate_runs_north_south(_heading)
	var texture: Texture2D
	var anchor: Vector2
	if runs_north_south:
		texture = BOOM_GATE_NS_RAISED if raised else BOOM_GATE_NS_LOWERED
		anchor = _BOOM_NS_ANCHOR
	else:
		texture = BOOM_GATE_EW_RAISED if raised else BOOM_GATE_EW_LOWERED
		anchor = _BOOM_EW_ANCHOR
	_draw_body_shadow(canvas)
	_draw_at_anchor(canvas, texture, anchor)

## Whether a gate sited with `along_axis` bars a road running north-south, and so draws the boom
## whose arm spans east-west. `along_axis` is the street's own along-axis, which
## `RegionPlanner._along_axis` sets to `DOWN` for a north-south street and `RIGHT` for an east-west
## one. Named rather than inlined so the drawing and the test that measures it read the same rule.
static func gate_runs_north_south(along_axis: Vector2) -> bool:
	return absf(along_axis.y) > absf(along_axis.x)

## How far the lowered arm reaches to either side of the gate's own ground point, across the road
## it bars: `x` the near edge (negative), `y` the far edge, in pixels along the cross-street axis.
## This is the number the player reads as *the bar is on the road* or *the bar is on the kerb*, and
## nothing in `_draw()` can be asserted headless — see `tests/test_checkpoints.gd`.
static func boom_arm_span(runs_north_south: bool) -> Vector2:
	if runs_north_south:
		var ns := _BOOM_NS_ARM.position.x - _BOOM_NS_ANCHOR.x
		return Vector2(ns, ns + _BOOM_NS_ARM.size.x)
	var ew := _BOOM_EW_ARM.position.y - _BOOM_EW_ANCHOR.y
	return Vector2(ew, ew + _BOOM_EW_ARM.size.y)
