class_name EventLooks
extends RefCounted
## Which look draws a row: the family its picture (`EventDef.look`) belongs to. The one place a
## row's picture picks a class, as `EventBehaviours.compose()` is the one place its data picks its
## behaviours.

## The look that draws `event`'s row.
static func for_row(event: EventInstance) -> EventLook:
	match event.def.look:
		EventDef.Look.CAT, EventDef.Look.MOUSE, EventDef.Look.YELLER, EventDef.Look.NEIGHBOR, \
				EventDef.Look.DOG_WALKER, EventDef.Look.BUSKER, EventDef.Look.LOOSE_DOG, \
				EventDef.Look.LEAF_BLOWER, EventDef.Look.CYCLIST, EventDef.Look.CHARGING_DOG, \
				EventDef.Look.CHATTING_MOTHER, EventDef.Look.POSTER_CREW, \
				EventDef.Look.POSTER_CREW_SQUARE, EventDef.Look.SKIP, EventDef.Look.IMPACT_CRATER, \
				EventDef.Look.STEAM, EventDef.Look.LOUDSPEAKER_MAST:
			return FigureLook.new(event)
		EventDef.Look.DELIVERY_VAN, EventDef.Look.FIRE_ENGINE, EventDef.Look.ICE_CREAM_VAN, \
				EventDef.Look.LORRY, EventDef.Look.POLICE_CAR, EventDef.Look.UNMARKED_VAN, \
				EventDef.Look.RIOT_VAN, EventDef.Look.ARMY_TRUCK, EventDef.Look.MOVING_VAN, \
				EventDef.Look.BURNT_OUT_CAR:
			return EventVehicleLook.new(event)
		EventDef.Look.ROBBER, EventDef.Look.ROBBER_GIVING_CHASE, EventDef.Look.MASKED_PURSUER, \
				EventDef.Look.DOOR_GUARD, EventDef.Look.VAN_GUARD_GIVING_CHASE, \
				EventDef.Look.GUARDSMAN_GIVING_CHASE, EventDef.Look.POLICEMAN_GIVING_CHASE:
			return PursuerLook.new(event)
		EventDef.Look.BIRDS:
			return FlockLook.new(event)
		EventDef.Look.ROADWORKS, EventDef.Look.STALL, EventDef.Look.BARRICADE, \
				EventDef.Look.COLLAPSED_FRONTAGE, EventDef.Look.SCAFFOLDING, \
				EventDef.Look.FALLEN_TREE, EventDef.Look.CAR_ACCIDENT, EventDef.Look.BURST_MAIN:
			return SpreadLook.new(event)
		EventDef.Look.CAFE, EventDef.Look.PROTEST, EventDef.Look.FIREFIGHT:
			return RankLook.new(event)
		EventDef.Look.ROADBLOCK:
			return RoadblockLook.new(event)
		EventDef.Look.BURNING_BUILDING:
			return FireLook.new(event)
		EventDef.Look.CHECKPOINT_HUT, EventDef.Look.CHECKPOINT_GATE, EventDef.Look.CHECKPOINT_POST:
			return CheckpointLook.new(event)
	# `NONE`, and `BURNT_SHELL`, drawn on the building it stands against.
	return EventLook.new(event)
