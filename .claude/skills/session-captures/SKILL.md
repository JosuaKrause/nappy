---
name: session-captures
description: Preserve and review dated runtime screenshots without treating them as design guidance.
---

# Session captures

Everything under `docs/evidence/archive/session-captures/` is dated runtime evidence. It records a
particular build, seed, route and presentation state; it is not an approved visual reference.

For a new capture, use a display-capable session and a bounded command such as:

```sh
tools/shot.sh /private/tmp/nappy-shot.png 4 --seed 4242 --spawn arterial --walk 2s3e
```

Inspect the PNG, then copy it into `docs/evidence/archive/session-captures/YYYY-MM-DD/` with a name
that identifies its source and scenario. Add provenance in the dated folder only when needed; put
the reusable workflow here. Agents may capture when their environment has a usable display. If
capture aborts or the environment is headless, report that limitation instead of fabricating a
frame. Update every in-repo link when moving an existing capture.
