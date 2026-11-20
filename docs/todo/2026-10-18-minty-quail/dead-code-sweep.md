# Code nothing reaches, and code for features the game no longer has, is deleted

**The ask.** "remove dead code or code needed for features that don't exist anymore. it adds to the
cost of maintaining the code base and confuses you. if we want a feature back we can just implement
it fresh which also guarantees that it adheres to the new design principles" (inbox #1180 in gray-dolphin).

**Read as:** code nothing reaches, and code that only serves a feature the game no longer has, is
deleted rather than kept; a feature wanted back is built fresh under the current design. The rule
is designing-classes'. This item is the sweep, across `src/` and `tools/`, one module per pull
request.

*Proposed, not asked for:* the method. Start from `tools/check_test_only_members.py`'s no-reader group
(members nothing under `src/` reads) and the members only their own file uses, then the catalogue
rows and the branches no catalogue row reaches. A name in a comment is not a use: the survey is
run with comments stripped, since a first survey that counted them missed four members
(minty-quail-misty-ferret). Each deletion says in its pull request what reached
the code last, or that nothing ever did.

**Where the rest is:** the survey (`check_test_only_members.py`, a scan for members named nowhere in
`src/`, `tests/`, `tools/` or `scenes/`, and the check's receiver typing for a public member no
file reaches whose name another class shares) finds these, in the events; each is read before
it goes, and a member only tests reach stays where its test is the only check of behaviour the game
uses.

- `src/events/`, for the events' interface rows that rewrite its files (`event-interface.md`):
  `EventDef.effect()`, which nothing calls (4b); `EventHold.stop()`, a hold ended by
  hand "for a rig", which no rig calls (4b, with the hold's part).
- `src/resistance/`: nothing.

The pass after these runs the survey again.
