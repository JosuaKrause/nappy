**CI checks that each inbox note a filing PR closes is transcribed word for word** (statement 12).
For every `Closes #N` in the PR's description, the job reads issue N's body as it stands and fails
unless a playtest file the PR adds contains that body verbatim. Because the player may edit a note
until the filing PR merges (statement 6), a note edited after it was copied turns the check red,
which is the signal to copy it again.

**Proposed, not asked for:** how whitespace and line wrapping are normalized before comparing,
since a playtest file wraps its quotes and an issue body does not.
