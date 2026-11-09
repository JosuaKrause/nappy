---
name: godot
description: Godot 4.7 and GDScript traps that have cost real time in this project — silent type drops, the typing every file owes and the warnings that are errors, pause and process_mode inheritance, camera smoothing, node naming, leaks. Load this BEFORE writing or debugging any GDScript, and whenever something behaves in a way the engine gives no error for.
---

# Godot 4.7 / GDScript gotchas

These are not obvious and the engine does not warn about most of them. **The ones not to miss:**

- **`set(key, value)` silently drops a type mismatch.** Never build typed objects from dictionaries.
- **`var x := <a Variant>` is a parse error**, and `load(path).instantiate()` is a Variant: annotate.
- **Code is typed wherever the language can type it, tests included** (inbox #1280): an untyped declaration and an unsafe property or method access are parse errors here, and a new file carries no ignore of them.
- **An untyped `Array` passed as `Array[T]` leaks at shutdown**, and `.slice()` drops the element type.
- **No warning the engine prints is left standing** (woolly-finch 19).
- **A feature is tied to a flag the environment informs, never to the environment** (PLAYTEST-25 1).
- **`process_mode` is inherited**: a node added under `Main` needs `main._pauses_with_the_game()`.
- **`SomeNode.new()` has no name, and a `Node` is not refcounted**: name it, and free a test double.
- **`_draw()` is retained, and `draw_set_transform` replaces** the transform somebody else set.
- **A picture is an asset, never code** (the **cues** skill).
- **`art/`, `docs/` and `tools/` keep no `.import` sidecars; `.godot/` is never committed.**
- **Comments are in the present tense, and an override carries `## Overrides Class.method.`**

`references/rare-traps.md` holds the traps met less often, each under its trigger: `.slice()` and
cross-script enums, a press read under `Control`s, the title's pause split, a paused camera,
Y-sorting, `instance uniform`s, a flood fill's structure, a worktree's import cache, and what the
Web build leaves out. **That one gives no error on the desktop**: the release Web engine has no
3D, navigation, networking peers, TLS backend, streamed-media codecs, alternate texture loaders,
procedural noise or ZIP; read it before using one.

## Types

**`set(key, value)` silently drops a type mismatch.** Never build typed objects from dictionaries —
every `Array[int]` field comes out empty with **no error anywhere**. Use an explicit factory
function with named parameters.

**Passing an untyped `Array` into an `Array[T]` parameter leaks at shutdown.** The coercion at the
call boundary retains the arguments; you get "N ObjectDB instances were leaked at exit". Declare the
real element type at the call site.

**Some warnings are errors by default.** `var x := some_variant` ("the variable type is being
inferred from a Variant value") fails the parse outright. Annotate instead: `var x: int = ...`.

**And no warning the engine prints is left standing** (woolly-finch 19). A warning at boot, in
`check.sh`'s log or in a test run is fixed at its cause rather than read around: a `Camera2D` under
physics interpolation wants `process_callback` set to physics in its scene, so the engine has
nothing to override and nothing to say about it once a run.

This does not show up until the project actually boots, which is why `check.sh` exists. The form
that catches people is `var x := load(path).instantiate()`, because it reads as obviously typed and
is not — and in a **test** it fails at load time, so the runner reports that suite as `LOAD FAIL`
and runs none of its checks. Write:

```gdscript
var scene: PackedScene = load(path)
var node: Node = scene.instantiate()
```

**Three more warnings are errors because `project.godot` makes them so** (its `[debug]` section
sets each `gdscript/warnings/` entry to the error level), so that every receiver has a class the
engine and `tools/check_field_reads.py` can tell and a read of another class's field cannot hide
behind an untyped name (inbox #1268; the **designing-classes** skill, "Fields are not API"):

- `untyped_declaration`: a variable, a parameter, a function's return or a `for` variable with no
  static type. An inferred type is a type: `var t := Thing.new()` and a `for` over an
  `Array[Thing]` pass.
- `unsafe_property_access`: a property read off a type too wide to declare it, such as a `Node`
  holding a project class.
- `unsafe_method_access`: a method called off such a type, or off a value the engine types as
  Variant.

Each fails the parse with "Warning treated as error", and the script fails to load, a suite as a
`LOAD FAIL`.

**Code is typed wherever the language can type it, and an untyped name is never a habit**
(inbox #1280): `src/`, the suites and their rigs, fakes and probes, and the scripts under `tools/`
alike. A value stays a Variant only where the language cannot type it, such as the inner level of
a nested collection (`Array[Array[Thing]]` is itself a parse error, so the inner arrays are plain
`Array`s) or what `back()` or `get()` returns, and it is then read through a typed name, as
below. **writing-tests** says what that asks of a suite and its fakes.

**So a new file is typed from its first line; only a file not yet typed opts out, with one line.**
That line is the file's very first, `@warning_ignore_start("untyped_declaration",
"unsafe_method_access")`, naming exactly those of the three warnings the file still trips and
nothing else, and it silences them to the end of the file. The files carrying it are a list that
only shrinks: the change that types a file deletes its line, or the names the file no longer
trips (a name deleted while the file still trips it fails the file's parse, in `check.sh`'s boot
or its suite's load, which is how to find out). No other ignore of the three is written anywhere:
`tools/check_field_reads.py` fails an `@warning_ignore`, `@warning_ignore_start` or
`@warning_ignore_restore` naming one of them below a file's first line and a malformed opt-out
line, and in CI a file that gains the line or a warning on it.

**The engine warns of nothing on a property read off a Variant.** An element of an untyped
`Array` or `Dictionary`, the inner level of a nested one, what `back()` or `get()` returns, a name
declared `: Variant`: `things[0].count` parses at every warning level, where `things[0].make()` is
an unsafe method access. So such a value is read through a typed name (`var thing: Thing = things[0]`, `for thing:
Thing in things`, `things[0] as Thing`), and in a file under `src/` without the opt-out line
`tools/check_field_reads.py` fails the read the engine lets through, wherever the name read is one
a class under `src/` declares as a `var`.

**The setting reaches every script a debug build parses in this project, and no release export.**
That is `src/`, `tests/` with its rigs, fixtures and probes, the `.gd` scripts under `tools/`
whether run with `--script` or as a scene, and a script a test writes at run time and boots in a
child process: its source string is typed like a file, or opens with the opt-out line where it is
not yet. A debug export is a debug build, so the debug Web export (`tools/export-web.sh debug`,
which `tools/serve-web.sh` serves) is held to the setting too. The engine generates the warnings
only in a debug build, so the release Web export is not held to it and proves nothing about it;
`check.sh` and the suites do.

## Capabilities

**Never tie a feature straight to the environment. Tie it to a flag the environment *informs*, and
leave the override**, so that, for one, telemetry can be had when it is needed (PLAYTEST-25 1).

So `OS.has_feature("web")`, `OS.is_debug_build()` and `DisplayServer.is_touchscreen_available()` are
allowed to **answer** the flag. They may not **be** it. The platform is the default; the flag is the
decision; the override is how anybody ever looks at the other branch.

```gdscript
# Wrong — the web branch cannot be entered anywhere it can be watched.
if OS.has_feature("web"):
    return

# Right — the platform picks the default and the flag is what the code reads.
static func available(config: RunConfig = null) -> bool:
    if config != null and config.forces_touch():
        return true
    return DisplayServer.is_touchscreen_available()
```

`TouchInput.available(config)` is that second shape and is the model to copy: the platform fact and the
policy built on it are separate, so `--touch` can render a touch-only screen on a machine with no
touchscreen, and a screenshot rig can photograph it. It asks the configuration through a method,
`RunConfig.forces_touch()`, never by reading its field: `tools/check_field_reads.py` fails a new
read of a `var` another class declares (the **designing-classes** skill).

**Why it is a rule rather than a preference: a hard-tied gate makes a whole branch unreachable from
every test you own** — it does not cause a bug, it makes one unfindable, and nothing about it looks
like a gap. `Telemetry.begin_run()`'s web gate carries `?telemetry=1` for exactly this reason.

The test is not "can I reach this branch" but **"can somebody watching a screen reach it"**. A branch
only the deploy target can enter is a branch nobody has seen.

## Structure

**`--script` skips autoloads.** The test suite runs as a **scene**
(`godot --headless --path . res://tests/tests.tscn`) because every test needs `Tuning`.

**An autoload name cannot also be a `class_name`.** That is why shared enums live in
`src/game_enums.gd` rather than on an autoload.

**`SomeNode.new()` does not get the name `SomeNode`.** `Camera2D.new()` is named `@Camera2D@41`, so
a `@onready var _camera := $Camera2D` in a test rig silently fails. **Set `.name` explicitly when a
node is looked up by path.**

**Nodes are not refcounted.** A test double extending a `Node` class must be `free()`d by hand or it
leaks. `RefCounted` doubles do not.

**Never commit `.godot/`** — the **committing** skill, "Never commit", says why and what a fresh
clone needs instead.

**A folder behind a `.gdignore` keeps no `.import` sidecars, and this section owns that rule.** An
empty `.gdignore` is the engine's own *this directory is not mine*: it covers the folder and every
folder under it, the engine imports nothing there, and nothing there is carried into the exported
build. `art/`, `docs/` and `tools/` each have one, so the game's own pictures, SVG and PNG alike,
have no sidecars at all: the bake reads the files and writes atlas pages into the gitignored
`assets/atlases/baked/`, and only the pages are imported (`docs/VISUALS.md`, "Where the pictures
live"). So a picture under `art/` is committed on its own, an obsolete sidecar is removed when an
asset moves into such a folder, and `docs/.gdignore` is never deleted, since it is what keeps the
engine out of the evidence and the reference photos. The one picture the engine imports itself is
the application icon, root `icon.png`, a raster outside `art/` that keeps its sidecar.

What a worktree's import cache does and does not carry, and what a failed texture preload looks
like, are `references/rare-traps.md`, "Imports".

## Pausing

**`process_mode` is inherited, so one `PROCESS_MODE_ALWAYS` exempts a whole subtree.** `main.gd`
sets it on itself so Esc still quits while the summary has the tree paused — and every descendant
defaults to `PROCESS_MODE_INHERIT`, so the city, the player, the crowd, the events and the deadline
all inherit the exemption and `get_tree().paused = true` pauses nothing.

`main._pauses_with_the_game()` is called on every node that is the game rather than the frame around
it. **If you add a node under `Main`, it needs that call**, and nothing warns you.

The title screen's split the other way round (the city running while the day does not) and a
paused `Camera2D` that never arrives are `references/rare-traps.md`, "Pausing".

## Physics and drawing

**`move_and_slide()` owns `velocity`, so do not put anything else in it.** Folding a deflection into
`velocity` before the slide means `is_idle()` and `run_excess_ratio()` — the only two questions the
baby asks the rig — start answering for the crowd rather than for the player. Restoring `velocity`
afterwards is worse: it throws away the slide's own correction, so walking into a wall stops reading
as idle and starts making sleep progress. **A second displacement goes through its own
`move_and_collide()`**, which respects walls and touches nothing.

**A picture is an asset, never code.** A glyph, an icon, a silhouette or a symbol is an image file
under `art/` drawn as a texture, never assembled in `_draw()` out of `draw_circle`, `draw_rect`,
`draw_line`, `draw_arc` or `draw_colored_polygon`; layout — a bar's fill, a scrim, a debug overlay —
is not a picture. The rule in full, with its reasons, is the **cues** skill's
`references/picture-is-an-asset.md`.

**A negative-width `Rect2` does not flip `draw_texture_rect`.** It is normalised on the way through,
so the sprite lands a full width to one side — which looks like art sliding off its own shadow, not
like a failed flip. Mirror by setting a transform that scales x by −1 about the anchor instead;
`Sprites.draw_standing()` is the one place that does.

**`draw_set_transform` *replaces* the canvas transform — it does not compose with one somebody else
already set, and there is no getter to read the old one back.** So a helper that sets an absolute
matrix silently discards whatever its caller had already set, and the caller cannot defend itself —
it can only hand the helper what it set. `Sprites` carries a base transform for exactly this reason;
the contract a caller keeps is the **cues** skill's `references/drawing-and-redraw-gates.md`,
"Drawing through `Sprites`".

**`_draw()` is retained.** It re-runs only on `queue_redraw()`, so an expensive one-off draw (the
city ground) is fine, but anything animated must call `queue_redraw()` itself.

Y-sorting against a thing whose mass extends away from its origin, and the sixteen canvas items
that can carry a readable `instance uniform`, are `references/rare-traps.md`, "Drawing".

## Code style

### Comments are written in the present tense

**This applies to every `##` docstring and every `#` comment, exactly as it applies to the docs.**
A comment states what the thing **is** and **why**, never where it came from.

- **A citation carries the player's reason, or it goes.** A comment may quote the player's own words
  with where they were said, `*(PLAYTEST-28, finding 4: "…")*` or `*(2026-09-13: "…")*`, because the
  quote is the reason the code is the way it is, and that reason is current (woolly-finch 34). A
  bare milestone number or entry name with no quote (`(M39)`, "since M33", "for twelve milestones
  this was wrong") is history, not a reason, and goes.
- **No former values.** Not "it was 148 until M35", not "this used to be `(1−t)²`". Keep the
  *relationship* that makes the current number right — "above the 12.0/s decay on the ground it
  stands on" — and let the decision records under `docs/decisions/` hold the story.
- **No narration of the fix.** "The first version parked every route against the city wall" belongs
  in the commit message and in the decision record, not above the function.
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
- **GDScript has no `@override`, so a method that overrides one of a project class says so**: a line
  `## Overrides Class.method.` among its `##` lines, naming the nearest declaring ancestor (its
  `class_name`, `Outer.Inner`, or the file's stem). `tools/check_overrides.py`, which
  `tools/lint.sh` runs over `src/` and `tests/`, fails a missing line and an untrue one; a
  misspelled method with no line at all is a new method to the check (inbox #1154 in gray-dolphin).
  An engine virtual no project class declares needs no line.
- Section dividers inside longer files:
  `# ---------------------------------------------------------------- drawing ---`
- Leading underscore for private members and methods. Godot lifecycle methods (`_ready`, `_draw`,
  `_process`) are the exception and are not private.

## Proposed, not asked for

- **What the `## Overrides` line names and where it is asked for** — the nearest declaring
  ancestor, no line for an engine virtual no project class declares, and `src/` and `tests/` as the
  scope — is the filer's proposal, open to the player's correction (inbox #1154 in gray-dolphin).
- **An opt-out line gains no warning** is the builder's choice (minty-quail-busy-heron), open to
  the player's correction. The player's words ask that the field-read check be made to work and
  approve the design review's way to do it (inbox #1268): the three warnings as errors, the one
  line at the top of a file not yet converted, and the files carrying it as a list that only
  shrinks; and they say code is typed wherever it can be (inbox #1280), which a new file carrying
  the line would not be.
- **Which values the language cannot type** ("Types": the inner level of a nested collection, what
  a Variant-returning call gives) is the filer's reading of where the player's rule ends
  (inbox #1280), taken from what the engine accepts.
