# The robber walks while he warns: two alert frames per view · 2026-10-17

The player, answering the second sheet (inbox #748): "robber can walk towards her", "nobody walks
-- only the robber", and of the two side alerts shown side by side on PR #750, "since he is
walking I read A and B as animation frames". So while he warns, the alley robber walks toward her
in two alternating frames, in each of the five views. Not wired into the game.

One GIF per view, each cycling its two frames forever, every frame shown for 130ms. Each frame
stands on the sidewalk's flat colour (`Palette.SIDEWALK`, `#8b8478`) in three blocks stacked top
to bottom: **game scale** (1x, the size the atlas bake rasterises the SVG at), **2x** (what the
game's camera draws on screen) and **6x**.

| View | GIF | Frame a | Frame b |
|---|---|---|---|
| front | `robber-walk-front-v1.gif` | `robber_alert_front.svg`, the planted step | `robber_alert_front_b.svg`, the passing step |
| front diagonal | `robber-walk-front_diagonal-v2.gif` | `robber_alert_front_diagonal.svg`, the planted step | `robber_alert_front_diagonal_b.svg`, the passing step |
| side | `robber-walk-side-v2.gif` | `robber_alert_side.svg` (B on PR #750), the planted step | `robber_alert_side_b.svg` (A on PR #750), the passing step |
| back diagonal | `robber-walk-back_diagonal-v2.gif` | `robber_alert_back_diagonal.svg`, the planted step | `robber_alert_back_diagonal_b.svg`, the passing step |
| back | `robber-walk-back-v1.gif` | `robber_alert_back.svg`, the planted step | `robber_alert_back_b.svg`, the passing step |

All in `art/events/`. **The planted step** is B's idea: the stance wide and both hands out of the
coat, held low and off the body on either side of him. **The passing step** is A's: the feet
drawn in under him and one hand held low in front of the coat at the hip; in the front and back
views, where a stride cannot be seen fore and aft, one foot is also lifted off the ground. Each
pair shares its canvas (26x44), its bottom-centre ground anchor (13,44) and its torso and hood, so
only the legs and arms change at the swap. Frame a is the planted step in every view, because the
game draws frame a whenever he covers no ground, so it is the picture he holds while he stands.
`robber_alert_side.svg` is the second sheet's `robber_alert_side-v2.svg` and
`robber_alert_side_b.svg` the side alert approved on PR #726, both drawings unchanged.

**Two versions.** The table names the current GIF of each view, and every GIF in the folder is a
delivered file, never overwritten:

| GIF | SHA-256 | What it shows |
|---|---|---|
| `robber-walk-front-v1.gif` | `7eae645904fc9735f191f2af1486c7d6080602b4aa0ba8f06b6cf35ae1ff7126` | current; `walk-v2.json` renders it byte for byte, so it has no v2 |
| `robber-walk-back-v1.gif` | `fa305697a09ceca5866240ff14114514f10601a4785add303fbb847b4b3f643a` | current; the same holds |
| `robber-walk-front_diagonal-v1.gif` | `4b2c1bf03d9220860a5d827f59d0d6c03105ba296698d479854d7c65d7437814` | the passing step's near arm starts mid-chest, so the shoulder slides 3px at the swap |
| `robber-walk-front_diagonal-v2.gif` | `ce49acdb37735e2eb96ad25a7b53b227213d1c476b8f99d5820b75f2f3fbb1f4` | current: the arm hangs from frame a's shoulder and bends at the elbow |
| `robber-walk-side-v1.gif` | `92fa7b29cb7efa63035282554b465a58d88962e946096870c3e07937d3f7dcee` | the two side frames in the other order, the passing step first |
| `robber-walk-side-v2.gif` | `24fe0cd01ba34ac39d9037bb10fe6a9610407b9804bb39831e84b5a70426cc42` | current: the planted step first |
| `robber-walk-back_diagonal-v1.gif` | `658fee4e3646244bdc94db7af6e52309df0750f37e1bc00a22bb846ebc0b2e4e` | the passing step's forward arm drawn across his back |
| `robber-walk-back_diagonal-v2.gif` | `e01dfeb5e48f4daf6d38bac7b3742ec415e767a32c92a29162b7fde307796d7d` | current: the arm behind the torso, only its sleeve and hand past his front |

`walk-v1.json` renders the v1 files from the art at commit 008a0829, `walk-v2.json` the v2 files
from the art at commit 3534794f.

**The rate** is the robber's own stride. `EventInstance` swaps a walking family's frame every
quarter turn of its gait phase, `PI / 2 / GAIT_RATE` (17.5px) of ground (`_gait_stepping()`), the
rate his lunge cycles `ROBBER_LUNGING_BY_VIEW_B` at; while he warns he closes on her at 130px/s
(the `alley_robbery` row), so a frame lasts 134ms, which a GIF's centisecond timing holds as 130ms.

## How the GIFs are made

`walk-v2.json` names each view's two frames, the scales, the frame time and the version that names
the output files. `make-walk-gifs.py`
renders each frame as a one-picture sheet with the second sheet's
[`render-sheet.gd`](../teal-trout-views-2026-10-17/render-sheet.gd) (Godot 4.7's own SVG parser,
the sidewalk ground) and joins each view's two sheets into a looping GIF with Pillow, which is
already in the repository's Python environment. From the repository root, with any Godot 4.7
project as `--project` (a scratch folder holding only a `project.godot` is enough) and a fresh
output folder:

```sh
uv run python docs/evidence/teal-trout-robber-walk-2026-10-17/make-walk-gifs.py \
  --repo "$PWD" --spec docs/evidence/teal-trout-robber-walk-2026-10-17/walk-v2.json \
  --godot "${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}" \
  --project <scratch project> --out <fresh scratch dir>
```

A delivered GIF is never overwritten; a revision is a new file with the next version number.

**What the GIFs cannot show**: the robber moving over the ground, his heading turning toward her,
the caret over him, or the alley floor he waits on; only the two pictures alternating in place.
**And they show far more walking than the game does.** The GIFs loop forever, but he notices her
within 140px and closes only to his 116px stand-off, then stands still in frame a until she moves
or his 1.8s notice ends. Unless she backs away he walks about 24px, about 0.2s and one swap, and
holds the planted step for the rest of his warning.
