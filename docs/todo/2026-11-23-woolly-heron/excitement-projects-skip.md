# The work `EventExcitement._projects()` skips has a test

**What is wrong.** `EventExcitement._projects()` (`src/events/event_excitement.gd`) answers whether a source
projects at all, so that the prediction in `ExcitementSource` skips its sampling for one that does not (a
finished or leaving event). No single change to it fails any suite: a leaving or finished event already
predicts 0 through its key, so the skip is an optimization nothing measures (pull request 1663's review).

**What a test holds.** For an event that is finished and for one that is leaving, the prediction takes no field
sample at all (a counted fake of the field), and for a live one it takes them.

**Shown fixed.** Making `_projects()` answer true always fails the new check, while the prediction's own answers
stay unchanged.
