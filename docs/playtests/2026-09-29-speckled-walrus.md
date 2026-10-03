# Playtest speckled-walrus — Address the classification PR review findings

2026-09-29.

PR #438, M159: Cache event-shape classification, is approved, green and out of draft. The next
prediction optimization is underway as stacked PR #439. The player asks to correct the lower
PR's review findings:

> "read the comments on 438 and address them"

> "especially the hardcoded absolute paths"

The comments at the reviewed head identify four findings: the evidence README's rerun commands
use local absolute checkout/scratch paths and omit baseline checkout creation; the runner fixes
the Godot executable to the Mac app bundle; two classification checks need their role as guards
against unrelated future writers clarified; and the new experiment-retention section lacks a
docs/evidence path trigger in the shared rule hook. The player asks to address the review, not
only the paths. These corrections belong in PR #438. Its historical command/provenance values
remain records of the original measurements; portable rerun instructions replace local working
paths in the current method. PR #439 inherits the corrected lower branch before final validation.

The findings are linked on PR #438:
[portable checkout commands](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4140361924),
[Godot executable selection](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4140362140),
[classification guard intent](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4140362430),
and [evidence rule injection](https://github.com/JosuaKrause/nappy/pull/438#discussion_r4140362821).

While those corrections are in progress, the player also requests author replies on the PR:

> "also respond to the comments with what you did"

Each finding receives a reply describing its correction and validation after the change is
pushed. The author does not resolve review threads opened by the player.
