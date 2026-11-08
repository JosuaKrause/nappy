# minty-quail — Two members of the world layer nothing reaches are deleted · 2026-11-07

minty-quail's `dead-code-sweep.md`, its first module, `src/world/`, in #1200: code nothing reaches
is deleted, and a feature wanted back is built fresh (inbox #1180 in gray-dolphin).

**Deleted.**
- **`Mover.with_radius()`** (`src/world/mover.gd`): named nowhere in `src/`, `tests/`, `tools/` or
  `scenes/`; added with the shared mover (#817), and nothing ever called it.
- **`Navigator.open_ground()`** (`src/world/navigator.gd`): added by #817; its only reader was
  `tests/test_world_passability.gd`, which now builds `Navigator.new()`, the same object, since the
  default map is `WorldMap.open_ground()`. Its line in `tools/test_only_members.txt` went with it.

**Choices where the design was silent, open to overturn:** one module only, as the item's method
says, although dead code is thin in every module; the test's guarantee kept and moved onto
`Navigator.new()` rather than deleted.

**The survey** found no module with more than a few unreached members; the item's file lists where
the rest is.
