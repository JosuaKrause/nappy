# Playtest 137 — A CI job does not download the evidence

2026-09-25. Said in conversation, watching `main`'s CI run after the v0.18.0 release.

## What the player said

> "one shard took significantly longer than the rest -- maybe we need to balance that again"

## What was found

The slow shard was shard 4 at 853s, against 201–357s for the others. Its tests took about three
minutes; 667s of the rest was `actions/checkout`'s shallow `git fetch`. Every CI job checks out the
whole tree at `HEAD`, about 949 MB in 7887 files, of which about 910 MB is `docs/evidence/`.
Across the last six `ci` runs the slowest shard's checkout took 670s, 412s, 37s, 35s, 211s and
176s, against about 35–40s when the network is quick. Rebalancing the plan would not move it.
The planned floor is a separate matter: `test_events.gd` alone is about 279s on CI, and M125,
the test suite is slow again, splits it.

## The statements

1. **A CI job fetches only what it runs**, so no shard waits minutes on downloading pictures
   nothing in it reads. Offered by the orchestrator in answer to the player's question.
