---
name: godot
description: Godot 4.7 and GDScript traps that have cost real time in this project — silent type drops, warnings that are errors, pause and process_mode inheritance, camera smoothing, node naming, leaks. Load this BEFORE writing or debugging any GDScript, and whenever something behaves in a way the engine gives no error for.
---

# Godot 4.7 / GDScript gotchas

These are not obvious and the engine does not warn about most of them.

## Types

**`set(key, value)` silently drops a type mismatch.** Never build typed objects from dictionaries —
every `Array[int]` field comes out empty with **no error anywhere**. Use an explicit factory
function with named parameters.

**Passing an untyped `Array` into an `Array[T]` parameter leaks at shutdown.** The coercion at the
call boundary retains the arguments; you get "N ObjectDB instances were leaked at exit". Declare the
real element type at the call site.

**Some warnings are errors by default.** `var x := some_variant` ("the variable type is being
inferred from a Variant value") fails the parse outright. Annotate instead: `var x: int = ...`.

This does not show up until the project actually boots, which is why `check.sh` exists. The form
that catches people is `var x := load(path).instantiate()`, because it reads as obviously typed and
is not — and in a **test** it fails at load time, so the suite prints nothing at all and looks like
it hung. Write:

```gdscript
var scene: PackedScene = load(path)
var node: Node = scene.instantiate()
```

**A cross-script enum is not the same type as itself.** `static func f(side: Side)` in one script,
called from another where `x` came from `OtherScript.Side`, fails to parse: *"argument 2 should be
Side but is StreetNetwork.Side"*. Widen the parameter to `int` and say why in a comment.
`StreetNetwork.beside_block()` is the one place that does.

## Structure

**`--script` skips autoloads.** The test suite runs as a **scene**
(`godot --headless --path . res://tests/tests.tscn`) because every test needs `Tuning`.

**An autoload name cannot also be a `class_name`.** That is why shared enums live in
`src/game_enums.gd` rather than on `GameState`.

**`SomeNode.new()` does not get the name `SomeNode`.** `Camera2D.new()` is named `@Camera2D@41`, so
a `@onready var _camera := $Camera2D` in a test rig silently fails. **Set `.name` explicitly when a
node is looked up by path.**

**Nodes are not refcounted.** A test double extending a `Node` class must be `free()`d by hand or it
leaks. `RefCounted` doubles do not.

**Never commit `.godot/`.** It is gitignored, which means a fresh clone has no `class_name` registry
and every typed reference fails to parse until `check.sh` runs the import pass.

## Pausing

**`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** `main.gd`
sets it on itself so Esc still quits while the summary has the tree paused — and every descendant
defaults to `PROCESS_MODE_INHERIT`, so the city, the player, the crowd, the events and the deadline
all inherit the exemption and `get_tree().paused = true` pauses nothing.

`main._pauses_with_the_game()` is called on every node that is the game rather than the frame around
it. **If you add a node under `Main`, it needs that call**, and nothing warns you.

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

## Physics and drawing

**`move_and_slide()` owns `velocity`, so do not put anything else in it.** Folding a deflection into
`velocity` before the slide means `is_idle()` and `run_excess_ratio()` — the only two questions the
baby asks the rig — start answering for the crowd rather than for the player. Restoring `velocity`
afterwards is worse: it throws away the slide's own correction, so walking into a wall stops reading
as idle and starts making sleep progress. **A second displacement goes through its own
`move_and_collide()`**, which respects walls and touches nothing.

**A negative-width `Rect2` does not flip `draw_texture_rect`.** It is normalised on the way through,
so the sprite lands a full width to one side. Mirror with `draw_set_transform(at, 0, Vector2(-1,
1))` around the anchor instead.

**Y-sorting compares origins**, so a thing whose mass extends away from its own origin sorts wrong.
Before reaching for a better comparison, ask whether the two things can ever legitimately be on
opposite sides of each other.

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw is
fine, but anything animated must call `queue_redraw()` itself.

## Performance

**A `Dictionary` keyed by `Vector2i` hashes a Variant on every lookup.** Fine for a small set; not
fine for a flood fill, where it costs about 3.6× a flat `PackedInt32Array` indexed by tile. Paint
the blocked set into the grid before the sweep rather than asking per neighbour, and write the four
neighbour steps out rather than looping an offset array — the loop's own bounds test costs more than
the arithmetic it guards.

## Code style

### Comments are written in the present tense

**This applies to every `##` docstring and every `#` comment, exactly as it applies to the docs.**
A comment states what the thing **is** and **why**, never where it came from.

- **No milestone numbers.** Not `(M39, playtest 10 finding 13: …)`, not "since M33", not "for twelve
  milestones this was wrong".
- **No former values.** Not "it was 148 until M35", not "this used to be `(1−t)²`". Keep the
  *relationship* that makes the current number right — "above the 7.7/s decay on the ground it
  stands on" — and let `docs/DECISIONS.md` hold the story.
- **No narration of the fix.** "The first version parked every route against the city wall" belongs
  in the commit message and in `DECISIONS.md`, not above the function.
- **Keep the trap.** A comment warning that a rule is easy to get backwards, or that a value is
  load-bearing for something non-obvious, is *current* and stays. The test is whether the sentence
  is still true if you know nothing about this project's history.

**Why:** a reader cannot tell which half of a paragraph is still true. A docstring that opens with a
milestone number costs every future reader the archaeology before they reach the rule, and the rule
is the only part that governs the code in front of them.

- Tabs for indentation. Wrap at ~96 columns.
- `##` doc comments on every class and on any function whose purpose is not obvious from its name.
  Class doc comments say what the thing is **for**, not what it contains.
- **Document the why and the edge cases; do not restate the implementation.** The code is right
  there.
- Section dividers inside longer files:
  `# ---------------------------------------------------------------- drawing ---`
- **Comments explain why, never what.**
- Leading underscore for private members and methods. Godot lifecycle methods (`_ready`, `_draw`,
  `_process`) are the exception and are not private.
