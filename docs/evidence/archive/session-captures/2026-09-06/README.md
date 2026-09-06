# Session captures — 2026-09-06

These are bounded runtime screenshots captured during this session. They document the current
live-renderer state and are evidence, not visual-style guidance. The approved design references
remain the explicitly named reference images in `docs/evidence/`.

- `user-live-run-004s.png` is the screenshot supplied from the user's local run.
- `codex-live-run-004s.png` is a four-second capture from the same seed/route style.

## Capture workflow

1. Run a bounded capture from a display-capable session, for example:

   ```sh
   tools/shot.sh /private/tmp/nappy-shot.png 4 --seed 4242 --spawn arterial --walk 2s3e
   ```

2. Inspect the PNG before preserving it. A screenshot that cannot be opened or that only shows a
   standing player is not useful evidence.
3. Copy the reviewed PNG into a dated folder under `docs/evidence/archive/session-captures/` and
   name it for its source and scenario, such as `user-live-run-004s.png` or
   `codex-live-run-004s.png`.
4. Add a short provenance line to that folder's README, then commit the image and note together.

Agents may perform this workflow when their environment has a usable display. If capture aborts or
the environment is headless, record the limitation instead of fabricating a screenshot. Archived
captures remain historical evidence and never become visual-style or implementation guidance.
