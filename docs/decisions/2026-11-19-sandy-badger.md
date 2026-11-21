# sandy-badger — The mouse's ground is the row's answer, not a branch on its id · 2026-11-20

**What was asked.** The entry sandy-badger, a finding of the design of minty-quail's row 3a: `RuledLocationGround`
(`src/events/ruled_location_ground.gd`) branched on the mouse's row id (`_MOUSE_ID`) at two places, where a fix
lands in the shared mechanism rather than a branch keyed on one row's id (**designing-classes**, a proposal of
plush-kestrel's, not the player's words). Built by a Sonnet agent as #1595.

**What was built.** Both branches decided one thing: whether the row would rather stand beside a garbage-sack pile
(`offer()` offers it the location's tiles beside a pile first; `scale()` weighs a location beside a pile five times
over). That is now a question the row answers, `EventDef.is_drawn_to_sack_piles()`, which the mouse's row declares in
the catalogue with `draw_to_sack_piles()` (the shape of `spans_the_street()` and `span_the_street()`). The ground asks
the row and names no id; `_MOUSE_ID` goes, and its two numbers are `_PILE_ADJACENCY` and `_PILE_EXTRA_COPIES`.
Nothing a player sees changes; `test_scheduler_mouse_piles` holds the mouse's placement by the pile through the real
ground.

**Open to overturn, the builder's where the item was silent:** the five-times weight stays the ground's number, not
the row's, since it is the location's own weight, which `EventDef.weight_on()` does not count again.
