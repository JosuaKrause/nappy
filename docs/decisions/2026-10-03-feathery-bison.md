# feathery-bison — One cyclist in about 400 is a pelican, and it is counted as one · built 2026-10-04

*([minty-hedgehog](../playtests/2026-10-03-minty-hedgehog.md), statement 8, note #437: "One in ~400
bikers should be a pelican riding a bicycle instead. Needs to be svg only", and "converted to PNG
during atlas creation but otherwise it will always stay SVG never become a converted PNG". Shown the
first drawing, the player: "Looks good, merge" (inbox #526). On 2026-10-04 (inbox #527): "when the
pelican spawns, when it's on screen, and when it's hitting the player. it must appear as its own
entry and it needs to be more granular than standard event telemetry"; "by telemetry I mean
goatcounter -- logs should be correctly identifying it from the beginning"; "the telemetry must go
out in the same release".)*

**Built (PR #522).** **The drawing.** A white pelican with black wing tips gripping the bars, orange
webbed feet on the pedals and a long yellow bill over an orange pouch, riding the cyclist's own bike,
copied path for path, so wheels, ground contact and anchor are the cyclist's: five views
(`art/events/pelican_cyclist{,_front,_back,_front_diagonal,_back_diagonal}.svg`), each with a `_b`
pedal frame. In the front view the bill is tucked down its chest; in the back view the head turns so
the bill shows in profile. It is SVG only: the atlas bake rasterizes it like any SVG, and no
illustrated PNG of it exists, the one exception to M109's conversion of the SVG catalogue to PNG,
which the **illustrated-png** skill names.

**About one cyclist in 400 is the pelican.** The roll is made once per rider, when its warning goes
up, against 1/400, from a random stream of its own (`GameState.day_rng(day, "pelican")`), so no other
choice in the run moves; the rider keeps it for its whole ride (`EventInstance.is_pelican`). Its
field, reach, speed and cost are the cyclist row's. `--pelican` draws every cyclist as the pelican
(`--force cyclist --pelican` sends them on demand).

**It is counted as itself.** GoatCounter gets four events of its own, each once per pelican, in the
`nappy-day-N-*` shape: `pelican-spawned` when it is created, `pelican-seen` on its first frame on
screen, `pelican-excited` when its field first adds to her meter, and `pelican-hit` when its reach
covers her; a day it ends is `lost-hard-fail-pelican`, or `lost-crying-pelican` when it added the
most to her meter, never `cyclist`. `VisitCounter` only listens, to four `EventBus` signals added for
it. The run log names it `pelican` from the warning's first line on — the badge's cue, the `ahead`
line, every `near` line, two new `near` lines for its first sighting and its strike, and the cause
at the end of the `lost` line — and `tools/goatcounter.sh` reads the events back.

**Proposed, not asked for, and open to overturn:** a white rather than a brown pelican, on the same
bike and colours as the cyclist; the roll at warning time, so a warning that never finds a place to
stand spends its roll; the screen-edge badge keeps the cyclist's silhouette; a scene recipe's
cyclist is never a pelican; the 1/400 constant in `EventManager` rather than `Tuning`, since nothing
a player feels depends on it; "hits her" as two events, `excited` for the field reaching her meter
and `hit` for the reach ending the day, and the four event names; the on-screen check in
`EventManager` beside the fire's own sighting rather than in the run-log observer, since the counter
on the live page runs without a run log; `to <cause>` on every crying or hard-fail `lost` line, not
only the pelican's.

**Verified.** `tests/test_pelican.gd` (the share within 10% of 1/400 over 480,000 rolls, determinism
per run and day, the look kept for the whole ride, danger and reach identical to the cyclist's, no
PNG of it, and one pelican sent the way the game sends a cyclist from warning to hit with every
signal once, the loss named `pelican` and no log line calling it `cyclist`), with
`tests/test_visit_counter.gd`, `tests/test_day_lost_to.gd` and `tools/test_goatcounter.py`, the view
and stride suites, `tools/check.sh`, `tools/lint.sh` and `tools/pycheck.sh`. The review sheets and
two windowed captures are in `docs/evidence/feathery-bison-pelican-2026-10-03/`. No live page has
sent the events yet: the counter is silent off the web.
