class_name EventLooks
extends RefCounted
## Which look draws a row: the family its picture (`EventDef.picture()`) belongs to. The one place a
## row's picture picks a class, as `EventBehaviours.compose()` is the one place its data picks its
## behaviours.

## The look that draws `event`, a live one of `row`: the family `row`'s picture belongs to, handed
## the event, the row, the drawer it paints through and whether nothing of it is drawn
## (`skip_draw`, `--skip events`), none of which changes under it.
static func for_row(event: EventInstance, row: EventDef, drawer: EventDrawer,
		skip_draw: bool) -> EventLook:
	match row.picture():
		EventDef.Look.CAT, EventDef.Look.MOUSE, EventDef.Look.YELLER, EventDef.Look.NEIGHBOR, \
				EventDef.Look.DOG_WALKER, EventDef.Look.BUSKER, EventDef.Look.LOOSE_DOG, \
				EventDef.Look.LEAF_BLOWER, EventDef.Look.CYCLIST, EventDef.Look.CHARGING_DOG, \
				EventDef.Look.CHATTING_MOTHER, EventDef.Look.POSTER_CREW, \
				EventDef.Look.POSTER_CREW_SQUARE, EventDef.Look.SKIP, EventDef.Look.IMPACT_CRATER, \
				EventDef.Look.STEAM, EventDef.Look.LOUDSPEAKER_MAST:
			return FigureLook.new(event, row, drawer, skip_draw)
		EventDef.Look.DELIVERY_VAN, EventDef.Look.FIRE_ENGINE, EventDef.Look.ICE_CREAM_VAN, \
				EventDef.Look.LORRY, EventDef.Look.POLICE_CAR, EventDef.Look.UNMARKED_VAN, \
				EventDef.Look.RIOT_VAN, EventDef.Look.ARMY_TRUCK, EventDef.Look.MOVING_VAN, \
				EventDef.Look.BURNT_OUT_CAR:
			return EventVehicleLook.new(event, row, drawer, skip_draw)
		EventDef.Look.ROBBER, EventDef.Look.ROBBER_GIVING_CHASE, EventDef.Look.MASKED_PURSUER, \
				EventDef.Look.DOOR_GUARD, EventDef.Look.VAN_GUARD_GIVING_CHASE, \
				EventDef.Look.GUARDSMAN_GIVING_CHASE, EventDef.Look.POLICEMAN_GIVING_CHASE:
			return PursuerLook.new(event, row, drawer, skip_draw)
		EventDef.Look.BIRDS:
			return FlockLook.new(event, row, drawer, skip_draw)
		EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.BARRICADE, \
				EventDef.Look.COLLAPSED_FRONTAGE, EventDef.Look.SCAFFOLDING, \
				EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN:
			return SpreadLook.new(event, row, drawer, skip_draw)
		EventDef.Look.CAFE, EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT:
			return RankLook.new(event, row, drawer, skip_draw)
		EventDef.Look.ROADBLOCK:
			return RoadblockLook.new(event, row, drawer, skip_draw)
		EventDef.Look.BURNING_BUILDING:
			return FireLook.new(event, row, drawer, skip_draw)
		EventDef.Look.CHECKPOINT_HUT, EventDef.Look.CHECKPOINT_GATE, EventDef.Look.CHECKPOINT_POST:
			return CheckpointLook.new(event, row, drawer, skip_draw)
	# `NONE`, and `BURNT_SHELL`, drawn on the building it stands against.
	return EventLook.new(event, row, drawer, skip_draw)
