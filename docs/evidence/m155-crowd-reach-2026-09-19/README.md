# M155 — the crowd's reach comes in

Runs of `tests/probes/m117_decay.gd`, three seeds (4242, 90210, 1337), day 1 and day 9, from

```sh
tools/test.sh probes/m117_decay.gd
```

| file | tree |
|---|---|
| `probe-45417c96.txt` | the base this item started from: `PEDESTRIAN_OUTER_RADIUS` 55px, `CAR_INTENSITY` 5.4, before any of M155's numbers moved |
| `probe-after-the-fix.txt` | this branch, with `PEDESTRIAN_OUTER_RADIUS` at 30px and `CAR_INTENSITY` raised to 7.7 to hold the main road's own price |

The quiet-pavement leg is the number the player's complaint is about: it nets −3.95/s in the base
file and −4.20/s after, against the empty street's own −6.0/s (`Tuning.EXCITEMENT_DECAY_WALKING`).
The main-road leg is the one that must not move: 5.71/s net on day 1 and −0.13/s on day 9 in the
base file, 5.70/s and −0.12/s after — held there by the car intensity rather than by the pedestrian
radius, which is why the quiet leg does not reach the full recovery its own radius alone would have
bought it. Both files also carry the `docs/EVENTS.md` cost table the same probe prints, unchanged
between them, since neither number it depends on moved.
