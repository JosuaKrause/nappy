class_name HintKind
extends RefCounted
## **The thought-bubble hints and the picture each one holds** (`ThoughtBubble`). One enum, so a
## watcher names its hint and the ledger counts it by the same id.
##
## **Which set of pictures the game draws is one line**: `ICON_SET_SUFFIX`. The first set is a small
## scene per hint (`""`), the simple set beside it is just each hint's thing (`"_simple"`); the
## player keeps one (the board question bubble-set), so the choice is not made in the code.
## *Proposed, not asked for:* the simple set, the one the player asked for ("keep both versions for
## comparison", inbox #1771 in spry-wombat).

enum Kind { BACK_TO_ROUTE, USE_ZEBRA, WALK_WIDE, WAY_TO_PARK }

const ICON_SET_SUFFIX := "_simple"

## The hint's id, as the ledger counts it and the run log names it.
static func id_of(kind: Kind) -> StringName:
	match kind:
		Kind.BACK_TO_ROUTE:
			return &"back_to_route"
		Kind.USE_ZEBRA:
			return &"use_zebra"
		Kind.WALK_WIDE:
			return &"walk_wide"
	return &"way_to_park"

## The baked region the hint's icon is drawn from (`art/ui/hint_<name>[_simple].svg`).
static func region_of(kind: Kind) -> StringName:
	var named := "park"
	match kind:
		Kind.BACK_TO_ROUTE:
			named = "back_to_route"
		Kind.USE_ZEBRA:
			named = "crosswalk"
		Kind.WALK_WIDE:
			named = "noise"
	return StringName("ui/hint_%s%s" % [named, ICON_SET_SUFFIX])

## Whether the bubble holds the pointing arrow beside the icon (`art/ui/hint_arrow.svg`); the
## others carry their own or point nowhere.
static func points(kind: Kind) -> bool:
	return kind != Kind.WALK_WIDE
