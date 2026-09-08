# Illustrated modular mother and pram

The runtime assembles the mother from `mother-parts-v3.png` and the pram from
`pram-layered-v3-draft-transparent.png`. Both files are RGBA PNGs with eight independently
authored directions. Their adjacent JSON manifests are the machine-readable source registration.

The canonical runtime order is `N, NE, E, SE, S, SW, W, NW`. The mother source columns read
`S, SE, E, NE, N, NW, W, SW`; the pram source columns already use the canonical order. Runtime
registration performs this mapping explicitly and never substitutes or mirrors a direction.

The 1280×1536 mother sheet uses independently packed horizontal bands for the head, torso, arms,
two upper legs, two lower legs and shoes. Tight arm and shoe crops isolate named painted anatomy.
Each articulated part records crop-local proximal and distal landmarks. The N, S and SW drawings
contain separate left and right arms. A profile drawing contains one visible arm, so that exact
same-facing crop is explicitly reused for the independently transformed near and far arms.

The torso source includes painted sleeves. The runtime uses each manifest's central
`core_polygons` mask for the coat body and draws the registered arm segments at their directional
sibling positions. This keeps the source coat while avoiding a duplicate outer sleeve layer.

The 1448×1086 pram source has four independently packed bands: chassis, seat, canopy and baby.
Each direction has a tight crop, a measured scale that keeps the chassis at the 30px legacy painted
height, and a shared assembly target. The chassis registers two crop-local grip contacts. The
mother's shoulder-to-hand segments terminate at those live transformed contacts.

All visible pieces share one z plane and are reordered as siblings for each direction. This keeps
the mother and pram together when their owning actor participates in scene y-sorting.

The contact sheet is review evidence only. Its two rows read `N, NE, E, SE / S, SW, W, NW`, and
its baseline is useful for judging shoe and wheel contact.
