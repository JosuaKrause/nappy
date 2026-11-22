# minty-quail — The look is a part (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its eighth pull request, "the look is a part", built as #1628 by Sonnet agents one part per turn. It finishes row
2b's leftover: a look is handed its look's settings and asks the live event the rest (event-interface 2.10).

**What was built.** `LookSpec` (`src/events/parts/look_spec.gd`, data) holds how an event is drawn: its picture, its
warning picture (`WarningPicture` moved onto it), whether it casts a shadow, whether it trails a lead, whether it hides
in its hold, whether it may be drawn as a pelican, and the guarded sides of the roadblock's band, which the region wall's copies override (`of()`, `none()` and
refinements). The row holds one with `use_look()` and `look()`, forwarding only `picture()`. Each look is handed its
look part and the row's body part by `EventLooks.for_row()`, when the live event sets itself up, and holds no row; the
van's look is handed the abduction part the same way. The live event gains a question only where a look asked one it lacked: `footprint()`, `moves()`,
`approach_speed()`, `peak()`, `pulses_every()`, `notice_within()`; the body part, which never changes, is handed to the
look rather than asked of the live event on every draw (event-interface 2.1 and 2.10). The barrier post asks
`guard_sides()`; the seal and region planners' wall copies refine the look with `guarded_on()`. The catalogue's writers
are rewritten by `convert_catalogue_look.py`, kept with the design, three rows by hand.

Row 2b's line and the abduction row of event-interface's section 4.1 say the look is handed its part.

**Measured.** The row fingerprint on main and the branch: every removed look setting shows the base's value under
`look()` on every row and copy, the wall copies' guarded sides equal; the look fingerprint (every line), the excitement
and placement fingerprints, `placement_rows.gd`, `escape_density.gd` and `curly_stork_piece_layout.gd` print the same;
no cost figure moved. The look fingerprint's own timing, one run each, read 3.6% higher on the branch, within the noise
of single runs.

**Open to overturn:** the design's forks; the six new questions of the live event; `EventDef.takes_a_victim_by()`,
which asks the row's abduction part for the live event and stands until the row's public
`abduction` field goes private; the refinement `casting_a_shadow()`; `guard_sides()`
returning a copy.
