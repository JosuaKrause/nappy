@warning_ignore_start("untyped_declaration", "unsafe_method_access")
extends RefCounted
## The events draw from the one baked `events` page rather than from individually preloaded
## textures or a runtime-packed group per family. `tests/test_event_views.gd`,
## `tests/test_event_strides.gd` and `tests/test_events.gd` pin the drawing selection itself —
## which picture a look, a view, a stride frame or a checkpoint fixture reaches for; this suite
## holds the two things the move onto the page adds, which none of those files has a natural home
## for: **every picture any of them can reach is actually on that page**, and `EventManager` holds
## it for its own life, read off the run log's lines for the page (`tests/atlas_page_log.gd`).
##
## **Why the completeness sweep is over the script's constants rather than over
## `EventPictures.family_sources()`.** `family_sources()` is read off the looks' `_draw_figure()`
## arms by hand, so a picture a new branch draws and nobody added there would be missing from both
## the sweep and the answer — the failure would be invisible to a test that asked `family_sources()`
## what to check. Every picture a draw can reach is a region-name string constant on
## `event_pictures.gd` or a value inside one of its tables, so walking `get_script_constant_map()`
## and recursing into the dictionaries and arrays asks the question of the file itself, and a
## picture added without a membership entry fails here on the next run.
##
## **Which page each one is on, and when a page may be read from disk at all, is
## `tests/test_atlas_loading.gd`'s.** The manager's hold watched here is what that rule rests on:
## with `main.RESIDENT_GROUPS` holding `events` from boot, the manager's acquire and release is only
## ever a count on a page that is already there.
##
## **`region()` is never called on an unacquired group here**, the same restraint
## `tests/test_atlas_stroller_crowd.gd` and `tests/test_atlas_library.gd` state for themselves: it
## answers null with a `push_error`, and an engine error in a suite makes the gate red whether or
## not a test expected it. Every check below reads `has_region()`, `group_of()` or the run log,
## none of which loads anything.

const StreetMap := preload("res://tests/fixtures/street_map.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")

func run(t) -> void:
	_test_every_picture_the_events_can_draw_is_on_the_events_page(t)
	_test_every_look_a_row_can_carry_has_pictures_on_the_page(t)
	_test_every_badge_silhouette_is_on_the_page(t)
	_test_both_dog_families_draw_their_accepted_transfers(t)
	_test_the_manager_holds_its_page_for_its_own_life(t)
	_test_a_manager_freed_mid_day_still_gives_its_page_back(t)

# ------------------------------------------------------------- the whole page ---

## Every region name on `event_pictures.gd` — the plain constants, the eight-view and stride
## tables, the pointing poses, the checkpoint fixtures — is a region of `events`.
##
## This is the contract in the player's own words, *"all textures that are loaded in an atlas must
## not be loaded individually"* ([PLAYTEST-105](../docs/playtests/PLAYTEST-105.md)), made checkable:
## a path the bake does not know is a picture that would have to be loaded on its own to be drawn,
## and a path baked onto some *other* group is one this page's reference does not cover.
func _test_every_picture_the_events_can_draw_is_on_the_events_page(t) -> void:
	var script: Script = load("res://src/events/views/event_pictures.gd")
	var pictures: Dictionary = {}
	for value: Variant in script.get_script_constant_map().values():
		_collect_paths(value, pictures)
	# The guard that this swept something: an empty map would pass every check below in silence,
	# which is exactly how a constant walk goes vacuous when the thing it walks changes shape.
	t.check(pictures.size() > 200,
			"the sweep found the catalogue's pictures to check (%d)" % pictures.size())
	for picture: String in pictures.keys():
		var name := StringName(picture)
		t.check(AtlasTable.baked().has_region(name),
				"%s is baked, under the region name %s" % [picture.get_file(), name])
		if not AtlasTable.baked().has_region(name):
			continue
		t.check(AtlasTable.baked().group_of(name) == EventPictures.ATLAS_GROUP,
				"%s is on the '%s' page, not on '%s'"
				% [picture.get_file(), EventPictures.ATLAS_GROUP, AtlasTable.baked().group_of(name)])
		t.check(AtlasTable.baked().native_size(name) > Vector2i.ZERO,
				"%s has a real size in the region table (%s)"
				% [picture.get_file(), AtlasTable.baked().native_size(name)])

## Recurses into dictionaries and arrays, since a view table's pictures are its values and the
## pointing poses are an array. Keyed into `found` so a picture several arms share — the guard, the
## dog, the boom kit — is checked once.
##
## **What makes a constant a picture is its shape, not a prefix a path used to carry**: a region
## name is `<family>/<picture>`, one slash and no extension, which is what
## `AtlasLibrary.region_name_for()` writes and what the file's constants now hold. Deliberately
## not `AtlasTable.baked().has_region()` — that would make the sweep select exactly the names that pass
## the check below, which is the shape of a test that cannot fail.
func _collect_paths(value: Variant, found: Dictionary) -> void:
	if value is String:
		var text: String = value
		if text.count("/") == 1 and not text.contains("."):
			found[text] = true
		return
	if value is Dictionary:
		for entry: Variant in (value as Dictionary).values():
			_collect_paths(entry, found)
		return
	if value is Array:
		for entry: Variant in (value as Array):
			_collect_paths(entry, found)

## The other direction: every look a catalogue row can carry has pictures enumerated for it, and
## every one of those is on the page. `family_sources()` is what makes "everything a look can draw"
## enumerable at all; this is what stops a new `Look` being added with nothing listed for it.
func _test_every_look_a_row_can_carry_has_pictures_on_the_page(t) -> void:
	var looks: Dictionary = {}
	for def in EventCatalogue.all():
		looks[def.look] = def.id
	var checked := 0
	for look: EventDef.Look in looks.keys():
		if look == EventDef.Look.NONE:
			continue
		var sources := EventPictures.family_sources(look)
		t.check(not sources.is_empty(),
				"the look drawn by '%s' has pictures listed for it" % looks[look])
		for picture in sources:
			checked += 1
			var name := StringName(picture)
			t.check(AtlasTable.baked().group_of(name) == EventPictures.ATLAS_GROUP,
					"'%s' draws %s from the '%s' page"
					% [looks[look], picture.get_file(), EventPictures.ATLAS_GROUP])
	t.check(checked > 0, "some look listed a picture to check (%d)" % checked)

## The screen-edge badge draws `EventPictures.icon_for()`'s own silhouette as a region of the same
## page the thing in the street draws from — `DangerEdge._draw_arrow()` reads
## `AtlasTable.native_size()` for the badge's fit and `AtlasLibrary.region()` for the picture, so
## a silhouette missing from the page is an arrow that says nothing on a day the row appears.
func _test_every_badge_silhouette_is_on_the_page(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.look == EventDef.Look.NONE:
			continue
		var icon := EventPictures.icon_for(def.look)
		t.check(not icon.is_empty(), "'%s' has a silhouette for the badge" % def.id)
		if icon.is_empty():
			continue
		checked += 1
		var name := StringName(icon)
		t.check(AtlasTable.baked().group_of(name) == EventPictures.ATLAS_GROUP,
				"'%s' badge draws %s from the '%s' page"
				% [def.id, icon.get_file(), EventPictures.ATLAS_GROUP])
	t.check(checked > 0, "some row offered a badge silhouette to check (%d)" % checked)

## Both dog families draw the comic pictures the player accepted *(2026-09-27, dotted-panda: "the
## graphics should be used in game")*: every picture the normal dog (the dog walker's and the loose
## dog's) can draw, and every frame of the charging dog's gallop, has its transfer PNG beside its
## SVG, so the default bake — every release and every CI run — bakes the PNG.
## `tests/test_atlas_library.gd` holds each baked region to its own PNG pixel for pixel; this holds
## that there is a PNG to hold it to. The charging dog's rest and alert are drawn from their SVGs,
## which the player judges in the game (inbox #748: "yes that's what I've been saying all along").
func _test_both_dog_families_draw_their_accepted_transfers(t) -> void:
	var pictures: Dictionary = {}
	for picture in EventPictures.family_sources(EventDef.Look.LOOSE_DOG):
		pictures[picture] = true
	for table: Dictionary in [EventPictures.CHARGING_DOG_BY_VIEW,
			EventPictures.CHARGING_DOG_BY_VIEW_B]:
		for view: String in table.keys():
			pictures[str(table[view])] = true
	t.check(not pictures.is_empty(),
			"the normal dog and the gallop had pictures to check (%d)" % pictures.size())
	for picture: String in pictures.keys():
		var transfer := AtlasLibrary.illustrated_path_for("art/%s.svg" % picture)
		t.check(FileAccess.file_exists(transfer), "%s is drawn from %s" % [picture, transfer])

# ------------------------------------------------------------- the lifetime ---

## A walk started on the manager with nothing planned (`start_recipe()`, the way a scene's recipe
## starts one): a day's planning is the planner's own work over a city, and what the lifetime
## tests ask is only what starting and clearing a walk does to the manager's hold on its page.
func _start_a_day(manager: EventManager, day: int) -> void:
	var none: Array[EventScheduler.Planned] = []
	manager.start_recipe(none, DaySpec.for_day(day), day, Vector2.ZERO)

## The event manager the lifetime tests watch: the real one, over a world of its own (a map of
## streets and a run, `setup_world()`) and the library handed in where the game hands its own, so
## no city is built around it.
func _manager(t, atlas: AtlasLibrary) -> EventManager:
	var manager := EventManager.new()
	manager.atlas = atlas
	manager.setup_world(StreetMap.full(), RunState.new())
	t.add_child(manager)
	return manager

## `EventManager` takes one reference in `_enter_tree()` and gives it back in `_exit_tree()`, and
## nothing between those two moments drops the page: not a day starting, not a day's events being
## streamed in and out, not `clear()` between two days. That is the whole of the lifetime — the
## page carries any row in the catalogue, so there is no smaller set to hold and no later moment to
## hold it in, and a count that came and went with the last instance of a family would be a
## blocking read from disk the next time one streamed in (PLAYTEST-109, *"don't unload anything
## that might be needed in one day and in the next"*).
##
## With no boot behind this rig the reference is what loads and drops the page, which is what makes
## the pairing visible at all; in a booted game it is a count on a page `RESIDENT_GROUPS` holds. A
## reference a day's events took and never gave back would leave the page held after the manager is
## freed, so the one release line at the end is what says the counts balanced.
func _test_the_manager_holds_its_page_for_its_own_life(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var group := EventPictures.ATLAS_GROUP
	var manager := _manager(t, atlas)
	t.check(pages.held(group) and pages.loads(group) == 1,
			"the manager holds the page from the moment it is in the tree")
	_start_a_day(manager, 1)
	t.check(pages.loads(group) == 1 and pages.releases(group) == 0,
			"a day's events draw on the page the manager holds, reading nothing more")
	manager.clear()
	t.check(pages.releases(group) == 0,
			"clearing the day keeps the page held rather than releasing and reloading it")
	_start_a_day(manager, 2)
	t.check(pages.loads(group) == 1 and pages.releases(group) == 0,
			"and a second day starts on the same page (%d loads)" % pages.loads(group))
	manager.clear()
	manager.free()
	t.check(pages.releases(group) == 1,
			"freeing the manager is what finally gives the page back, with no reference left over")
	pages.stop()

## The leak `clear()` cannot catch, since it never releases: a manager torn down mid-day — quitting to
## the title screen with a day still running. The library's counts outlive the freed node (in a
## booted game the library is the sitting's), so `EventManager._exit_tree()` is the only thing
## between this and a reference held for the rest of the process.
func _test_a_manager_freed_mid_day_still_gives_its_page_back(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var manager := _manager(t, atlas)
	_start_a_day(manager, 1)
	t.check(pages.held(EventPictures.ATLAS_GROUP),
			"the day's manager holds its page before the manager is torn down")
	manager.free()
	t.check(not pages.held(EventPictures.ATLAS_GROUP),
			"freeing the manager mid-day releases the events page too, with no clear() in between")
	pages.stop()
