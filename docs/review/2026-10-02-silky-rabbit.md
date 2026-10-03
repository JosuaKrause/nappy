# silky-rabbit — Nearby ground preparation during real play · 2026-10-02

Hold this stepping-specific review until the player chooses the runtime in
[breezy-walrus, ground preparation after the mobile test](../todo/2026-10-02-breezy-walrus/README.md).
It lapses if stepping is removed and atomic preparation restored; the general scenery review
under [M159, nearby scenery during walking and transitions](2026-09-19-M159.md) remains.

If stepping remains the default, retain this review. If it remains behind a
default-off debug dev flag, retain this review for the optional enabled path and
its comparison with the default atomic path. A useful comparison uses the same
route and settings in atomic and stepped builds, or both positions of the dev
flag, switched on the phone through `?debug=1` on the released page
([choose-runtime](../todo/2026-10-02-breezy-walrus/choose-runtime.md) says how the flag gets there). This is a controlled comparison that the existing mobile observation does
not supply; it does not repeat the already answered unpaired perception question.

For either retained-stepping option, use the same ordinary run as M159 in the browser and on
the phone, traversing blocks, reversing while nearby ground prepares, changing days
and changing orientation. Check missing or late ground, water and route-curb seams,
and the full game's competing-work performance. Desktop-browser perception and
that complete-game judgment remain open. The phone observation in
[snowy-ibis, mobile stepping feedback](../playtests/2026-10-02-snowy-ibis.md)
answers the mobile perceptual-stutter question for its tested build; do not ask
for that same observation again. It does not answer the remaining correctness checks.

Record device/browser, build, route and observations in one new playtest linked
from both review items. The [decision and matched comparison](../decisions/2026-10-02-silky-rabbit.md)
and [evidence](../evidence/silky-rabbit-ground-frames-2026-10-02/README.md)
describe the stepped implementation and its source/cell equality checks.
