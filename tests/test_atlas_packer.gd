extends RefCounted
## `AtlasLibrary.plan()`'s own contract, on synthetic sizes rather than the tree's own pictures:
## `test_atlas_library.gd` holds the fill floor and aspect ceiling the real pages must clear, and
## this suite holds what a rectangle packer can be checked on directly — that it is deterministic,
## that no two placements' own padding overlaps, that a member too big for any page is named
## rather than folded into a page-sized failure, and the one behaviour PLAYTEST-109 refused: rows
## sorted by height, where a row beside a tall picture still leaves the room beside it empty.
## *"a greedy approach is fine but don't let obvious empty space go wasted."*

func run(t) -> void:
	_test_deterministic(t)
	_test_small_members_land_beside_a_tall_one_not_below_it(t)
	_test_no_two_padded_regions_overlap(t)
	_test_never_narrower_than_the_widest_member(t)
	_test_an_oversize_member_is_named_rather_than_the_page(t)
	_test_empty_input(t)
	_test_two_big_members_that_only_fit_side_by_side_above_the_square_root(t)

## Two calls on the same sizes place every member at the same spot — the free-rectangle list a
## placement leaves is a pure function of the placements before it, and the sort that decides
## placement order breaks every tie by the caller's own array position rather than by anything
## that could differ between two runs of the same tree.
func _test_deterministic(t) -> void:
	var sizes := _sample_sizes()
	var first := AtlasLibrary.plan(sizes)
	var second := AtlasLibrary.plan(sizes)
	t.check(first["size"] == second["size"], "two plans of the same sizes agree on the page size")
	var first_regions: Array = first["regions"]
	var second_regions: Array = second["regions"]
	var mismatches := 0
	for i in first_regions.size():
		if first_regions[i] != second_regions[i]:
			mismatches += 1
	t.check(mismatches == 0, "two plans of the same sizes place every member the same (%d differ)"
			% mismatches)

## The case PLAYTEST-109 refused an answer built on: one tall picture and a run of small ones.
## Sorted shelves put the tall picture alone on its own row, exactly as tall as it is, and start
## every small picture on a fresh row below — the room beside the tall one is never offered to
## anything. The free-rectangle packer keeps that room as a free rectangle the moment the tall
## one is placed, so every small member lands inside it: to the tall member's right and no lower
## than its own bottom edge.
func _test_small_members_land_beside_a_tall_one_not_below_it(t) -> void:
	var sizes: Array[Vector2i] = [Vector2i(40, 300)]
	for i in 12:
		sizes.append(Vector2i(30, 30))
	var layout := AtlasLibrary.plan(sizes)
	t.check(layout["fits"], "the tall-plus-small case fits on one page")
	var regions: Array = layout["regions"]
	var tall: Rect2i = regions[0]
	var beside_and_within := 0
	for i in range(1, regions.size()):
		var small: Rect2i = regions[i]
		var beside := small.position.x >= tall.position.x + tall.size.x
		var within_height := small.position.y >= tall.position.y \
				and small.position.y + small.size.y <= tall.position.y + tall.size.y
		if beside and within_height:
			beside_and_within += 1
	t.check(beside_and_within == sizes.size() - 1,
			"every small member lands to the tall one's right, inside its height (%d of %d)"
			% [beside_and_within, sizes.size() - 1])

## Every region grown by `AtlasLibrary.PADDING` stays clear of every other's — the geometric
## claim `test_atlas_library.gd`'s own overlap check makes about the real pages, proved here
## against sizes chosen to stress the packer rather than to be plausible art: a wide member, a
## tall one, several near-square ones and a sliver, none of them multiples of each other.
func _test_no_two_padded_regions_overlap(t) -> void:
	var sizes: Array[Vector2i] = [
		Vector2i(200, 18), Vector2i(19, 210), Vector2i(64, 61), Vector2i(63, 64),
		Vector2i(5, 90), Vector2i(90, 5), Vector2i(33, 33), Vector2i(17, 17),
		Vector2i(120, 47), Vector2i(47, 120), Vector2i(8, 8), Vector2i(150, 150),
	]
	var layout := AtlasLibrary.plan(sizes)
	t.check(layout["fits"], "the stress case fits on one page")
	var regions: Array = layout["regions"]
	var page := Rect2i(Vector2i.ZERO, layout["size"])
	var outside := 0
	for rect in regions:
		if not page.encloses((rect as Rect2i).grow(AtlasLibrary.PADDING)):
			outside += 1
	t.check(outside == 0, "every region and its padding is on the page (%d are not)" % outside)
	var overlaps := 0
	for i in regions.size():
		var a: Rect2i = (regions[i] as Rect2i).grow(AtlasLibrary.PADDING)
		for j in range(i + 1, regions.size()):
			var b: Rect2i = (regions[j] as Rect2i).grow(AtlasLibrary.PADDING)
			if a.intersects(b):
				overlaps += 1
	t.check(overlaps == 0, "no two padded regions overlap (%d pairs do)" % overlaps)

## The square-root target is a floor, not a suggestion: a lone wide member is never asked to
## share a page narrower than itself.
func _test_never_narrower_than_the_widest_member(t) -> void:
	var sizes: Array[Vector2i] = [Vector2i(500, 10), Vector2i(4, 4), Vector2i(6, 3)]
	var layout := AtlasLibrary.plan(sizes)
	t.check(layout["fits"], "a small group with one wide member fits")
	var page_size: Vector2i = layout["size"]
	t.check(page_size.x >= 500, "the page is never narrower than its widest member (%d)"
			% page_size.x)

## A member whose own bordered size cannot fit on any page — wider or taller than
## `AtlasLibrary.MAX_ATLAS_SIDE` leaves room for — is named by its own index rather than folded
## into a page-sized failure, since the bake reads that index back to the member's own path.
func _test_an_oversize_member_is_named_rather_than_the_page(t) -> void:
	var sizes: Array[Vector2i] = [Vector2i(10, 10), Vector2i(AtlasLibrary.MAX_ATLAS_SIDE, 10)]
	var layout := AtlasLibrary.plan(sizes)
	t.check(not layout["fits"], "an oversize member fails to fit")
	t.check(int(layout.get("overflow", -1)) == 1, "the oversize member's own index is named (%d)"
			% int(layout.get("overflow", -1)))

func _test_empty_input(t) -> void:
	var layout := AtlasLibrary.plan([])
	t.check(layout["fits"], "an empty group trivially fits")
	t.check((layout["regions"] as Array).is_empty(), "an empty group places nothing")

## Two big members that only sit side by side above the square-root width a single-width packer
## would have tried: at that width each is too wide for the room the other leaves, so a search
## that never tries a wider candidate stacks them and forces the page to their combined height —
## the hole this suite's synthetic case exists to catch before a real page's does, the way
## `street_kit`'s own tall road picture and wide road picture forced a stack at the square root
## and a fifth less page once a wider candidate let them sit side by side. `bigger` is placed
## first (it is both the larger by area and the taller of the two, which is what lets `smaller`
## share its row instead of opening one below): stacked needs `max(150,100) x (200+180)` = 150x380
## = 57000px²; side by side needs `(150+100) x max(200,180)` = 250x200 = 50000px², a ninth less
## and shorter than the two members' combined height. `_candidate_widths()`'s running sum of the
## widest members' own widths is what finds the side-by-side width here, not the even sweep — the
## two are exactly as wide together as the case needs and nothing in between.
func _test_two_big_members_that_only_fit_side_by_side_above_the_square_root(t) -> void:
	var bigger := Vector2i(150, 200)
	var smaller := Vector2i(100, 180)
	var sizes: Array[Vector2i] = [bigger, smaller]
	for i in 6:
		sizes.append(Vector2i(20, 20))
	var layout := AtlasLibrary.plan(sizes)
	t.check(layout["fits"], "the two-big-members case fits on one page")
	var page_size: Vector2i = layout["size"]
	var stacked_height := bigger.y + smaller.y
	t.check(page_size.y < stacked_height,
			"the page (%dx%d) is shorter than the two members' stacked height (%d) — they sit on one row"
			% [page_size.x, page_size.y, stacked_height])
	var regions: Array = layout["regions"]
	var bigger_rect: Rect2i = regions[0]
	var smaller_rect: Rect2i = regions[1]
	var side_by_side := (bigger_rect.position.x + bigger_rect.size.x <= smaller_rect.position.x
			or smaller_rect.position.x + smaller_rect.size.x <= bigger_rect.position.x)
	t.check(side_by_side, "the two members land beside each other, not one above the other (%s, %s)"
			% [bigger_rect, smaller_rect])

## A spread of sizes wide enough to exercise growth, best-fit choice and the split more than
## once, with no two the same — a size repeated would let a placement pass this suite by landing
## on the size's own symmetry rather than on the packer actually choosing between candidates.
func _sample_sizes() -> Array[Vector2i]:
	var sizes: Array[Vector2i] = []
	for i in 24:
		sizes.append(Vector2i(12 + i * 5, 10 + (i * 7) % 60))
	return sizes
