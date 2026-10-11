# plush-marten — day 12's park closed by a police cordon

Evidence for the plush-marten entry (the cordon), 2026-10-11.

- `art-first-attempt.png` — a source preview of the three new pictures at scale 3, not a gameplay
  capture: `art/closures/cordon_tape_across.svg` laid edge to edge across the top,
  `art/closures/cordon_tape_along.svg` stacked down the left, `art/closures/cordon_post.svg` at
  every stretch end, and the existing policeman on foot (`art/events/policeman_lunging_side.svg`,
  `art/events/policeman_waiting_front.svg`) for scale, over a flat grass and sidewalk fill. Made by
  a scratch Godot script that loads each SVG with `Image.load_svg_from_string()` at scale 3 and
  blends them onto one image; it shows the pictures' shapes, colours and relative size only, not
  how the game draws or sorts them.

## The cordon in play

Two runs of one scene, recorded frame by frame with Godot's own movie writer (60fps, 1280x720,
`--player-view --no-focus-pause --no-save`), neither under `--invincible`, on the build at
`407d1366ee5cf05ee9131ea8a84e93cf9658da42` plus nothing else. The scene is `scene-recipes/task-12-swing.json` (run seed 11, city
seed 1917501, day 12) with its extent made the whole city (`{"scope":"full"}`, its stretch, context,
actors, posters and route bag dropped, as `SceneRecipeDraft.base_of()` drops them) and its
`playback.walk` extended; the scratch recipes are not committed. Command, from the repository:

    Godot --path . --resolution 1280x720 --write-movie <dir>/frame.png --fixed-fps 60 -- \
        --recipe <scratch recipe> --recipe-mode scripted --player-view --no-focus-pause --no-save

Both walks are the recipe's own `1.95w0.7n0.7s5.71w3.13s0.35e`, which reaches the swing about 12.9s
in, then `0.4p0.5S0.8E`: the robber the swing sends comes from above, she runs from him for 1.3s
inside the park and he gives up (the run log: "gave up after 0.0s — closest 185px, she ran 0.3s
of it"), leaving her standing in the park's south-east.

- **Shut in**: then `20p`, standing. The run log: "the last gap of the park's cordon is taped
  12.2s after the swing, with her inside: she is shut in", then "lost_hard_fail after 24.8s to
  park-cordon — They taped the last gap with you still inside the park."
  - `tape-and-officers.png` (frame 1200, 7.1s after the touch): the east side taped and the south
    side being taped by one officer, posts at every stretch end, the ground still grass.
  - `cordon-closing-sheet.png`: frames 880, 1000, 1120, 1240, 1360 and 1484, two seconds apart
    from 1.7s after the touch, each scaled to 480x270: the two officers walking in at the top of
    the view on the east side's sidewalk, splitting at the edge, one taping south and round the
    south-west corner, the gap closing on the west side, where it was nearest her at the touch.
  - `cordon-closing.mp4`: frames 775 to 1487 (the touch to the day's end, 11.9s), 960x540, H.264.
  - `trapped-last-gap.png` (frame 1484): the last stretch open on the west side with an officer
    beside it, three frames before it is taped.
  - `trapped-day-ends.png` (frame 1487, the last): the day's end over the closed cordon.
- **Out in time**: then `0.9n2.6w9p`, walking north and then west out through the west side,
  about 4.6s after the touch. The run log: "the park at block (2, 8) is cordoned off 12.2s after
  the swing, with her outside".
  - `out-in-time.png` (frame 1560, 13.1s after the touch): she stands on the sidewalk across the
    street to the west, the park taped all round, an officer walking off.

What these do not show: the escort officers (this park had nobody in it; `tests/test_park_cordon.gd`
holds them), the screen-edge corners under the joystick scheme, and how often the robber the swing
sends leaves her in the park long enough to be shut in.
