# Two phone frame records, seed 67, days 9 and 14, v0.27.1

The player's two frame records from playtest
[velvet-marten](../../playtests/2026-10-11-velvet-marten.md), kept unchanged under the names the page
gave them. They are evidence for [M159](../../todo/2026-09-19-M159/README.md), a slow frame names the
frame that was slow, and for [bouncy-swan](../../todo/2026-10-11-bouncy-swan/README.md), the phone's
lag spikes are found and fixed. What each column means is in [TELEMETRY.md](../../TELEMETRY.md),
"Per-system frame records".

## Source

| file | day | SHA-256 | bytes |
|---|---:|---|---:|
| `nappy-frames-seed67-2026-10-11T17-30-58.json` | 9 | `4680d80d95b92fc4824a0fa191d1796a1855d58ddaf474d8f12c0f8d485f750e` | 1,573,460 |
| `nappy-frames-seed67-2026-10-11T17-40-04.json` | 14 | `2c2ab53741a1ae89c2eb4f811ed6b948df934e3c82f19860370341f67f508f37` | 1,364,230 |

- **The build**: the released v0.27.1 page (each file's `build` reads `v0.27.1 (c876e09)`), opened
  with `?debug=1&framerecord=1&seed=67&day=9` and `&day=14`, record schema 2, ground mode 2, renderer
  `gl_compatibility`.
- **The device, by its user agent**: Chrome 154 on Android. The string is Chrome's reduced one
  (`Android 10; K` is a fixed placeholder), so it names neither the phone's model nor its Android
  version.
- **What identifies anyone**: the user agent string, and nothing else.
- **Why whole and uncompressed**: a phone's frames cannot be recreated by a rerun, the bouncy-swan
  attribution rests on single frames in them, and `analyse.py` (below) reads the files as the page
  wrote them.
- **`?debug=1` is on in both**, and the readout it shows adds draw calls and drawing work of its
  own, so neither record is the cost of a page without it.

## What each holds

- **Day 9** (the first walled day): 10,628 kept frames over about 282 s of play, three attempts that
  each start at the doorstep. Its longest frame is process frame 7736, 205.9 s in, at her position
  (2419, 1903): 775 ms, 748 ms of it `events`. That is the lag spike the player felt ("the last
  attempt had a big lag spike").
- **Day 14** (the densest): 8,922 kept frames over about 312 s of play, no frame longer than about
  110 ms. The player (#703 in velvet-marten): "No super lag spikes but a lot of stutter".

`docs/evidence/m159-phone-frame-record-2026-10-04/analyse.py` prints the per-bucket tables for a
record passed as its argument. It stops at its section 6 on a file without day 1, since that
section compares day 1's first 40 seconds; the sections before it are printed.
