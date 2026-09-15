class_name TextureAtlas
extends RefCounted
## One shared texture per group of pictures, so whatever composes a scene reads from one image
## source per group rather than from one per picture. *(Playtest 76: "it is good to have
## everything built into atlases so the composite doesn't have to deal with multiple image
## sources.")*
##
## A group is named by its caller — `"stroller"`, `"head_indicators"`, `"decoration"`, one per
## event family — and packed on the shelf layout `plan()` describes: tallest picture first, one
## pixel of padding between neighbours and around the edge, and a hard cap of `MAX_ATLAS_SIDE` on
## either side.
##
## **The atlas relocates whichever raster `TextureResolver.resolve()` already chose and changes no
## picture.** Every source is resolved on the way in, so the default PNG transfers are what gets
## packed and `--svg`/`?svg=1` packs the SVG rasters instead; an `AtlasTexture` reports its
## region's own size, so scale, offsets, mirroring, anchors, shadows and y-sort all read exactly
## the number they read from the source texture.
##
## **Nothing ever waits on an atlas and nothing ever draws a missing picture.** `texture_for()`
## answers the source texture until the group is collected and answers it again after `release()`,
## so a user drawn before its atlas is ready, or drawn from a rig that never asked for one at all,
## draws precisely what it draws today.
##
## **Three phases, because only the middle one may leave the main thread.** `request()` reads the
## source images — `Texture2D.get_image()` talks to the renderer, so it is a main-thread call —
## and hands the blitting to a `WorkerThreadPool` task; `collect()` runs on the main thread and
## creates the `ImageTexture`, which is a renderer resource and may not be made anywhere else.
## `Main._process()` pumps `collect_ready()` once a frame, which is the only place in the running
## game that finishes a request.
##
## Releasing drops the atlas texture. The `preload`ed sources stay resident either way, since a
## `preload` holds them for the script's life; making those tables lazy so a released group's
## memory actually goes is a separate step and is not taken here.
##
## **A group becoming ready and a group being released are both `texture` lines in the run log**,
## with the milliseconds on them, so a run can be read back for whether a picture arrived before
## it was drawn. *(2026-09-15: "make sure telemetry records when a texture is loaded/unloaded" —
## "atlas or not" — "ideally with timing information".)*

## The safe upper bound for one canvas texture's side on a phone.
const MAX_ATLAS_SIDE := 2048
## The margin kept between two packed images, and between the atlas edge and its first shelf, so
## bilinear filtering at a region's own edge never samples a neighbour's pixel.
const PADDING := 1

## One requested group: what it was asked to pack, where each picture went, and how far along it
## is. `atlas` is null until `collect()` has run, which is what `texture_for()` reads to decide
## between the region and the source.
class Pack extends RefCounted:
	## Key -> the resolved source `Texture2D`, which is what `texture_for()` answers until the
	## atlas exists and again once it is released.
	var sources: Dictionary = {}
	## The keys in `sources`, in the order `regions` and `images` are indexed by.
	var keys: Array = []
	var images: Array[Image] = []
	var regions: Array[Rect2i] = []
	## The destination, created on the main thread and written by the worker task alone.
	var target: Image = null
	## The `WorkerThreadPool` task blitting into `target`, or -1 when there is none outstanding.
	var task_id := -1
	var atlas: ImageTexture = null
	## Key -> `AtlasTexture`, empty until `collect()`.
	var packed: Dictionary = {}
	## When `request()` was called, when `collect()` made the texture, and how long the worker's
	## own blit took — the three numbers the `texture` run-log line is written from.
	var requested_usec := 0
	var ready_usec := 0
	var blit_usec := 0
	var atlas_size := Vector2i.ZERO

static var _packs: Dictionary = {}

## How many atlases `collect()` has made ready this run. A static counter rather than a per-frame
## hook on a gameplay class, per the **telemetry** rule — `TelemetryObserver._spike_context()`
## reads it the same way it reads `TextureResolver.load_count()`, it does not compute it.
static var _collected_count := 0

## How many atlases have been collected this run, for the spike context.
static func collected_count() -> int:
	return _collected_count

# ---------------------------------------------------------------- requesting ---

## Asks for `name`'s atlas, reading every source image now and packing it on a worker thread.
##
## `sources` maps whatever the caller indexes its pictures by — a view name, a frame index, the
## source `Texture2D` itself — to the `Texture2D` to pack. **A second request for a name already
## known is ignored**, sources and all: every caller in the running game passes the same table for
## a given name, so re-reading it would be silly work for an answer that cannot change, and a
## caller placed second must not restart a pack the first one is already waiting on. A test that
## packs a different set under one name calls `release()` or `reset_for_tests()` between cases.
##
## Returns whether this call is the one that started the pack.
static func request(name: String, sources: Dictionary) -> bool:
	if _packs.has(name):
		return false
	var pack := Pack.new()
	pack.requested_usec = Time.get_ticks_usec()
	_packs[name] = pack
	var sizes: Array[Vector2i] = []
	for key in sources.keys():
		var texture: Texture2D = TextureResolver.resolve(sources[key])
		if texture == null:
			continue
		# `get_image()` asks the renderer for the texture's pixels, so it belongs on the main
		# thread; the copy is what the worker is then free to read without anybody else's
		# format conversion happening underneath it.
		var image := texture.get_image()
		if image == null:
			continue
		image = image.duplicate()
		if image.is_compressed() and image.decompress() != OK:
			continue
		if image.get_format() != Image.FORMAT_RGBA8:
			image.convert(Image.FORMAT_RGBA8)
		pack.sources[key] = texture
		pack.keys.append(key)
		pack.images.append(image)
		sizes.append(image.get_size())
	var layout := plan(sizes)
	assert(layout["fits"], "atlas '%s' is %s, over the %dpx phone-safe canvas side"
			% [name, layout["size"], MAX_ATLAS_SIDE])
	if not layout["fits"]:
		return true
	pack.regions.assign(layout["regions"])
	var atlas_size: Vector2i = layout["size"]
	pack.atlas_size = atlas_size
	pack.target = Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	pack.task_id = WorkerThreadPool.add_task(func() -> void: _blit(pack),
			false, "TextureAtlas: " + name)
	return true

## The shelf layout, as a pure function of the sizes it is asked to place: tallest first, so a
## shelf's own height is set by the first image placed on it and never grows once later, shorter
## images are added beside it.
##
## Separate from `request()` and public because it is the only part of the packing a test can hold
## still: the over-2048 case is an `assert()` in `request()`, which aborts the run rather than
## returning, so what a suite checks is the `fits` this reports for a set that cannot fit.
##
## `regions[i]` is where `sizes[i]` goes — the caller's own order, not the order they were placed
## in.
static func plan(sizes: Array[Vector2i]) -> Dictionary:
	var order: Array[int] = []
	for index in sizes.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return sizes[a].y > sizes[b].y)
	var regions: Array[Rect2i] = []
	regions.resize(sizes.size())
	var shelf_x := PADDING
	var shelf_y := PADDING
	var shelf_height := 0
	var width := 0
	for index in order:
		var size: Vector2i = sizes[index]
		if shelf_x + size.x + PADDING > MAX_ATLAS_SIDE:
			shelf_y += shelf_height + PADDING
			shelf_x = PADDING
			shelf_height = 0
		regions[index] = Rect2i(shelf_x, shelf_y, size.x, size.y)
		width = maxi(width, shelf_x + size.x)
		shelf_x += size.x + PADDING
		shelf_height = maxi(shelf_height, size.y)
	var atlas_size := Vector2i(width + PADDING, shelf_y + shelf_height + PADDING)
	return {
		"regions": regions,
		"size": atlas_size,
		"fits": atlas_size.x <= MAX_ATLAS_SIDE and atlas_size.y <= MAX_ATLAS_SIDE,
	}

## The worker half: nothing here touches the renderer, the scene tree or any state another thread
## can reach. `pack.target` was created by `request()` and is written by this task alone until
## `collect()` has waited for it.
static func _blit(pack: Pack) -> void:
	var started := Time.get_ticks_usec()
	for index in pack.images.size():
		var image: Image = pack.images[index]
		pack.target.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()),
				pack.regions[index].position)
	# Written here and read in `collect()` after `wait_for_task_completion()`, which is what makes
	# the hand-off ordered; nothing else on either side touches this field.
	pack.blit_usec = Time.get_ticks_usec() - started

# ---------------------------------------------------------------- collecting ---

## Finishes `name`'s pack if its worker task is done, and reports whether the atlas now exists.
##
## `wait` blocks until the task finishes rather than answering false, which is what a test that
## wants the atlas in hand asks for; the frame pump never does, because a blocking collect on the
## main thread is the stutter the atlases exist to avoid.
static func collect(name: String, wait := false) -> bool:
	var pack: Pack = _packs.get(name)
	if pack == null:
		return false
	if pack.atlas != null:
		return true
	if pack.task_id == -1:
		return false
	if not wait and not WorkerThreadPool.is_task_completed(pack.task_id):
		return false
	# Always reaped, never merely tested: a task id that is dropped without this call leaks its
	# slot in the pool for the rest of the run.
	WorkerThreadPool.wait_for_task_completion(pack.task_id)
	pack.task_id = -1
	pack.atlas = ImageTexture.create_from_image(pack.target)
	pack.packed = {}
	for index in pack.keys.size():
		var region := AtlasTexture.new()
		region.atlas = pack.atlas
		region.region = Rect2(pack.regions[index])
		# So a neighbour's pixel is never sampled across a region's own edge under bilinear
		# filtering — see `PADDING`.
		region.filter_clip = true
		pack.packed[pack.keys[index]] = region
	# The source images have been copied into the atlas and nothing reads them again.
	pack.images.clear()
	pack.target = null
	pack.ready_usec = Time.get_ticks_usec()
	_collected_count += 1
	Telemetry.note("texture", "atlas %s ready: %d pictures in %dx%d, %.1f ms from request (%.1f ms packed off the main thread)"
			% [name, pack.keys.size(), pack.atlas_size.x, pack.atlas_size.y,
			(pack.ready_usec - pack.requested_usec) / 1000.0, pack.blit_usec / 1000.0])
	return true

## Collects every request whose worker task has finished. `Main._process()` calls this once a
## frame; it is the only thing in the running game that does.
static func collect_ready() -> void:
	for name: String in _packs.keys():
		collect(name)

## Whether `name`'s atlas exists, which is the same question as whether `texture_for()` answers a
## region rather than a source.
static func is_ready(name: String) -> bool:
	var pack: Pack = _packs.get(name)
	return pack != null and pack.atlas != null

# ----------------------------------------------------------------- answering ---

## The picture `key` should be drawn from: the `AtlasTexture` over `name`'s shared texture once it
## is collected, and the source texture before that, after `release()`, and for a `name` nobody
## ever requested.
##
## `source` is the caller's own picture, and giving it is what makes the last of those cases safe:
## a rig that builds one entity without ever building the city has no atlas to read from and still
## has to draw. A caller that requested the group can leave it out.
static func texture_for(name: String, key: Variant, source: Texture2D = null) -> Texture2D:
	var pack: Pack = _packs.get(name)
	if pack == null:
		return source
	if pack.packed.has(key):
		return pack.packed[key]
	if pack.sources.has(key):
		return pack.sources[key]
	return source

# ----------------------------------------------------------------- releasing ---

## Drops `name`'s atlas, so its users go back to drawing their source textures and the next
## `request()` for that name packs afresh. Waits for an outstanding worker task first: a pack
## released while its blit is still running would otherwise leave the pool holding a task nobody
## will ever reap.
static func release(name: String) -> void:
	var pack: Pack = _packs.get(name)
	if pack == null:
		return
	if pack.task_id != -1:
		WorkerThreadPool.wait_for_task_completion(pack.task_id)
		pack.task_id = -1
	var now := Time.get_ticks_usec()
	if pack.ready_usec > 0:
		Telemetry.note("texture", "atlas %s released after %.1f ms drawn from"
				% [name, (now - pack.ready_usec) / 1000.0])
	else:
		Telemetry.note("texture", "atlas %s released %.1f ms after it was requested, never ready"
				% [name, (now - pack.requested_usec) / 1000.0])
	_packs.erase(name)

## Releases every group, so the next `request()` packs under whatever presentation mode is current
## — paired with `TextureResolver.reset_for_tests()` in every test that forces one, since a suite
## that toggles `--svg` mid-run would otherwise keep drawing through the mode packed first.
static func reset_for_tests() -> void:
	for name: String in _packs.keys():
		var pack: Pack = _packs[name]
		if pack.task_id != -1:
			WorkerThreadPool.wait_for_task_completion(pack.task_id)
			pack.task_id = -1
	_packs.clear()
	_collected_count = 0
