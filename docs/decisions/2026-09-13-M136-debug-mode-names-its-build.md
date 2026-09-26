## M136 — Debug mode names its build · built 2026-09-13

*(2026-09-13, [PLAYTEST-70](../playtests/PLAYTEST-70.md): "Debug mode should contain the commit +
describe.")* Built in the orchestrating session on `feature/m136-build-stamp` rather than
delegated: seven files, and the whole of the context — the version plumbing, the note, the
export — was already read for the answer that preceded it.

**The stamp is `git describe` and the commit together.** `TitleScreen.build_text()` —
`v0.10.3 (875609a5)` on a release, `v0.10.3-2-gab12cd3-dirty (ab12cd3)` on a working tree —
joins `version_text()`, the describe form the title screen already showed, with the new
`commit_text()`: `Telemetry.source_commit()`, git's `rev-parse --short HEAD`, where there is a
repository, else the new setting `application/config/source_commit`. The commit is carried
beside the version rather than derived from it because on a release describe collapses to the
bare tag, and a tag is a name a later `git tag -f` can move; the hash names this code and nothing
else. `DebugModeNote` carries the stamp after its words, and the readout's first line is
`build …`, read once on the first frame that assembles it, since a working tree pays two `git`
spawns for the answer and a release page with neither flag never pays them. The title screen
keeps the version alone: the hash is a developer's number and the note and the readout are where
a developer looks.

**One script stamps every export.** `tools/export-web.sh` writes the version and the commit into
`project.godot` for the duration of the export and puts the file back from a copy on every exit,
so a failed export leaves no stamp in the working tree. The version is `RELEASE_TAG` when the
caller set one — `deploy.yml` passes the pushed tag, and its checkout is shallow, so describe
there would name no tag — and describe with a `-dirty` mark otherwise; the commit is HEAD's
either way. Each anchor is asserted to occur exactly once before it is written and the result is
read back. The workflow's own `sed` step that wrote the version is gone, so a local export and a
served debug export are stamped the same way a deploy is, rather than carrying the placeholder.

**Checked.** The title test in `tests/test_pause.gd` asserts `commit_text()` against git,
`build_text()` against its two halves, and reads the stamp back off a `DebugModeNote`'s label;
a local release export was run and both settings read back out of the pack with the tree's own
describe and hash. Open to overturn: the three spaces between the note's words and the stamp,
and the readout line's word `build`.
