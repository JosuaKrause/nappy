# polite-gull — Phone frame records with fewer pixels · 2026-10-12

On a build released after `?dpr=` merged (the published page before it has no such parameter), open
the web build on the phone with `?debug=1&framerecord=1&seed=67&day=14`, walk the same day-14 route
for the same time, and press `save frames`; that is the baseline. Then add `&dpr=2`, `&dpr=1.5` and
`&dpr=1` in turn and look: the world's pixel art should stay sharp while text softens, and the
readout's `window` and `drawn` lines say what was drawn. Save one more record, the same way, at the
lowest value that still looks right. Which `dpr` looks acceptable, and does its record's `render`
fall against the baseline? The cap is recorded in [M159-11](../decisions/2026-09-19-M159-11.md).
