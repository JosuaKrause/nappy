# minty-quail — The closure pieces are told what they are and draw through the scenery drawer (C4) · 2026-11-24

**The ask.** The city scene's pass (the Opus design, C4): a closure piece's `piece`, `kind` and `across`,
and the park fence's `sign_offset`, were fields `City` wrote across the object, and the pieces laid their
pictures straight on their own canvas, so a suite could only read them off fields. The rule is that fields
are not API (inbox #1173 in gray-dolphin) and that a holder of pictures is tested with an injected drawer
that confirms what it draws (inbox #1018 in brisk-ferret).

## What was built

- `ClosureMarker.stand_as(piece, closure_kind, lies_across)` and `ParkFenceMarker.mount_sign(offset)` are
  the one writer each; `_piece`, `_kind`, `_across` and `_sign_offset` are private (the three were
  `@export`; no scene sets them).
- `ClosureMarker.draw_through(drawer)` hands a piece the `SceneryDrawer` every picture is laid through:
  `_stand()` lays the rect `Sprites.draw_standing()` fills for an unmirrored picture, and the park rail's
  two strips are laid with their source rects. The shadows stay drawn on the piece (no picture). A piece
  never handed one makes its own on entering the tree, as it makes its own library.
- `City.draw_scenery_through(drawer)` replaces the drawer the city makes, before `build()`; the city hands
  its one drawer to the decals, the vents' rotors and now every closure piece. It is a kept hand-in line.
- `tests/test_spent_park.gd` hands the city a recording drawer and its own library and reads each piece
  off what it laid: a post is the piece whose only picture is the post's, a park sign's ground is the foot
  of the rect its sign was laid in plus the piece's position, a panel runs across when it laid the
  across-barrier picture, and every piece that drew a park picture is a `ParkFenceMarker` standing within
  a tile of the fenced park.
- The `[ClosureMarker]` and `[ParkFenceMarker]` lines of `tools/field_reads.txt` are deleted.

## Measured

- Each rewritten check fails on its break and passes otherwise: a `ClosureMarker` built for a park post
  (two failures: the terminal panel and post, the archway's support order), the sign offset moved by a tile
  (the sign-midpoint check fails), the panel's `lies_across` swapped (the same two as the first break).
- `test_spent_park.gd` runs 54602 checks on main and 54581 on the branch: the per-piece `kind` checks
  became picture checks, with the within-a-tile check added.
- A closed street seen from its junction (seed 4242, day 1) is the same picture before and after
  (`docs/evidence/minty-quail-closure-pieces-street-2026-11-24/`).
