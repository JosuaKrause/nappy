extends RefCounted
## The events draw from the one baked `events` page rather than from individually preloaded
## textures or a runtime-packed group per family. `tests/test_event_views.gd`,
## `tests/test_event_strides.gd` and `tests/test_events.gd` pin the drawing selection itself —
## which picture a look, a view, a stride frame or a checkpoint fixture reaches for; this suite
## holds the two things the move onto the page adds, which none of those files has a natural home
## for: **every picture any of them can reach is actually on that page**, and `EventManager` holds
## exactly one reference on it for its own life.
##
## **Why the completeness sweep is over the script's constants rather than over
## `EventInstance.family_sources()`.** `family_sources()` is read off `_draw_body()`'s arms by
## hand, so a picture a new branch draws and nobody added there would be missing from both the
## sweep and the answer — the failure would be invisible to a test that asked `family_sources()`
## what to check. Every picture a draw can reach is a `res://assets/…` string constant on
## `event_instance.gd` or a value inside one of its tables, so walking `get_script_constant_map()`
## and recursing into the dictionaries and arrays asks the question of the file itself, and a
## picture added without a membership entry fails here on the next run.
##
## **Which page each one is on, and when a page may be read from disk at all, is
## `tests/test_atlas_loading.gd`'s.** The reference counted here is what that rule rests on: with
## `main.RESIDENT_GROUPS` holding `events` from boot, the manager's acquire and release is only
## ever a count on a page that is already there.
##
## **`region()` is never called on an unacquired group here**, the same restraint
## `tests/test_atlas_stroller_crowd.gd` and `tests/test_atlas_library.gd` state for themselves: it
## answers null with a `push_error`, and an engine error in a suite makes the gate red whether or
## not a test expected it. Every check below reads `has_region()`, `group_of()`, `is_acquired()`
## or `reference_count()`, none of which loads anything.

const CITY_SCENE := preload("res://scenes/world/city.tscn")
const SEED := 4242

func run(t) -> void:
	AtlasLibrary.reset_for_tests()
	_test_every_picture_the_events_can_draw_is_on_the_events_page(t)
	_test_every_look_a_row_can_carry_has_pictures_on_the_page(t)
	_test_every_badge_silhouette_is_on_the_page(t)
	_test_the_manager_holds_one_reference_for_its_own_life(t)
	_test_a_manager_freed_mid_day_still_gives_its_page_back(t)
	AtlasLibrary.reset_for_tests()

# ------------------------------------------------------------- the whole page ---

## Every `res://assets/…` string on `event_instance.gd` — the plain constants, the eight-view and
## stride tables, the pointing poses, the checkpoint fixtures — is a region of `events`.
##
## This is the contract in the player's own words, *"all textures that are loaded in an atlas must
## not be loaded individually"* ([PLAYTEST-105](../docs/playtests/PLAYTEST-105.md)), made checkable:
## a path the bake does not know is a picture that would have to be loaded on its own to be drawn,
## and a path baked onto some *other* group is one this page's reference does not cover.
func _test_every_picture_the_events_can_draw_is_on_the_events_page(t) -> void:
	var script: Script = load("res://src/events/event_instance.gd")
	var pictures: Dictionary = {}
	for value: Variant in script.get_script_constant_map().values():
		_collect_paths(value, pictures)
	# The guard that this swept something: an empty map would pass every check below in silence,
	# which is exactly how a constant walk goes vacuous when the thing it walks changes shape.
	t.check(pictures.size() > 200,
			"the sweep found the catalogue's pictures to check (%d)" % pictures.size())
	for picture: String in pictures.keys():
		var name := AtlasLibrary.region_name_for(picture)
		t.check(AtlasLibrary.has_region(name),
				"%s is baked, under the region name %s" % [picture.get_file(), name])
		if not AtlasLibrary.has_region(name):
			continue
		t.check(AtlasLibrary.group_of(name) == EventInstance.ATLAS_GROUP,
				"%s is on the '%s' page, not on '%s'"
				% [picture.get_file(), EventInstance.ATLAS_GROUP, AtlasLibrary.group_of(name)])
		t.check(AtlasLibrary.native_size(name) > Vector2i.ZERO,
				"%s has a real size in the region table (%s)"
				% [picture.get_file(), AtlasLibrary.native_size(name)])

## Recurses into dictionaries and arrays, since a view table's pictures are its values and the
## pointing poses are an array. Keyed into `found` so a picture several arms share — the guard, the
## dog, the boom kit — is checked once.
func _collect_paths(value: Variant, found: Dictionary) -> void:
	if value is String:
		var text: String = value
		if text.begins_with("res://assets/"):
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
		var sources := EventInstance.family_sources(look)
		t.check(not sources.is_empty(),
				"the look drawn by '%s' has pictures listed for it" % looks[look])
		for picture in sources:
			checked += 1
			var name := AtlasLibrary.region_name_for(picture)
			t.check(AtlasLibrary.group_of(name) == EventInstance.ATLAS_GROUP,
					"'%s' draws %s from the '%s' page"
					% [looks[look], picture.get_file(), EventInstance.ATLAS_GROUP])
	t.check(checked > 0, "some look listed a picture to check (%d)" % checked)

## The screen-edge badge draws `EventInstance.icon_for()`'s own silhouette as a region of the same
## page the thing in the street draws from — `DangerEdge._draw_arrow()` reads
## `AtlasLibrary.native_size()` for the badge's fit and `AtlasLibrary.region()` for the picture, so
## a silhouette missing from the page is an arrow that says nothing on a day the row appears.
func _test_every_badge_silhouette_is_on_the_page(t) -> void:
	var checked := 0
	for def in EventCatalogue.all():
		if def.look == EventDef.Look.NONE:
			continue
		var icon := EventInstance.icon_for(def.look)
		t.check(not icon.is_empty(), "'%s' has a silhouette for the badge" % def.id)
		if icon.is_empty():
			continue
		checked += 1
		var name := AtlasLibrary.region_name_for(icon)
		t.check(AtlasLibrary.group_of(name) == EventInstance.ATLAS_GROUP,
				"'%s' badge draws %s from the '%s' page"
				% [def.id, icon.get_file(), EventInstance.ATLAS_GROUP])
	t.check(checked > 0, "some row offered a badge silhouette to check (%d)" % checked)

# ------------------------------------------------------------- the lifetime ---

func _rng(day: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("test_atlas_events:%d:%d" % [SEED, day])
	return rng

func _city(t) -> City:
	var city: City = CITY_SCENE.instantiate()
	t.add_child(city)
	city.build(CityGenerator.generate(SEED))
	return city

## `EventManager` takes one reference in `_enter_tree()` and gives it back in `_exit_tree()`, and
## nothing between those two moments moves the count: not a day starting, not a day's events being
## streamed in and out, not `clear()` between two days. That is the whole of the lifetime — the
## page carries any row in the catalogue, so there is no smaller set to hold and no later moment to
## hold it in, and a count that came and went with the last instance of a family would be a
## blocking read from disk the next time one streamed in (PLAYTEST-109, *"don't unload anything
## that might be needed in one day and in the next"*).
##
## With no boot behind this rig the reference is what loads and drops the page, which is what makes
## the pairing visible at all; in a booted game it is a count on a page `RESIDENT_GROUPS` holds.
func _test_the_manager_holds_one_reference_for_its_own_life(t) -> void:
	t.check(not AtlasLibrary.is_acquired(EventInstance.ATLAS_GROUP),
			"nothing holds the events page before a manager exists")
	var city := _city(t)
	t.check(AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP) == 1,
			"the manager holds exactly one reference from the moment it is in the tree (got %d)"
			% AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP))
	var consumed: Array[String] = []
	city.events.start_day(1, _rng(1), consumed)
	t.check(AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP) == 1,
			"a day's events do not each take a reference of their own (got %d)"
			% AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP))
	city.events.clear()
	t.check(AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP) == 1,
			"clearing the day keeps the page held rather than releasing and reloading it")
	city.events.start_day(2, _rng(2), consumed)
	t.check(AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP) == 1,
			"and a second day starts on the same one reference (got %d)"
			% AtlasLibrary.reference_count(EventInstance.ATLAS_GROUP))
	city.events.clear()
	city.free()
	t.check(not AtlasLibrary.is_acquired(EventInstance.ATLAS_GROUP),
			"freeing the city is what finally gives the page back")

## The leak `clear()` cannot catch, since it never releases: a city torn down mid-day — quitting to
## the title screen with a day still running. `AtlasLibrary`'s counts are static and outlive the
## freed node, so `EventManager._exit_tree()` is the only thing between this and a reference held
## for the rest of the process.
func _test_a_manager_freed_mid_day_still_gives_its_page_back(t) -> void:
	var city := _city(t)
	var consumed: Array[String] = []
	city.events.start_day(1, _rng(3), consumed)
	t.check(AtlasLibrary.is_acquired(EventInstance.ATLAS_GROUP),
			"the day's manager holds its page before the city is torn down")
	city.free()
	t.check(not AtlasLibrary.is_acquired(EventInstance.ATLAS_GROUP),
			"freeing the city mid-day releases the events page too, with no clear() in between")
