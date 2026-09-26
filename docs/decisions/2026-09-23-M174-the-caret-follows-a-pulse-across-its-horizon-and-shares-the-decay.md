## M174 — The caret follows a pulse across its horizon, and shares the decay · built 2026-09-23

*([PLAYTEST-115](../playtests/PLAYTEST-115.md): "if I keep doing what I'm doing I very likely get
that amount in net gain (so the halo will match roughly the caret if that happens)".)* The caret
projected a source's rate as it stood at the instant it was read for all of
`Tuning.EXPECTED_IMPACT_HORIZON` (five seconds), and netted the whole of her walking decay against
each source separately. Against `homeless_yeller` (a five-second pulse) and `busker` (seven) the
halo afterwards could differ from the caret by a multiple, and with two sources near her every
caret read low.

Now `EventInstance._pulse_mean_multiplier()` integrates the pulse envelope over the horizon from
the pulse's own phase, in closed form, so a pulse whose period divides the horizon projects the
same caret at every phase and a longer one depends on where in its beat she is. And
`expected_impact_at()` in `EventInstance` and `CrowdAgent` is split into a gross projection and a
net: `ExcitementHalo` sums every live source's gross once a frame and each caret takes its share
of the horizon's decay by the same arithmetic the halo shares the landed decay with
(`ExcitementHalo.net_landed()`), so the carets add up to the projected rise. A caller that never
hands the halo's total over keeps the old per-source netting. No row's cost moved;
`docs/COSTS.md` is unchanged.

`tests/test_danger.gd` checks the promise as the average of four walked passes at phases spread
over one period against the one projected caret, since a single pass past the man shouting lands
anywhere from about 3 to about 20 points by which beat meets her closest approach; and two
sources straddling her path against what they land net of one shared decay.

**Open to overturn, chosen by the agent:** every live source joins the shared decay, as every
live source joins the halo's total, rather than only the ones drawing a caret; an
`intensity_ramp` is still read at the current instant, not projected, since neither pulsed row
has one.
