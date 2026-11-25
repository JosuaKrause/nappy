class_name Prop
extends ScenerySprite
## Small scenery. Feet-anchored like everything else, so it y-sorts against the player:
## she passes behind a tree's canopy and in front of its trunk.

enum Kind { TREE, PLAYGROUND_FRAME, BOLLARD, STREET_TREE, SACK, SACK_PILE }

## Region names in the "decoration" atlas group (`CityDecals.DECORATION_ATLAS`), whose lifetime
## is the city's: `City.build()` acquires the group on its library before any prop is spawned and
## `City._exit_tree()` releases it, so every region asked for below is always available. A tree's
## pictures and its ground shape are `TreePictures`', which the street trees' planner reads too.
const SWING_FRAME := &"props/swing_frame"
const BOLLARD := &"props/bollard"
const SACK := &"props/garbage_sack"
const SACK_PILE := &"props/garbage_sacks_pile"

@export var _kind := Kind.TREE
## Deterministic per-prop variation, so a park does not shimmer between frames.
@export var _variant := 0
@export var _scale_factor := 1.0
## The city's library (`AtlasLibrary`), handed before the prop is added: the city holds the
## decoration group on it, and the prop draws its regions from it.
var atlas: AtlasLibrary

## Dresses the prop before it is added: drawn from `library` as `as_kind`, with `with_variant` and
## `scaled` varying its look (a park tree's scale: a street tree is drawn at its picture's own size
## whatever it is dressed with). See `atlas`, `kind()`, `variant()` and `scale_factor()`.
func dress(library: AtlasLibrary, as_kind: Kind, with_variant := 0, scaled := 1.0) -> void:
	atlas = library
	_kind = as_kind
	_variant = with_variant
	_scale_factor = scaled

## What the prop is.
func kind() -> Kind:
	return _kind

## The prop's deterministic variation: which of two tree pictures it draws, and which way round.
func variant() -> int:
	return _variant

## How much larger than its picture's own size the prop is drawn.
func scale_factor() -> float:
	return _scale_factor

## This prop's own ground shape — a point for a tree, a street tree, the bollard, a sack or a
## sack pile, sized off the same texture fraction the shadow always used; a segment for the swing
## frame, from one A-frame to the other (`_playground_frame_shape()`). Computed once `_ready()`
## fires, by which point the prop has been dressed (`dress()`), and read for the shadow
## (`shadow_outlines()`). **No prop has a
## body** except the bollard (`_add_bollard_body()`). A tree on a pavement is walked past exactly
## like a tree in a park *(2026-09-12, the
## player, PLAYTEST-58.md: "trees shouldn't have a hitbox at all. trees in parks don't why should
## the ones in the street be treated differently?")*; a sack or a pile carries none either, so the
## ground under it stays exactly as walkable as the pavement or alley it stands on. Decoration
## only — see `GarbageSacks`' own class doc for why a pile is not yet an obstruction.
var _shape: GroundShape

## The post's body, once `_ready()` has made it; null for every other prop.
var _body: StaticBody2D

## The collision shape of the post's body, or null for a prop with none (every prop but a post): the circle its shadow is
## drawn from.
func body_shape() -> Shape2D:
	return null if _body == null else (_body.get_child(0) as CollisionShape2D).shape

func _ready() -> void:
	_shape = _compute_shape()
	if _kind == Kind.BOLLARD:
		_add_bollard_body()

## **The one prop with a body: a precinct's post.** A `StaticBody2D` holding `_shape`'s own
## collision resource, so the post's body is the ground contact its shadow is drawn from (one shape
## per object, M61) rather than a second number. A tree, a sack and a pile stay bodiless; a post
## stops her *(2026-10-10, the player, azure-puffin, on the bollards: "it will make the middle of
## the road impassable when going from street to pedestrian road. that's okay. this is intended")*,
## and `CityMap.BOLLARD_SPACING` keeps every gap between posts narrower than her body, so a row of
## them shuts the carriageway band while the pavements beside it stay open. Open to overturn: the
## radius is the shadow's 0.4 of the 12px picture (4.8px), not the picture's 6px rim.
func _add_bollard_body() -> void:
	var body := StaticBody2D.new()
	body.name = "BollardBody"
	_body = body
	var collision := CollisionShape2D.new()
	collision.shape = _shape.collision_shape()
	body.add_child(collision)
	add_child(body)

## A post's ground shape: a point of 0.4 of the 12px picture (4.8px), the one definition its body,
## its shadow and anything planning round it (`RouteRigPlanner`, the route rig's planner) read.
static func bollard_shape() -> GroundShape:
	return GroundShape.point(AtlasTable.baked().native_size(BOLLARD).x * 0.4)

func _compute_shape() -> GroundShape:
	match _kind:
		Kind.TREE:
			return TreePictures.shape(_variant, _scale_factor)
		Kind.STREET_TREE:
			return TreePictures.street_tree_shape(_variant)
		Kind.PLAYGROUND_FRAME:
			return _playground_frame_shape()
		Kind.BOLLARD:
			return bollard_shape()
		Kind.SACK:
			return GroundShape.point(AtlasTable.baked().native_size(SACK).x * 0.35)
		Kind.SACK_PILE:
			return GroundShape.point(AtlasTable.baked().native_size(SACK_PILE).x * 0.3)
		_:
			return GroundShape.point(0.0)

func _draw() -> void:
	if not residence().is_resident():
		return
	match _kind:
		Kind.TREE:
			_draw_tree()
		Kind.PLAYGROUND_FRAME:
			_draw_shadow()
			Sprites.draw_standing(self, atlas.region(SWING_FRAME), Vector2.ZERO)
		Kind.BOLLARD:
			_draw_shadow()
			Sprites.draw_standing(self, atlas.region(BOLLARD), Vector2.ZERO)
		Kind.SACK:
			_draw_shadow()
			Sprites.draw_standing(self, atlas.region(SACK), Vector2.ZERO)
		Kind.SACK_PILE:
			_draw_shadow()
			Sprites.draw_standing(self, atlas.region(SACK_PILE), Vector2.ZERO)
		Kind.STREET_TREE:
			_draw_street_tree()

## Fills this prop's shadow where it stands: the one place every kind of prop draws its shadow
## through, so the drawing and the debug view's trace (`shadow_outlines()`) read one thing.
func _draw_shadow() -> void:
	for outline in shadow_outlines(Vector2.ZERO):
		draw_colored_polygon(outline, Palette.SHADOW)

## The ground this prop's shadow covers standing at `at`, what `_draw()` fills and the debug view's
## shadow layer (`DebugLayers`, `--layers 2`) traces: one oval under each A-frame of the swing
## frame (`GroundShape.paired_shadow_outlines()`, the cars' one oval per wheel pair, on the bottom
## row of its picture), since a shadow lies where a thing meets the ground and not across its whole
## picture (minty-hedgehog 1); the ground shape's own outline for every other prop, a tree's oval
## already lying at its trunk's foot. Empty for a shape too small to cast one
## (`GroundShape.casts_a_shadow()`).
func shadow_outlines(at: Vector2) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	if _shape == null or not _shape.casts_a_shadow():
		return outlines
	if _kind == Kind.PLAYGROUND_FRAME:
		return _shape.paired_shadow_outlines(at, Vector2.RIGHT, 0.0)
	outlines.append(_shape.shadow_outline(at))
	return outlines

## How far each A-frame's feet stand from the swing frame's middle, as a share of half its width:
## `swing_frame.svg` stands each A-frame's two feet across one half of its 56px (6 to 21 and 35 to
## 50), round the middle of that half.
const SWING_A_FRAME_SHARE := 0.5

## The swing frame's own ground shape — a segment from one A-frame to the other, read off the
## region table the same way `CrowdAgent`'s car reads its two: its spine's ends under the two
## A-frames' feet (`SWING_A_FRAME_SHARE` of half its width from the middle), and its rounding the
## frame's depth, read as half its picture's own height, which is how far each A-frame's legs reach
## before and behind its crossbar.
static func _playground_frame_shape() -> GroundShape:
	var size := Vector2(AtlasTable.baked().native_size(SWING_FRAME))
	return GroundShape.segment(size.x * 0.5 * SWING_A_FRAME_SHARE, size.y * 0.5)

## **The ground ellipse at the swing frame's base**, its semi-axes in px round the bottom centre the
## frame stands on: half its picture's width and half its height (the ellipse's semi-axes, so it
## spans the whole picture, 56 by 34px), 28 by 17px for `swing_frame.svg`'s 56 by 34 — the spot day 12's task is touched at
## (`ResistanceDirector._shape_the_touch()`). Read off the region table rather than the shadow, so
## the shadow lying under the frame's feet leaves the spot the size and the place it is: both ovals
## of the shadow lie inside it.
static func swing_frame_base() -> Vector2:
	return Vector2(AtlasTable.baked().native_size(SWING_FRAME)) * 0.5

## Two tree shapes and a mirror, so ten trees in a park are not one silhouette repeated.
func _draw_tree() -> void:
	_draw_tree_at(TreePictures.drawn_size(_variant, _scale_factor))

## The same standing tree every park tree draws, at its picture's own size whatever the prop was
## dressed with (`TreePictures.street_tree_size()`). The street tree's pit is a ground decal owned
## by `CityDecals`, so it stays under the player and other entities.
func _draw_street_tree() -> void:
	_draw_tree_at(TreePictures.street_tree_size(_variant))

## A tree picture drawn `size` large, with its shadow. The size is read off the region table rather
## than off the drawn texture: a region reports its source's own size.
func _draw_tree_at(size: Vector2) -> void:
	_draw_shadow()
	Sprites.draw_standing(self, atlas.region(TreePictures.region(_variant)), Vector2.ZERO, size,
			absi(_variant) % 4 < 2)
