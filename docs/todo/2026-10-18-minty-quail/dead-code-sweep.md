# Code nothing reaches, and code for features the game no longer has, is deleted

**The ask.** "remove dead code or code needed for features that don't exist anymore. it adds to the
cost of maintaining the code base and confuses you. if we want a feature back we can just implement
it fresh which also guarantees that it adheres to the new design principles" (inbox #1180 in gray-dolphin).

**Read as:** code nothing reaches, and code that only serves a feature the game no longer has, is
deleted rather than kept; a feature wanted back is built fresh under the current design. The rule
is designing-classes'. The first
case, the covering-set path (`EventScheduler._place_a_set_piece()`), goes in #1169. This item is the
sweep for the rest, across `src/` and `tools/`, one module per pull request.

*Proposed, not asked for:* the method. Start from `tools/check_test_only_members.py`'s no-reader group
(members nothing under `src/` reads) and the members only their own file uses, then the catalogue
rows and the branches no catalogue row reaches. Each deletion says in its pull request what reached
the code last, or that nothing ever did.
