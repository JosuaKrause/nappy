# minty-quail — The comparison of two trees' placement rows is a tool (minty-quail, tools) · 2026-11-10

**The ask.** A manual sequence done a second time becomes a script (woolly-finch 23). The script
that compares two trees' placement rows (the record minty-quail-grassy-magpie states its rule) had
been run by hand at every placement step, and a copy sat in the first baseline reading's evidence
folder; the end-of-refactor remeasure runs it once more (the entry's README, "Order").

## What was built

- **`tools/compare-placement-rows.py`**: one `--sample NAME CITIES MAIN_LOG HEAD_LOG` per sample,
  `--roles FILE`, and labels for the two trees' headings. It prints the rows outside two standard
  errors pooled, the rows outside them on two or more samples with the same sign, a summary and the
  counts, and nothing that belongs to one step. Help on `--help` and `-h`; a missing sample, an
  unknown flag, a bad city count or an unreadable log is refused before any work.
- **`tests/probes/placement_roles.gd`**, the role probe moved out of the evidence folder and typed:
  it prints the role table the tool reads, since the rows log carries no roles and an older tree has
  no `role_for()`, so one table serves both trees.
- `tools/test_compare_placement_rows.py` (four cases, run by `tools/pycheck.sh`), the tool's entry in
  `tools/test_cli_help.py`, and its row in the using-tools catalogue.
- Run on the first baseline reading's logs, the tool prints a file byte-identical to that reading's
  `raw/placement_comparison.txt`.

## Choices the builder made, open to the player's overturn

- **The role table is a file the tool is handed**, printed by the probe, rather than the Python tool
  starting the engine itself.
