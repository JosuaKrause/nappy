# Building fronts redrawn — 2026-09-23

Before/after evidence for M186, the building fronts redrawn to one bar. "Before" is `main` with
M185's doors and storefronts; "after" is this branch. The entrance doors and storefronts are the
same pictures in both.

## Whole fronts

`fronts-before-{gamescale,4x}.png` assemble fronts from `main`'s pictures the way
`src/city/building.gd` draws them — tinted wall and roof cells, windows (lifted two pixels over a
door or storefront), corners, plinth or storefronts, then door, fire escape and portico, then the
roof and its parapets — with a scratch compositor, for a residential front with a door and fire
escape A, a tall-sash one with escape B, an industrial front with its steel door, a commercial
one with storefronts, a civic one with the portico, a home-block front keeping its ground-floor
windows, a boarded commercial block, a burnt residential one and a one-row sliver. Game scale is
the 1x raster blown up 2x nearest, the camera's own zoom; 4x is the SVGs rendered at scale 4. The
mother beside each is for size only, and the window lighting and layouts were chosen for the
sheet.

`fronts-after-{gamescale,4x}.png` are drawn by the game's own `Building` node instead, from the
baked atlas, by `render-fronts.tscn` (below) with `--set fronts`: two residential fronts with
escapes a and b, a two-story residential front, an industrial, a commercial and a civic front,
her own building, a boarded commercial block and a burnt residential one with an escape. Every
roll — windows lit, window style, storefronts, the door's column, the escape — is the one
`Building` makes for the lot the script placed it on; only the escape a front must carry was
asked for, by trying lots until the roll gave it. `--zoom 2` is the camera's own zoom, `--zoom 4`
enlarged.

## The fire escape

`fire-escape-stack-{gamescale,4x}.png` are drawn by `Building` the same way, `--set fire-escape`:
a five-story front with escape a and one with escape b, a four-story and two three-story fronts,
and a two-story front whose own roll gave it an escape that it does not carry, since a front of
two floors carries none. Each escape has a balcony on every floor line from the top floor's down
to the first floor's, the flight of each hanging down to the next, and the platform alone on the
first floor's, so the ground floor under it holds only the brackets.

`fire-escape.png` shows `main`'s two fire-escape pictures and this branch's four —
`fire_escape_{a,b}` and `fire_escape_platform_{a,b}` — at game scale and at 4x over the tinted
wall, rendered through Godot's SVG parser one by one.

| Picture | Command, in the worktree after `tools/check.sh` |
|---|---|
| `fire-escape-stack-gamescale.png` | `godot --path . res://docs/evidence/building-fronts-redrawn-2026-09-23/render-fronts.tscn -- --output fire-escape-stack-gamescale.png --set fire-escape --zoom 2 --no-save` |
| `fire-escape-stack-4x.png` | the same with `--zoom 4` |
| `fronts-after-gamescale.png` | the same with `--set fronts --zoom 2` |
| `fronts-after-4x.png` | the same with `--set fronts --zoom 4` |

The scene needs a window (a drawn frame is what it saves) and runs as a scene rather than with
`--script`, because `Building` calls into the `Tuning` autoload.

## Families

`facade-kit-tiles.png`, `facade-kit-windows.png` and `civic-portico.png` show each redrawn piece
before and after, at game scale and at 4x, over the tinted wall (or roof, for the parapets).
`facade-kit-seams.png` repeats the tinted wall and roof three by three to show there is no join.

## In the game

`in-game/{before,after}-<street>.png`, 1280×720, day 1, taken with `tools/shot.sh` on this
machine. Each proves what that street looked like on that seed in that build; the HUD and the
developer readout are on because the rig draws them.
The `after` stills are of the tree in the commit that adds them, so they carry the stacked fire
escape and `main`'s plain wall behind her front door.

| Still | Command (after `tools/shot.sh out.png <wait>`) |
|---|---|
| `residential` | `18 --seed 4242 --walk 3s2@160@9s3e --invincible --no-save` |
| `commercial` | `8 --seed 4267 --spawn signal --invincible --no-save` |
| `industrial` | `8 --seed 4242 --spawn power_station --invincible --no-save` (the power station, its industrial neighbors below it in the zoomed view) |
| `home` | `8 --seed 4242 --invincible --no-save` |

Each `*_zoom` still adds `--zoom 0.5` to the same command.
