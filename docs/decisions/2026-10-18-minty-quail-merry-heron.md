# minty-quail — Every file under the tests is typed, and its item goes · 2026-11-24

`docs/todo/2026-10-18-minty-quail/typed-everywhere.md` asked that code be typed wherever GDScript
can type it, the tests included (inbox #1280 in olive-ferret): a new file is fully typed from its
first line, and a value the language cannot type is read through a typed name. Its "Done when"
holds, so the file is deleted; the text is at `git show
3fa20307d:docs/todo/2026-10-18-minty-quail/typed-everywhere.md`.

**Measured on 2026-11-24.** `uv run python tools/check_field_reads.py --summary` counts no file
carrying the file-level ignore of the typing warnings, under `src/` or `tests/`, whichever of the
three warnings it names, and lists no read of another class's field (`tools/field_reads.txt` is
empty). The two `PROBE` strings that suites write out as scripts at run time
(`tests/test_scene_recipe_activity.gd` and `tests/test_scene_recipe_runtime.gd`) carry no such
ignore either.

**What the item said that no longer stands.** Its "Build" said every file under `tests/` "carries
no file-level ignore but the two below" and named no two; the two were the `PROBE` strings, now
typed. Its proposals (a sweep of the other modules' fields from each pass's records, and the
pass's list built with `tools/field_answers.py`) were carried out by the module passes and the
field-read conversion; the plainer alternative it named, leaving each read to its suite's
conversion, was not taken.
