class_name GroundRecipe
extends RefCounted
## The ground's composition recipe (`assets/ground_layers.json`), read from disk by the first ask and
## held by this object after, like the `ground` page it composes from. **One per process**, held by
## the `Sitting` and handed to every city (`City.ground_recipe`, set by `main._new_city()`), which
## hands it to `GroundLayers.build_tile_set()`; nothing fetches it.
##
## The ground is repainted at the start of every day, and a repaint that went back to the disk would
## make each day's ground depend on what the file system holds at that moment -- a file moved under a
## running game would leave that day with no recipe and no ground. The first build is the city's
## own, before the first day is drawn. A city nobody handed one (a suite's hand-built city) holds its
## own and reads the file once for itself.

## The composition recipe: which shared base and which transparent overlays each source id wants,
## which severity pool each damage source draws from, and the grass features. **A data file the
## game reads at runtime, so it lives under `assets/` and is named in the Web preset's
## `include_filter`** — a `.json` is not a resource and would otherwise not be exported at all.
## Its filenames are the illustrated PNGs' own; `_layer_image()` turns each one into a region name
## and the pixels come off the page.
const PATH := "res://assets/ground_layers.json"

var _manifest: Dictionary = {}
var _read := false

## The recipe, or `{}` when the file is missing, unreadable or not a version 1 recipe.
func manifest() -> Dictionary:
	if not _read:
		_read = true
		_manifest = _read_file()
	return _manifest

func _read_file() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH)) != OK:
		push_warning("Ignoring invalid ground layer manifest: %s" % PATH)
		return {}
	var data: Variant = parser.data
	var recipe := data as Dictionary
	return recipe if recipe != null and int(recipe.get("version", 0)) == 1 else {}
