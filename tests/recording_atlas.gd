extends AtlasLibrary
## **An atlas library that remembers who asked it for a page**: each `acquire()` is counted under the
## script that called it, so a suite can say what a node asked the library it was handed. A node that
## was never handed this library makes one of its own and asks that, and shows here as nothing. A
## helper, not a suite: the runner loads only `test_*.gd`.

## The script paths that called `acquire()`, each with how many times.
var _asked := {}

## Overrides AtlasLibrary.acquire.
func acquire(group: StringName) -> void:
	var stack := get_stack()
	if stack.size() > 1:
		var source := String(stack[1].get("source", ""))
		_asked[source] = int(_asked.get(source, 0)) + 1
	super(group)

## How many times code in `script_path` (`res://src/...`) acquired a page on this library.
func acquired_from(script_path: String) -> int:
	return int(_asked.get(script_path, 0))
