class_name Prop
extends Node2D
## Small scenery. Feet-anchored like everything else, so it y-sorts against the player:
## she passes behind a tree's canopy and in front of its trunk.

enum Kind { TREE, PLAYGROUND_FRAME, BOLLARD, STREET_TREE, SACK, SACK_PILE }

const TREES: Array[Texture2D] = [
	preload("res://assets/props/tree_a.svg"),
	preload("res://assets/props/tree_b.svg"),
]
const SWING_FRAME := preload("res://assets/props/swing_frame.svg")
const BOLLARD := preload("res://assets/props/bollard.svg")
const TREE_PIT := preload("res://assets/props/tree_pit.svg")
const SACK := preload("res://assets/props/garbage_sack.svg")
const SACK_PILE := preload("res://assets/props/garbage_sacks_pile.svg")

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
			var size := TREES[absi(variant) % TREES.size()].get_size() * scale_factor
			return GroundShape.point(size.x * 0.28)
		Kind.PLAYGROUND_FRAME:
			return _playground_frame_shape()
		Kind.BOLLARD:
			return GroundShape.point(BOLLARD.get_size().x * 0.4)
		Kind.SACK:
			return GroundShape.point(SACK.get_size().x * 0.35)
		Kind.SACK_PILE:
			return GroundShape.point(SACK_PILE.get_size().x * 0.3)
		_:
			return GroundShape.point(0.0)

func _draw() -> void:
	match kind:
		Kind.TREE:
			_draw_tree()
		Kind.PLAYGROUND_FRAME:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, SWING_FRAME, Vector2.ZERO)
		Kind.BOLLARD:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, BOLLARD, Vector2.ZERO)
		Kind.SACK:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, SACK, Vector2.ZERO)
		Kind.SACK_PILE:
			shape.draw_shadow(self, Vector2.ZERO)
			Sprites.draw_standing(self, SACK_PILE, Vector2.ZERO)
		Kind.STREET_TREE:
			_draw_street_tree()

## The swing frame's own shadow shape — a capsule along its width, read off its own texture the
## same way `CrowdAgent`'s car reads its two: `radius` from the frame's depth (its texture height),
## `half_length` from what is left of half its width once the rounded ends are accounted for.
static func _playground_frame_shape() -> GroundShape:
	var size := SWING_FRAME.get_size()
	var radius := size.y * 0.5
	return GroundShape.segment(size.x * 0.5 - radius, radius)

## Two tree shapes and a mirror, so ten trees in a park are not one silhouette repeated.
func _draw_tree() -> void:
	var texture: Texture2D = TREES[absi(variant) % TREES.size()]
	var size := texture.get_size() * scale_factor
	shape.draw_shadow(self, Vector2.ZERO)
	Sprites.draw_standing(self, texture, Vector2.ZERO, size, absi(variant) % 4 < 2)

## The pit first — a ground decal at the node's own point, `tree_pit.svg`'s own contract ("ground
## anchor is the canvas centre") — then the same standing tree every park tree draws, unscaled by
## `scale_factor`: the pit is a tile of paving, not a canopy, so it stays tile-sized regardless of
## which tree stands in it.
func _draw_street_tree() -> void:
	var pit := TextureResolver.resolve(TREE_PIT)
	draw_texture_rect(pit, Rect2(-pit.get_size() * 0.5, pit.get_size()), false)
	_draw_tree()
