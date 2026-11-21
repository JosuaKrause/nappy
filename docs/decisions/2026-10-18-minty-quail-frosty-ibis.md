# minty-quail — The body is a part (row 4b) · 2026-11-21

**What was asked.** Row 4b of minty-quail's `event-interface.md` (a row is written as its parts), designed by Opus;
this is its fifth pull request, "the body is a part", built as #1618 by three Sonnet agents in turn.

**What was built.** `BodySpec` (`src/events/parts/body_spec.gd`, data) holds what the row is on the ground: its
shape, whether it is solid and when, its pieces (`BodyPiece`, which replaces `EventDef.SolidPart`), what a walker takes
it for, whether it parks, and how it lies, now one choice where three flags resolved by precedence (no row wrote two,
so no answer moved). The 11px floor on a drawn width is stated once, in `BodySpec.drawn_width()`. The row holds one
`body()` set by `use_body()`, with forwards for what callers outside the folder ask; `EventBody` is handed the part;
the catalogue writes one body per row, by a script kept with the design. Every copy shares its row's body, so the hand
carries of the shape and the pieces in the copies, the seal planner, the happenings and the director are gone.
`validate()` loses the checks the value makes unwritable (a reach that disagrees with the shape: the reach is the
shape's; a piece with no shape: `BodyPiece.at()` refuses it) and keeps "solid once it starts with no body", the
pieces-inside check, and a new refusal of a body that claims to be solid with no shape, which the old reach check
caught.

**A defect the step found and its construction fixes.** The director's copy of a row offered ground
(`EventDirector._with_ground()`) carried the shape but not the pieces, so a crash it handed out stood solid across the
whole street (reach 96) instead of only at its two cars (36.1), against M118 (a car crash is solid only where the cars
are). A copy now shares the body and keeps its pieces; the row fingerprint shows the seven copies that moved, and no
other answer did.

**Measured.** The row fingerprint (`tests/probes/row_fingerprint.gd`): every old body setting shows the base's value
under `body()`, and `obstructs_within()` equals the old `obstructs_radius` on all 55 rows; the differing lines are the
floor now applied inside `drawn_width()` (its callers floored already), three shapeless rows answering no piece where
the base gave one with a null shape, and the crash's copies above. The look and excitement fingerprints,
`curly_stork_piece_layout.gd`, `escape_density.gd` and `placement_rows.gd` print the same on main and the branch.

**A deep copy loses the body**, since a `GroundShape` cannot be stored: the game makes none, and a check holds that no
code under `src/events`, `src/routes`, `src/resistance` or `src/day` does, and that every copy it makes shares its row's
body.

**Open to overturn:** the design's forks; the builders' names for the walker refinements (`walked_through()`,
`walked_round()`, `unmet()`), `reshaped(shape)`, `lies_as_a_spread()` kept as a forward on the row.
