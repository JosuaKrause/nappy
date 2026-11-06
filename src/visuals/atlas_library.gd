class_name AtlasLibrary
extends RefCounted
## The baked atlases' pages, handed out by region name, one page per group, and which of them are
## held.
##
## `tools/bake-atlases.sh` writes a page PNG per group and one region table into `BAKED_ROOT`
## before the engine imports anything; a library is built over that table (`AtlasTable`) and
## answers `region()` with an `AtlasTexture` over the page. **The page is the only texture a group
## costs**: it is loaded on the first `acquire()` and dropped on the last `release()`, and nothing
## here ever loads a constituent picture.
##
## **One library per sitting, handed to whoever draws.** The `Sitting` holds it (`Sitting.atlas`),
## so the pages held for the life of the process (`hold_for_the_process()`) and the loading moments
## outlive the scene reload a held restart makes, and `main` hands it to everything that acquires a
## group or draws a region: the city hands it on to its furniture, its crowd and its events, the
## screens to their buttons. Nothing fetches it. A node built with none handed (a suite's
## hand-built city, stroller or button) makes its own when it first acquires, and its counts are
## its own; a test hands the nodes it compares one fresh library instead.
##
## **A region is valid only while its group is acquired.** `region()` on an unacquired group
## is a programming error rather than a fallback — it says so with `push_error` and answers
## `null`, because the alternative, quietly loading the page, is exactly the second copy in
## memory the atlases exist to prevent. Ask the table (`AtlasTable.native_size()`,
## `has_region()`) instead when the question is about geometry: it answers with no texture loaded
## at all, which is what a layout pass or a shadow's footprint needs.
##
## **A page may only be read from disk in a loading window.** `load()` blocks the frame that
## calls it, so a page that arrives on the frame it is first drawn in is a stutter the player
## sees — *"we cannot start loading something in the frame we need it"*. A boot sequence opens a
## window, names the moment it is (`MOMENT_STARTUP`, `MOMENT_DAY_BRIEF`, `MOMENT_ESCAPE`), takes
## what it wants and closes it again; an `acquire()` that finds its page unloaded with no window
## open loads it anyway and reports `MOMENT_OUTSIDE` with a `push_error`, which makes the test
## gate red. See `moment_for_a_load()` for the third state, before any boot has claimed the
## moments at all.
##
## The bake shares this file's `region_name_for()`, `illustrated_path_for()` and `plan()`, so
## the name a picture is baked under, the PNG that stands in for it and where it lands on its
## page are decided in one place rather than agreed between two. They are static and hold
## nothing, so the bake's headless `--script` run builds no library.

## Where the bake writes. Gitignored: a page is a build output, rebuilt from the sources on
## demand, and never committed.
const BAKED_ROOT := "res://assets/atlases/baked/"
## The region table's own script (`AtlasTable`), preloaded rather than named: the bake compiles
## this file in a headless `--script` run, where a checkout with no `.godot/` has no class-name
## cache for a `class_name` to resolve against.
const AtlasTableScript := preload("res://src/visuals/atlas_table.gd")
## Which group every picture belongs to, its lifetime and its padding kind. Checked in, and the
## one file a new consumer edits.
const MEMBERSHIP_PATH := "res://assets/atlases/membership.json"
## Where the authoring pictures live. `art/` carries a `.gdignore`, so the engine imports nothing
## under it and exports nothing from it; these two constants are read by the bake alone, through
## `FileAccess`, and never by a `load()`. The running game never sees a constituent picture.
const ART_ROOT := "res://art/"
## Where a PNG transfer stands in for an authored SVG.
const ILLUSTRATED_ROOT := ART_ROOT + "illustrated/svg-transfer/"

## The safe upper bound for one canvas texture's side on a phone.
const MAX_ATLAS_SIDE := 2048
## The border every region owns, so bilinear filtering at a region's own edge never samples a
## neighbour. An opaque family's border holds its own edge pixels (extruded); a sprite's stays
## transparent.
const PADDING := 1
## What `plan()` leaves between two neighbours and around the page. Two rather than one, so the
## `PADDING` border belongs to a single region: at one pixel of separation the gap column
## between two neighbours would be both regions' border at once and whichever was written last
## would win, which makes "extruded" false for the other one.
const SEPARATION := 2 * PADDING

## The moments a page is allowed to be read from disk in. `MOMENT_STARTUP` is a boot before its
## first screen is interactive, `MOMENT_DAY_BRIEF` the screen between two days, `MOMENT_ESCAPE`
## the `--start-escape` boot, which is that mode's own startup.
const MOMENT_STARTUP := &"startup"
const MOMENT_DAY_BRIEF := &"day brief"
const MOMENT_ESCAPE := &"escape"
## What a load that happened with no window open is called, in the run log and in the error.
const MOMENT_OUTSIDE := &"OUTSIDE"
## Before anything has claimed the loading moments — a process that builds nodes by hand rather
## than booting the game, which is every suite in `tests/`. Nothing is being played, so there is
## no frame a load could stutter; `main`'s boot is the only thing that ever claims them.
const MOMENT_UNMANAGED := &"unmanaged"

## The region table this library's pages are cut by: the baked one (`AtlasTable.baked()`), the
## same object every geometry reader asks, so a page and the rects read off it can never come from
## two tables.
var _table: AtlasTableScript
## Group -> its `Page`, one per group the table names, built with the library.
var _pages: Dictionary = {}
## Whether a boot sequence owns the loading moments. False until `claim_the_loading_moments()`
## is called and again after `release_the_loading_moments()`.
var _moments_claimed := false
## The open window's own moment, or `&""` when it is shut.
var _window: StringName = &""
## Groups held for the life of the process, each holding exactly one reference of its own.
var _resident: Dictionary = {}
## Region name -> the `AtlasTexture` handed out for it while its group is acquired, so a draw
## call's `region()` is one lookup. Each page lists the names it handed out, and its last release
## drops them from here.
var _textures: Dictionary = {}
## Where the library's own `texture` lines go, and the ground's (`note()`): a `Callable(kind,
## text)`, the boot's run trace's `note`, which `main` hands the sitting's library each boot. Empty,
## the default, writes nowhere: the bake (`tools/bake_atlases.gd`), and a suite's library it hands
## none. A `Callable` rather than a `RunTrace`, which sits on the domain model's layer, above this
## one.
var trace_note := Callable()

## Group name -> the loaded page `Texture2D`, its reference count and its size.
class Page extends RefCounted:
	var texture: Texture2D = null
	var count := 0
	var size := Vector2i.ZERO
	## When the page was last read from disk, so the line the release writes can say how long the
	## page was actually resident. `-1` while nothing holds it.
	var loaded_at_usec := -1
	## The region names handed out over this page (`AtlasLibrary._textures`), dropped with it.
	var handed_out: Array[StringName] = []

## A library over the baked region table, with nothing acquired and no moments claimed.
func _init() -> void:
	_table = AtlasTableScript.baked()
	for group: StringName in _table.groups():
		var page := Page.new()
		page.size = _table.page_size(group)
		_pages[group] = page

# ------------------------------------------------------------------ the names ---

## The region name a source path is baked under: its repository path without the `art/` prefix
## and without its extension, so `res://art/events/cat_running_side.svg` is
## `events/cat_running_side`.
##
## **The rule is the path and nothing else**, so a name is stable under everything but a rename
## of the picture itself, a consumer can write it as a literal, and the bake and the test derive
## the same string from the membership file without a table between them. Takes either a
## `res://` path or a repository-relative one.
##
## **The consumers do not call this.** Every one of them writes the region name as a literal,
## which is what the source move left them with: an authoring path under `art/` is nothing the
## engine could load, so a constant holding one would be a lie the type checker cannot catch.
## This is the bake's own rule, shared so that the name a picture is baked under and the name a
## test derives from the membership file come from one place.
static func region_name_for(source_path: String) -> StringName:
	var path := source_path.trim_prefix("res://").trim_prefix("art/")
	var extension := path.get_extension()
	if not extension.is_empty():
		path = path.left(path.length() - extension.length() - 1)
	return StringName(path)

## The illustrated PNG that stands in for an authored SVG, or "" for anything else. **The default
## bake is what chooses between the two**, once, before the game runs: the transfer where one
## exists and the SVG's own raster where none does. Existence and size are the caller's to check.
static func illustrated_path_for(source_path: String) -> String:
	var path := source_path
	if not path.begins_with("res://"):
		path = "res://" + path
	if not path.begins_with(ART_ROOT) or not path.ends_with(".svg"):
		return ""
	return ILLUSTRATED_ROOT + path.trim_prefix(ART_ROOT).trim_suffix(".svg") + ".png"

# ----------------------------------------------------------------- the layout ---

## A greedy free-rectangle packer (MaxRects, best-area fit — Jylänki's algorithm), so the room
## beside and under a tall member is offered to the next member instead of sitting empty until a
## shelf packer opens a new row. **Rejected: a shelf packer** — one row filled to `MAX_ATLAS_SIDE`
## before the next opens, so a group under that width is a single strip and a row is as tall as
## its own tallest member, which is the dead space PLAYTEST-109 measured beside `street_kit` and
## `interior`'s one 256px-tall picture. **Rejected: rows sorted by height**, offered to the
## player and refused, because a row beside a tall picture still leaves room "where you can
## easily put smaller things" (PLAYTEST-109). **Rejected: a guillotine packer** — a guillotine
## split commits to one cut line across the whole free rectangle, so the leftover strip beside a
## tall member is as tall as the member whether or not anything that size ever needs it;
## MaxRects keeps every leftover rectangle a placement leaves (not just the two a single cut line
## would draw) and lets a later, smaller member claim exactly the corner it fits, at the cost of
## checking more candidates per placement — cheap next to the bake's own rasterizing.
##
## `regions[i]` is where `sizes[i]` goes, in the caller's own order. **Deterministic**: members
## are placed largest padded area first, ties broken by the caller's own array order — which the
## bake already sorts alphabetically — so two bakes of the same tree place every member the same
## way, and the free-rectangle list a placement leaves is itself a pure function of the placements
## before it.
##
## **The square root is where the search starts, not the answer.** A single width can leave an
## obvious hole a wider page would not: `street_kit` packed at its own square-root width (366)
## stacks two same-area road pictures because neither fits beside the other at that width, and
## widening to where they sit side by side needs a *fifth less* page, not more. `plan()` packs
## the same members at every width `_candidate_widths()` offers and keeps the smallest result
## whose aspect ratio clears `_aspect_ceiling()`, ties broken by the narrower width (candidates are
## visited narrowest first and only a strict improvement replaces the kept result, so the same
## widths in the same order always keep the same one). Every candidate is packed by the same
## deterministic placement, so this is still one pure function of `sizes`, just evaluated more
## than once.
##
## Shared with the bake rather than owned by it, because the test that checks a page for
## overlaps and the tool that writes the page have to mean the same thing by "fits".
static func plan(sizes: Array[Vector2i]) -> Dictionary:
	if sizes.is_empty():
		return {"regions": [], "size": Vector2i.ZERO, "fits": true}
	# The footprint a member reserves while packing: its own size plus the `SEPARATION` gap owed
	# to whatever lands beside or under it. Two free rectangles' footprints never overlap, so any
	# two placed members end up at least `SEPARATION` apart in whichever axis separates them —
	# the same guarantee the old shelf packer gave by construction, proved for this one instead of
	# assumed.
	var padded: Array[Vector2i] = []
	var total_area := 0
	var widest := 0
	for size in sizes:
		var footprint: Vector2i = size + Vector2i(SEPARATION, SEPARATION)
		padded.append(footprint)
		total_area += footprint.x * footprint.y
		widest = maxi(widest, footprint.x)
	# A member whose own footprint alone would exceed the page limit cannot fit beside anything,
	# on any page this packer could ever produce — named on its own rather than folded into the
	# group's "packs to NxN" failure, since that message would stay true of a group of any size.
	for index in sizes.size():
		if padded[index].x + SEPARATION > MAX_ATLAS_SIDE or padded[index].y + SEPARATION > MAX_ATLAS_SIDE:
			return {
				"regions": [],
				"size": padded[index] + Vector2i(SEPARATION, SEPARATION),
				"fits": false,
				"overflow": index,
			}
	var order: Array[int] = []
	for index in sizes.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool:
		var area_a := padded[a].x * padded[a].y
		var area_b := padded[b].x * padded[b].y
		if area_a != area_b:
			return area_a > area_b
		return a < b)
	var ceiling := _aspect_ceiling(sizes)
	var best_regions: Array[Rect2i] = []
	var best_size := Vector2i.ZERO
	var best_meets_ceiling := false
	var best_area := -1
	for width in _candidate_widths(padded, widest, total_area):
		var attempt := _pack_at_width(order, padded, sizes, width)
		if not attempt["fits"]:
			continue
		var size: Vector2i = attempt["size"]
		var aspect := float(maxi(size.x, size.y)) / float(mini(size.x, size.y))
		var meets := aspect <= ceiling
		var area := size.x * size.y
		# Ascending width order plus "only a strict improvement replaces the kept result" is the
		# whole of the tie-break: the first width tried at the best (meets-ceiling, area) pair is
		# the one that survives every later candidate that only matches it.
		var better := best_area == -1 \
				or (meets and not best_meets_ceiling) \
				or (meets == best_meets_ceiling and area < best_area)
		if better:
			best_regions = attempt["regions"]
			best_size = size
			best_meets_ceiling = meets
			best_area = area
	if best_area == -1:
		# Every candidate width still overflows `MAX_ATLAS_SIDE` in height — a group too big for
		# one page regardless of shape. Report the narrowest attempt, which is what a human
		# widening the page limit or splitting the group would want to see first.
		var narrowest := _pack_at_width(order, padded, sizes, widest)
		return {"regions": narrowest["regions"], "size": narrowest["size"], "fits": false}
	return {
		"regions": best_regions,
		"size": best_size,
		"fits": best_size.x <= MAX_ATLAS_SIDE and best_size.y <= MAX_ATLAS_SIDE,
	}

## The widths `plan()` tries, narrowest first, deduplicated: the widest padded member (below this
## nothing could ever be placed) up to twice the square-root target (capped at the page limit),
## sweeping `_WIDTH_STEPS` evenly spaced points across that range plus the square-root width
## itself, **and the running sum of the `_WIDEST_MEMBERS_TRIED` widest-by-width members' own
## widths** — the specific widths an even sweep can straddle without ever landing on: two
## same-area members whose combined width is a few pixels past the nearest even step still stack
## instead of sitting side by side unless one of the tried widths is at least their sum.
const _WIDTH_STEPS := 16
const _WIDEST_MEMBERS_TRIED := 8

static func _candidate_widths(padded: Array[Vector2i], widest: int, total_area: int) -> Array[int]:
	var low := widest
	var high := clampi(ceili(2.0 * sqrt(float(total_area))), low, MAX_ATLAS_SIDE - SEPARATION)
	var seen: Dictionary = {}
	var widths: Array[int] = []
	var add := func(width: int) -> void:
		var clamped := clampi(width, low, high)
		if not seen.has(clamped):
			seen[clamped] = true
			widths.append(clamped)
	add.call(low)
	add.call(high)
	add.call(clampi(ceili(sqrt(float(total_area))), low, high))
	var by_width: Array[int] = []
	for index in padded.size():
		by_width.append(index)
	by_width.sort_custom(func(a: int, b: int) -> bool:
		if padded[a].x != padded[b].x:
			return padded[a].x > padded[b].x
		return a < b)
	var running := 0
	for i in mini(by_width.size(), _WIDEST_MEMBERS_TRIED):
		running += padded[by_width[i]].x
		add.call(running)
	for step in range(_WIDTH_STEPS + 1):
		add.call(low + int(round(float(high - low) * step / float(_WIDTH_STEPS))))
	widths.sort()
	return widths

## One MaxRects pack at a fixed page width, best-area fit: the same placement `plan()` used to run
## at a single square-root width, now called once per candidate. `fits` answers for height alone —
## `width` is always within `MAX_ATLAS_SIDE` by construction, since every candidate is clamped to
## it before this is called.
static func _pack_at_width(order: Array[int], padded: Array[Vector2i], sizes: Array[Vector2i],
		width: int) -> Dictionary:
	var regions: Array[Rect2i] = []
	regions.resize(sizes.size())
	var free_rects: Array[Rect2i] = []
	var floor_y := SEPARATION
	for index in order:
		var footprint: Vector2i = padded[index]
		var found := false
		var placed_at := Vector2i.ZERO
		var best_leftover := 0
		var best_short_side := 0
		for free in free_rects:
			if footprint.x > free.size.x or footprint.y > free.size.y:
				continue
			var leftover := free.size.x * free.size.y - footprint.x * footprint.y
			var short_side := mini(free.size.x - footprint.x, free.size.y - footprint.y)
			if not found or leftover < best_leftover \
					or (leftover == best_leftover and short_side < best_short_side):
				found = true
				placed_at = free.position
				best_leftover = leftover
				best_short_side = short_side
		if not found:
			# Nothing free is big enough — grow the page downward by exactly this member's own
			# footprint height, which always fits it since `width` is never less than the widest
			# member's own footprint width.
			var grown := Rect2i(Vector2i(SEPARATION, floor_y), Vector2i(width, footprint.y))
			floor_y += footprint.y
			free_rects.append(grown)
			placed_at = grown.position
		regions[index] = Rect2i(placed_at, sizes[index])
		_split_free_rects(free_rects, Rect2i(placed_at, footprint))
	var used := Vector2i.ZERO
	for rect in regions:
		used.x = maxi(used.x, rect.position.x + rect.size.x)
		used.y = maxi(used.y, rect.position.y + rect.size.y)
	var page_size := used + Vector2i(SEPARATION, SEPARATION)
	return {"regions": regions, "size": page_size, "fits": page_size.y <= MAX_ATLAS_SIDE}

## The aspect ratio (longer side over shorter) a well-packed page should not exceed, as a function
## of the sizes being packed rather than of any one arrangement of them: `1.8` when no single
## member dominates, loosened to `1.0 + dominance` — the largest of a member's own width or height
## over the square root of the group's own total bordered area — when one member already needs
## most of one side of an ideally square page, since no packer can make the page more square than
## that member's own shape forces. `plan()`'s own width search is scored against this, and
## `tests/test_atlas_library.gd` restates the rule to hold every baked page to it.
static func _aspect_ceiling(sizes: Array[Vector2i]) -> float:
	if sizes.is_empty():
		return 1.8
	var bordered_area := 0
	var widest := 0
	var tallest := 0
	for size in sizes:
		var bordered: Vector2i = size + Vector2i.ONE * (2 * PADDING)
		bordered_area += bordered.x * bordered.y
		widest = maxi(widest, size.x)
		tallest = maxi(tallest, size.y)
	var ideal_side := sqrt(float(bordered_area))
	var dominance := float(maxi(widest, tallest)) / ideal_side if ideal_side > 0.0 else 0.0
	return maxf(1.8, 1.0 + dominance)

## Removes `placed` from the free space `plan()` can still offer: every free rectangle `placed`
## overlaps is replaced by the up-to-four slabs of itself `placed` does not cover (left, right,
## top, bottom, in that order), and a slab another slab already wholly encloses is dropped, since
## a placement can only ever search it and find the larger one first. Exact duplicates are
## collapsed before the containment check, or two equal rectangles would each call the other
## redundant and both would be dropped.
static func _split_free_rects(free_rects: Array[Rect2i], placed: Rect2i) -> void:
	var kept: Array[Rect2i] = []
	for free in free_rects:
		if not free.intersects(placed):
			kept.append(free)
			continue
		if placed.position.x > free.position.x:
			kept.append(Rect2i(free.position, Vector2i(placed.position.x - free.position.x, free.size.y)))
		if placed.end.x < free.end.x:
			kept.append(Rect2i(Vector2i(placed.end.x, free.position.y),
					Vector2i(free.end.x - placed.end.x, free.size.y)))
		if placed.position.y > free.position.y:
			kept.append(Rect2i(free.position, Vector2i(free.size.x, placed.position.y - free.position.y)))
		if placed.end.y < free.end.y:
			kept.append(Rect2i(Vector2i(free.position.x, placed.end.y),
					Vector2i(free.size.x, free.end.y - placed.end.y)))
	var deduped: Array[Rect2i] = []
	for rect in kept:
		if not deduped.has(rect):
			deduped.append(rect)
	free_rects.clear()
	for i in deduped.size():
		var redundant := false
		for j in deduped.size():
			if i != j and deduped[j] != deduped[i] and deduped[j].encloses(deduped[i]):
				redundant = true
				break
		if not redundant:
			free_rects.append(deduped[i])


# ----------------------------------------------------------- the two moments ---

## A boot takes ownership of the loading moments and opens its first window in one call.
##
## **This is what turns the rule on for this library from here on**: until
## `release_the_loading_moments()`, a page read from disk outside a window is an error. Only a
## boot may say it — `main._hold_every_page_a_day_draws()` is the one caller — because only a
## boot knows that this process is a game somebody is about to watch. A library no boot claims,
## which is every one a suite builds by hand along with its `Stroller`, `City` or `Crowd`, stays
## `MOMENT_UNMANAGED` and loads as it always did.
func claim_the_loading_moments(moment: StringName) -> void:
	_moments_claimed = true
	_window = moment

## Opens a window inside an existing claim, and names the moment it is. The day brief's own two
## lines are the caller.
##
## **A no-op where no boot has claimed the moments**, rather than a second way to claim them: a
## test that drives the day brief's screen on a hand-built `main` would otherwise turn the rule
## on for a library no boot ever held a page in.
func open_loading_window(moment: StringName) -> void:
	if not _moments_claimed:
		return
	_window = moment

func close_loading_window() -> void:
	_window = &""

## Hands the moments back, so the library is `MOMENT_UNMANAGED` again. `main._exit_tree()` calls
## it, which is what lets the held restart — a whole scene reload — boot into a clean claim
## rather than into the previous `main`'s closed window.
func release_the_loading_moments() -> void:
	_moments_claimed = false
	_window = &""

## What a page read from disk *right now* would be called: the open window's own moment,
## `MOMENT_OUTSIDE` when the moments are claimed and the window is shut, or `MOMENT_UNMANAGED`
## when no boot has claimed them. Asked without loading anything, which is how a test can state
## the rule without provoking a real engine error into the gate's output.
func moment_for_a_load() -> StringName:
	if not _moments_claimed:
		return MOMENT_UNMANAGED
	return _window if _window != &"" else MOMENT_OUTSIDE

## Takes the one reference that keeps `group` resident for the life of the process, and does
## nothing if it is already held. **This is what makes "nothing is unloaded that the next day
## might need" true by construction**: a consumer's own `_exit_tree()` release can then only ever
## drop the count back to this reference, never to nought, so a city torn down between two runs
## or a node re-entering the tree never costs a reload. The library outlives the scene reload
## because the `Sitting` holds it.
func hold_for_the_process(group: StringName) -> void:
	if _resident.has(group):
		return
	_resident[group] = true
	acquire(group)

## Gives back a residency taken earlier. The one caller is a boot whose run draws the *other*
## parent than the last one did — a held restart rerolls the choice inside one process — and
## dropping a page nothing in the new run will draw is the whole point of splitting the two.
func stop_holding(group: StringName) -> void:
	if not _resident.has(group):
		return
	_resident.erase(group)
	release(group)

# --------------------------------------------------------------- the lifetime ---

## Takes a reference on `group`, loading its page on the first one.
##
## **The load is the thing the moments govern**, not the reference: every count after the first
## is free, which is why a consumer keeps its own `acquire()`/`release()` pair as the proof that
## the page is there while it draws.
func acquire(group: StringName) -> void:
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return
	page.count += 1
	if page.count > 1:
		return
	var moment := moment_for_a_load()
	var started := Time.get_ticks_usec()
	var path := BAKED_ROOT + String(group) + ".png"
	var texture: Texture2D = load(path)
	if texture == null:
		push_error("Baked atlas page missing: %s" % path)
		page.count = 0
		return
	page.texture = texture
	page.loaded_at_usec = started
	# Written before the error below, so an offending load is in the log whichever way the run
	# ends. `texture` is the kind docs/TELEMETRY.md already gives to "when a picture was loaded
	# and what it cost".
	note("texture", "atlas page '%s' loaded in the %s: %.1f ms, %d x %d"
			% [group, moment, (Time.get_ticks_usec() - started) / 1000.0,
			page.size.x, page.size.y])
	if moment == MOMENT_OUTSIDE:
		push_error(("Atlas group '%s' was read from disk outside a loading window. A page loads "
				+ "at startup or in a day brief and nowhere else — see AtlasLibrary's own doc.")
				% group)

## One line about the textures in the run log, written where `trace_note` says: the library's own
## page lines, and the composed ground's (`GroundLayers`, which builds it from this library's page).
func note(kind: String, text: String) -> void:
	if trace_note.is_valid():
		trace_note.call(kind, text)

## Drops a reference on `group`, freeing its page and every region handed out over it on the
## last one. A `release()` with nothing acquired is a programming error and says so.
##
## **The last release writes the other half of the page's own pair of lines** — the group, how
## long it was resident and how big it was — so a reader who finds a page loading twice in one run
## can see the drop between the two reads rather than inferring it from a second load line. Only
## the last one: every release above it costs nothing and drops no memory, so a line for it would
## say a page went when it did not. A page held for the life of the process
## (`hold_for_the_process()`) never reaches this in an ordinary run; the held restart's swap of one
## parent's page for the other's is what does.
func release(group: StringName) -> void:
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return
	if page.count == 0:
		push_error("Released atlas group '%s' that was not acquired" % group)
		return
	page.count -= 1
	if page.count > 0:
		return
	for name in page.handed_out:
		_textures.erase(name)
	page.handed_out.clear()
	page.texture = null
	var held := Time.get_ticks_usec() - page.loaded_at_usec
	page.loaded_at_usec = -1
	note("texture", "atlas page '%s' released after %.1f s: %d x %d"
			% [group, held / 1000000.0, page.size.x, page.size.y])

# ---------------------------------------------------------------- the regions ---

## The picture to draw, as an `AtlasTexture` over its group's page: its region's own size is
## what `get_size()` answers, so scale, offsets, mirroring, anchors and y-sort read exactly the
## number they read from a single-picture texture.
##
## **Null when the group is not acquired**, with an error naming the region — see the class
## note. The `AtlasTexture` is cached per name and dropped with the page, so a draw call costs a
## dictionary lookup and a released group leaves nothing behind.
func region(name: StringName) -> AtlasTexture:
	var cached: AtlasTexture = _textures.get(name)
	if cached != null:
		return cached
	var group := _table.group_of(name)
	if group == &"":
		push_error("No baked region '%s'" % name)
		return null
	var page: Page = _pages.get(group)
	if page == null or page.texture == null:
		push_error("Region '%s' asked for while its group '%s' is not acquired" % [name, group])
		return null
	var texture := AtlasTexture.new()
	texture.atlas = page.texture
	texture.region = Rect2(_table.region_rect(name))
	# So a neighbour's pixel is never sampled across a region's own edge — see `PADDING`.
	texture.filter_clip = true
	_textures[name] = texture
	page.handed_out.append(name)
	return texture

## The whole page as a CPU image, for the ground compositor, which composes its TileSet out of
## the page's pixels rather than drawing regions. Loaded on demand and **not cached**: it is a
## megabyte-scale image wanted once per day repaint and holding it would be the second resident
## copy this class exists to avoid. Answers null for an unknown group.
func page_image(group: StringName) -> Image:
	var page: Page = _pages.get(group)
	if page == null:
		push_error("No baked atlas group '%s'" % group)
		return null
	var texture: Texture2D = page.texture
	if texture == null:
		texture = load(BAKED_ROOT + String(group) + ".png")
	if texture == null:
		push_error("Baked atlas page missing for group '%s'" % group)
		return null
	var image: Image = texture.get_image()
	if image == null:
		return null
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)
	return image
