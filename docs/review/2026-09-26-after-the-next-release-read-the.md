**After the next release, read the counter back** (`tools/goatcounter.sh --check`, then
`tools/goatcounter.sh`, in a session that carries `GOATCOUNTER_TOKEN`). `--check` should say the
key reads statistics on `nappy.goatcounter.com`, and the funnel should start showing
`instant-*`, `noise-*`, `mark-*`, `controls-keys`, `poster-pursuit` and the day's events, each
counted every time it happens. Check on `josuakrause.goatcounter.com` that the page visit still
arrives. **Does each loss now name its cause, do repeated attempts at a day show as repeated counts,
and do the counts answer "are the special/unique things actually getting encountered"?** Records are
`DECISIONS.md`, M208, M209 and M225.
