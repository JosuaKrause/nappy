# A finished event's look shows nothing

**What is wrong.** No check in `tests/test_event_views.gd` holds that a finished event's look shows nothing
(pull request 1663's review).

**What a test holds.** A look handed a finished event draws nothing, and the same look handed the same event not
yet finished does draw.

**Shown fixed.** Making the look ignore that the event is finished fails the new check.
