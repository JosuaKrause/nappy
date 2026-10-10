# The trailer's reuse modes refuse a changed cut

**Medium · from the re-review of PR #580 (the trailer reimagined, its camera starting at the
player).** Pick up after [mossy-hawk](../2026-10-10-mossy-hawk/README.md), which edits the same
script.
- `--selected-reuse` and `--selected-remix` (`tools/trailer.sh`) cut the kept footage at the
  current `tools/trailer/shots.json` times and check only the file's sha256; the base's own
  settings record `shots_sha256` and nothing compares it. Changing `choice.length` from 7 to 6 and
  running `--selected-remix` cuts the dog shot's last second and starts the tail inside the old
  title card with no error, though the README says the mode "refuses any retained-base mismatch".
  Record the timeline the base was cut with in `tools/trailer/final-score.json`, refuse when it
  differs, and test it.
- **Low:** `audition_source_signature()` hashes `shasum` output, which includes absolute paths, so a
  base made in the main checkout never matches in a worktree; hash contents with repo-relative
  paths. `--selected-remix` hardcodes `trailer-glass-alarm-final.json`, which `final-score.json` does
  not declare, and a missing `source_settings` file lets a `jq` failure escape `set -e` and record
  `capture_revision: ""`; declare it and fail when either is missing.
- **Low:** `playback.settled_camera` accepts any value (`"false"` is truthy) in
  `src/dev/scene_recipe_runtime.gd`; require a bool as `camera.fixed` does, with a schema test.
- **Low, wording:** `tools/trailer.sh`'s usage and its row in the using-tools skill say `--selected`
  builds an "ending" layer, though `ending_events` is empty; a comment in the cutting functions says
  "two intervals" where the code replaces three and quotes a commit hash; the README quotes
  "4.4-second". Reword without the layer, the hash or the number.
