**After the next release, read the counter back** (`tools/goatcounter.sh --check`, then
`tools/goatcounter.sh`, in a session that carries `GOATCOUNTER_TOKEN`). `--check` should say the
key reads statistics, and the funnel should start showing `instant-*`, `noise-*`, `mark-*` and
the day's one-off events beside the old ones. **Does each loss now name its cause, and do the
counts answer "are the special/unique things actually getting encountered"?** Record is
`DECISIONS.md`, M208 and M209.
