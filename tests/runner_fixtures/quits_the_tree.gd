extends RefCounted
## A suite that quits the tree, held outside suite discovery like `engine_error.gd` and run only
## by name:
##
##     tools/test.sh runner_fixtures/quits_the_tree.gd
##
## The runner lets a frame pass after every suite, so this quit takes effect there: the process
## exits 0 before the runner prints its closing "N checks, M failures" line, and every later suite
## of a shard would be dropped silently. `tools/test.sh` fails a run that lacks that line, which is
## what this fixture proves.

const SENTINEL := "M-quit sentinel: quits_the_tree.gd is running and is about to quit the tree"

func run(t) -> void:
	print(SENTINEL)
	t.check(true, "the fixture's own assertion passes before it quits the tree")
	t.get_tree().quit()
