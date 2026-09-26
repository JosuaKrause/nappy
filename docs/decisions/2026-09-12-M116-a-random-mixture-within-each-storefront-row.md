## M116 — A random mixture within each storefront row, 2026-09-12

[PLAYTEST-61](../playtests/PLAYTEST-61.md) first reports that the wider fronts lost their variety
and look empty, then accepts the four source variants: "those are fine for now". The remaining
request is "a single house front should sample randomly from the variants", because "the
example picture shows only one variant applied four times". The larger doors and all twelve
SVG sources remain unchanged.

The picker independently rolled each store, which allowed the pictured facade to select the
same type four times. Each building now shuffles the four variants, uses each once, then
reshuffles when a longer facade needs another group. An immediate repeat at the group boundary
is swapped away. **Chosen where the request was silent:** sampling without replacement inside
each group, rather than independent draws that can produce another identical row. The seed
still comes from the building's variant and position, so rebuilding or advancing the day does
not change its store identities. Awnings and shutter severity remain seeded per storefront.

**Merge review:** incoming main `05c733b2317bb3708a0e7220c25d2aee29805efe` and the storefront
tip `90e20055effd24a6ae99263d9c54567449017ba7` share base
`b9d3805e68e28f8a11749ea2d5cea684359ecf43`. Both inserted records at the top of `DECISIONS.md`;
both records are retained. Main's checkpoint reach, shared release latch, walker hold and
interior-door changes remain intact, including their tests. `CITY.md` combines its walker-door
documentation with the storefront contract. The reviewed size question leaves `REVIEW.md`.
The storefront playtest is renumbered from 60 to 61 to avoid the separate apartment-graphics
record numbered 60 on the concurrent documentation branch; its original words, date and
evidence remain intact. Milestone identities do not collide.

A subsequent clean merge takes main `105ef597927137cd475f950a2b9e4fc78be878f1`, which adds that
apartment Playtest 60 and its separate queue/review updates. Both playtests and their references
remain distinct; this documentation-only update changes no gameplay or storefront source.

PR 129's review also requested a named evidence parent and explicit texture-selection checks.
The complete original run moved under `evidence/playtest-61-2026-09-12/`, with all six files
byte-identical and its document links updated. The texture selector reads eligibility from the
generated variant list, avoiding a duplicate commercial/height predicate. Focused checks cover
one variant per complete column pair, a skipped partner column, an ordinary odd end column and
an ordinary base on a shallow facade. Import/boot and the focused `city_decay` suite pass after
these review fixes.

Verification: import/boot, doc lint and focused `city_decay`, `checkpoints` and `interior`
suites pass on the merged tree. The storefront regression samples different building seeds,
checks complete groups and neighbors, and preserves the order across rebuilds and state changes.
The [updated gameplay still](../evidence/archive/session-captures/2026-09-12/m116-storefront-mix-seed255862635-day1.png)
shows the same facade using pharmacy, café, grocer and sign-front variants from left to right.
Capture: seed 255862635, day 1, 1280×720, four seconds, `--svg --invincible --no-title`; a
temporary default-spawn override placed the rig at tile 70,57 and was removed afterward.
