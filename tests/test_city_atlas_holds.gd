extends RefCounted
## The atlas groups a `City` holds while it stands, each read off the run log's lines for the page
## (`tests/atlas_page_log.gd`): the "decoration" page arrives with `City.build()` and is read from
## disk once however many props and decals draw from it, and `City._exit_tree()`'s `release()`
## balances `build()`'s `acquire()`.
##
## **This is a direct test of the city**: the group's lifetime is a fact about `City`, so the real
## city is built here (from a cached map, `tests/city_map_cache.gd`) and nowhere in the suites about
## the atlas page itself (`tests/test_atlas_decoration.gd`, `tests/test_atlas_library.gd`).

const MapCache := preload("res://tests/city_map_cache.gd")
const PageLog := preload("res://tests/atlas_page_log.gd")
const CITY_SCENE := preload("res://scenes/world/city.tscn")
## The seed of the run the city is handed (`RunCity.with_own_run()`).
const RUN_SEED := 2
const SEED := 4242

func run(t) -> void:
	_test_the_city_reads_the_group_once(t)
	_test_the_group_is_released_when_the_city_is_freed(t)

## The "decoration" page arrives with `City.build()` and is read from disk once while the city
## stands, so nothing in `Prop` or `CityDecals` could ever be asked to draw a region before the
## group backing it exists: a draw from an unacquired group would mean the city itself never
## actually acquired it, which the load line the run log carries after `build()` refuses.
##
## `AtlasLibrary.region()` on an unacquired group is deliberately not called here to provoke the
## failure directly — see `tests/test_atlas_library.gd`'s own note beside the same choice: the
## `push_error` it raises is a real engine error, and an engine error fails the whole run
## (`docs/DECISIONS.md`, M164), which would be a worse silence than the state checks below.
func _test_the_city_reads_the_group_once(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	city.atlas = atlas
	t.add_child(city)
	t.check(pages.loads(CityDecals.DECORATION_ATLAS) == 0,
			"nothing reads the decoration page before the city is built")
	city.build(map)
	t.check(pages.held(CityDecals.DECORATION_ATLAS),
			"City.build() acquires the decoration group")
	t.check(pages.loads(CityDecals.DECORATION_ATLAS) == 1,
			"and the page is read from disk once, however many props and decals draw from it (%d)"
			% pages.loads(CityDecals.DECORATION_ATLAS))
	# A region a real draw depends on actually resolves while the city stands.
	var door := atlas.region(City.DOOR_TEXTURE)
	t.check(door != null
			and door.get_size() == Vector2(AtlasTable.baked().native_size(City.DOOR_TEXTURE)),
			"the door's region resolves to its own size while the city holds the group")
	city.free()
	pages.stop()

## `City._exit_tree()` owes `build()`'s `acquire()` a matching `release()` — a city freed without
## one would leave the page counted, and resident, for a city that no longer exists.
func _test_the_group_is_released_when_the_city_is_freed(t) -> void:
	var atlas := AtlasLibrary.new()
	var pages := PageLog.new(atlas)
	var map := MapCache.of(SEED)
	var city: City = RunCity.with_own_run(CITY_SCENE, RUN_SEED)
	city.atlas = atlas
	t.add_child(city)
	city.build(map)
	t.check(pages.held(CityDecals.DECORATION_ATLAS),
			"the group is acquired while the city stands")
	city.free()
	t.check(pages.releases(CityDecals.DECORATION_ATLAS) == 1,
			"the page is dropped once the city that acquired it is freed, with no reference left over")
	pages.stop()
