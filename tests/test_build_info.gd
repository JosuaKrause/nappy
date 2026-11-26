extends RefCounted
## `BuildInfo`: which version strings name a release candidate. The reading is the one the page
## counter's gate (`GoatCounterOutbox.may_ever_send()`, `tests/test_visit_counter.gd`) and the
## save's file name (`GameSave.player_path()`, `tests/test_save.gd`) both rest on, so it is held
## here once, on the version strings a build can actually carry: a candidate's baked tag, a
## release's, a working tree's `git describe` and an export's placeholder names.


func run(t: TestRunner) -> void:
	_test_a_candidates_baked_tag_names_a_candidate(t)
	_test_nothing_else_a_build_can_carry_names_one(t)
	_test_a_working_tree_is_no_candidate_whatever_git_describes(t)

func _test_a_candidates_baked_tag_names_a_candidate(t: TestRunner) -> void:
	for version: String in ["v0.30.0-rc.1", "v0.31.0-rc.12", "v1.0.0-rc.3"]:
		t.check(BuildInfo.names_a_release_candidate(version),
			"%s, the tag a candidate's export bakes, names a release candidate" % version)

func _test_nothing_else_a_build_can_carry_names_one(t: TestRunner) -> void:
	for version: String in [
		"v0.29.3",
		"v0.31.0-rc.1-3-gab12cd3",
		"v0.31.0-rc.1-dirty",
		"v0.29.3-49-gab12cd3-dirty",
		"ab12cd3",
		"dev",
		"ci-0123456789abcdef",
		"unknown",
		"",
	]:
		t.check(not BuildInfo.names_a_release_candidate(version),
			"%s names no release candidate: a release, a working tree or a placeholder" % version)

## **A developer's checkout is never a candidate, even sitting exactly on a candidate's tag**, where
## `git describe` says `vX.Y.Z-rc.N`: the save and the counter ask `exported_version()`, which is
## the version an export baked and, on a working tree like this run's, the placeholder
## `project.godot` carries, so the player's own save stays the release's.
func _test_a_working_tree_is_no_candidate_whatever_git_describes(t: TestRunner) -> void:
	t.check(not BuildInfo.names_a_release_candidate(BuildInfo.exported_version()),
		"a working tree's exported version (%s) names no candidate, whatever git describes (%s)"
		% [BuildInfo.exported_version(), BuildInfo.version_text()])