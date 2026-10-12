# polite-gull — Two phone frame records, direct to screen and fewer pixels · 2026-10-12

On the phone, open the web build with `?debug=1&seed=<N>&framerecord=1` and walk the same day-14
route for the same time, then save the record; that is the baseline. Reload with `&direct=1` added:
if the page is black, that is the answer to the first question, and the record is skipped. Then add
`&dpr=2`, `&dpr=1.5` and `&dpr=1` in turn and look: the world's pixel art should stay sharp while text
softens, and the readout's `window` and `drawn` lines say what was drawn. Save one more record at the
lowest value that still looks right. Does the page draw with `&direct=1`? Which `dpr` looks
acceptable, and does its record's `render` fall against the baseline? The switches are recorded in
[M159-11](../decisions/2026-09-19-M159-11.md).
