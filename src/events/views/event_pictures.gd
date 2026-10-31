class_name EventPictures
extends RefCounted
## Every picture an event is drawn in, by name, and the tables and rules that pick one: what a row
## looks like is data, read by the looks (`src/events/views/`) and by the badge and the placement
## that measure a picture's size.
##
## **Every picture below is the name its region is baked under, never a loaded texture and never
## a file path.** The authoring SVG it came from lives under `art/`, which the engine ignores, so
## there is nothing here to `load()` even by accident: `drawn()` hands the draw call a region of
## the one `events` page. Everything the drawing asks of a picture goes through the two helpers
## beside `drawn()`: `native_size()` for a size read outside a draw, and nothing else — a
## `Texture2D` is never held here.

const CAT_CROUCHED := "events/cat_crouched"
const CAT_RUNNING := "events/cat_running"
## The `"side"` entry of `MOUSE_BY_VIEW` below, east-facing per `facings.csv` — see
## `EventCatalogue._alley_mouse()`. Also `icon_for()`'s own badge silhouette.
const MOUSE := "events/mouse"
## The dash's own second frame, and the `"side"` entry of `MOUSE_BY_VIEW_B` — its tail curls a
## little differently rather than crossing legs it has no room to draw at this scale, read off
## `EventLook._gait_stepping()` the same way every other family's own `_b` table is.
const MOUSE_B := "events/mouse_b"
## The only generic here, and it is not a look: it is the *walker* half of a dog walker, which is a
## picture of somebody holding a lead rather than a picture of nobody in particular. Every row draws
## something of its own.
const PERSON := "events/person"
const YELLER := "events/yeller"
const NEIGHBOR := "events/neighbor_front"
const BUSKER := "events/busker"
const POSTER_CREW := "events/poster_crew"
## The square crew's own badge silhouette: the same man at the advertising column he pastes on,
## which is what tells the two crews apart at badge size.
const POSTER_CREW_SQUARE := "events/poster_crew_square"
const ROBBER_WAITING := "events/robber_waiting"
const ROBBER_LUNGING := "events/robber_lunging"
const PROTESTER := "events/protester"
## The eight pointing poses, one per 45° bearing sector — see `protester_texture()`. Ordered
## clockwise from north to match `RunTrace.compass()`'s own bearing convention.
const PROTESTER_POINT_N := "events/protester_point_n"
const PROTESTER_POINT_NE := "events/protester_point_ne"
const PROTESTER_POINT_E := "events/protester_point_e"
const PROTESTER_POINT_SE := "events/protester_point_se"
const PROTESTER_POINT_S := "events/protester_point_s"
const PROTESTER_POINT_SW := "events/protester_point_sw"
const PROTESTER_POINT_W := "events/protester_point_w"
const PROTESTER_POINT_NW := "events/protester_point_nw"
const GUNMAN := "events/gunman"
## The unsuffixed source is every family's own side view — see `docs/GRAPHICS.md`'s side-facing
## convention, `docs/evidence/svg-vehicles-2026-09-10/facings.csv`. The four-way suffixed sets below
## it are each family's front, back and two diagonals, bound through `EventLook._draw_eight_view()`.
## Each family's unbound `_end.svg` stays on disk (see `docs/GRAPHICS.md`, the events table).
const DELIVERY_VAN := "events/delivery_van"
const DELIVERY_VAN_FRONT := "events/delivery_van_front"
const DELIVERY_VAN_BACK := "events/delivery_van_back"
const DELIVERY_VAN_FRONT_DIAGONAL := "events/delivery_van_front_diagonal"
const DELIVERY_VAN_BACK_DIAGONAL := "events/delivery_van_back_diagonal"
const FIRE_ENGINE := "events/fire_engine"
const FIRE_ENGINE_FRONT := "events/fire_engine_front"
const FIRE_ENGINE_BACK := "events/fire_engine_back"
const FIRE_ENGINE_FRONT_DIAGONAL := "events/fire_engine_front_diagonal"
const FIRE_ENGINE_BACK_DIAGONAL := "events/fire_engine_back_diagonal"
const POLICE_CAR := "events/police_car"
const POLICE_CAR_FRONT := "events/police_car_front"
const POLICE_CAR_BACK := "events/police_car_back"
const POLICE_CAR_FRONT_DIAGONAL := "events/police_car_front_diagonal"
const POLICE_CAR_BACK_DIAGONAL := "events/police_car_back_diagonal"
const UNMARKED_VAN := "events/unmarked_van"
const UNMARKED_VAN_FRONT := "events/unmarked_van_front"
const UNMARKED_VAN_BACK := "events/unmarked_van_back"
const UNMARKED_VAN_FRONT_DIAGONAL := "events/unmarked_van_front_diagonal"
const UNMARKED_VAN_BACK_DIAGONAL := "events/unmarked_van_back_diagonal"
const VAN_VICTIM := "events/van_victim"
## The night raid's van: `EventLook._draw_eight_view()` reads `RIOT_VAN_BY_VIEW` below through the
## same octant/mirror convention `EightDirection` gives every other family. Its side picture is
## authored facing west, the same as `unmarked_van` and `army_truck` below
## (`docs/evidence/svg-vehicles-2026-09-10/facings.csv`), so it takes the same `side_faces_west`
## override those two do.
const RIOT_VAN := "events/riot_van"
const RIOT_VAN_FRONT := "events/riot_van_front"
const RIOT_VAN_BACK := "events/riot_van_back"
const RIOT_VAN_FRONT_DIAGONAL := "events/riot_van_front_diagonal"
const RIOT_VAN_BACK_DIAGONAL := "events/riot_van_back_diagonal"
const ARMY_TRUCK := "events/army_truck"
const ARMY_TRUCK_FRONT := "events/army_truck_front"
const ARMY_TRUCK_BACK := "events/army_truck_back"
const ARMY_TRUCK_FRONT_DIAGONAL := "events/army_truck_front_diagonal"
const ARMY_TRUCK_BACK_DIAGONAL := "events/army_truck_back_diagonal"
const FLAME := "events/flame"
const BARRIER_SEGMENT := "events/barrier_segment"
const BARRIER_SEGMENT_VERTICAL := "events/barrier_segment_vertical"
const BARRIER_END := "events/barrier_end"
const RUBBLE := "events/rubble"
const CHECKPOINT_BLOCK := "events/checkpoint_block"
const ROADBLOCK_SEGMENT := "events/roadblock_segment"
const ROADBLOCK_SEGMENT_VERTICAL := "events/roadblock_segment_vertical"
const ROADBLOCK_END := "events/roadblock_end"
## A hunting roadblock's own shadow once it draws as a guard rather than as the band: person-scale,
## matching `alley_robbery`'s own `GroundShape.point(9.0)` rather than `def.shape` — the band's 60px
## capsule, which is still what the collision body and the cold picture are built from.
const GUARD_SHADOW_RADIUS := 9.0

const BARRICADE_PILE := "events/barricade_pile"
const CAFE_TABLE := "events/cafe_table"
const CAFE_SITTER := "events/cafe_sitter"
const DOG := "events/dog"
const CYCLIST := "events/cyclist"
const STALL := "events/stall"
const LEAF_BLOWER := "events/leaf_blower"
const PIGEON := "events/pigeon"
const PIGEON_DOWN := "events/pigeon_down"
const ICE_CREAM_VAN := "events/ice_cream_van"
const ICE_CREAM_VAN_FRONT := "events/ice_cream_van_front"
const ICE_CREAM_VAN_BACK := "events/ice_cream_van_back"
const ICE_CREAM_VAN_FRONT_DIAGONAL := "events/ice_cream_van_front_diagonal"
const ICE_CREAM_VAN_BACK_DIAGONAL := "events/ice_cream_van_back_diagonal"
const LORRY := "events/lorry"
const LORRY_FRONT := "events/lorry_front"
const LORRY_BACK := "events/lorry_back"
const LORRY_FRONT_DIAGONAL := "events/lorry_front_diagonal"
const LORRY_BACK_DIAGONAL := "events/lorry_back_diagonal"
const CHARGING_DOG := "events/charging_dog"
const CHATTING_MOTHER_WALKING := "events/chatting_mother_walking"
const CHATTING_MOTHER_TALKING := "events/chatting_mother_talking"
## Seal pictures — see `SealPlanner` and `docs/DECISIONS.md`, "Eight seal pictures".
const FALLEN_TREE := "events/fallen_tree"
const CAR_ACCIDENT := "events/car_accident"
const CAR_ACCIDENT_SHADOW := "events/car_accident_shadow"
const SKIP := "events/skip"
const SCAFFOLDING := "events/scaffolding"
const BURST_MAIN := "events/burst_water_main"
const MOVING_VAN := "events/moving_van"
const MOVING_VAN_VERTICAL := "events/moving_van_vertical"
const BURNT_OUT_CAR := "events/burnt_out_car"
const BURNT_OUT_CAR_VERTICAL := "events/burnt_out_car_vertical"
const COLLAPSED_FRONTAGE := "events/collapsed_frontage"
## Directional siblings for the three whole-street scenes. Vehicles and upright props are authored
## in the street's projection rather than rotating every pixel of the horizontal composition.
const FALLEN_TREE_VERTICAL := "events/fallen_tree_vertical"
const CAR_ACCIDENT_VERTICAL := "events/car_accident_vertical"
const CAR_ACCIDENT_VERTICAL_SHADOW := "events/car_accident_vertical_shadow"
const BURST_MAIN_VERTICAL := "events/burst_water_main_vertical"
## The crash's and the burst main's second frames, one per street axis: the same canvas and every
## pixel of the scene but the moving part — the crash's smoke one puff further up, the main's
## fountain surging and splashing on the rims. `wide_scene_texture()` picks them off
## `EventLook._idle_stepping()`, on the two periods below, since neither scene ever moves.
const CAR_ACCIDENT_B := "events/car_accident_b"
const CAR_ACCIDENT_VERTICAL_B := "events/car_accident_vertical_b"
const BURST_MAIN_B := "events/burst_water_main_b"
const BURST_MAIN_VERTICAL_B := "events/burst_water_main_vertical_b"
## A puff of smoke's own tempo: slow enough that the smoke reads as rising rather than flickering.
const CAR_ACCIDENT_SMOKE_PERIOD := 1.2
## A splash's: water under pressure surges quickly, so the fountain beats faster than the smoke.
const BURST_MAIN_SPLASH_PERIOD := 0.5

# ---------------------------------------------------------- eight-view families ---
# Every family below shares the crowd walker's own convention (`docs/GRAPHICS.md`, "the crowd
# walkers"; `CrowdAgent.WALKER_VIEW_BY_SECTOR`): N back, NE/NW back_diagonal, E/W side, SE/SW
# front_diagonal, S front, the three west sectors mirroring their east-authored partner about the
# feet anchor (`EightDirection.is_mirrored()`). `EIGHT_VIEW_BY_SECTOR` is that same table, copied
# rather than shared — an event and a walker have no common base to hang one array on — and
# `EventLook._select_view()` below is `WalkerLook.sector()`'s own shape applied generally: one
# held sector per instance, since only one `Look` is ever live on a given instance.
const EIGHT_VIEW_BY_SECTOR: Array[String] = [
	"side", "front_diagonal", "front", "front_diagonal", "side",
	"back_diagonal", "back", "back_diagonal",
]

const PERSON_BY_VIEW := {
	"front": "events/person_front",
	"back": "events/person_back",
	"side": "events/person_side",
	"front_diagonal": "events/person_front_diagonal",
	"back_diagonal": "events/person_back_diagonal",
}
## Feet-passing companion to `PERSON_BY_VIEW`, the walker frame-authoring rule applied to the dog
## walker's own body: cardinal and side views lift the coat and head one pixel and cross the legs
## and shoes, the two diagonals leave everything but the legs untouched. See
## `EventLook._gait_stepping()`.
const PERSON_BY_VIEW_B := {
	"front": "events/person_front_b",
	"back": "events/person_back_b",
	"side": "events/person_side_b",
	"front_diagonal": "events/person_front_diagonal_b",
	"back_diagonal": "events/person_back_diagonal_b",
}
const YELLER_BY_VIEW := {
	"front": "events/yeller_front",
	"back": "events/yeller_back",
	"side": "events/yeller_side",
	"front_diagonal": "events/yeller_front_diagonal",
	"back_diagonal": "events/yeller_back_diagonal",
}
## See `PERSON_BY_VIEW_B` above for the frame-authoring rule.
const YELLER_BY_VIEW_B := {
	"front": "events/yeller_front_b",
	"back": "events/yeller_back_b",
	"side": "events/yeller_side_b",
	"front_diagonal": "events/yeller_front_diagonal_b",
	"back_diagonal": "events/yeller_back_diagonal_b",
}
## The neighbor, the passer-by's own body in work clothes (`docs/GRAPHICS.md`, the neighbor): the
## same five views and the same feet-passing frames, so the gait is the dog walker's own.
const NEIGHBOR_BY_VIEW := {
	"front": "events/neighbor_front",
	"back": "events/neighbor_back",
	"side": "events/neighbor_side",
	"front_diagonal": "events/neighbor_front_diagonal",
	"back_diagonal": "events/neighbor_back_diagonal",
}
const NEIGHBOR_BY_VIEW_B := {
	"front": "events/neighbor_front_b",
	"back": "events/neighbor_back_b",
	"side": "events/neighbor_side_b",
	"front_diagonal": "events/neighbor_front_diagonal_b",
	"back_diagonal": "events/neighbor_back_diagonal_b",
}
const BUSKER_BY_VIEW := {
	"front": "events/busker_front",
	"back": "events/busker_back",
	"side": "events/busker_side",
	"front_diagonal": "events/busker_front_diagonal",
	"back_diagonal": "events/busker_back_diagonal",
}
## The strumming hand raised — read by `FigureLook._draw_busker()` off
## `EventLook._idle_stepping()`'s own timer rather than `EventLook._gait_stepping()`'s distance,
## since he never moves. Everything but the hand/arm draped over the guitar is byte-identical to
## frame a.
const BUSKER_BY_VIEW_B := {
	"front": "events/busker_front_b",
	"back": "events/busker_back_b",
	"side": "events/busker_side_b",
	"front_diagonal": "events/busker_front_diagonal_b",
	"back_diagonal": "events/busker_back_diagonal_b",
}
const POSTER_CREW_BY_VIEW := {
	"front": "events/poster_crew_front",
	"back": "events/poster_crew_back",
	"side": "events/poster_crew_side",
	"front_diagonal": "events/poster_crew_front_diagonal",
	"back_diagonal": "events/poster_crew_back_diagonal",
}
## The pasting frame: the back view — the crew facing the wall it pastes, which is how every crew
## on her way stands — with the brush raised to the wall, alternated with frame a on the idle timer
## (`POSTER_CREW_PASTE_PERIOD`) so the crew is seen pasting. The other four views have no second
## frame and name frame a's own picture.
const POSTER_CREW_BY_VIEW_B := {
	"front": "events/poster_crew_front",
	"back": "events/poster_crew_back_b",
	"side": "events/poster_crew_side",
	"front_diagonal": "events/poster_crew_front_diagonal",
	"back_diagonal": "events/poster_crew_back_diagonal",
}
## The square crew's five views. A 44x44 canvas where the sidewalk crew's is 30x44: the worker is
## that family's own figure, unmoved on the anchor, and the extra width is the advertising column
## he stands at. The column is a cylinder, so it is the same picture in all five and only the
## worker turns.
const POSTER_CREW_SQUARE_BY_VIEW := {
	"front": "events/poster_crew_square_front",
	"back": "events/poster_crew_square_back",
	"side": "events/poster_crew_square_side",
	"front_diagonal": "events/poster_crew_square_front_diagonal",
	"back_diagonal": "events/poster_crew_square_back_diagonal",
}
const CAFE_SITTER_BY_VIEW := {
	"front": "events/cafe_sitter_front",
	"back": "events/cafe_sitter_back",
	"side": "events/cafe_sitter_side",
	"front_diagonal": "events/cafe_sitter_front_diagonal",
	"back_diagonal": "events/cafe_sitter_back_diagonal",
}
## A lean, not a stride: the sitters never move, so this alternates on
## `EventLook._idle_stepping()`'s own timer rather than on `EventLook._gait_stepping()`'s distance.
## Everything but the lap/table-contact stays put; the seated body above it leans a couple of pixels
## — see the SVG's own comment.
const CAFE_SITTER_BY_VIEW_B := {
	"front": "events/cafe_sitter_front_b",
	"back": "events/cafe_sitter_back_b",
	"side": "events/cafe_sitter_side_b",
	"front_diagonal": "events/cafe_sitter_front_diagonal_b",
	"back_diagonal": "events/cafe_sitter_back_diagonal_b",
}
const VAN_VICTIM_BY_VIEW := {
	"front": "events/van_victim_front",
	"back": "events/van_victim_back",
	"side": "events/van_victim_side",
	"front_diagonal": "events/van_victim_front_diagonal",
	"back_diagonal": "events/van_victim_back_diagonal",
}
## See `PERSON_BY_VIEW_B` for the frame-authoring rule. Read by `EventVehicleLook._draw_abduction()`
## off `EventLook._victim_gait_stepping()`, her own short scripted walk to the van rather than the
## ordinary distance-driven gait — see that function's doc.
const VAN_VICTIM_BY_VIEW_B := {
	"front": "events/van_victim_front_b",
	"back": "events/van_victim_back_b",
	"side": "events/van_victim_side_b",
	"front_diagonal": "events/van_victim_front_diagonal_b",
	"back_diagonal": "events/van_victim_back_diagonal_b",
}
const PROTESTER_BY_VIEW := {
	"front": "events/protester_front",
	"back": "events/protester_back",
	"side": "events/protester_side",
	"front_diagonal": "events/protester_front_diagonal",
	"back_diagonal": "events/protester_back_diagonal",
}
## The plain rank's own stride — see `PERSON_BY_VIEW_B` for the rule. The eight
## `protester_point_*` poses stay single; `RankLook._draw_protest()` only reaches this table when
## `protester_texture()` answers its own `PROTESTER` sentinel.
const PROTESTER_BY_VIEW_B := {
	"front": "events/protester_front_b",
	"back": "events/protester_back_b",
	"side": "events/protester_side_b",
	"front_diagonal": "events/protester_front_diagonal_b",
	"back_diagonal": "events/protester_back_diagonal_b",
}
const LEAF_BLOWER_BY_VIEW := {
	"front": "events/leaf_blower_front",
	"back": "events/leaf_blower_back",
	"side": "events/leaf_blower_side",
	"front_diagonal": "events/leaf_blower_front_diagonal",
	"back_diagonal": "events/leaf_blower_back_diagonal",
}
## See `PERSON_BY_VIEW_B` for the frame-authoring rule. `leaf_blower` never moves today, so this
## is never actually reached in play — wired for uniformity the way `lorry`'s own diagonal views
## are, in case a future site ever turns him.
const LEAF_BLOWER_BY_VIEW_B := {
	"front": "events/leaf_blower_front_b",
	"back": "events/leaf_blower_back_b",
	"side": "events/leaf_blower_side_b",
	"front_diagonal": "events/leaf_blower_front_diagonal_b",
	"back_diagonal": "events/leaf_blower_back_diagonal_b",
}
const ROBBER_WAITING_BY_VIEW := {
	"front": "events/robber_waiting_front",
	"back": "events/robber_waiting_back",
	"side": "events/robber_waiting_side",
	"front_diagonal": "events/robber_waiting_front_diagonal",
	"back_diagonal": "events/robber_waiting_back_diagonal",
}
const ROBBER_LUNGING_BY_VIEW := {
	"front": "events/robber_lunging_front",
	"back": "events/robber_lunging_back",
	"side": "events/robber_lunging_side",
	"front_diagonal": "events/robber_lunging_front_diagonal",
	"back_diagonal": "events/robber_lunging_back_diagonal",
}
## The lunge's own stride — see `PERSON_BY_VIEW_B`. The waiting posture stays single: a man only
## watching the street is not moving yet.
const ROBBER_LUNGING_BY_VIEW_B := {
	"front": "events/robber_lunging_front_b",
	"back": "events/robber_lunging_back_b",
	"side": "events/robber_lunging_side_b",
	"front_diagonal": "events/robber_lunging_front_diagonal_b",
	"back_diagonal": "events/robber_lunging_back_diagonal_b",
}
## His warning, between the wait and the lunge: both hands out of his coat, held low, walking at her
## through his notice *(inbox #748: "robber can walk towards her")*. 26×44 against the waiting
## picture's 22×44, the body moved with the canvas, so the swap keeps his feet where they were.
const ROBBER_ALERT_BY_VIEW := {
	"front": "events/robber_alert_front",
	"back": "events/robber_alert_back",
	"side": "events/robber_alert_side",
	"front_diagonal": "events/robber_alert_front_diagonal",
	"back_diagonal": "events/robber_alert_back_diagonal",
}
## The alert walk's other frame, alternated with `ROBBER_ALERT_BY_VIEW` by
## `EventLook._gait_stepping()` as he walks at her through his notice, the way
## `ROBBER_LUNGING_BY_VIEW_B` is with his lunge: one walk cycle, the same canvas and anchor per
## view. Held still (a held lunge he stands for) he shows the first.
const ROBBER_ALERT_BY_VIEW_B := {
	"front": "events/robber_alert_front_b",
	"back": "events/robber_alert_back_b",
	"side": "events/robber_alert_side_b",
	"front_diagonal": "events/robber_alert_front_diagonal_b",
	"back_diagonal": "events/robber_alert_back_diagonal_b",
}
## The policeman on foot (`art/events/policeman_*`): the robber's set one for one — the same
## canvases, anchors and postures, east-authored like the robber's — so he is drawn the way the
## robber is (`PursuerLook._draw_policeman()`). The unsuffixed lunge is his badge silhouette
## (`icon_for()`).
const POLICEMAN_LUNGING := "events/policeman_lunging"
const POLICEMAN_WAITING_BY_VIEW := {
	"front": "events/policeman_waiting_front",
	"back": "events/policeman_waiting_back",
	"side": "events/policeman_waiting_side",
	"front_diagonal": "events/policeman_waiting_front_diagonal",
	"back_diagonal": "events/policeman_waiting_back_diagonal",
}
const POLICEMAN_LUNGING_BY_VIEW := {
	"front": "events/policeman_lunging_front",
	"back": "events/policeman_lunging_back",
	"side": "events/policeman_lunging_side",
	"front_diagonal": "events/policeman_lunging_front_diagonal",
	"back_diagonal": "events/policeman_lunging_back_diagonal",
}
## **A policeman who is about to charge stands square-on with one hand raised, palm out**, as the
## guard's alert is drawn (`GUARD_ALERT_BY_VIEW`): the man an investigating patrol car or a hunting
## van lets out, through day 8, for the second he stands beside her before he charges
## (`PursuerLook.policeman_pictures()`). On the policeman's own canvases and bottom-centre anchor,
## sharing his waiting picture's body. *(Inbox #764 in minty-lemur, the player: van guardsmen about
## to charge hold up their hands; an event that does not spawn already charging always needs a
## warning.)*
const POLICEMAN_ALERT_BY_VIEW := {
	"front": "events/policeman_alert_front",
	"back": "events/policeman_alert_back",
	"side": "events/policeman_alert_side",
	"front_diagonal": "events/policeman_alert_front_diagonal",
	"back_diagonal": "events/policeman_alert_back_diagonal",
}
## The lunge's own stride, as `ROBBER_LUNGING_BY_VIEW_B` is the robber's.
const POLICEMAN_LUNGING_BY_VIEW_B := {
	"front": "events/policeman_lunging_front_b",
	"back": "events/policeman_lunging_back_b",
	"side": "events/policeman_lunging_side_b",
	"front_diagonal": "events/policeman_lunging_front_diagonal_b",
	"back_diagonal": "events/policeman_lunging_back_diagonal_b",
}
const CHATTING_MOTHER_WALKING_BY_VIEW := {
	"front": "events/chatting_mother_walking_front",
	"back": "events/chatting_mother_walking_back",
	"side": "events/chatting_mother_walking_side",
	"front_diagonal": "events/chatting_mother_walking_front_diagonal",
	"back_diagonal": "events/chatting_mother_walking_back_diagonal",
}
## The pacing walk's own stride — see `PERSON_BY_VIEW_B`. The talking posture stays single: she is
## frozen for the whole of a conversation, `is_chatting()`'s own meaning.
const CHATTING_MOTHER_WALKING_BY_VIEW_B := {
	"front": "events/chatting_mother_walking_front_b",
	"back": "events/chatting_mother_walking_back_b",
	"side": "events/chatting_mother_walking_side_b",
	"front_diagonal": "events/chatting_mother_walking_front_diagonal_b",
	"back_diagonal": "events/chatting_mother_walking_back_diagonal_b",
}
const CHATTING_MOTHER_TALKING_BY_VIEW := {
	"front": "events/chatting_mother_talking_front",
	"back": "events/chatting_mother_talking_back",
	"side": "events/chatting_mother_talking_side",
	"front_diagonal": "events/chatting_mother_talking_front_diagonal",
	"back_diagonal": "events/chatting_mother_talking_back_diagonal",
}

## The animal/rider families below reuse the existing unsuffixed constant as `"side"` rather than
## preloading a second copy of the same picture: `docs/evidence/svg-vehicles-2026-09-10/
## facings.csv` marks every one of them "existing canonical source" rather than a new drawing, and
## `docs/GRAPHICS.md` says to replace a preload only where the suffixed source is a different
## picture from the one already live. `mouse` joins them below.
const MOUSE_BY_VIEW := {
	"front": "events/mouse_front",
	"back": "events/mouse_back",
	"side": MOUSE,
	"front_diagonal": "events/mouse_front_diagonal",
	"back_diagonal": "events/mouse_back_diagonal",
}
## The dash's own second frame — its tail curls a little differently rather than crossing legs it
## has no room to draw at this scale, unlike `CAT_RUNNING_BY_VIEW_B`'s quadrupeds — alternated by
## `EventLook._gait_stepping()` the same way every other family's own `_b` table is.
const MOUSE_BY_VIEW_B := {
	"front": "events/mouse_front_b",
	"back": "events/mouse_back_b",
	"side": MOUSE_B,
	"front_diagonal": "events/mouse_front_diagonal_b",
	"back_diagonal": "events/mouse_back_diagonal_b",
}
const CAT_CROUCHED_BY_VIEW := {
	"front": "events/cat_crouched_front",
	"back": "events/cat_crouched_back",
	"side": CAT_CROUCHED,
	"front_diagonal": "events/cat_crouched_front_diagonal",
	"back_diagonal": "events/cat_crouched_back_diagonal",
}
const CAT_RUNNING_BY_VIEW := {
	"front": "events/cat_running_front",
	"back": "events/cat_running_back",
	"side": CAT_RUNNING,
	"front_diagonal": "events/cat_running_front_diagonal",
	"back_diagonal": "events/cat_running_back_diagonal",
}
## The dash's own stride. Unlike the humanoid families (`PERSON_BY_VIEW_B`), a quadruped's low
## silhouette has no coat or head to lift, so every view here only shifts the leg marks — the
## distance-driven bob (`EventLook.current_bob()`) still supplies the vertical motion cue. The
## crouched posture stays single: it is the telegraph, held still.
const CAT_RUNNING_BY_VIEW_B := {
	"front": "events/cat_running_front_b",
	"back": "events/cat_running_back_b",
	"side": "events/cat_running_b",
	"front_diagonal": "events/cat_running_front_diagonal_b",
	"back_diagonal": "events/cat_running_back_diagonal_b",
}
const DOG_BY_VIEW := {
	"front": "events/dog_front",
	"back": "events/dog_back",
	"side": DOG,
	"front_diagonal": "events/dog_front_diagonal",
	"back_diagonal": "events/dog_back_diagonal",
}
## Shared by the dog walker's own dog and the loose dog — see `CAT_RUNNING_BY_VIEW_B` for why a
## quadruped's b frame only shifts the legs.
const DOG_BY_VIEW_B := {
	"front": "events/dog_front_b",
	"back": "events/dog_back_b",
	"side": "events/dog_b",
	"front_diagonal": "events/dog_front_diagonal_b",
	"back_diagonal": "events/dog_back_diagonal_b",
}
## The normal dog's third picture per view — the dog walker's and the loose dog's, not the charging
## dog's — so it walks step, rest, opposite step, rest *(2026-09-27, teal-marmot: "the normal dog
## should have three frames. we have the resting one now and one leg forward. now we need one
## frame with the other leg forward")*. What a c picture *is* depends on the view, and
## `dog_picture()` is the one place that says so.
const DOG_BY_VIEW_C := {
	"front": "events/dog_front_c",
	"back": "events/dog_back_c",
	"side": "events/dog_c",
	"front_diagonal": "events/dog_front_diagonal_c",
	"back_diagonal": "events/dog_back_diagonal_c",
}

## Which of the normal dog's three pictures a view draws on a beat of its four-beat walk: the
## first step while `stepping` in the first half of the stride, the opposite step while `stepping`
## in the second, and the rest pose whenever it is not stepping — between the two steps, and for
## as long as it stands still. **The rest and the opposite step are different tables per view.**
## The side and both diagonals rest on their b picture (legs gathered under the body) and take the
## opposite step on c; front and back already alternate their diagonal leg pairs between a and b,
## so their c picture is the square neutral stance and is their rest.
static func dog_picture(view: String, stepping: bool, second_half: bool) -> String:
	var cardinal := view == "front" or view == "back"
	if not stepping:
		return DOG_BY_VIEW_C[view] if cardinal else DOG_BY_VIEW_B[view]
	if not second_half:
		return DOG_BY_VIEW[view]
	return DOG_BY_VIEW_B[view] if cardinal else DOG_BY_VIEW_C[view]

const CHARGING_DOG_BY_VIEW := {
	"front": "events/charging_dog_front",
	"back": "events/charging_dog_back",
	"side": CHARGING_DOG,
	"front_diagonal": "events/charging_dog_front_diagonal",
	"back_diagonal": "events/charging_dog_back_diagonal",
}
## See `CAT_RUNNING_BY_VIEW_B`.
const CHARGING_DOG_BY_VIEW_B := {
	"front": "events/charging_dog_front_b",
	"back": "events/charging_dog_back_b",
	"side": "events/charging_dog_b",
	"front_diagonal": "events/charging_dog_front_diagonal_b",
	"back_diagonal": "events/charging_dog_back_diagonal_b",
}
## **The dog that waits for her has a stage of its own on each side of the gallop** *(velvet-marten,
## #698: "the waiting charging dog needs a proper resting frame when in wait. It looks like it's
## flying"; polite-toad, #722: "a distinct alert and rest post for each charger that gets triggered
## by the player")*: sitting, ears soft and tail on the ground, while it waits, and up on four stiff
## legs with its hackles raised and its jaw shut on its teeth while it stands for its notice, the
## open red jaw kept for the charge. Each is one still picture — "nobody walks -- only the robber"
## (inbox #748) — on the gallop's own canvases and bottom-centre anchor, so the swap does not move
## the dog. Drawn from the SVGs: the gallop keeps its comic transfers, and the player judges the
## style switch in the game (inbox #748: "yes that's what I've been saying all along").
const CHARGING_DOG_RESTING_BY_VIEW := {
	"front": "events/charging_dog_resting_front",
	"back": "events/charging_dog_resting_back",
	"side": "events/charging_dog_resting",
	"front_diagonal": "events/charging_dog_resting_front_diagonal",
	"back_diagonal": "events/charging_dog_resting_back_diagonal",
}
const CHARGING_DOG_ALERT_BY_VIEW := {
	"front": "events/charging_dog_alert_front",
	"back": "events/charging_dog_alert_back",
	"side": "events/charging_dog_alert",
	"front_diagonal": "events/charging_dog_alert_front_diagonal",
	"back_diagonal": "events/charging_dog_alert_back_diagonal",
}
const CYCLIST_BY_VIEW := {
	"front": "events/cyclist_front",
	"back": "events/cyclist_back",
	"side": CYCLIST,
	"front_diagonal": "events/cyclist_front_diagonal",
	"back_diagonal": "events/cyclist_back_diagonal",
}
## The pedal's own two positions — rider and bike are one picture, so one phase swaps both without
## anything here needing to know they are drawn together.
const CYCLIST_BY_VIEW_B := {
	"front": "events/cyclist_front_b",
	"back": "events/cyclist_back_b",
	"side": "events/cyclist_b",
	"front_diagonal": "events/cyclist_front_diagonal_b",
	"back_diagonal": "events/cyclist_back_diagonal_b",
}
## The pelican that about one cyclist in four hundred is instead *(minty-hedgehog, statement 8: "One
## in ~400 bikers should be a pelican riding a bicycle instead. Needs to be svg only")* — the same
## bike, path for path, on the same canvases, so it shares the cyclist's registration, wheel contact
## and pedal frames and only the rider differs. Drawn when `is_pelican` is set; see
## `EventSpawner.rolls_a_pelican()` for who decides that and when.
const PELICAN_BY_VIEW := {
	"front": "events/pelican_cyclist_front",
	"back": "events/pelican_cyclist_back",
	"side": "events/pelican_cyclist",
	"front_diagonal": "events/pelican_cyclist_front_diagonal",
	"back_diagonal": "events/pelican_cyclist_back_diagonal",
}
## See `CYCLIST_BY_VIEW_B`: the pelican's own two pedal positions.
const PELICAN_BY_VIEW_B := {
	"front": "events/pelican_cyclist_front_b",
	"back": "events/pelican_cyclist_back_b",
	"side": "events/pelican_cyclist_b",
	"front_diagonal": "events/pelican_cyclist_front_diagonal_b",
	"back_diagonal": "events/pelican_cyclist_back_diagonal_b",
}
const PIGEON_BY_VIEW := {
	"front": "events/pigeon_front",
	"back": "events/pigeon_back",
	"side": PIGEON,
	"front_diagonal": "events/pigeon_front_diagonal",
	"back_diagonal": "events/pigeon_back_diagonal",
}
const PIGEON_DOWN_BY_VIEW := {
	"front": "events/pigeon_down_front",
	"back": "events/pigeon_down_back",
	"side": PIGEON_DOWN,
	"front_diagonal": "events/pigeon_down_front_diagonal",
	"back_diagonal": "events/pigeon_down_back_diagonal",
}
## The vehicle-scale families below share the same five-view shape as every family above, but not
## all of them share its mirror convention: `docs/evidence/svg-vehicles-2026-09-10/README.md` — "the
## existing delivery van, fire engine, unmarked van, riot van, army truck and moving van side
## pictures visibly place the cab at the left" — so their single `"side"` picture is authored facing
## **west**, backwards from every side picture above. `EventLook._draw_eight_view()`'s own
## `side_faces_west` parameter is the one bit that reads, per family, from `facings.csv`'s
## `mirror_x` column rather than being assumed; every front, back and diagonal view is unaffected;
## each is its own picture for its own compass point regardless of which way the side view faces.
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
## Drawn with `side_faces_west` set (`EventVehicleLook`) — west-authored like
## `UNMARKED_VAN_BY_VIEW` and `ARMY_TRUCK_BY_VIEW` above, see that pair's own doc comment — so the
## side view mirrors on **east** to match `facings.csv`'s recorded `mirror_x`.
const RIOT_VAN_BY_VIEW := {
	"front": RIOT_VAN_FRONT,
	"back": RIOT_VAN_BACK,
	"side": RIOT_VAN,
	"front_diagonal": RIOT_VAN_FRONT_DIAGONAL,
	"back_diagonal": RIOT_VAN_BACK_DIAGONAL,
}

## **The vehicles that move roll on wheels that stay on the ground.** *(2026-09-11, the player:
## "cars could bop up and down while the wheels stay in the same place".)* Each of these looks' five
## views is drawn as its ordinary picture — the body — and a wheels picture on the same canvas and
## anchor, which `EventLook._draw_eight_view()` draws back down by `EventLook.current_bob()` so the
## lift `EventLook.draw()` gives the whole drawing reaches the body alone. The parked delivery and
## ice-cream vans never move, so their pictures keep their wheels and sit still.
const POLICE_CAR_WHEELS_BY_VIEW := {
	"front": "events/police_car_front_wheels",
	"back": "events/police_car_back_wheels",
	"side": "events/police_car_wheels",
	"front_diagonal": "events/police_car_front_diagonal_wheels",
	"back_diagonal": "events/police_car_back_diagonal_wheels",
}
const FIRE_ENGINE_WHEELS_BY_VIEW := {
	"front": "events/fire_engine_front_wheels",
	"back": "events/fire_engine_back_wheels",
	"side": "events/fire_engine_wheels",
	"front_diagonal": "events/fire_engine_front_diagonal_wheels",
	"back_diagonal": "events/fire_engine_back_diagonal_wheels",
}
const UNMARKED_VAN_WHEELS_BY_VIEW := {
	"front": "events/unmarked_van_front_wheels",
	"back": "events/unmarked_van_back_wheels",
	"side": "events/unmarked_van_wheels",
	"front_diagonal": "events/unmarked_van_front_diagonal_wheels",
	"back_diagonal": "events/unmarked_van_back_diagonal_wheels",
}
const RIOT_VAN_WHEELS_BY_VIEW := {
	"front": "events/riot_van_front_wheels",
	"back": "events/riot_van_back_wheels",
	"side": "events/riot_van_wheels",
	"front_diagonal": "events/riot_van_front_diagonal_wheels",
	"back_diagonal": "events/riot_van_back_diagonal_wheels",
}
const ARMY_TRUCK_WHEELS_BY_VIEW := {
	"front": "events/army_truck_front_wheels",
	"back": "events/army_truck_back_wheels",
	"side": "events/army_truck_wheels",
	"front_diagonal": "events/army_truck_front_diagonal_wheels",
	"back_diagonal": "events/army_truck_back_diagonal_wheels",
}
const LORRY_WHEELS_BY_VIEW := {
	"front": "events/lorry_front_wheels",
	"back": "events/lorry_back_wheels",
	"side": "events/lorry_wheels",
	"front_diagonal": "events/lorry_front_diagonal_wheels",
	"back_diagonal": "events/lorry_back_diagonal_wheels",
}
const WHEELS_BY_LOOK := {
	EventDef.Look.POLICE_CAR: POLICE_CAR_WHEELS_BY_VIEW,
	EventDef.Look.FIRE_ENGINE: FIRE_ENGINE_WHEELS_BY_VIEW,
	EventDef.Look.UNMARKED_VAN: UNMARKED_VAN_WHEELS_BY_VIEW,
	EventDef.Look.RIOT_VAN: RIOT_VAN_WHEELS_BY_VIEW,
	EventDef.Look.ARMY_TRUCK: ARMY_TRUCK_WHEELS_BY_VIEW,
	EventDef.Look.LORRY: LORRY_WHEELS_BY_VIEW,
}
## The wheels pictures drawn under their body rather than over it: the end views of the 34x50
## trucks and vans, whose tyres stand out along both flanks and whose body was always drawn over
## their inner edge. Every other wheels picture is drawn over its body, the order each tyre had
## when it was part of the one picture — so a vehicle at rest is the same pixels either way.
const WHEELS_BEHIND_THE_BODY: Array[String] = [
	"events/fire_engine_front_wheels", "events/fire_engine_back_wheels",
	"events/unmarked_van_front_wheels", "events/unmarked_van_back_wheels",
	"events/riot_van_front_wheels", "events/riot_van_back_wheels",
	"events/army_truck_front_wheels", "events/army_truck_back_wheels",
	"events/lorry_front_wheels", "events/lorry_back_wheels",
]

## The region door's own kit — see `RegionPlanner` and `docs/CITY.md`, "Regions and the wall".
const HUT_NORTH := "checkpoints/hut_north"
const HUT_SOUTH := "checkpoints/hut_south"
const HUT_EAST := "checkpoints/hut_east"
const HUT_WEST := "checkpoints/hut_west"
## The stationary picture beside a hut (`checkpoint_hut`) or alone (`checkpoint_post`) — a guard
## who never turns, since neither row ever moves. The guard who does — a heated `roadblock`'s
## escort and `masked_pursuer` — reads `GUARD_STANDING_BY_VIEW`/`GUARD_LUNGING_BY_VIEW` below
## instead, through `EventLook._draw_eight_view()`.
const GUARD_STANDING := "checkpoints/guard_standing"
const GUARD_LUNGING := "checkpoints/guard_lunging"
## Bound through `EventLook._draw_eight_view()` for the two rows whose guard actually turns as he
## moves. East-authored, like the person/animal families: `guard_lunging_side.svg`'s own comment —
## "East-authored oblique views mirror about the feet" — so no `side_faces_west` override. Each
## view's own ground anchor (standing 22×44, anchor (11, 44); lunging 36×44, anchor (17, 44)) is
## within a pixel of `Sprites.draw_standing()`'s own bottom-centre assumption, same as every other
## family bound that way — only the stationary kit's `EventLook._draw_at_anchor()` calls need
## `GUARD_ANCHOR` below, since those draw through `draw_texture_rect()` directly.
const GUARD_STANDING_BY_VIEW := {
	"front": "checkpoints/guard_standing_front",
	"back": "checkpoints/guard_standing_back",
	"side": "checkpoints/guard_standing_side",
	"front_diagonal": "checkpoints/guard_standing_front_diagonal",
	"back_diagonal": "checkpoints/guard_standing_back_diagonal",
}
const GUARD_LUNGING_BY_VIEW := {
	"front": "checkpoints/guard_lunging_front",
	"back": "checkpoints/guard_lunging_back",
	"side": "checkpoints/guard_lunging_side",
	"front_diagonal": "checkpoints/guard_lunging_front_diagonal",
	"back_diagonal": "checkpoints/guard_lunging_back_diagonal",
}
## **A guard who has noticed her stands square-on with one hand raised, palm out** *(inbox #748:
## "guards should lift their hand in warning")*, held still for his notice: the hunting roadblock's
## guard at his post, the guardsman a vehicle lets out beside its door, the masked man at the foot
## of the shaft (`PursuerLook.masked_pursuer_pictures()`), and — the front view — a checkpoint hut's
## or post's guard while her crossing of its door's line warns her (`guard_warns_her`). Never the
## van's guard a task sends or the guardsman a torn poster sends: both arrive already charging.
## 22×44 front and back, 26×44 side and diagonals, bottom-centre anchored like the standing family.
const GUARD_ALERT_BY_VIEW := {
	"front": "checkpoints/guard_alert_front",
	"back": "checkpoints/guard_alert_back",
	"side": "checkpoints/guard_alert_side",
	"front_diagonal": "checkpoints/guard_alert_front_diagonal",
	"back_diagonal": "checkpoints/guard_alert_back_diagonal",
}
const BOOM_GATE_NS_LOWERED := "checkpoints/boom_gate_ns_lowered"
const BOOM_GATE_NS_RAISED := "checkpoints/boom_gate_ns_raised"
const BOOM_GATE_EW_LOWERED := "checkpoints/boom_gate_ew_lowered"
const BOOM_GATE_EW_RAISED := "checkpoints/boom_gate_ew_raised"

## The basement vent's blow, and the one picture in the catalogue that is a *volume* of air rather
## than a body: `steam.svg` is the cloud alone on a 32×48 canvas, standing on the middle of the
## floor grate it rises out of.
const STEAM := "events/steam"
## Its second frame: the cloud lifted and spread and a fresh puff pushing up out of the grate.
## Alternated off `_idle_stepping(STEAM_BILLOW_PERIOD)` for the instance's whole life, which is
## exactly one blow — between blows the vent's plan keeps no instance at all.
const STEAM_B := "events/steam_b"
const STEAM_BILLOW_PERIOD := 0.7
## The vent's floor grate, which is **not** the blow's picture: a blow is an instance that comes and
## goes, and a vent that is there all the time, blowing or not, is what a player can plan around. So
## no look draws it — the building lays one at every vent for the whole escape
## (`BuildingPlan.lay_the_grates()`), through `steam_grate()`, at floor level under everything that
## stands, and each blow's cloud rises out of it. A ground decal on its own 32×32 canvas, centred on
## the vent's point, which is the two cloud frames' bottom-centre anchor, so the column comes up out
## of the slots with no offset of its own.
const STEAM_GRATE := "events/steam_grate"

## The mast — a pole and horns standing on a street — and the two overlays `FigureLook._draw_mast()`
## puts above it, never its own colour, so a lamp and a set of arcs can be tinted per state rather
## than baked into a second picture. `MAST_LAMP` sits at the horn housing; `SOUND_PULSE` is
## `art/events/sound_pulse.svg`, whose own comment names the anchor `MAST_PULSE_AT` reads from.
const MAST := "events/mast"
const MAST_LAMP := "events/mast_lamp"
const SOUND_PULSE := "events/sound_pulse"
## `mast.svg`'s own horn housing, read off the source the way `HUT_ANCHOR` is — where the lamp
## sits and where the arcs rise from, both measured from the mast's own bottom-centre ground point.
const MAST_LAMP_AT := Vector2(0.0, -44.0)
const MAST_PULSE_AT := Vector2(0.0, -48.0)

## The finale's crater, the mark an off-screen explosion leaves on the street. One of the three
## prepared sizes; the row obstructs at exactly half this picture's width, so the hole and the
## ground she cannot walk on are the same circle — see `EventCatalogue._impact_crater()`.
const IMPACT_CRATER := "props/impact_crater_2x2"
## Its centre, which is also its ground point: the picture is a hole in the road rather than a
## thing standing on it, so it is registered on its middle and not on its base. The source's own
## comment names the same point — *"Ground anchor is the canvas centre (32,32)"* — on a 64×64
## canvas, and `EventCatalogue._impact_crater()`'s own 32px body is half of the same width.
const CRATER_ANCHOR := Vector2(32.0, 32.0)
## Each asset's own documented ground anchor, read out of the SVG's own comment rather than
## assumed — neither is `Sprites.draw_standing`'s bottom-centre: the hut's doorway sits a few
## pixels short of the canvas's own bottom edge. See `EventLook._draw_at_anchor`.
const HUT_ANCHOR := Vector2(28.0, 52.0)
const GUARD_ANCHOR := Vector2(11.0, 44.0)

## A boom's two posts, as the ground point each of them stands on in its own canvas — the near
## post is the `ground anchor` the SVG documents, the far one is the receiving post at the other
## end of the arm, read off the same post box and base plate the near one is read off. Both states
## of each boom put its posts in exactly these places, which is what keeps a raised bar registered
## with the lowered one it replaces.
const BOOM_NS_NEAR_POST := Vector2(84.0, 59.0)
const BOOM_NS_FAR_POST := Vector2(5.0, 55.0)
const BOOM_EW_NEAR_POST := Vector2(21.0, 88.0)
const BOOM_EW_FAR_POST := Vector2(18.5, 12.0)
## **A boom hangs from its body's ground point midway between its two posts, not from one of
## them.** A gate is sited on the middle of the carriageway — `RegionPlanner._add_door_bodies`
## puts it on the road's own centre line between the two huts — and a picture hung by the near
## post alone puts its whole arm to one side of that point: on the kerb, with the lanes it exists
## to bar left open underneath it. Anchored between the posts, each post lands just outside a kerb
## and the arm crosses the lanes, which is the shape the picture was drawn as.
const BOOM_NS_ANCHOR := (BOOM_NS_NEAR_POST + BOOM_NS_FAR_POST) * 0.5
const BOOM_EW_ANCHOR := (BOOM_EW_NEAR_POST + BOOM_EW_FAR_POST) * 0.5
## The lowered arm's own extent inside each canvas — the striped bar itself, not the posts or the
## sockets. Only `boom_arm_span()` reads them: where the bar lands across the road is the thing a
## test can check and `EventLook.draw()` cannot.
const BOOM_NS_ARM := Rect2(4.0, 43.0, 79.0, 7.0)
const BOOM_EW_ARM := Rect2(15.0, 7.0, 9.0, 76.0)

## The one silhouette that stands for a look, at any size, as the picture's own path — `""` for a
## look with nothing to put in a badge. The badge turns it into a region of the `events` page the
## same way everything in this file does; a path is what makes the table comparable, which is the
## rule below.
##
## It lives here rather than in `DangerEdge` for the same reason the caret lives in `Sprites`: a
## cue that belongs to the vocabulary does not belong to a class, and the screen-edge badge's whole
## job is to draw *the thing's own picture* — a second table of which picture that is, kept in the
## UI, is how a badge ends up showing a generic van for a fire engine. `tests/test_events.gd`
## asserts every visible row has one and that no two looks return the same picture, which is the
## half of the one-picture-per-row rule that a `look` field cannot enforce by itself.
static func icon_for(look: EventDef.Look) -> String:
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
		EventDef.Look.POSTER_CREW_SQUARE: return POSTER_CREW_SQUARE
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
		EventDef.Look.IMPACT_CRATER: return IMPACT_CRATER
		EventDef.Look.MASKED_PURSUER: return GUARD_LUNGING
		EventDef.Look.STEAM: return STEAM
		EventDef.Look.LOUDSPEAKER_MAST: return MAST
		EventDef.Look.NEIGHBOR: return NEIGHBOR
		# The side view rather than `GUARD_LUNGING`, which is `MASKED_PURSUER`'s badge: the same
		# man, and the one picture of his that no other look already stands for.
		EventDef.Look.DOOR_GUARD: return str(GUARD_LUNGING_BY_VIEW["side"])
		# The same reasoning for the same man: `ROBBER`'s badge is the lunge seen from the front,
		# so the robber a handed-over task sets on her is badged by the one view of it no other
		# look already stands for.
		EventDef.Look.ROBBER_GIVING_CHASE: return str(ROBBER_LUNGING_BY_VIEW["side"])
		# The same man again: `MASKED_PURSUER` already stands for the front (`GUARD_LUNGING`) and
		# `DOOR_GUARD` for the side, so the guard the van's task sets on her is badged by the back.
		EventDef.Look.VAN_GUARD_GIVING_CHASE: return str(GUARD_LUNGING_BY_VIEW["back"])
		# The policeman's own lunge silhouette, the unsuffixed picture drawn for his badge.
		EventDef.Look.POLICEMAN_GIVING_CHASE: return POLICEMAN_LUNGING
		# The guard once more: the front, side and back of his lunge are taken, so the guardsman
		# a torn poster sends from day 9 is badged by its front diagonal.
		EventDef.Look.GUARDSMAN_GIVING_CHASE: return str(GUARD_LUNGING_BY_VIEW["front_diagonal"])
		_: return ""

## The wheels drawn under `icon_for()`'s own silhouette, `""` for a look whose silhouette is one
## picture. A vehicle that rolls on wheels of its own (`WHEELS_BY_LOOK`) has its side view split
## in two, and a badge showing the body alone would be a van with no wheels — so the badge draws
## this over the same rectangle, the same order the street draws it in.
static func icon_wheels_for(look: EventDef.Look) -> String:
	var wheels_by_view: Dictionary = WHEELS_BY_LOOK.get(look, {})
	return str(wheels_by_view.get("side", ""))

## Which texture a "whole scene" seal picture (`FALLEN_TREE`, `CAR_ACCIDENT`, `BURST_MAIN`) draws,
## given whether the street it stands on rotates the spread onto local Y
## (`EventInstance.runs_vertically()`).
##
## **A separate directional asset, not a runtime rotation of the one texture.**
## The spread axis remap only relabels which texture dimension is "along" the obstruction; it never
## turns pixels. `wide_scene_texture` therefore supplies an authored composition for each street
## axis, so cars keep the right projection and people and barriers remain upright. Repeatable
## segments are close enough to square for the dimension swap itself. `EventDef.look` and
## `EventInstance.runs_vertically()` together pick the texture, with no field on the def.
##
## `frame_b` asks for the scene's second frame where it has one — the crash's smoke and the burst
## main's fountain. On screen the two are `EventScenery` layers, one behind each of the scene's
## slices (`SpreadLook._build_the_slices()`), and `SpreadLook._update_scenery()` alternates their
## frame off its own `EventLook._idle_stepping()` call; `EventLook.draw_body()` only picks `frame_b`
## here when it draws the whole scene itself, which happens on the halo's own canvas (`canvas !=
## self`) or with no slices standing. The fallen tree has nothing that moves and answers its one
## picture either way.
static func wide_scene_texture(look: EventDef.Look, vertical: bool, frame_b := false) -> String:
	match look:
		EventDef.Look.FALLEN_TREE: return FALLEN_TREE_VERTICAL if vertical else FALLEN_TREE
		EventDef.Look.CAR_ACCIDENT:
			if frame_b:
				return CAR_ACCIDENT_VERTICAL_B if vertical else CAR_ACCIDENT_B
			return CAR_ACCIDENT_VERTICAL if vertical else CAR_ACCIDENT
		EventDef.Look.BURST_MAIN:
			if frame_b:
				return BURST_MAIN_VERTICAL_B if vertical else BURST_MAIN_B
			return BURST_MAIN_VERTICAL if vertical else BURST_MAIN
		_: return ""

## A crash scene has several separate contacts with the ground, so it carries a matching shadow
## picture rather than painting one ellipse across the entire closed street. `""` for a scene with
## no authored contact art, which is every one but the crash. Both of the crash's frames stand on
## the same contacts — only the smoke moves — so each axis has one shadow for its two frames.
static func wide_scene_shadow(picture: String) -> String:
	if picture == CAR_ACCIDENT or picture == CAR_ACCIDENT_B:
		return CAR_ACCIDENT_SHADOW
	if picture == CAR_ACCIDENT_VERTICAL or picture == CAR_ACCIDENT_VERTICAL_B:
		return CAR_ACCIDENT_VERTICAL_SHADOW
	return ""

## The selected picture for a stationary vehicle. The row keeps one look because both files
## depict the same vehicle rather than two catalogue entries.
static func stationary_vehicle_texture(look: EventDef.Look, side_view: bool) -> String:
	match look:
		EventDef.Look.MOVING_VAN:
			return MOVING_VAN if side_view else MOVING_VAN_VERTICAL
		EventDef.Look.BURNT_OUT_CAR:
			return BURNT_OUT_CAR if side_view else BURNT_OUT_CAR_VERTICAL
		_:
			return ""

## Preserves the authored end-on projection instead of stretching it to the circular collision
## diameter. Side views are fitted to that diameter because their long silhouette is the width the
## solid row claims on the axis where that picture is used.
static func stationary_vehicle_extent(picture: String, side_view: bool,
		side_width: float) -> Vector2:
	var size := native_size(picture)
	if not side_view:
		return size
	return Vector2(side_width, size.y * side_width / size.x)

## The roadworks panel source follows the spread's authored projection. The vertical source is
## selected for an east-west street or horizontal alley; the ordinary source remains the broad
## panel for a north-south street or vertical alley.
static func roadwork_segment_texture(spread_vertical: bool) -> String:
	return BARRIER_SEGMENT_VERTICAL if spread_vertical else BARRIER_SEGMENT

## The roadblock's barrier follows the same projection rule as the roadworks one above: the
## end-on picture for a band stacked down a north-south column (an east-west street or a
## horizontal alley), the broadside one otherwise. Stacking the broadside picture down a column
## repeats a side view per segment rather than drawing one barrier running away from the camera.
static func roadblock_segment_texture(spread_vertical: bool) -> String:
	return ROADBLOCK_SEGMENT_VERTICAL if spread_vertical else ROADBLOCK_SEGMENT

## The bob a moving event rides on: a stride's worth of lift, once per stride's worth of ground.
## Sized against a walking pace rather than a running one — 34px is roughly a step.
const BOB_PER_PX := PI / 34.0
const BOB_HEIGHT := 2.5

## A few seconds per swap — slow enough that a café frontage reads as sitting rather than
## fidgeting. See `EventLook._idle_stepping()`.
const SITTER_IDLE_PERIOD := 3.4
## A strum's own tempo. See `EventLook._idle_stepping()`.
const BUSKER_STRUM_PERIOD := 0.5
## A brush stroke's, for a poster crew pasting. See `POSTER_CREW_BY_VIEW_B`.
const POSTER_CREW_PASTE_PERIOD := 0.8

## How far above the entity the mark floats, and how big it is at full strength.
const MARK_HEIGHT := 44.0
const MARK_WIDTH := 15.0
const MARK_FLASHES_PER_SECOND := 3.0

## The largest rectangle `EventLook.mark_rect()` can ever be, in a row's own space: the doubled
## caret at full swell, outline included — what `footprint_of()` keeps off screen for a row that can
## be marked.
static func largest_mark_rect() -> Rect2:
	var top := -(MARK_HEIGHT + 10.0) - MARK_WIDTH * 0.8 - MARK_WIDTH * 0.85 - 1.0
	var bottom := -(MARK_HEIGHT + 10.0) + MARK_WIDTH * 0.5 + 1.0
	return Rect2(-MARK_WIDTH - 1.0, top, (MARK_WIDTH + 1.0) * 2.0, bottom - top)

# **One page for the whole catalogue, held from boot.** *(PLAYTEST-108: "we can do one events page
# for now".)* Every picture in this file — the checkpoint kit and the finale's crater included — is
# a region of `ATLAS_GROUP`, and `EventManager` is what holds a reference on it while a day's
# events exist; `main.RESIDENT_GROUPS` is what keeps it there for the life of the process, so no
# event ever costs a read from disk in a played frame.
#
# **This replaces one runtime-packed group per `EventDef.Look`.** A picture two looks both draw —
# the guard, the dog, the boom kit — was packed into each of their groups, because a family that
# could be released had to be self-contained; on one page each picture is one region and the
# duplicates are gone. A single group also means nothing here has to decide *when* a family
# arrives: a baked page is there the moment it is acquired, so an instance never draws a source
# picture "until its pack is collected".

## The one baked page everything in this file draws from.
const ATLAS_GROUP := &"events"

## The picture to draw: a region of the `events` page, whose own `get_size()` is the source
## picture's size, so every offset, extent, anchor and mirror below reads exactly the number it
## read from a preloaded texture.
##
## **Null, with an engine error naming the region, if nothing holds the page** — `AtlasLibrary`'s
## own rule, and the reason `EventManager` acquires the group rather than trusting the boot's
## residency. Nothing here defends against that: a drawing that quietly fell back to loading the
## picture itself is the second resident copy the milestone exists to remove.
static func drawn(picture: String) -> AtlasTexture:
	return AtlasLibrary.region(StringName(picture))

## A picture's own size, answered from the region table with nothing acquired and no texture
## loaded — what the layout arithmetic around a spread, a café rank, a protest rank or a badge
## needs, as a `Vector2` like a texture's `get_size()`.
static func native_size(picture: String) -> Vector2:
	return Vector2(AtlasLibrary.native_size(StringName(picture)))

## The basement vent's floor grate, for the building to lay at every vent
## (`BuildingPlan.lay_the_grates()`) — see `STEAM_GRATE`
## for why no instance draws it. Fetched here rather than by name there, so the region is still
## named in this file with every other picture of the page.
static func steam_grate() -> AtlasTexture:
	return drawn(STEAM_GRATE)

## Every picture a row with this look can draw, as repository paths.
##
## Read straight off `EventLook.draw_body()`'s own arms: if a branch there can reach a picture, it
## is here. A look whose arm draws nothing in the street (`BURNT_SHELL`) lists its badge silhouette
## instead. Not read by the live draw path, which has the path already in hand — this is the one
## place "everything a look can draw" is enumerable, which is what a completeness check against
## `assets/atlases/membership.json` wants (`tests/test_atlas_events.gd`), the same role
## `Stroller.sources_by_group()` plays for the rig.
static func family_sources(look: EventDef.Look) -> Array[String]:
	var sources: Dictionary = {}
	match look:
		EventDef.Look.CAT:
			_collect_views(sources, [CAT_CROUCHED_BY_VIEW, CAT_RUNNING_BY_VIEW,
					CAT_RUNNING_BY_VIEW_B])
		EventDef.Look.MOUSE:
			_collect_views(sources, [MOUSE_BY_VIEW, MOUSE_BY_VIEW_B])
		EventDef.Look.YELLER:
			_collect_views(sources, [YELLER_BY_VIEW, YELLER_BY_VIEW_B])
		EventDef.Look.NEIGHBOR:
			_collect_views(sources, [NEIGHBOR_BY_VIEW, NEIGHBOR_BY_VIEW_B])
		EventDef.Look.DOG_WALKER:
			_collect_views(sources, [PERSON_BY_VIEW, PERSON_BY_VIEW_B, DOG_BY_VIEW, DOG_BY_VIEW_B,
					DOG_BY_VIEW_C])
		EventDef.Look.CAFE:
			_collect_views(sources, [CAFE_SITTER_BY_VIEW, CAFE_SITTER_BY_VIEW_B])
			_collect(sources, [CAFE_TABLE])
		EventDef.Look.DELIVERY_VAN:
			_collect_views(sources, [DELIVERY_VAN_BY_VIEW])
		EventDef.Look.BUSKER:
			_collect_views(sources, [BUSKER_BY_VIEW, BUSKER_BY_VIEW_B])
		EventDef.Look.ROADWORKS:
			_collect(sources, [BARRIER_SEGMENT, BARRIER_SEGMENT_VERTICAL, BARRIER_END])
		EventDef.Look.FIRE_ENGINE:
			_collect_views(sources, [FIRE_ENGINE_BY_VIEW, FIRE_ENGINE_WHEELS_BY_VIEW])
		EventDef.Look.BURNING_BUILDING:
			_collect(sources, [FLAME, STEAM, STEAM_B])
		EventDef.Look.BURNT_SHELL:
			# Nothing in the street — the building behind it is drawn burnt instead — so its one
			# picture is its badge silhouette (`icon_for()`).
			_collect(sources, [RUBBLE])
		EventDef.Look.LOOSE_DOG:
			_collect_views(sources, [DOG_BY_VIEW, DOG_BY_VIEW_B, DOG_BY_VIEW_C])
		EventDef.Look.STALL:
			_collect(sources, [STALL])
		EventDef.Look.LEAF_BLOWER:
			_collect_views(sources, [LEAF_BLOWER_BY_VIEW, LEAF_BLOWER_BY_VIEW_B])
		EventDef.Look.BIRDS:
			_collect_views(sources, [PIGEON_BY_VIEW, PIGEON_DOWN_BY_VIEW])
		EventDef.Look.CYCLIST:
			_collect_views(sources, [CYCLIST_BY_VIEW, CYCLIST_BY_VIEW_B, PELICAN_BY_VIEW,
					PELICAN_BY_VIEW_B])
		EventDef.Look.ICE_CREAM_VAN:
			_collect_views(sources, [ICE_CREAM_VAN_BY_VIEW])
		EventDef.Look.LORRY:
			_collect_views(sources, [LORRY_BY_VIEW, LORRY_WHEELS_BY_VIEW])
		EventDef.Look.CHARGING_DOG:
			_collect_views(sources, [CHARGING_DOG_RESTING_BY_VIEW, CHARGING_DOG_ALERT_BY_VIEW,
					CHARGING_DOG_BY_VIEW, CHARGING_DOG_BY_VIEW_B])
		EventDef.Look.CHATTING_MOTHER:
			_collect_views(sources, [CHATTING_MOTHER_WALKING_BY_VIEW,
					CHATTING_MOTHER_WALKING_BY_VIEW_B, CHATTING_MOTHER_TALKING_BY_VIEW])
		EventDef.Look.POLICE_CAR:
			_collect_views(sources, [POLICE_CAR_BY_VIEW, POLICE_CAR_WHEELS_BY_VIEW])
		EventDef.Look.POSTER_CREW:
			_collect_views(sources, [POSTER_CREW_BY_VIEW, POSTER_CREW_BY_VIEW_B])
		EventDef.Look.POSTER_CREW_SQUARE:
			_collect_views(sources, [POSTER_CREW_SQUARE_BY_VIEW])
		EventDef.Look.ROADBLOCK:
			_collect(sources, [ROADBLOCK_SEGMENT, ROADBLOCK_SEGMENT_VERTICAL, ROADBLOCK_END])
			_collect_views(sources, [GUARD_STANDING_BY_VIEW, GUARD_ALERT_BY_VIEW,
					GUARD_LUNGING_BY_VIEW])
		EventDef.Look.UNMARKED_VAN:
			_collect_views(sources, [UNMARKED_VAN_BY_VIEW, UNMARKED_VAN_WHEELS_BY_VIEW,
					VAN_VICTIM_BY_VIEW, VAN_VICTIM_BY_VIEW_B])
		EventDef.Look.ROBBER:
			_collect_views(sources, [ROBBER_WAITING_BY_VIEW, ROBBER_ALERT_BY_VIEW,
					ROBBER_ALERT_BY_VIEW_B, ROBBER_LUNGING_BY_VIEW, ROBBER_LUNGING_BY_VIEW_B])
		EventDef.Look.ROBBER_GIVING_CHASE:
			# Sent already chasing: no notice, so no alert to draw.
			_collect_views(sources, [ROBBER_WAITING_BY_VIEW, ROBBER_LUNGING_BY_VIEW,
					ROBBER_LUNGING_BY_VIEW_B])
		EventDef.Look.RIOT_VAN:
			_collect_views(sources, [RIOT_VAN_BY_VIEW, RIOT_VAN_WHEELS_BY_VIEW])
		EventDef.Look.ARMY_TRUCK:
			_collect_views(sources, [ARMY_TRUCK_BY_VIEW, ARMY_TRUCK_WHEELS_BY_VIEW])
		EventDef.Look.BARRICADE:
			_collect(sources, [BARRICADE_PILE])
		EventDef.Look.PROTEST:
			_collect_views(sources, [PROTESTER_BY_VIEW, PROTESTER_BY_VIEW_B])
			_collect(sources, [PROTESTER])
			_collect(sources, POINTING_POSES)
		EventDef.Look.FIREFIGHT:
			_collect(sources, [GUNMAN])
		EventDef.Look.FALLEN_TREE:
			_collect(sources, [FALLEN_TREE, FALLEN_TREE_VERTICAL])
		EventDef.Look.CAR_ACCIDENT:
			_collect(sources, [CAR_ACCIDENT, CAR_ACCIDENT_VERTICAL, CAR_ACCIDENT_SHADOW,
					CAR_ACCIDENT_VERTICAL_SHADOW, CAR_ACCIDENT_B, CAR_ACCIDENT_VERTICAL_B])
		EventDef.Look.BURST_MAIN:
			_collect(sources, [BURST_MAIN, BURST_MAIN_VERTICAL, BURST_MAIN_B,
					BURST_MAIN_VERTICAL_B])
		EventDef.Look.COLLAPSED_FRONTAGE:
			_collect(sources, [COLLAPSED_FRONTAGE])
		EventDef.Look.SCAFFOLDING:
			_collect(sources, [SCAFFOLDING])
		EventDef.Look.SKIP:
			_collect(sources, [SKIP])
		EventDef.Look.MOVING_VAN:
			_collect(sources, [MOVING_VAN, MOVING_VAN_VERTICAL])
		EventDef.Look.BURNT_OUT_CAR:
			_collect(sources, [BURNT_OUT_CAR, BURNT_OUT_CAR_VERTICAL])
		EventDef.Look.CHECKPOINT_HUT:
			_collect(sources, [HUT_NORTH, HUT_SOUTH, HUT_EAST, HUT_WEST, GUARD_STANDING,
					GUARD_ALERT_BY_VIEW["front"]])
		EventDef.Look.CHECKPOINT_GATE:
			_collect(sources, [BOOM_GATE_NS_LOWERED, BOOM_GATE_NS_RAISED, BOOM_GATE_EW_LOWERED,
					BOOM_GATE_EW_RAISED])
		EventDef.Look.CHECKPOINT_POST:
			_collect(sources, [GUARD_STANDING, GUARD_ALERT_BY_VIEW["front"]])
		EventDef.Look.IMPACT_CRATER:
			_collect(sources, [IMPACT_CRATER])
		EventDef.Look.DOOR_GUARD:
			_collect_views(sources, [GUARD_STANDING_BY_VIEW, GUARD_ALERT_BY_VIEW,
					GUARD_LUNGING_BY_VIEW])
		EventDef.Look.VAN_GUARD_GIVING_CHASE:
			# Sent already chasing: no notice, so no alert to draw.
			_collect_views(sources, [GUARD_STANDING_BY_VIEW, GUARD_LUNGING_BY_VIEW])
		EventDef.Look.MASKED_PURSUER, EventDef.Look.GUARDSMAN_GIVING_CHASE:
			# The masked man's notice at the foot of the shaft, and the guardsman's out of a
			# vehicle.
			_collect_views(sources, [GUARD_STANDING_BY_VIEW, GUARD_ALERT_BY_VIEW,
					GUARD_LUNGING_BY_VIEW])
		EventDef.Look.POLICEMAN_GIVING_CHASE:
			# His alert is the man out of a vehicle's; the one a torn poster sends never shows it.
			_collect_views(sources, [POLICEMAN_WAITING_BY_VIEW, POLICEMAN_ALERT_BY_VIEW,
					POLICEMAN_LUNGING_BY_VIEW, POLICEMAN_LUNGING_BY_VIEW_B])
			_collect(sources, [POLICEMAN_LUNGING])
		EventDef.Look.STEAM:
			_collect(sources, [STEAM, STEAM_B])
		EventDef.Look.LOUDSPEAKER_MAST:
			_collect(sources, [MAST, MAST_LAMP, SOUND_PULSE])
	# A `Dictionary` while it is being built, because several arms reach the same picture twice —
	# the dog walker's own dog is the loose dog's, and the guard stands at three different rows —
	# and a look's pictures are a set rather than a list.
	var paths: Array[String] = []
	for picture: String in sources.keys():
		paths.append(picture)
	paths.sort()
	return paths

static func _collect(sources: Dictionary, pictures: Array) -> void:
	for picture: String in pictures:
		sources[picture] = true

static func _collect_views(sources: Dictionary, tables: Array) -> void:
	for table: Dictionary in tables:
		for view in table.keys():
			sources[str(table[view])] = true

## The five-view generalisation of `EventLook._draw_simple`, for a family that has the full
## front/back/side/diagonal set — `EventLook._select_view()` picks the view from `heading` and
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
## `EventLook._draw_simple` itself is untouched and keeps drawing the one row that has no
## directional family at all: `skip`.
##
## `by_view_b` is the family's own feet-passing set, read off `EventLook._gait_stepping()` when
## given — empty for every vehicle family, which has no stride, so the lookup falls through to
## `by_view`.
##
## **A look in `WHEELS_BY_LOOK` is drawn in two layers, and its wheels and its shadow stay on the
## ground.** `EventLook.draw()` and `EntityHalo` both lift the canvas by `EventLook.current_bob()`
## before calling here, so the wheels picture and the shadow are drawn back down by the same amount
## and only the body rises and falls; the wheels go over the body or, for the pictures in
## `WHEELS_BEHIND_THE_BODY`, under it.
##
## **`draw_shadow` is false only for `RoadblockLook._draw_roadblock()`'s guard.** Every other
## caller's own body shadow — `def.parts()`'s default single piece, `def.shape` at local origin — is
## exactly the shadow this row wants under the picture this function draws. A heated roadblock's
## guard is the one exception: `def.shape` there is the barrier band's own shape, not his, and the
## band's real shadow is already drawn separately, back at the post he left
## (`SpreadLook._draw_spread()`); the automatic call here would draw a second, band-shaped shadow
## under his current position instead of his own small one, so `RoadblockLook._draw_roadblock()`
## draws that shadow itself and passes `false`.
##
## `at` is where the feet stand in local space: the node's own origin for every caller but
## `RoadblockLook._draw_roadblock()`, whose guard stands beside his band rather than on its centre.
## How much empty canvas each police car view leaves below its own drawn content, in px, read off
## the SVGs (`art/events/police_car*.svg`): the side view's tyres touch its bottom row, the front
## and back views' bodies end two rows above theirs and the diagonals' tyres two rows above theirs —
## the same margins the crowd car's views leave (`CrowdAgent.CAR_CANVAS_BOTTOM_MARGIN`).
const POLICE_CAR_CANVAS_BOTTOM_MARGIN := {
	"front": 2.0,
	"back": 2.0,
	"side": 0.0,
	"front_diagonal": 2.0,
	"back_diagonal": 2.0,
}

## The same for the fire engine's views (`art/events/fire_engine*.svg`): the side view's tyres end
## a row above its canvas's bottom, the front and back views' wheels five rows above theirs and the
## diagonals' four.
const FIRE_ENGINE_CANVAS_BOTTOM_MARGIN := {
	"front": 5.0,
	"back": 5.0,
	"side": 1.0,
	"front_diagonal": 4.0,
	"back_diagonal": 4.0,
}

## The canvas margins of the car family `look` belongs to — a patrol car's or the fire engine's —
## both bodies a segment `EventDef.vehicle` lays along the heading and a picture anchored over it.
static func canvas_margins(look: EventDef.Look) -> Dictionary:
	return FIRE_ENGINE_CANVAS_BOTTOM_MARGIN if look == EventDef.Look.FIRE_ENGINE \
			else POLICE_CAR_CANVAS_BOTTOM_MARGIN

## Whether `look` is a body whose picture is anchored over it by `EventLook._body_anchor()`: the
## patrol car's and the fire engine's, the two looks of a car that drives (`EventDef.vehicle`).
static func is_anchored_over_its_body(look: EventDef.Look) -> bool:
	return look == EventDef.Look.POLICE_CAR or look == EventDef.Look.FIRE_ENGINE

## The eight pointing poses, in the bearing order `protester_texture()` indexes into: north
## first, then clockwise. Kept beside the poses themselves rather than built in the function, so
## the table is one thing to read rather than eight `match` arms.
const POINTING_POSES: Array[String] = [
	PROTESTER_POINT_N, PROTESTER_POINT_NE, PROTESTER_POINT_E, PROTESTER_POINT_SE,
	PROTESTER_POINT_S, PROTESTER_POINT_SW, PROTESTER_POINT_W, PROTESTER_POINT_NW,
]

## The plain rank, or whichever of the eight `protester_point_*` poses points closest to
## `objective` from `from`. `Vector2.INF` is "nothing to point at" — a chalk-mark step or no step
## at all — and draws the same plain `PROTESTER` the row always used. *(2026-09-11, the player:
## "the mark is findable now -- I don't think we need pointing for that. but the other tasks are
## not as easy and need pointing.")*
##
## The bearing is `RunTrace.compass()`'s own arithmetic — clockwise from north (`-y`), through
## east (`+x`) at 90° — rounded to the nearest of the eight 45° sectors the poses were drawn for.
static func protester_texture(from: Vector2, objective: Vector2) -> String:
	if objective == Vector2.INF:
		return PROTESTER
	var toward := objective - from
	if toward.length_squared() < 0.0001:
		return PROTESTER
	var bearing := rad_to_deg(atan2(toward.x, -toward.y))
	var sector := roundi(bearing / 45.0) % 8
	if sector < 0:
		sector += 8
	return POINTING_POSES[sector]

## Whether a gate sited with `along_axis` bars a road running north-south, and so draws the boom
## whose arm spans east-west. `along_axis` is the street's own along-axis, which
## `RegionPlanner._along_axis` sets to `DOWN` for a north-south street and `RIGHT` for an east-west
## one. Named rather than inlined so the drawing and the test that measures it read the same rule.
static func gate_runs_north_south(along_axis: Vector2) -> bool:
	return absf(along_axis.y) > absf(along_axis.x)

## How far the lowered arm reaches to either side of the gate's own ground point, across the road
## it bars: `x` the near edge (negative), `y` the far edge, in pixels along the cross-street axis.
## This is the number the player reads as *the bar is on the road* or *the bar is on the kerb*, and
## nothing in `EventLook.draw()` can be asserted headless — see `tests/test_checkpoints.gd`.
static func boom_arm_span(runs_north_south: bool) -> Vector2:
	if runs_north_south:
		var ns := BOOM_NS_ARM.position.x - BOOM_NS_ANCHOR.x
		return Vector2(ns, ns + BOOM_NS_ARM.size.x)
	var ew := BOOM_EW_ARM.position.y - BOOM_EW_ANCHOR.y
	return Vector2(ew, ew + BOOM_EW_ARM.size.y)
