# frosty-marmot: the escape's trucks, a lane crater, the swerve and the corner turn

Dated runtime evidence for pull request #1796 (frosty-marmot, the escape's walks meet more army
trucks than explosions heard). It records one build, seed and walk each, with the event route layer
on; it is not an approved visual reference.

**Claim.** An explosion's crater (`lane_crater`) takes one lane of a street and leaves the other;
an army truck sent down her street pulls into the other lane to pass it and back after it
(`WayOn.driven()`); and a truck sent down the crossing street at the box ahead of her turns the
corner there into her street toward her (`EventDirector._round_the_corner_toward()`). The hot-pink
line is the truck's own route (`--layers 7`, `EventRouteLines`), dot at its start.

**Limits.** `--invincible` holds the meters, so the HUD reads excitement 0 and the clock does not
move; it says nothing about what the trucks cost (the record frosty-marmot measures that). Each
picture is one moment of one seed's walk. The burst ran beside a headless game run on the same
machine, so it holds 19 frames over its three seconds rather than 36 (`swerve-burst.json` has
the frame times).

**Source.** Build dde7cc2a4 (shown in the debug readout), Godot 4.7.2, 1280x720 window. The
walk is `RouteRig`'s walk to the exit (`--route`), the walker `tests/probes/escape_winnable.gd`
measures. `tools/shot.sh` refuses `--route`, since `RouteRig` quits the process the moment she
arrives; every capture here ends long before she arrives, so the game was started directly with
the flags `shot.sh` adds:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 --disable-vsync -- \
  --screenshot <out.png> --after <seconds> --start-escape city --seed <seed> --route tunnel \
  --no-title --invincible --layers 7 [--press snapshot_burst 31.4]
```

| File | Seed, walk, time | What it shows |
|---|---|---|
| `swerve-approach-seed4216201080-31.8s.png` | 4216201080, tunnel, 31.8s | A lane crater in the near lane of the street, a truck driving east toward it, its route pulling into the far lane before the crater and back after it |
| `swerve-passing-seed4216201080-32.4s.png` | 4216201080, tunnel, 32.4s | The same truck in the far lane, level with the crater |
| `swerve-burst.mp4`, `swerve-burst.json` | 4216201080, tunnel, 31.4s to 34.4s | The swerve in motion (`tools/clip.sh` from the burst; the JSON holds the frame times) |
| `corner-turn-seed11-7.75s.png` | 11, tunnel, 7.75s | A truck sent down the crossing street at the box she was walking toward when it was sited (she has reached it by now), its route turning there into her street, toward where she was sited |

Kept: the stills and the burst that show the claim. Not kept: the burst's 19 PNG frames (the clip
holds them), a still at 7.3s of the corner turn that the 7.75s one supersedes, and the run logs.
