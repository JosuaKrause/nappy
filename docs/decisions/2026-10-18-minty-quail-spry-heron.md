# minty-quail — The pram's, the ground shape's, the move proposal's, the view's and the route tree's fields read through methods outside the events · 2026-11-18

**What it is.** A part of minty-quail's `field-reads.md` conversion: five classes' fields read from
outside their files outside the events: the pram (`Stroller`), the shape a body takes on the ground
(`GroundShape`), a crowd member's planned step (`MoveProposal`), the camera's view (`VisibleView`)
and the route tree (`RouteTree`). A Sonnet builder built it to the settled pattern. It changes
nothing in play.

**What was built.** The move proposal's `from` is private, read through the existing `stands_at()`;
the separation pass asks a new `has_parked()`; day 12's park cordon sets its officers through the
existing `step_to()` and `use_body_radius()`. The route tree's `branches` is private behind
`branches()`, which returns the same array. The pram's `shape` and `pram_shape` are private behind
`shape()` and `pram_shape()`; `is_carrying()` is new, and `main` calls `use_carrying_rig()` instead
of writing `carrying`; the scene recipe runtime uses the existing `facing_direction()`. The ground
shape's readers use the existing `spine_half_length()` and `rounding_radius()`. The view answers
`camera_view()` and `screen_cover()`. `tools/field_reads.txt` lost seventeen lines and gained none.

**Left:** the fields the events read stay public (the move proposal's `to`, `radius`, `parked`,
`open`, `stood_round`; the ground shape's `kind`, `half_length`, `radius`, `half_extents`; the
pram's `carrying` and `facing`; the view's `view` and `controls`) and go private with the events'
interface.

**Proposed, not asked for, open to the player:** the names `has_parked()`, `is_carrying()`,
`camera_view()` and `screen_cover()` (a method cannot share a public field's name);
`use_carrying_rig()` taking no argument, since nothing turns it off.
