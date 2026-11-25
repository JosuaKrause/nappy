**Open: `tools/check_field_reads.py`'s `--help` and `--summary` describe the opt-out line's list as live,
and `tools/typing_census.py` has no file to keep in step.** The help is rewritten for a tree where no
file carries the line (the check fails a file that gains it; a use through a receiver whose class
cannot be told fails in every file under `src/`); the code paths that skip a use in a file with the
line, and `--summary`'s count of such files, are deleted if nothing can reach them, with their tests.
`tools/typing_census.py`, its tests and its row in the using-tools skill are retired or given a job
that still exists, and the godot and using-tools rows that name it follow.
