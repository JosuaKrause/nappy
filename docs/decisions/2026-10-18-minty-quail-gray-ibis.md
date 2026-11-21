# minty-quail — The nine settings classes become values (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus as
ten pull requests; this is the third, "the nine settings classes become values", built as #1611 by two Sonnet agents in
turn (the first stopped near its limit at a pushed commit). What the row already held as a value object becomes a
value: no public field, built once (section 2.1's rules; minty-lemur #785, #794).

**What was built.** The nine settings classes move to `src/events/parts/` (the data layer) with private fields, the
factories they have, refinements that return a new value, and the questions their readers ask; they stay `Resource`s
until the draft (the design's F2). **The hunt carries its rung**: `HuntSpec.pressing()`, `letting_out(men)` and
`pursuing(chase)`, so a row answers to heat exactly when it holds a hunt, and the row's `heat_response` goes; the row
answers `answers_to_heat()` and `hunts_for_her()`. The patrol car, the one row that presses, lets one man out as before.
`validate()` loses the pairings the parts make unwritable, each named in the pull request with the construction that
rules it out. The catalogue, the game's readers and the tests write and read through the parts.

**Measured.** The row fingerprint (`tests/probes/row_fingerprint.gd`) on main and the branch: every base line appears on
the head once private names are normalised; the 1,649 `heat_response` lines map exactly onto `answers_to_heat()`,
`hunts_for_her()` and the hunt's rung; every new answer equals the setting it replaces; the copies' hashes differ only
by renames (the review compared the planners' rows line by line). `docs/COSTS.md` is unchanged but for its header.

**The probe, fixed here.** The fingerprint followed every answer into the object it returns; once refinements returned
new values, each call gave a fresh object, its cycle check never fired, and a run recursed until it filled the disk with
Godot's log. It now marks a refinement's answer (an answer that is a new value of its receiver's own class) rather than
following it.

**Open to overturn:** the design's forks; the builders' factory and refinement names; `PursuitSpec.catching_within()`,
which 4b-6 moves to `LethalSpec`.
