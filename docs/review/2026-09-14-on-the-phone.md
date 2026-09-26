**On the phone, on the release that carries the tick, load the four settings on seed 123
again** — `?debug=1&seed=123`, then `&skip=crowd`, `&skip=motion`, `&skip=motion,crowd` —
within the first ten seconds of the day, and read `fps` against playtest 74's table
(`DECISIONS.md`, M140, the phone reading). The physics tick now runs half as often; the
`physics` line is per tick and the `process` line is the worst frame of the last second, so
`fps` is the number that says whether the frame moved. **Does it?** Same record, M141.
