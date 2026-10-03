**The scene-recipe entries say only what the player asked**
([#456's review](https://github.com/JosuaKrause/nappy/pull/456#pullrequestreview-5400224728), the
filing of saved scene recipes for exact tests and trailer shots). Open PR #457 builds these
entries and edits them; whichever PR next edits them applies these, so two branches do not rewrite
the same lines.

- `docs/todo/2026-10-03-calm-stork/trailer-recipes.md`: "alternate parents with a randomized
  initial choice" reads the player's "randomly alternate" as strict alternation from a random
  start; PLAYTEST-139 statement 8 says "chosen at random but fixed". Quote statement 8, or mark the
  reading as the filer's.
- calm-stork's README and `trailer-recipes.md` need a still of her running from guards, but the
  M204 record says `tools/shot.sh --screenshot` hangs on `--start-escape` with `--walk` or `--after`
  ("not investigated") and nobody owns that hang. calm-stork takes it over (marked proposed) or
  names the capture path it uses, and M204's README points at calm-stork.
- `docs/todo/2026-10-03-velvet-hare/free-play-and-extent.md`: "without an invisible wall,
  teleport or reset" is not the player's; they said only that the scene may be bounded with default
  texture beyond it. Mark it "Proposed, not asked for:" and name `City._spawn_boundary()`, which
  builds walls just outside the map.
- `docs/todo/2026-10-02-round-ferret/examples-and-verification.md`: "Proposed coverage:" becomes
  "Proposed, not asked for:"; the calm-stork and round-ferret READMEs drop their status lines
  ("following the review's requested split"); and "the existing per-shot trim/start control" is
  named: the `in` field in `tools/trailer/shots.json`.
- mossy-swan's framing says the player "introduces ... a planned extent", but the quote refers to an
  extent already discussed that the file never records, and gentle-marten files the player's
  2026-10-03 answers inside the quoted review without the questions they answered. A playtest is
  never rewritten, so a short new note records the earlier extent and the questions.
