# calm-pelican — The trailer's reuse modes refuse a changed cut · 2026-10-10

From the re-review of PR #580 (the trailer reimagined, its camera starting at the player):
`--selected-reuse` and `--selected-remix` cut the kept footage at the current shot list's times but
checked only the file's hash, so changing a shot's length (the choice shot from 7s to 6s) built a
wrong trailer with no error — the dog shot lost its last second and the tail started inside the old
title card — while the README said the modes refuse any mismatch.

**Built in PR #645.** `tools/trailer/final-score.json` records the timeline each kept base was cut
with (`source_base_timeline`, `remix_base_timeline`: shot, gap and length per shot), the schema in
`tools/trailer.sh` validates both, and both reuse modes compare the matching timeline with
`shots.json` before any base or render is touched, refusing any difference. The saved-audio
signature hashes file contents with repo-relative paths, so a base made in one checkout matches in a
worktree (existing bases recapture once). `--selected-remix` reads its manifest name from
`final-score.json` rather than a hardcoded one, requires the source settings file, and fails on an
empty capture revision. The usage text, the using-tools row and the README no longer promise an
ending layer, a hash or a "4.4-second" intro. New checks in `tools/test_cli_help.sh` refuse both
modes with a changed choice length. No trailer was rendered.

**Chosen where the item was silent, open to overturn:** the timeline is stored as readable per-shot
arrays compared exactly rather than as a hash; each base has its own field; `source_base_timeline`
records the current timeline, since no kept base exists locally to read one from — if the old base
was cut with a different timeline, that field needs correcting.
