# calm-walrus: where the escape ends, stills of the walk-in

**Claim.** The escape's last section is won when her centre is on the spine's last row, and the
game then walks her on by herself into the tunnel's opening or across the bridge deck before the
ending screen comes. Each way out has stills of seed 4242: on the street before the last row
(still walking; the old rule's 48px circle around the last tile's centre has just been entered), the
walk-in (the HUD reads `phase over`; the bridge three, the tunnel five frames across the edge), and the
ending screen over where she stopped (the bridge: tile 115, 200, a deck's length past the edge; the
tunnel: past the edge, inside the opening).

**Limits.** One seed, a throwaway start position and timed shots, not a recorded walk: `phase over`
and her tile in each HUD readout place a frame, and the shots' times are this machine's. The first
still of each way out is where the old rule's circle is first entered, from the geometry, not a frame
of the old build. The bridge's four stills and the tunnel's street-before and ending stills were taken
on the branch's previous head, before the tunnel's walk was slowed; where the walk ends is unchanged.
A burst cannot show the walk-in (the tree is paused while she walks and the burst stops with it), so
the tunnel's walk-in frames are written by the second throwaway patch below, one every sixth physics
tick of the walk, from the viewport.

**What the tunnel frames show.** She is darkened a step at a time by the ramp inside the opening
(`CityEdge.TUNNEL_DARK`: `RAMP_STEP_PX` 8px rects over `TUNNEL_DEPTH_TILES` tiles), which lies over the
entity layer she is drawn in, so it lands on her as on a car: her coat and legs go from full colour at
the edge through a dim red to nearly black over five frames, and she stands in the dark at the end.
The walk into the tunnel is at `Tuning.WALK_SPEED` (92px/s), so the ramp's 64px take her 0.7 s; at a
run (168px/s) they took 0.4 s, and the first review's two stills, 0.45 s apart, caught her bright and
then gone. Dated runtime evidence, not a visual reference.

**Source.** Branch feature-calm-walrus-escape-end, the commit that adds these files, plus two
throwaway patches, not committed. The first, at the end of `Main._engage_the_day()`, puts her four
tiles back from the threshold:

```
if OS.get_environment("EVIDENCE_EXIT") != "" and not _day.spec().exit_points().is_empty():
	var kind := int(OS.get_environment("EVIDENCE_EXIT"))
	var back := float(OS.get_environment("EVIDENCE_BACK_PX"))
	var at: Vector2 = _day.spec().exit_points()[kind]
	_player.global_position = at + Vector2(0.0, back if kind == CityExit.Kind.TUNNEL else -back)
```

The second, at the top of `EscapeWalkIn._physics_process()` after the null check, with
`var _ticks := 0` beside `_target`:

```
var frames_dir := OS.get_environment("EVIDENCE_FRAMES")
if frames_dir != "":
	_ticks += 1
	if _ticks % int(OS.get_environment("EVIDENCE_STRIDE")) == 0:
		get_viewport().get_texture().get_image().save_png("%s/f_%03d_y%d.png" % [frames_dir, _ticks, int(_player.global_position.y)])
```

`EVIDENCE_EXIT` is `CityExit.Kind` (0 tunnel, 1 bridge); `EVIDENCE_BACK_PX` is 130. The walk-in frames:
`EVIDENCE_FRAMES=<existing dir> EVIDENCE_STRIDE=6 EVIDENCE_EXIT=0 EVIDENCE_BACK_PX=130 RESOLUTION=1280x720
tools/shot.sh out.png 12 --start-escape city --seed 4242 --invincible --no-title --no-save --walk 3.5p6n
--layers 4 --press ui_accept 3`. The other stills use the same command without the frames variables
(the second patch is not needed), with the walk's last letter `n` for the tunnel and `s` for the
bridge, and the wait in seconds: bridge 4.95 (1), 5.4 (2), 9 (3), 16 (4); tunnel 4.6 (1), 12 (4). The
brief is answered at 3 s, she stands until 3.5 s, then walks. `--invincible` freezes her excitement
for the timing's sake, so these show nothing of the baby: the baby standing still through the walk is
held by the booted case in `tests/finale_rig.gd`, which runs without it.

**Kept.** `bridge-1-before-the-last-row.png`, `bridge-2-walk-in-begins.png`,
`bridge-3-mid-deck.png`, `bridge-4-ending-across-the-deck.png`, `tunnel-1-street-before.png`,
`tunnel-walk-in-1-feet-at-the-edge.png` to `tunnel-walk-in-5-in-the-opening.png` (the walk, in
order), `tunnel-4-ending-inside.png`.
