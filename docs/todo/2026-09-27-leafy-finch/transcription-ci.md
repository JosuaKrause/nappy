**CI checks that each inbox note a filing PR files is transcribed word for word** (statement 12).
For every note the PR's description names as filed (`Filed from #N`), the job reads issue N's body
and fails unless a playtest file the PR adds contains that body verbatim. The orchestrator closes
the batch's notes right after pushing the PR (statement 22), so a note does not change after it was
copied and the check does not have to catch a later edit; it catches a copy that was never right.
The description is read through GitHub's API when the job runs, not from the event that started the
run, since editing a description starts no run: a description corrected after a red check is
re-checked by re-running the job.

**It also fails on a note that is not the player's** (statements 19 and 23): an issue N opened by
anyone but the player turns the check red, whatever its label, unless the capture script of
`capture.md` opened it, which is an issue opened as `claude-orchestrator` or `codex-coder` that
carries the script's own tag (the player chose "Yes, marked by the script"). An issue opened by
anyone else is left open for the player to read; it is never filed.

**Proposed, not asked for:** the `Filed from #N` line's form; the capture tag's form (a label only
the script sets, or a line it writes in the body); how whitespace and line wrapping are normalized before comparing,
since a playtest file wraps its quotes and an issue body does not.
