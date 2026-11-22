class_name EventLooks
extends RefCounted
## Which look draws a row: the family its picture (`LookSpec.picture()`) belongs to. The one place a
## row's picture picks a class, as `EventBehaviours.compose()` is the one place its data picks its
## behaviours.

## The look that draws `event`, a live one of a row drawn as `look`: the family its picture belongs
## to, handed the event, the look part, the body part (`body`), the drawer it paints through,
## whether nothing of it is drawn (`skip_draw`, `--skip events`) and the box its drawing is
## gated by (`drawn_view`), none of which changes under it, the van's the abduction part its row
## takes a victim by (`abduction`, null for a row that takes nobody), and the roadblock's the
## barrier post its guards stand at (`barrier_post`, none for a row with no post).
static func for_row(event: EventInstance, look: LookSpec, body: BodySpec,
		abduction: AbductionSpec, drawer: EventDrawer, skip_draw: bool,
		drawn_view: DrawnView, barrier_post: EventBarrierPost) -> EventLook:
	match look.picture():
		EventDef.Look.CAT, EventDef.Look.MOUSE, EventDef.Look.YELLER, EventDef.Look.NEIGHBOR, \
				EventDef.Look.DOG_WALKER, EventDef.Look.BUSKER, EventDef.Look.LOOSE_DOG, \
				EventDef.Look.LEAF_BLOWER, EventDef.Look.CYCLIST, EventDef.Look.CHARGING_DOG, \
				EventDef.Look.CHATTING_MOTHER, EventDef.Look.POSTER_CREW, \
				EventDef.Look.POSTER_CREW_SQUARE, EventDef.Look.SKIP, EventDef.Look.IMPACT_CRATER, \
				EventDef.Look.STEAM, EventDef.Look.LOUDSPEAKER_MAST:
			return FigureLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.DELIVERY_VAN, EventDef.Look.FIRE_ENGINE, EventDef.Look.ICE_CREAM_VAN, \
				EventDef.Look.LORRY, EventDef.Look.POLICE_CAR, EventDef.Look.UNMARKED_VAN, \
				EventDef.Look.RIOT_VAN, EventDef.Look.ARMY_TRUCK, EventDef.Look.MOVING_VAN, \
				EventDef.Look.BURNT_OUT_CAR:
			return EventVehicleLook.new(event, look, body, abduction, drawer, skip_draw,
					drawn_view)
		EventDef.Look.ROBBER, EventDef.Look.ROBBER_GIVING_CHASE, EventDef.Look.MASKED_PURSUER, \
				EventDef.Look.DOOR_GUARD, EventDef.Look.VAN_GUARD_GIVING_CHASE, \
				EventDef.Look.GUARDSMAN_GIVING_CHASE, EventDef.Look.POLICEMAN_GIVING_CHASE:
			return PursuerLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.BIRDS:
			return FlockLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.BARRICADE, \
				EventDef.Look.COLLAPSED_FRONTAGE, EventDef.Look.SCAFFOLDING, \
				EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN:
			return SpreadLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.CAFE, EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT:
			return RankLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.ROADBLOCK:
			return RoadblockLook.new(event, look, body, drawer, skip_draw, drawn_view,
					barrier_post)
		EventDef.Look.BURNING_BUILDING:
			return FireLook.new(event, look, body, drawer, skip_draw, drawn_view)
		EventDef.Look.CHECKPOINT_HUT, EventDef.Look.CHECKPOINT_GATE, EventDef.Look.CHECKPOINT_POST:
			return CheckpointLook.new(event, look, body, drawer, skip_draw, drawn_view)
	# `NONE`, and `BURNT_SHELL`, drawn on the building it stands against.
	return EventLook.new(event, look, body, drawer, skip_draw, drawn_view)
