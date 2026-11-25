# calm-walrus: where the escape ends, stills of the walk-in

**Claim.** The escape's last section is won when her centre is on the spine's last row, and the
game then walks her on by herself into the tunnel's opening or across the bridge deck before the
ending screen comes. Each way out has four stills of seed 4242: on the street before the last row
(still walking; the old rule's 48px circle around the last tile's centre has just been entered), the
walk-in begun (the HUD reads `phase over`), the walk-in further along, and the ending screen over
where she stopped (the bridge: tile 115, 200, a deck's length past the edge; the tunnel: past the
edge, inside the opening).

**Limits.** One seed, a throwaway start position (below) and timed shots, not a recorded walk:
`phase over` and her tile in each HUD readout place a frame, and the shots' times are this machine's.
The first still of each way out is where the old rule's circle is first entered, from the geometry,
not a frame of the old build. In the tunnel stills she goes behind the portal's face once her feet
pass the map's edge, as a car does (`CityEdge`). Dated runtime evidence, not a visual reference. A
burst cannot show the walk-in: the tree is paused while she walks and the burst stops with it.

**Source.** Branch feature-calm-walrus-escape-end, the commit that adds these files, plus this
throwaway patch at the end of `DayController.start()`, not committed:

```
if OS.get_environment("EVIDENCE_EXIT") != "" and _player and not _spec.exit_points().is_empty():
	var kind := int(OS.get_environment("EVIDENCE_EXIT"))
	var back := float(OS.get_environment("EVIDENCE_BACK_PX"))
	var at: Vector2 = _spec.exit_points()[kind]
	_player.global_position = at + Vector2(0.0, back if kind == CityExit.Kind.TUNNEL else -back)
```

`EVIDENCE_EXIT` is `CityExit.Kind` (0 tunnel, 1 bridge); `EVIDENCE_BACK_PX` is 130, four tiles back
from the threshold. Command, from the repository root, with `<S>` the wait in seconds and `<D>`
`n` for the tunnel, `s` for the bridge:

`EVIDENCE_EXIT=<0|1> EVIDENCE_BACK_PX=130 RESOLUTION=1280x720 tools/shot.sh out.png <S> --start-escape city --seed 4242 --invincible --no-title --no-save --walk 3.5p6<D> --layers 4 --press ui_accept 3`

The brief is answered at 3 s, she stands until 3.5 s, then walks. Waits: bridge 4.95 (1), 5.4 (2),
9 (3), 16 (4); tunnel 4.6 (1), 4.95 (2), 5.4 (3), 12 (4).

**Kept.** `bridge-1-before-the-last-row.png`, `bridge-2-walk-in-begins.png`,
`bridge-3-mid-deck.png`, `bridge-4-ending-across-the-deck.png`, `tunnel-1-street-before.png`,
`tunnel-2-walk-in-begins.png`, `tunnel-3-in-the-opening.png`, `tunnel-4-ending-inside.png`.
