priority: later

# misty-trout — The south-facing stroller hides its handle · filed 2026-10-03

> "the handle is shown in the south facing stroller when it should be hidden. solution is probably
> to just remove the black bar in the scaled up version before scaling down"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 9 (note #442). **The south-facing stroller hides its handle.** South is `pram_front`
(the M109 travel-direction record: "S/SE/SW show the outside of the hood"); its PNG
`art/illustrated/svg-transfer/rig/pram_front.png` shows a dark bar across the hood's base. The player's
fix is a suggestion ("probably"): remove the bar in the large image before it is scaled down.

**Proposed, not asked for:** fix the source `art/rig/pram_front.svg` too, since the illustrated-png
skill keeps the SVG first, and check the southern diagonals for the same bar.
