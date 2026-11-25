# sandy-goose: do the escape city's trucks, explosions, vans and roadblocks show up on her way

Evidence of the record that `tools/decisions.sh sandy-goose` prints. Source revision: main at
`6cd1965eb` (calm-hare's event director fix is in it), with the one probe below untracked.

**Claim.** On that build every one of 24 seeds and both exits has army trucks and finale explosions on her
street and in sight along her way, all but one run in 24 have an abduction van, and about three runs in four a roadblock; the escape's own rows
do show up. **Limits.** The static count is geometry (where the plan stands rows against the path), not a
play; the live count is twelve walks of the game's plain walker, which avoids nothing.

## Files

- `sandy_goose_escape_dangers.gd.txt`: the probe, a copy of `tests/probes/sandy_goose_escape_dangers.gd`
  (kept as `.txt` so the folder holds no script). Rerun: copy it to `tests/probes/`, then
  `tools/test.sh probes/sandy_goose_escape_dangers.gd` into a fresh scratch file; about 30 s.
- `static-output.txt`: its `ESCAPE_DANGERS` lines, one per seed and exit, then the totals.
- `live-table.txt` and `live/`: twelve walks (seeds 4242, 1, 77, 9001, 23, 5, each to the tunnel and the
  bridge) of the game's own walker, headless:
  `Godot --headless --path <worktree> -- --start-escape city --seed <S> --route <tunnel|bridge> --no-save --no-title`.
  Each file keeps the run log's `near`, `lost`, `route`, `plan` and `start` lines (the rest, mostly `frame` and
  `texture`, is routine). Two runs of a seed and exit gave the same lines, so one of each is kept; up to four
  walks ran side by side at one point, which changes no line kept here.

## How it is counted

- **On her way:** the exit's chain (`FinalePlanner.Plan.chains`), two-tile cells, each at its centre.
- **On her street:** the row stands inside a street segment of `Plan.open_streets` that holds a cell of the
  chain. **On the path:** inside a cell of the chain itself (a street is wider than her path, so this is small
  for rows that stand beside the road).
- **In sight:** the row lies within `Tuning.VIEW_HALF_EXTENT` (the screen's half width and half height in world
  pixels) of some cell centre of the chain: on her screen at some moment of the walk. "Off" is in sight and not
  on her street.
- **Live:** distinct places a row is named in the run log's `near` lines (what is within a cue radius of her).
  A roadblock names a place for each of its pieces, so its count is pieces, not roadblocks.
