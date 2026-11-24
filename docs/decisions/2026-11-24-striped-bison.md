# striped-bison — The field-to-method rewrite is a committed tool · 2026-11-24 · not from an entry

Putting a class's public field behind a method (`City.map` to `map()`, the nine `CityMap` fields) was done by
three scripts kept in the orchestrator's git-ignored briefs folder and copied to `/tmp` for each run: one renamed
the field private in its file, one loaded every script in the engine and listed each use the parser then refused, one
rewrote each listed use. They had run three times (the design's row 4a, C3 in #1689, C5 in #1714), each time
copied again and edited for the class, which the repository's rule for a sequence done a second time forbids
(woolly-finch 23). The #1714 review found it.

**What is built.** `tools/field_to_method.py CLASS_FILE FIELD[=METHOD] ...` does the three steps in one run: it copies
the project to a scratch directory, imports it, renames the fields in the class's file, runs
`tools/field_to_method_probe.tscn` (loads every script under `src/`, `tests/` and `tools/`) until the engine refuses
no use it can place, and then rewrites the checkout's uses `.field` to `.method()` and renames the field in the
class's file. Where the readers' list holds a use it cannot place, a use already private, a local or parameter named like the field (the in-class rename is by name), or a script that failed
after the rename and loaded before, it refuses before writing anything. `--dry-run` prints the list and the count.
It prints the stub of the method, every remaining use of the old name without parentheses or by string, and the lines
of `tools/field_reads.txt` and `tools/test_only_members.txt` that name the field, so the builder searches for the old
name and settles the lists as the pass owes.

**Measured.** On `main` at `7b21dcc30` (#1714's merge base) `field_to_method.py src/city/city.gd map` lists 1,122
uses on 1,041 lines in 100 files, in four rounds, as the scripts did. Of the 101 files it writes, 92 are byte for byte
#1714's head; the other nine are the files #1714 changed by hand after the script: `city.gd` (the method and its doc
line, which the tool prints as a stub), seven files where the two added characters pushed a line past about 96
columns and it was rewrapped, and `test_scene_recipe_runtime.gd` (a use the engine did not list, found by search).

**What it replaces, and what it does not do.** It replaces `rename_private.py`, `probe_readers_4a.py` and
`rewrite_map.py` of the design's folder, whose groups were edited into the script for each run; the class and its
fields are now arguments. It does not write the method, place it or document it; it does not turn a write into a call;
it does not see a property read through a Variant (a Dictionary's value, an untyped var) or a use inside a string a
suite boots, which the remaining-uses list is for. `tools/test_field_to_method.py` tests the rewrite's parts and a
whole run against a stand-in engine; the real engine's run is the measurement above.

**Tried and rejected.** Running the probe inside the checkout and putting the files back: a failed run would leave the
checkout half renamed, and the checkout may hold another builder's uncommitted edit. The scratch copy costs a copy of
the project, which the whole run, engine included, keeps under a minute. A `_p_` fallback name where the file already declares `_name`, as the old script had:
the tool refuses, since a field renamed to a second name is not what a reader of the diff expects.
