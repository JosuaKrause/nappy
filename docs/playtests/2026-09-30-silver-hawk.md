# Playtest silver-hawk — Review corrections for event classification and prediction reuse

2026-09-30.

The assistant had addressed four original comments on #438, event-shape classification caching,
and completed #439, identical danger-prediction sample reuse, stacked on it. The player merged
#438. A subsequent review of #438 raised runner checkout/output validation and a misleading
hook-test label. A review of #439 raised a completed-work paragraph in the queue, missing clean
source provenance and audit safeguards, two method-shadowing locals, and a vacuous removal check.
The player directs all corrections into the still-open #439 and requests replies on #438 that
link to the fixing commit in #439:

> 438 has comments after the merge -- address them in 439 and respond in 438 linking to 439's commit
> address all remaining comments from 438 and all comments from 439

The two post-merge #438 findings are
[runner validation](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4141072110) and
[the hook-test label](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4141072558).
The four #439 findings are
[queue history](https://github.com/JosuaKrause/nappy/pull/439#discussion_r4141086306),
[shadowing locals](https://github.com/JosuaKrause/nappy/pull/439#discussion_r4141086776),
[source provenance and safe audit reruns](https://github.com/JosuaKrause/nappy/pull/439#discussion_r4141087477),
and [the removal assertion](https://github.com/JosuaKrause/nappy/pull/439#discussion_r4141087951).
The earlier four #438 threads each contain a review reply saying its original concern is
satisfied. The author replies to the six remaining findings; only a thread's opener resolves it.

The assistant proposes a new controlled before/after collection using clean checkouts and
recorded source hashes to close the historical provenance gap; this cannot retroactively prove
the sources used for the original captures. The earlier instruction to leave #439 unmerged
remains in force.
