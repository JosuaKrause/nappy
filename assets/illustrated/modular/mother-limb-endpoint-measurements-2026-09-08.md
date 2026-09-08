# Mother and pram attachment measurements

The runtime registration in `mother-parts-v3.manifest.json` uses source-visible crop-local
landmarks. An alpha scan with threshold 24/255 confirms painted pixels within four source pixels of
every torso, arm, leg and shoe endpoint. The same check covers both registered pram grip contacts
in every direction.

The 1280×1536 mother source has these independently packed bands:

| Drawing | Source band | Alpha-visible extent |
|---|---:|---:|
| head | 0–195 | about 44–190 |
| torso | 195–430 | about 205–413 |
| arms | 430–600 | about 440–582 |
| left upper leg | 600–790 | about 603–787 |
| left lower leg | 790–915 | about 795–907 |
| right upper leg | 915–1135 | about 920–1117 |
| right lower leg | 1135–1260 | about 1131–1251 |
| registered shoes | 1260–1355 | about 1273–1332 |

The common skeleton places ground at 0, hips at -20px, neck at -36.2px and shoulders near -33.2px.
The source-to-world transverse scale is 0.0707692308 world pixels per source pixel. Torso
neck-to-hem and head neck pivots meet that skeleton directly; the result retains the legacy
46px painted body stature without applying one scale to an invented row grid.

Arm landmarks run from the painted coat seam to the center of the painted hand. N, S and SW use
the two independent arm components present in their source columns. NE, E, SE, NW and W contain
one visible profile arm; `source_reuse` records that same-facing reuse for the near and far
shoulder-to-hand transforms. Each hand endpoint maps to its corresponding transformed brown pram
grip contact.

The shoe axis starts at the painted ankle opening and ends at the painted sole. The gait solves
knees against the raised ankle, lower legs end at that ankle, and shoes continue from ankle to
sole. This keeps a planted sole on ground and lifts the full shoe during a swing.

The approved 1448×1086 pram source uses chassis 0–350, seat 350–600, canopy 600–800 and baby
800–1086 as inspection bands. Tight per-direction crops follow alpha-visible art. Chassis scales
come from each drawing's painted top-to-wheel-baseline span, while seat, canopy and baby pivots map
to shared assembly contacts.

The torso drawing contains sleeves outside the reusable coat core. Per-direction texture polygons
retain the central painted coat and exclude those outer sleeves. Pixels hidden inside the original
sleeve-to-coat overlap are not separately available in the source.
