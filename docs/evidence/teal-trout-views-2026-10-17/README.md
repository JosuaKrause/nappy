# teal-trout — every view of the chargers' rest and alert poses, review sheet

The poses asked for in [teal-trout](../../todo/2026-10-11-teal-trout/README.md) (every charger is
neutral, then warns, then charges), now in all five views the game's view maps use (`front`,
`front_diagonal`, `side`, `back_diagonal`, `back`), laid side by side before anything is wired
into the game. The front and side views are the ones the player approved on the first sheet
([teal-trout-poses-2026-10-11](../teal-trout-poses-2026-10-11/README.md)); the back and both
diagonals are new here, and so is a second robber side alert.

Each sheet has two blocks: on top at **game scale** (1x, the SVG's own pixel size, which is the
size the atlas bake rasterises it at before the camera draws it twice as large), below
**enlarged six times**. The rows, top to bottom, are front, front diagonal, side, back diagonal and
back; the robber's sheets have one more row, his **side v2**, under his side row. The columns, left
to right, are **neutral · alert · charge**:

| Sheet | Neutral | Alert | Charge |
|---|---|---|---|
| `dog-views-v1.png` | `art/events/charging_dog_resting*.svg`, sitting | `art/events/charging_dog_alert*.svg`, stiff on four legs | `charging_dog*.svg`, the gallop's frame a |
| `robber-views-v1.png`, `robber-views-alley-v1.png` | `robber_waiting_*.svg`, hands in his coat | `robber_alert_*.svg`, both hands out | `robber_lunging_*.svg`, frame a |
| `guard-views-v1.png` | `art/checkpoints/guard_standing_*.svg`, at his post | `guard_alert_*.svg`, a hand raised | `guard_lunging_*.svg` |

The sheets stand on the sidewalk's flat colour (`Palette.SIDEWALK`, `#8b8478`), and the robber's
second sheet on the alley floor's (`Palette.ALLEY_FLOOR`, `#3c3a42`), the ground he waits on. A
flat colour is what a map draws when it cannot draw the ground's art, so the alley sheet tests his
contrast against the alley's tone, not against its tiles.

**The robber's side alert has two versions.** Row 3 is v1, `art/events/robber_alert_side.svg`,
the one approved on the first sheet; row 4 is v2,
[`robber_alert_side-v2.svg`](robber_alert_side-v2.svg), kept in this folder because nothing in
the game uses it. v1 keeps his waiting silhouette and adds one small hand at the hip; v2 changes the
outline, with a wide stance, the near arm held off the body back and low with its hand behind his
hip, and the far hand showing past his front. The robber's back and diagonal alerts follow v2's
idea, both hands out and held low on either side of him with the stance wider, which is also
what his front alert already does.

The diagonals are drawn facing east, like the rest of each family, and the game mirrors them for
west. Every picture is grounded at its bottom centre. The dog's poses use the charging dog's own
canvases (30x28 front and back, 38x28 diagonals, 40x22 side). The robber's and the guard's alerts
that need room for an arm are 26 wide where their standing pictures are 22, widened 2px on each
side with the body moved 2px with it, so the body stays over the same ground anchor at the swap.
That covers every robber alert, and the guard's side and both diagonals. The guard's front and
back alerts fit the 22-wide canvas.

## How the sheets are made

`render-sheet.gd` is the first sheet's script with one addition, an optional `ground` colour in
the spec. It loads each SVG through the engine's own parser (`Image.load_svg_from_string`) at each
scale and stands every picture on one ground line per row, centred in its column. A sheet's spec
(`dog-views-v1.json` and the others) lists its rows, its scales and its ground. To rerun, from the
repository root with any Godot 4.7 project as `--path` (a scratch one with only a `project.godot`
is enough), with absolute paths, writing to a fresh file:

```sh
godot --headless --path <scratch project> \
  --script docs/evidence/teal-trout-views-2026-10-17/render-sheet.gd -- \
  --repo "$PWD" --spec "$PWD/docs/evidence/teal-trout-views-2026-10-17/dog-views-v1.json" \
  --output <scratch dir>/dog.png
```

A delivered sheet is never overwritten; a revision is a new file with the next version number. The
delivered sheets' SHA-256:

| Sheet | SHA-256 |
|---|---|
| `dog-views-v1.png` | `89df8e645834d47e99b27fbb615f981dbbdba4ba86a2adea45725a2da2ab1f81` |
| `guard-views-v1.png` | `77e527bfada74cad9aa9b6be97f5d8143fad9512dc4b4def0a46cb6d8b159c71` |
| `robber-views-v1.png` | `e0b88ec121f586184ae894b397f02837797d8c643d0b2409c3cd6e3781be1b29` |
| `robber-views-alley-v1.png` | `6e2566d086d42a96707ca6834f7c45b2b3fcdaa8470772789947e8b4c4e084df` |
