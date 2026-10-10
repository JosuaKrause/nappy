# mossy-hawk — A movement script turns smoothly and ends where the abrupt one does · 2026-10-10

The player, inbox #633 comment 1 in [dotted-wombat](../playtests/2026-10-10-dotted-wombat.md): "in
general when running a movement script we should have a smooth option where west 1s north 1s has a
movement in 270 (left) then gradually going to 0 (north) in a way that the exact horizontal position
ends up being the same as with the abrupt version … they should end up in the same exact place no
matter whether smooth is on or off). for the trailer I would want smooth to be on".

**Built in PR #638.** `WalkPlan` (`src/dev/walk_plan.gd`) decides what a movement script presses on
each physics tick, abrupt or smooth, for a scene recipe's playback (`playback.smooth`, a boolean)
and for `--walk` with the new `--smooth-walk` dev flag. The walk string's syntax is unchanged and
smooth is off unless asked for. Through a turn the press blends in a straight line from the old
step's unit vector to the new one's, so her heading sweeps through every bearing between and her
speed dips to cos(Δ/2) of full in the middle (0.71 for a right angle). The window is centred where
the abrupt turn's own acceleration ramp puts it, measured by replaying the abrupt script, which
makes the end position exact on open ground: `tests/test_walk_plan.gd` drives a real `Stroller`
tick by tick and finds smooth and abrupt equal within 0.01px for `1w1n`, `1w1n1e`, an oblique turn,
a reversal, a running turn and a short lead-in; dropping the measured lag fails it by 10–36px.

**M82's unit-length rule is kept for everything a player can reach.** The blended press is shorter
than one only inside a scripted turn; no player input path changed, and the **verify** skill names
the smoothed turn as the one scripted exception.

**The trailer turns smoothly.** All nine trailer recipes set `"smooth": true`: the choice shot's
three turns (its wrong-turn reversal now slows over 0.8s), the birds' turn, the park circle's eight
legs, and the turn in the walk and city shots' lead-ins; the dog, chase, trucks and gatehouse have
no turn it can change. `tools/trailer.sh --validate` and every scene's assertions pass, nothing was
retimed, and final positions match the abrupt runs within 0.001px in the game. A pedestrian bump in
the walk shot's lead-in pushes the smooth walk north where the abrupt one went south, so she walks
that shot 7.1px further north. The selected cut was rendered again with smooth turns; stills of the
choice shot's turn are in [mossy-hawk-smooth-turn-2026-10-10](../evidence/mossy-hawk-smooth-turn-2026-10-10/),
beside the re-encode comparison.

**Chosen where the entry was silent, open to overturn:** the pressed vector is blended rather than
the heading rotated at the entry's proposed `(Δ/2)/tan(Δ/2)` speed, since the blend is exact tick by
tick and the rotation only close; the window is 0.8s, clamped to half of each neighbouring step and
to start only once the abrupt velocity has settled, and a turn with too little room stays abrupt; a
reversal slows down and walks back; smooth is on in every trailer recipe, even where it changes
nothing; a smooth `--walk` is pressed on the physics tick while the abrupt one still runs on process
frames, so on that path the two agree within one tick; the end position matches on open ground only,
since walls, stairs and crowd shoves can still move her differently.

**Open for the player:** [M204](2026-09-25-M204.md) rejected "A pause in the wrong turn" on the
player's "always keep moving". The smoothed reversal decelerates over 0.8s instead of about 0.26s.
Measured in the choice shot, neither reaches a standstill, but the smoothed one comes closer and
stays slow longer: its slowest tick is 0.39px/s against the abrupt 1.33px/s, it is below the
game's idle threshold (`IDLE_SPEED_THRESHOLD`, 12px/s) for 3 ticks (0.1s) against 1, and below
half walking speed (46px/s) for 12 ticks (0.4s) against 4. The
[review item](../review/2026-10-10-mossy-hawk.md) asks the player to judge it in the new cut.

**The re-encode under 10MB, for [frosty-egret](../todo/2026-10-10-frosty-egret/README.md).** The
smooth cut (47.9s, 30,426,821 bytes) re-encoded in two passes (`libx264 -preset slow -b:v 1400k`,
AAC 128k, `+faststart`) is 9,228,642 bytes, SSIM 0.944 and PSNR 30.7 dB on average and 17.2 dB at
its worst frame: the street shots stay readable but outlines soften, and the zoomed-out city at the
end smears its fine detail. Both files are in `build/trailer/mossy-hawk-smooth/` in the main
checkout, not committed; the evidence folder holds the turn's stills and a side-by-side of the
original and the re-encode.
