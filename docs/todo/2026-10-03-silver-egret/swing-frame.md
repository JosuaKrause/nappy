**Whether day 12's touch spot at the swing frame gets a mark of its own is the player's to
answer**, since the swing frame's shadow no longer shows the spot. The swing frame casts one oval
under each A-frame (the record silver-egret-sunny-magpie), and day 12's touch spot is kept at its
size and place, the ellipse at the frame's base, 28 by 17px (`Prop.swing_frame_base()`), both ovals
inside it. The orchestrator's pick on the board (swing-frame-shadow) also drew the chalk task's usual
mark there, and that part is not built: a red-arrow task's destination draws no chalk mark (the
record snowy-kestrel; azure-koala 6: "red arrow tasks show a chalk mark at their destination", which
the player called wrong), and day 12's swing is one of the destinations that record took the mark
off.

**The question for the player**, through the orchestrator on the board: does day 12's spot get the
chalk mark back, overturning snowy-kestrel for this one destination, or does it stay as built, shown
by the two ovals inside it and the red arrow ending on the frame's base? A yes is a change to
`ContactPoint.draws_a_mark()` (true for the swing's contact too) with `docs/GRAPHICS.md` and
`tests/test_destination_drawing.gd`, which holds that a destination draws nothing, following; a no
deletes this item and, with it, the entry. The other answer on the board, changing the touch zone
with the shadow, replaces the spot itself.
