**The rule is worded as the player said it.** `docs/NARRATIVE.md`'s *the contact is
whichever look-alike she reaches first* becomes *whichever look-alike she hands the note
to*, and the director's own doc comment with it. A test in `tests/test_resistance.gd`
walks a rig within reach of one look-alike, out again, and onto a second, and asserts the
step completes on the second — what the code already does and nothing pins.
