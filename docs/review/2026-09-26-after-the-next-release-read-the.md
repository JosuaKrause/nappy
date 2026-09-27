**After the next release, read the counter back** (`tools/goatcounter.sh --check`, then
`tools/goatcounter.sh`, in a session that carries `GOATCOUNTER_TOKEN`). `--check` should say the
key reads statistics on `nappy.goatcounter.com`, and the funnel should start showing
`lost-crying-*`, `lost-hard-fail-*`, `mark-*`, `controls-keys`, `poster-pursuit` and the day's
events, each counted every time it happens, with each day's own losses grouped under one "Lost"
heading and a subtotal per kind. The page visit arrives on the same site, listed as
`/nappy.josuakrause.com` (`tools/goatcounter.sh --raw` shows it), once per visitor, since only the
visit keeps sessions. **Does each loss now name its cause in one event rather than two, do repeated
attempts at a day show as repeated counts, and do the counts answer "are the special/unique things
actually getting encountered"?** Records are `DECISIONS.md`, M208, M209 and M225 (both records), and
the record for folding the cause into the loss's own name.
