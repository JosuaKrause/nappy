## Illustrated worktree recovery — 2026-09-09

The player asked for a clean slate after PR #49, with a new PR for anything worth committing.
The remaining worktrees were audited against `b4e0fba` before removal. The sprite WIP commit
`7a8aa5d` is patch-equivalent to `b6fcd8b` on main; the street reference commit `42122aa` is
patch-equivalent to `678a60a`, and all ten of its changed files match main byte for byte.

The sprite ancestry merge starts at main `b4e0fba`, with incoming tip `7a8aa5d` and merge base
`cb5e0a9`. Both visual helpers are absent in the base. The add/add conflicts are resolved by
retaining the evolved main implementations: directional registrations still accept a single
pivot but also carry per-view pivots and measured segment axes; planted gait still consumes
actual displacement but also bounds reach, consumes movement across step boundaries, and exposes
ankle and sole positions. Reintroducing the WIP would discard those registration repairs. No
numbered records are introduced by either old commit, so no identity renumbering is needed.

The street ancestry merge uses prepared tip `d641098`, incoming tip `42122aa`, and base
`87ad702`. It merges cleanly with no tree change: the v2 source assets, sidecars, generation
record, and review-scene bindings are already identical. Both old commits are retained as
ancestors of the cleanup PR without reverting any later runtime or art work.

The dirty walker crowd binding and tests match `0a2d56e` byte for byte. Its untracked compositor
differs only in where it guards an empty initial pose; main guards both variant updates and
registration/reset state. The shared documentation edits only repair evidence paths that are
already repaired on main, or refer to a TODO item already archived. The three bound PNG sources
and their sidecars are already preserved. These leftovers do not add a new runtime requirement.

One unused source is recovered: the worktree's `assets/illustrated/walkers/lower-denim-sneakers-v1.png`
and its original import sidecar. Its prompt is already in the generation record. The file is
preserved byte for byte (Git blob `4ca00801afb815b2103c91bb40eb322af207596d`); inspection shows
joined trouser-and-shoe silhouettes, and `sips` reports a 2032 × 774 image with alpha. It remains
unbound and is not approved as a replacement for the articulated runtime source. Review moved it
to `assets/illustrated/source/`, the folder for unwired drafts, because the web export takes
every resource under `assets/` and the walkers folder held four PNGs beside a manifest that
registers three; the sidecar keeps its uid and its cache path follows the new source path. The
review also recorded that the sheet reads front first with the back view in cell 5, not the
prompt's N-first order. The one stash in the working clone is an unrelated route-tree WIP and is
not part of this recovery.
