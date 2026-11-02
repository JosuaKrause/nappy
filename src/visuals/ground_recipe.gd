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

const PATH := "res://assets/ground_layers.json"

var _manifest: Dictionary = {}
var _read := false
var _reads := 0

## The recipe, or `{}` when the file is missing, unreadable or not a version 1 recipe.
func manifest() -> Dictionary:
	if not _read:
		_read = true
		_manifest = _read_file()
	return _manifest

func _read_file() -> Dictionary:
	_reads += 1
	if not FileAccess.file_exists(PATH):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH)) != OK:
		push_warning("Ignoring invalid ground layer manifest: %s" % PATH)
		return {}
	var data: Variant = parser.data
	return data if data is Dictionary and int(data.get("version", 0)) == 1 else {}

## How many times this object has read the file. A suite asks that it stays at one.
func reads() -> int:
	return _reads
