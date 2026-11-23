# The prediction suite's source-movement check holds the position term and the axis term

**What is wrong.** In `tests/test_prediction_reuse.gd` the check for a source that moves cannot fail on the
position term of the prediction, and no check holds the axis term alone (pull request 1663's review).

**What a test holds.** Two cases, each moving one term only: a source that changes position with its axis fixed
changes the prediction, and one that turns its axis in place changes it; a source that does neither does not, so
its cache is reused.

**Shown fixed.** Dropping the position term from the prediction's key fails the first case and leaves the second
passing; dropping the axis term does the reverse.
