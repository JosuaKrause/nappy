priority: now

# silky-magpie — The field-read check's help and the typing census say what is true with no opt-out line left · filed 2026-11-25

**What this is.** Found by the review of the pull request that closed minty-quail (the codebase
refactored by layer): no `.gd` file carries the `@warning_ignore_start` opt-out line any more, and
two tools still speak of a conversion in progress. `uv run python tools/check_field_reads.py --help`,
which the skills call the one text of what the check sees, says "the files carrying that line are the
list of files not yet converted, which only shrinks", that a use is skipped "in a file with the
line", and that `--summary` counts the files still carrying it. `tools/typing_census.py` keeps each
file's opt-out line in step with what the file trips, which has nothing left to do.

**Proposed, not asked for:** the band, `now`, is the filer's proposal: work on how the project is
worked on goes first (inbox #1305 in grassy-trout). No playtest note is behind it.

**Read as:** a tools change (python-tooling, cli-tools), so it is not a docs-only edit and was not
made in the closing pull request. Whether the census is retired or repurposed (code that serves a
feature no longer there is deleted, designing-classes) is the builder's question to put to the
orchestrator with what it finds.

**Items**, one file each:

- `help-and-census.md`: the help text, `--summary`, and the census.
