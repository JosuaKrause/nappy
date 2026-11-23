priority: later

# velvet-tapir — Named test runs in parallel checkouts share one user data directory · filed 2026-11-23

**What is wrong.** Every checkout and worktree shares Godot's one `user://` save directory, so
`test_save_wiring` fails when two checkouts run it at once (13 and 3 failures were seen, and it passes when
the two run one after the other; pull request 1666's review). `tools/test.sh` refuses a second full run while
another test run is alive (exit 3), but never refuses a named run, and agents run named suites in parallel
worktrees all day. A filing from a review, not from the player's words; the band, `later`, is the filer's
proposal.

**Two ways to fix it, the builder picks and says why** (the plainer first):

- **A per-checkout user data directory for a test run**, so two runs never share `user://`: `tools/test.sh`
  points Godot at a directory under the checkout (or a temporary one it removes after), through the engine's
  own means of relocating user data, in every mode.
- **A refusal**: a named run that includes a suite touching `user://` refuses to start while another run is
  alive, as a full run does, with the same `TEST_ALLOW_PARALLEL_RUN=1` escape.

**Shown fixed.** Two named runs of `test_save_wiring.gd` started at once from two worktrees both pass;
`tools/test.sh --help` says which way holds, and `tools/test_cli_help.sh` still passes.
