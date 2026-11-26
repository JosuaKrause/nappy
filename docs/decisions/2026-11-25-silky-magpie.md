# silky-magpie — The field-read help and the typing census say what is true · 2026-11-25

No `.gd` file carries the `@warning_ignore_start` opt-out line any more (minty-quail, the codebase refactored by layer),
and two tools still spoke of a conversion in progress: `tools/check_field_reads.py --help` and `--summary` described the
list of files carrying the line as live and shrinking, and `tools/typing_census.py` kept each file's line in step with the
warnings the file trips.

**The check's rule is now "no file opts out".** A `@warning_ignore`, `@warning_ignore_start` or
`@warning_ignore_restore` that names one of `untyped_declaration`, `unsafe_property_access` and `unsafe_method_access`, or
whose argument the check cannot read, fails in every `.gd` file outside `docs/`, whatever its form (the former first-line
form included) and with or without `--base`. The "converted file" notion is gone: a use whose receiver's class cannot be
told fails in every file under `src/`. Deleted with what served it: the opt-out line's parser and canonical form, the
count of skipped uses (`Found.skipped`), `--summary`'s count of files still carrying the line, and the `--base` half that
failed a file gaining the line (an absolute failure leaves nothing to compare). `--base` still compares the list of reads.
The help names none of it as live.

**Two other tools read the line and lost that path.** `tools/field_answers.py` named a file that still ignored
`unsafe_property_access` (its `ignoring_unsafe_property_access` JSON key and its markdown line), and
`tools/check_test_only_members.py` let an engine-typed value count as a reader in a file whose line silenced that access.
Neither can be reached with the line failing everywhere, so both are deleted, with their tests.

**The census is deleted, not repurposed.** `tools/typing_census.py` (with `typing_census.gd`, `typing_census_names.gd`,
`typing_census.tscn` and `tools/test_typing_census.py`) existed to keep each file's opt-out line equal to what the file
trips, and `--check` already said it had nothing to keep in step. Its one other mode counted a further warning given as
an argument (`standalone_expression`) per folder and per line; nothing uses it, and `project.godot` makes that warning an
error, so the engine already names every occurrence. Code that serves a feature no longer there is deleted
(designing-classes). The using-tools row, `pycheck.sh`'s test line and `test_cli_help.py`'s entry follow; the godot,
writing-tests and designing-classes skills and CI's comment say "no file opts out" and no longer describe the line's one
form. A future return of the line would need the census again; git history holds it.
