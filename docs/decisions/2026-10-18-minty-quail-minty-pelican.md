# minty-quail — main.gd is typed and loses its opt-out line · 2026-11-19

**What it is.** A typing pass of minty-quail's `field-reads.md` ("What is left of the typing under
`src/`"), which listed `src/main.gd` as waiting for no other item. The player on typing: "we type
when we can" (inbox #1280 in olive-ferret). An Opus builder built it. It changes nothing in play.

**What was built.** `main.gd`'s first line, `@warning_ignore_start("unsafe_property_access",
"unsafe_method_access")`, is gone, so the three typing warnings are errors in it; its declarations
were already typed. Three names were not:

- **The HUD and the day summary** were held as `CanvasLayer`, so every call on them was an unsafe
  method access. Neither script has a `class_name`, so `main` preloads each script as a constant
  (`HudScript`, `DaySummaryScript`) and types `_hud` and `_summary` through it, the form the suites
  already use for the same two scripts (`tests/test_hud.gd`, `tests/booted_main.gd`). The field-read
  check reads a receiver typed through a preloaded script.
- **A scene recipe's load result** (`SceneRecipeRuntime.load_recipe()`, a `Dictionary`) was read
  as `result.errors.is_empty()`, a method called off a Variant. Its errors are read into a typed
  `Array` by subscript, and its data by subscript too.

## Other classes' fields main reads, by class

Built with `tools/field_answers.py src/main.gd`; each method it printed apart was read in its class.

- **`City`**: `map`, read in twenty places, no method; `navigator`, read once, no method; the
  eight settings `main` writes into the city before `build()` (`trace`, `run`, `ground_recipe`,
  `atlas`, `ground_mode`, `scenery_frame_locked`, `skip_shadows`, `frame_timing`), no method.
  `build()` assigns `atlas` only as its own fallback when none was handed, which answers no write.
  All of them go with the city scene's pass (`city-hand-ins.md`).
- **`StillWatch`**: `trace`, written, no method (the tests-one-module item's group of fields only a
  test reads).
- **`TouchControls`**: `rotated`, written in two places, no method (the same group).
- **`WorldMap`**: `world`, read once (`_put_her_in()` hands the baby her world), no method.
  `has_world()` answers whether a world stands, worked out from the field, not the world itself.
- **The HUD and the day summary**: no field. Every var either script declares is underscore-private
  and `main` reads none; its uses are their signals (`continued`, `restart_requested`), the HUD's
  `use_the_day` handed on as a Callable, and the engine's `visible`. The field-read check cannot
  see such a read, since a file with no `class_name` declares no var it counts, so this was read by
  hand.

`tools/field_reads.txt` neither gains nor loses a line: typing exposed no read the list did not
already hold, so the clash with the rule that such a read is converted or the file left untyped
(inbox #1429 in minty-rabbit) did not arise.

## What typing showed the test-only member check

`tools/check_test_only_members.py` counted a call on an engine value in a file whose opt-out line
silenced its warning as a reader of every class's member of that name. `main`'s untyped
`_hud.use_atlas()`, `_hud.use_run()`, `_summary.is_showing()` and `result.data` were so counted for
five members no game file reads outside its own:

- **`Sitting.use_atlas` and `EventManager.use_run` are hand-ins** and take lines in the list's
  hand-ins' `[kept]` group: the game hands its own value in (the sitting keeps the library it makes;
  the manager takes its run in `setup()`), and `tests/test_atlas_boot.gd` and
  `tests/test_event_parts.gd` hand theirs in.
- **`EntityHalo.is_showing()`, `SaveIndicator.is_showing()` and `SceneRecipeRuntime.data` go
  internal** (`_is_showing()`, `_data`), since only their own files read them, and their suites read
  what each class does outward instead:
  - the halo's suites read what the rim draws: the shader's `halo_colour` alpha, exactly zero where
    the rim is out (`tests/test_halo.gd`, whose two checks of a settled rim already held it drawn at
    its target and so drop the read), and the rim drawn afresh on the frames after its glow settles
    (`tests/test_car_views.gd`);
  - the save suites read whether the symbol's `Icon` draws at an alpha above zero, through
    `Boot.save_symbol_shows()` beside the helpers that already read which picture it draws
    (`tests/test_save.gd`, `tests/test_save_wiring.gd`);
  - the scene recipes' lifecycle suite reads the recipe as its file has it (`_authored()`), which is
    what the runtime plays, since no suite there boots a draft.

Each moved check was shown to fail with the class mutated, the mutation reverted and never
committed: the save symbol raised by no change (34 failures) and raised from its first frame (26);
the rim no longer asking for a redraw once settled (the three redraw checks), counting as showing at
zero alpha (the two checks of a dark rim), and a fade a hair short of zero never snapped (the hair
check); and the recipe's meters seeded at zero (the meters check), an authored event not recorded
(the installed-events check), and the recipe's day read one later in `DevFlags`, which is where the
authored day reaches the run (the authored-day check).

## Rejected, with the reason

- **A `class_name` on `hud.gd` and `day_summary.gd`**: it edits two files of the view for what a
  preloaded constant does in `main` alone, and `HUD` is already `main`'s name for the HUD's scene.
- **`[kept]` lines for the three members that went internal**, built first: refused in review,
  since each had a reader in its own file and a way for its suite to read it outward, so the lines
  only deferred the conversion the `[own file only]` group asks for, and that group only shrinks.

## Verified

`tools/check.sh` boots with no error or warning; the suites that boot `main` (`test_main`,
`test_boot_handing`, `test_run_config` and nineteen more, `test_held_restart` and `test_invincible`
among them) pass, and so do the suites of the three members made internal (`test_save`,
`test_save_wiring`, `test_halo`, `test_car_views` and the three scene recipe lifecycle suites);
`check_layers.py`, `check_field_reads.py --base origin/main` and
`check_test_only_members.py --base origin/main` pass, and `check_field_reads.py --summary` counts
one file fewer under `src/` carrying the opt-out line.

**Proposed, not asked for, open to the player:** typing the two screens through preloaded scripts;
the outward reads chosen for the three members made internal.
