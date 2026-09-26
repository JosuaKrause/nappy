## `run.sh` rebuilds a stale class cache instead of refusing — 2026-09-06

**Asked for X · overturned to Y on 2026-09-06**, in the player's own words: *"I thought check now
automatically runs before run"*, and then *"add the cleanup to check so it just starts"*.

**X was M70's refusal.** `tools/run.sh` compared every `class_name` declared under `src/` and
`tests/` against the `"class": &"Name"` entries in `.godot/global_script_class_cache.cfg`, and on a
mismatch printed *"run tools/check.sh to rebuild it — then check git status, because its import pass
sometimes rewrites project.godot and docs/ARCHITECTURE.md as a side effect"* and exited 1. The
reasoning written into the script was that the import pass costs about two seconds even with nothing
to import, on a path reached twenty times a session, and that it was known to dirty two files
nobody asked it to touch — *"neither is a price this quick, common path should pay on the chance the
cache happens to be stale."*

**Y is that it rebuilds.** The detection is unchanged and still costs two greps, so the common path
is untouched — measured at 34 ms on a current cache, against about ten seconds for the rebuild it
now runs only when a class is genuinely absent. After `check.sh` returns it re-runs the same
comparison and refuses if a name is *still* missing, because that is no longer a stale cache and
running the game would only produce the parse error the check exists to prevent.

**What made the overturn safe was fixing the second half of the old reasoning rather than accepting
it.** `tools/check.sh` now records, before it runs, whether `project.godot` and
`docs/ARCHITECTURE.md` were clean, and reverts either one afterwards if it was clean before and is
dirty after — from an `EXIT` trap, so it also happens on the failure paths, which is exactly when
nobody thinks to look at the working tree. A file that already carried changes is **left alone and
named**: reverting a `project.godot` somebody had deliberately edited would delete real work to fix a
whitespace bug.

**Two rejected shapes.** Rebuilding on a *modification time* was rejected for the reason M70 gave
originally — every ordinary edit changes a script's mtime, so "edit a script, play it" would cost a
full import every time; the cached-class comparison has no false positives. And having `run.sh`
revert the two files itself was rejected because the rewrite belongs to the pass that causes it: a
second caller of `check.sh` would otherwise need the same guard, and CI already calls it.

**Verified with a stub binary** standing in for Godot: one that dirties `project.godot` proves the
revert fires and prints which file it reverted; the same run with `project.godot` already edited
proves it leaves the edit alone and says so. The rebuild path was proved by deleting `ModeButton`'s
entry from the cache and watching `run.sh` detect it, rebuild, and launch.
