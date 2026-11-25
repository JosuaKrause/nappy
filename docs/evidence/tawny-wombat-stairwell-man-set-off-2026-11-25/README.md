# tawny-wombat: the stairwell masked man set off by a place, 2026-11-25

**Claim.** In the escape's building, the masked man is not in the world until she comes within 426px
of the foot of the right shaft; then his screen-edge badge goes up, pointing down the shaft, and he
comes on the same tick, already running; the badge stays up until he comes into her view and then
comes down. The stairwell probe's outcomes are the same on main and on this change.

**Limits.** One seed, one walk (the building's own walker, which runs once he comes), one build.
The stills show one moment each of a run; the burst's `burst.json` gives each frame's time. They
say nothing of a walker's catch, which `tests/test_interior_masked_man.gd` and the probe hold.

## The run (`rig-120502-seed4242-v0.29.2-739-g77f283345/`)

Source revision `77f283345` (pull request #1759's branch; from a fresh clone,
`git fetch origin refs/pull/1759/head` first, then check out that commit). Command, from the
repository root:

    tools/run.sh --seed 4242 --start-escape --route home --no-save --frame-trace --after 25 \
        --press snapshot_burst 13.4

`--route home` has the building's walker (`BuildingWalker`) press the section's brief and walk her
out by the right shaft; `--frame-trace` with `--after` is what carries `--press` in a run with no
screenshot. The burst started at 13.1s of the section, the tick his badge went up.

Kept, under the run folder's own name: `run.log.excerpt.txt`, the run log from 12.4s to 16.8s (his
badge up at 422px, closing 130px/s; down 0.9s later with him 248px away; she got through), and three
frames of the burst with its `burst.json`:

- `asked/burst-16026366-001/frame-0003.png` (0.17s into the burst): the badge at the bottom edge,
  his silhouette, pointing down the shaft; he is 422px below her, out of sight.
- `frame-0013.png` (1.01s): he comes into view at the bottom of the screen, and the badge is down.
- `frame-0017.png` (1.33s): he runs up the flight at her, drawn lunging, as she reaches the door.

The other 33 frames, the full run log and the frame trace are left out: they show the same walk
between those moments, boot output and the city section after it.

## The probe (`probe-main.txt`, `probe-branch.txt`)

`tools/test.sh probes/escape_stairwell_guard_trigger.gd`'s `TRIGGER` lines (seed 4242, five ways
onto the second flight, three paces), run on main at `c051a7de8` in a detached worktree and on this
change at `77f283345`. The two files are identical.
