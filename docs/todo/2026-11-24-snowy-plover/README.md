priority: later
after: 2026-10-18-minty-quail

# snowy-plover — The scene recipes' untested corners: the director's arrow ground, free play past its end, the boundary probe and a bounded scene's gate · filed 2026-11-24

**What this is.** Four behaviors of the scene recipes (the developer's scenes that put her in one
situation and play it, run by `src/dev/scene_recipe_runtime.gd`) that no suite checks.
minty-quail's scene-recipe test gaps are sent here, and the record
minty-quail-bouncy-hare says where they came from. No playtest note is behind it; the band,
`later`, is the filer's proposal, and the `after:` line is minty-quail's, whose test conversion
decides which suites exist to hold these checks.

**Read as:** each item adds a test and, where it says so, one small hand-in in `src/dev` that the
test needs; none changes what the game does. A builder takes an item when the suite it names is next
touched, and shows the check failing before it passes by making the change the item names to the
source and running the suite.

**Items**, one file each:

- `director-arrow-ground.md`: the director's own use of the arrow ground.
- `free-play-past-its-end.md`: a scene in free play past its whole duration.
- `boundary-probe-world.md`: the runtime suite's boundary probe writing the runtime's named world.
- `bounded-scene-gate.md`: a bounded scene's check that no event body stands outside the
  authored ground.
