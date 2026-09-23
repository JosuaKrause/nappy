# Building fronts redrawn — 2026-09-23

Before/after evidence for M186, the building fronts redrawn to one bar. "Before" is `main` with
M185's doors and storefronts; "after" is this branch. The entrance doors and storefronts are the
same pictures in both.

## Whole fronts

`fronts-{before,after}-gamescale.png` and `fronts-{before,after}-4x.png` assemble fronts the way
`src/city/building.gd` draws them — tinted wall and roof cells, windows (lifted two pixels over a
door or storefront), corners, plinth or storefronts, then door, fire escape and portico, then the
roof and its parapets — for a residential front with a door and fire escape A, a tall-sash one
with escape B, an industrial front with its steel door, a commercial one with storefronts, a
civic one with the portico, a home-block front keeping its ground-floor windows, a boarded
commercial block, a burnt residential one and a one-row sliver. Game scale is the 1x raster blown
up 2x nearest, the camera's own zoom; 4x is the SVGs rendered at scale 4. The mother beside each
is for size only. The window lighting and layouts are chosen for the sheet, not rolled by a seed.

## Families

`facade-kit-tiles.png`, `facade-kit-windows.png`, `fire-escape.png` and `civic-portico.png` show
each redrawn piece before and after, at game scale and at 4x, over the tinted wall (or roof, for
the parapets). `facade-kit-seams.png` repeats the tinted wall and roof three by three to show
there is no join.

## In the game

`in-game/{before,after}-<street>.png`, 1280×720, day 1, taken with `tools/shot.sh` on this
machine. Each proves what that street looked like on that seed in that build; the HUD and the
developer readout are on because the rig draws them.

| Still | Command (after `tools/shot.sh out.png <wait>`) |
|---|---|
| `residential` | `18 --seed 4242 --walk 3s2@160@9s3e --invincible --no-save` |
| `commercial` | `8 --seed 4267 --spawn signal --invincible --no-save` |
| `industrial` | `8 --seed 4242 --spawn power_station --invincible --no-save` (the power station, its industrial neighbors below it in the zoomed view) |
| `home` | `8 --seed 4242 --invincible --no-save` |

Each `*_zoom` still adds `--zoom 0.5` to the same command.
