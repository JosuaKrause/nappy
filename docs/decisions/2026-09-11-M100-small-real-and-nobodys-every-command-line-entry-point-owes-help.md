## M100 — Small, real, and nobody's · every command-line entry point owes help, built 2026-09-11

*(2026-09-11: "help doesn't work it just starts the game which becomes unresponsive. also invalid
arguments should get rejected and cause the help to be printed"; "rejecting invalid args and
having a --help/-h is a general requirements for everything that is cli accessible".)* The rule
went into the **cli-tools** skill the same day and this is the item that made the nineteen
existing tools obey it — eight agent commits on `feature/cli-tools-help`, reviewed here. Every
shell script under `tools/` answers `--help` and `-h` with its usage and exits before any work,
and rejects an unknown flag, a flag missing its value or a stray word with the usage on stderr and
a non-zero exit; the three Python tools already did through `argparse`, and `codex-hooks.py` now
checks its arguments before reading stdin, where it used to hang on a bad call. **The dev-flag
list is read from the game rather than copied**: `src/dev/dev_flags.gd` gained one table naming
every flag and its arity — with the optional-value shapes (`--force`'s numeric interval,
`--start-escape`'s part name) spelled per flag rather than inferred — and `tools/lib_dev_flags.sh`
reads it live for `run.sh` and `shot.sh`, so the scripts cannot drift from the game; `README.md`'s
flag section is held to the same table by a test rather than generated from it, the smaller of
the two ways to fail loudly on drift. **What the sweep found on the way**: `telemetry.sh` fell
through to "print the newest run" on any flag it did not know; `release.sh` read an unrecognised
second word as "do not push"; `stats.sh --help` took the reject path and exited 1; `export-web.sh`
and `serve-web.sh` ignored stray arguments. **Left as a forwarder on purpose**: `test.sh` validates
only its own three flags and passes everything else to the test scene, because suite filters and
scene flags such as `--svg` have no closed vocabulary readable from the shell; the day one exists,
it validates the way `run.sh` does. Every caller — CI's workflows, the lint hook's positional
path, the Codex hook's bare call, and every documented invocation in the docs and skills — was
checked and kept working. `tools/test_cli_help.sh` (wired into CI) and `tools/test_cli_help.py`
hold the two-path test for every tool.
