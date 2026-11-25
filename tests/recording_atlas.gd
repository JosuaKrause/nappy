extends AtlasLibrary
## **An atlas library that remembers who asked it for a page, and which pictures it was asked
## for**: each `acquire()` is counted under the script that called it, and each `region()` is kept
## by name, so a suite can say what a node asked the library it was handed. A node that was never
## handed this library makes one of its own and asks that, and shows here as nothing. A helper, not
## a suite: the runner loads only `test_*.gd`.

## The script paths that called `acquire()`, each with how many times.
var _asked := {}
## The picture names asked of `region()` since `pictures_asked()` last answered, in the order asked.
var _pictures: Array[StringName] = []

## Overrides AtlasLibrary.acquire.
func acquire(group: StringName) -> void:
	var stack: Array = get_stack()
	if stack.size() > 1:
		var frame: Dictionary = stack[1]
		var source := String(frame.get("source", ""))
		_asked[source] = int(_asked.get(source, 0)) + 1
	super(group)

## How many times code in `script_path` (`res://src/...`) acquired a page on this library.
func acquired_from(script_path: String) -> int:
	return int(_asked.get(script_path, 0))

## Overrides AtlasLibrary.region.
func region(name: StringName) -> AtlasTexture:
	_pictures.append(name)
	return super(name)

## The picture names asked of this library since the last call, in the order asked; answering
## forgets them, so the next call answers only what is asked after this one.
func pictures_asked() -> Array[StringName]:
	var asked := _pictures
	_pictures = []
	return asked
