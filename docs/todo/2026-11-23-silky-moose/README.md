priority: later

# silky-moose — tests/probes/minty_quail_crowd_frames.gd does not parse on main · filed 2026-11-23

**What is wrong.** `tests/probes/minty_quail_crowd_frames.gd` declares `var drawn := DrawnView.on(t)` near the top of its run function and, further down, `var drawn := {}` (the dictionary the `note` callable fills as a frame finishes drawing), so the engine refuses the script: "a variable named drawn is already declared". The probe is not a suite and not headless, so no test run loads it. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** pull request 1684's builder, loading every script under `tests/`.

**What a builder does.** Rename one of the two (the dictionary is the one that says what it holds, for example `last_drawn`), and parse every script under `tests/` to find any other that no longer loads.

**Shown fixed.** Loading the script headless reports no parse error, and the same for every other script under `tests/`.
