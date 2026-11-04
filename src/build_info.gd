class_name BuildInfo
extends RefCounted
## What build is running: the version and the commit, asked of `git` on a working tree and read
## from the settings `tools/export-web.sh` bakes into an export.
##
## **Data about the build, below everything that shows or records it.** The title screen, the
## save, the run log's first line and folder name, the frame trace and record, the debug note and
## the readout all name the build, and each of them reads it here rather than from one another, so
## none of them depends on a screen or a log to know what it is running.

## The version the run was played on: `git describe`'s own form, `<tag>-<commits-since>-g<hash>`
## (e.g. `v0.0.0-49-gab12cd3`), or a bare abbreviated hash where no tag is reachable, with
## `-dirty` appended if the working tree was not clean.
##
## Without it a trace cannot be checked against anything: "day one was brutal" is only a finding
## if the code that produced it can be got back. Naming the tag as well as the hash is what lets a
## reader tell *which release this is close to* without opening a shell.
##
## **Dirty is asked separately from `git describe`, not folded into its own `--dirty` flag.**
## `git describe --dirty` only looks at tracked files (`git diff-index`), so a file that has never
## been committed leaves it silent. `git status --porcelain` counts untracked files as dirty too:
## the mark only ever claims "this is not exactly that commit", and it must never claim otherwise.
##
## Asked of `git` at runtime rather than baked in, because the project has no build step to bake
## it during — `tools/run.sh` starts the engine on the working tree. An exported build has no
## repository to ask, which is what "unknown" means; `version_text()` falls back to what the export
## baked instead.
static func source_version() -> String:
	# A browser cannot launch git; `version_text()` uses the export's baked metadata instead.
	if OS.has_feature("web"):
		return "unknown"
	var repository := ProjectSettings.globalize_path("res://")
	var describe_out: Array = []
	if OS.execute("git", ["-C", repository, "describe", "--tags", "--always"], describe_out) != 0:
		return "unknown"
	var version := ("\n".join(describe_out)).strip_edges()
	if version == "":
		return "unknown"
	var status: Array = []
	if OS.execute("git", ["-C", repository, "status", "--porcelain"], status) != 0:
		return version
	return version + ("-dirty" if ("\n".join(status)).strip_edges() != "" else "")

## The commit on its own — `git rev-parse --short HEAD`, or "unknown" where there is no repository
## to ask. `source_version()` ends in a hash in `git describe`'s tagged form, but on a commit that
## *is* a tag — every release — describe says only the tag, and a tag is a name a later
## `git tag -f` can move; the hash names this code and nothing else.
static func source_commit() -> String:
	if OS.has_feature("web"):
		return "unknown"
	var repository := ProjectSettings.globalize_path("res://")
	var out: Array = []
	if OS.execute("git", ["-C", repository, "rev-parse", "--short", "HEAD"], out) != 0:
		return "unknown"
	var commit := ("\n".join(out)).strip_edges()
	return commit if commit != "" else "unknown"

## The version a person is shown: `source_version()` where there is a repository, because a
## developer wants to know exactly what is running, and otherwise `application/config/version` —
## the setting `tools/export-web.sh` bakes into the export before it is built: the release tag on a
## deploy, `git describe` with a `-dirty` mark on a local export — so a player sees the release
## rather than "unknown".
static func version_text() -> String:
	var from_git := source_version()
	if from_git != "unknown":
		return from_git
	return ProjectSettings.get_setting("application/config/version", "unknown")

## The commit on its own, by the same two steps: `source_commit()` where there is a repository,
## else `application/config/source_commit`, which `tools/export-web.sh` bakes beside the version.
## On a release `version_text()` is the bare tag, and a tag can be moved; the hash cannot.
static func commit_text() -> String:
	var from_git := source_commit()
	if from_git != "unknown":
		return from_git
	return ProjectSettings.get_setting("application/config/source_commit", "unknown")

## What the debug furniture and the files a run writes say the build is — `v0.10.3 (875609a5)` on
## a release, `v0.10.3-2-gab12cd3-dirty (ab12cd3)` on a working tree — the `git describe` form and
## the commit together, since describe alone collapses to the tag on every release. *(2026-09-13,
## playtest 70: "Debug mode should contain the commit + describe.")*
static func build_text() -> String:
	return "%s (%s)" % [version_text(), commit_text()]
