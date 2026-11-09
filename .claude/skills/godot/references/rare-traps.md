# Rarer engine traps

Read the section that names what you are about to touch: a `.slice()` of a typed array, an enum
passed between scripts, a press read under `Control`s, the title screen's pause split or a paused
camera, Y-sorting, an `instance uniform`, a flood fill, a worktree's import cache, or an engine
feature the Web build leaves out. None of them gives an error.

## Types

**`.slice()` on a typed `Array` drops the element type.** `for map in _maps.slice(0, 3):` over
an `Array[CityMap]` leaves `map` untyped under 4.7's static inference, so the first `:=` further
down the call chain — `var centre := map.tile_rect_to_world(...).get_center()` — is the
Variant-inference error above, and a suite that carries it fails to load (`LOAD FAIL`). Annotate the loop variable: `for map: CityMap in _maps.slice(0, 3):`.

**A cross-script enum is not the same type as itself.** `static func f(side: Side)` in one script,
called from another where `x` came from `OtherScript.Side`, fails to parse: *"argument 2 should be
Side but is StreetNetwork.Side"*. Widen the parameter to `int` and say why in a comment.
`StreetNetwork.beside_block()` is the one place that does.

## Input

**A press read in `_unhandled_input()` must cross every `Control` above it.** The GUI pass runs
first and ends a press at the topmost `Control` under it whose `mouse_filter` is STOP, and a bare
`Control`, `ColorRect` or `Panel` defaults to STOP; containers default to PASS. So every drawn-only
`Control` over such a screen is set to IGNORE. A test that calls `_unhandled_input()` directly skips
the GUI pass and cannot see this: send the press through `Input.parse_input_event()` and
`Input.flush_buffered_events()`.

## Pausing

The title screen needs the split the other way round — the **city** running while the **day** does
not — so `_city` goes to `ALWAYS` for the duration and `_player` is pinned to `PAUSABLE`, because
she is a child of it and would otherwise inherit the exemption. **Anything that wants the same trick
names its own exceptions the same way; there is no "pause everything except" switch and there should
not be one.**

**A paused `Camera2D` with smoothing on never arrives.** `position_smoothing_enabled` is applied in
the camera's **own** process callback, so a camera that is `PAUSABLE` under a paused tree stops
following the thing it is attached to and sits wherever it last was — which on the first frame of a
run is the world origin, clamped to the corner of the boundary wall.

`Stroller.stand_aside()` puts the camera on `ALWAYS` for the duration. The thing that looks like the
cause and is not: **hiding a `Node2D` does not deactivate a `Camera2D` under it.**

## Drawing

**Y-sorting compares origins**, so a thing whose mass extends away from its own origin sorts wrong.
**Before reaching for a better comparison, ask whether the two things can ever legitimately be on
opposite sides of each other.** Buildings cannot — no lot tile is walkable — so they are a layer of
their own and sort against nothing. The one thing a building has that rises over walkable ground,
a power station's stack, is therefore not part of the building: it is an entity of its own in
`Entities`, sorted at its foot.

**Only sixteen canvas items can carry a readable `instance uniform` at once, and only a browser
shows it.** The Compatibility renderer — this project's on every platform (`project.godot`,
`rendering_method="gl_compatibility"`) — gives each such item a 16-`vec4` block, first free block
first, and its canvas shader declares only 256 `vec4`s to read them from. An item handed a block
past the sixteenth reads past the declared array, which GLSL leaves undefined: a desktop GL driver
happens to read on into the buffer and draws it right, while WebGL reads zero and draws it as if
the uniform were zero, for as long as it lives, with no error anywhere. A headless test has no
renderer at all, so a native run, a headless test and a screenshot rig all look right. **Build
such an item only while it is needed, free it on the spot with `remove_child()` and `free()`, and
keep a count**: freeing a canvas item hands blocks to items built earlier in the same frame before
it releases its own, so a `queue_free()` still holds its block while that frame's new items take
theirs. `EntityHalo.RIM_BUDGET`, `EntityHalo.release()` and its class doc are the worked case.

## Performance

**A `Dictionary` keyed by `Vector2i` hashes a Variant on every lookup.** Fine for a small set; not
fine for a flood fill, where it costs about 3.6× a flat `PackedInt32Array` indexed by tile. Paint
the blocked set into the grid before the sweep rather than asking per neighbour, and write the four
neighbour steps out rather than looping an offset array — the loop's own bounds test costs more than
the arithmetic it guards.

## Imports

**Texture `.import` sidecars elsewhere are repository files; `.godot/imported/` is the cache**, and
a worktree's imported textures do not travel with commits. After checking out an asset branch, run
`check.sh` in the actual test folder. `run.sh` runs the import pass itself when a global class or an
imported copy is missing; `shot.sh` and a bare `godot --path` do not. A failed texture preload can
leave a GDScript uncompiled and produce nonexistent `new()` followed by nil-method errors: read the
first load or parse error before changing the constructor. For illustrated assets, the
**illustrated-png** skill says which import, boot and visual checks a texture change owes.

## What the Web build leaves out

The release Web engine omits 3D, navigation, Godot networking peers and the mbedTLS backend,
streamed-media codecs, alternate texture loaders, procedural noise and ZIP support; before using
one of those feature families, follow
[Turning a module back on](../../../tools/web-template/README.md#turning-a-module-back-on).
