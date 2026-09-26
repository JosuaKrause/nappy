## Illustrated assets and experiment preservation — 2026-09-06

PLAYTEST-30 preserves the full reference discussion. The player briefly chose a diagonal grid, then explicitly tabled it again:
"let's not go diagonal for now but try to match the diagonal artworks style". The implemented
projection is not changed. Main's M79 investigation was read and supplemented with the distinction
between rotation and dimetric compression, upright artwork, long-footprint sorting, silhouette
occlusion and inverse-projected streaming bounds.

The selected next sample is illustrated 2.5D PNG art with modular character parts and eight views,
not primitive 3D geometry. The mother follows the supplied green-coat, scarf and bun reference.
Foot planting must follow actual world travel; distance-driven oscillation alone did not satisfy
the player's gait feedback. The supplied cardinal mockup is a composition reference, not a change
away from the richer illustrated style. Minimap, portraits and bottom-bar action verbs were not
adopted. All four distinct supplied reference files were committed.

Before direction-changing edits, every graphics worktree was committed and pushed, including
rejected experiments. The player then requested that rejected histories be kept inside the one
overhaul branch, with no dangling branches. The snapshot commits are: SVG actors/events
`de81fc7`, earlier city `9215a9a`, earlier UI `38036ac`, 3D projection `1dace44`, articulated animals
`9ef72e3`, and the newer screen study `d9b6ad9`. The original stash also received a remote backup.
These histories are preserved through ancestry-only merges where their content is not adopted;
`git show <commit>:<path>` retrieves the exact experiment. The SVG actors/events polish remains
eligible for its separately requested PR, not evidence that the full overhaul is complete.
