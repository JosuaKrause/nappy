# minty-quail — The look is a part (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its eighth pull request, "the look is a part", built as #1628 by Sonnet agents one part per turn. It finishes row
2b's leftover: a look is handed its look's settings and asks the live event the rest (event-interface 2.10).

**What was built.** `LookSpec` (`src/events/parts/look_spec.gd`, data) holds how an event is drawn: its picture, its
warning picture (`WarningPicture` moved onto it), whether it casts a shadow, whether it trails a lead, whether it hides
in its hold, whether it may be drawn as a pelican, and the checkpoint wall's guarded sides (`of()`, `none()` and
refinements). The row holds one with `use_look()` and `look()`, forwarding `picture()` and `casts_a_shadow()`. Each
look is handed its part by `EventLooks.for_row()` and holds no row; the van's look is handed the abduction part as the
abduction behaviour is. The live event gains a question only where a look asked one it lacked: `drawn_body()`,
`footprint()`, `moves()`, `approach_speed()`, `peak()`, `pulses_every()`, `notice_within()`. The barrier post asks
`guard_sides()`; the seal and region planners' wall copies refine the look with `guarded_on()`. The catalogue's writers
are rewritten by `convert_catalogue_look.py`, kept with the design, three rows by hand.

**Measured.** The row fingerprint on main and the branch: every removed look setting shows the base's value under
`look()` on every row and copy, the wall copies' guarded sides equal; the look fingerprint (every line), the excitement
and placement fingerprints, `placement_rows.gd`, `escape_density.gd` and `curly_stork_piece_layout.gd` print the same;
no cost figure moved. The look fingerprint's own timing, one run each, read 3.6% higher on the branch, within the noise
of single runs.

**Open to overturn:** the design's forks; the seven new questions of the live event; `EventDef.takes_a_victim_by()`,
which stands until the abduction setting becomes a part; the refinement `casting_a_shadow()`; `guard_sides()`
returning a copy.
