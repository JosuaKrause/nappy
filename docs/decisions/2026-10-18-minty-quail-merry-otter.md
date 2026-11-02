# minty-quail — The suites that boot the game read the booted scene tree; main has no public read surface (tests through public seams) · 2026-11-02


minty-quail's `tests-public-seams.md`: the suites that boot the game. The item stays open for the
checkpoint and finale suites and the reads no seam answers yet.

**Built.**
- No `src/` change: `main` gains no public member and no signal. A `booted` signal and a public
  `make_player()` were built and taken out, since nothing in the game reads `main` back and a member
  only a test reads is not a seam (records -44 and -47).
- `tests/booted_main.gd` boots the real `main.tscn` with a scratch-path save, waits real frames until
  she stands in a world and the boot camera is gone (bounded, failing a check rather than hanging),
  finds the city, the interior, the day, the resistance, her and the baby, and the screens by the
  names `main` gives them, and touches the title and the summary's Continue through the viewport.
  A check about what a node was handed before it built catches it as it enters the tree
  (`SceneTree.node_added`).
- Fourteen suites moved onto it. Private-read lines: baby_world 17 to 0, move_poses 23 to 6,
  player_presentation to 0, run_config 18 to 16, boot_handing 14 to 3, camera_start 17 to 3, run_flow 22
  to 4, invincible 14 to 4, escape_invisible_wall 13 to 0, main 3 to 3, full_run 3 to 1, day_controller
  3 to 0, day_loop 46 to 0, park_return 54 to 7. Every check kept; camera_start gains one (the lost
  day's continue placed the next attempt, so its home-ground checks cannot pass by never running).
  The flow modes are read off what the screens show: a brief by its title, the ending by its hidden
  Continue (playtest 28's rule that the ending has none).
- The suites take longer where they boot `main` and let real frames pass.

**Open to overturn** (the builders' choices where the brief was silent): the scene tree as `main`'s
read surface; `move_poses` ticking the resistance and the day through their public `tick()` without
`main`'s walking-and-unpaused gate; `day_controller`'s single real frame in place of an injected
delta.
