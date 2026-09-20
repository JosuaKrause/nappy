class_name Prop
extends Node2D
## Small scenery. Feet-anchored like everything else, so it y-sorts against the player:
## she passes behind a tree's canopy and in front of its trunk.

enum Kind { TREE, PLAYGROUND_FRAME, BOLLARD, STREET_TREE, SACK, SACK_PILE }

## `AtlasLibrary` region names in the "decoration" group (`CityDecals.DECORATION_ATLAS`), whose
## lifetime is the city's: `City.build()` acquires the group before any prop is spawned and
## `City._exit_tree()` releases it, so every region asked for below is always available.
## `AtlasLibrary.native_size()` answers with nothing acquired, which is what lets
## `StreetTrees.footprint_radius()` plan tree clearance off `TREES` ahead of any city existing.
const TREES: Array[StringName] = [&"props/tree_a", &"props/tree_b"]
const SWING_FRAME := &"props/swing_frame"
const BOLLARD := &"props/bollard"
const SACK := &"props/garbage_sack"
const SACK_PILE := &"props/garbage_sacks_pile"

@export var kind := Kind.TREE
## Deterministic per-prop variation, so a park does not shimmer between frames.
@export var variant := 0
@export var scale_factor := 1.0

## This prop's own ground shape — a point for a tree, a street tree, the bollard, a sack or a
## sack pile, sized off the same texture fraction the shadow always used; a capsule for the swing
## frame (`_playground_frame_shape()`). Computed once `_ready()` fires, by which point `city.gd`
## has already set `kind`, `variant` and `scale_factor` on the new node (`Prop.new()` then the
## three exports, then `add_child()`), and read by `_draw()` for the shadow. **No prop has a
## body.** A tree on a pavement is walked past exactly like a tree in a park *(2026-09-12, the
## player, PLAYTEST-58.md: "trees shouldn't have a hitbox at all. trees in parks don't why should
## the ones in the street be treated differently?")*; a sack or a pile carries none either, so the
## ground under it stays exactly as walkable as the pavement or alley it stands on. Decoration
## only — see `GarbageSacks`' own class doc for why a pile is not yet an obstruction.
var shape: GroundShape

func _ready() -> void:
	shape = _compute_shape()

func _compute_shape() -> GroundShape:
	match kind:
		Kind.TREE, Kind.STREET_TREE:
			var size := Vector2(AtlasLibrary.native_size(TREES[absi(variant) % TREES.size()])) \
					* scale_factor
			return GroundShape.point(size.x * 0.28)
		Kind.PLAYGROUND_FRAME:
			return _playground_frame_shape()
		Kind.BOLLARD:
			return GroundShape.point(AtlasLibrary.native_size(BOLLARD).x * 0.4)
		Kind.SACK:
			return GroundShape.point(AtlasLibrary.native_size(SACK).x * 0.35)
		Kind.SACK_PILE:
			return GroundShape.point(AtlasLibrary.native_size(SACK_PILE).x * 0.3)
		_:
			return GroundShape.point(0.0)

func _draw() -> void:
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PLAYGROUND_FRAME:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, AtlasLibrary.region(SWING_FRAME), Vector2.ZERO)
		Kind.BOLLARD:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, AtlasLibrary.region(BOLLARD), Vector2.ZERO)
		Kind.SACK:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, AtlasLibrary.region(SACK), Vector2.ZERO)
		Kind.SACK_PILE:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, AtlasLibrary.region(SACK_PILE), Vector2.ZERO)
		Kind.STREET_TREE:
			_draw_street_tree()

## The swing frame's own shadow shape — a capsule along its width, read off the region table the
## same way `CrowdAgent`'s car reads its two: `radius` from the frame's depth (its picture's own
## height), `half_length` from what is left of half its width once the rounded ends are accounted
## for.
static func _playground_frame_shape() -> GroundShape:
	var size := Vector2(AtlasLibrary.native_size(SWING_FRAME))
	var radius := size.y * 0.5
	return GroundShape.segment(size.x * 0.5 - radius, radius)

## Two tree shapes and a mirror, so ten trees in a park are not one silhouette repeated.
func _draw_tree() -> void:
	var name: StringName = TREES[absi(variant) % TREES.size()]
	# The size is read off the region table rather than off the drawn texture, since `scale_factor`
	# is applied here and the two answer the same number either way — a region reports its
	# source's own size.
	var size := Vector2(AtlasLibrary.native_size(name)) * scale_factor
	shape.draw_shadow(self, Vector2.ZERO)
	Sprites.draw_standing(self, AtlasLibrary.region(name), Vector2.ZERO, size, absi(variant) % 4 < 2)

## The same standing tree every park tree draws, unscaled by `scale_factor`. The street tree's pit
## is a ground decal owned by `CityDecals`, so it stays under the player and other entities.
func _draw_street_tree() -> void:
	_draw_tree()
