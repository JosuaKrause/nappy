# M56, the masked pursuer faces where he is heading

One `tools/shot.sh` capture on `feature/directional-guards-and-mouse`, taken from a worktree based
on `origin/main`'s tip at capture time, after binding `GUARD_STANDING_BY_VIEW`/
`GUARD_LUNGING_BY_VIEW` through `EventInstance._draw_eight_view()` (PLAYTEST-128, statement 1).

```
tools/shot.sh out.png 28 --start-escape stairwell:right --invincible --no-save \
    --press ui_accept 0.5 --press snapshot_burst 22
```

Kept whole at `masked-pursuer-rig-091710-seed461373610/` — `run.log`, `asked/burst-23461537-001/`
(36 frames) and the run's own final still, `masked-pursuer-climbing.png`.

**A still stands in for a burst here, and that is a fork worth stating plainly rather than working
around silently.** `InteriorEvents._place_the_masked_man()` places the first pursuer at the foot of
the right-hand shaft the instant the section starts, running its whole height immediately — so by
the time a `--press snapshot_burst` fires near the start of a run, he has not yet climbed into the
camera's view around her at the top landing. `burst.json`'s own `duration_seconds` confirms every
burst's captured window is its first ~3 real seconds regardless of how long the `snapshot_burst`
key is held, so a burst pressed early always comes back empty (36 identical frames of an empty
stairwell, kept at `asked/burst-23461537-001/` for the record) however long the hold. Delaying it
with a second chained `--press` — a filler hold, or a second `snapshot_burst` right after the
first — reliably broke whatever lets the interior's own clock advance without another input held:
repeated tries with two chained presses, and with a single hold past roughly 27 real seconds or a
longer total wait past 28, sat on the same frozen opening frame out to 40 real seconds tried.
**The one combination that reproduced consistently — three separate runs, three different random
seeds, three matching results — is the exact command above**, a single `ui_accept` tap to dismiss
the section's own brief and then one continuous `snapshot_burst` hold timed so the run's *final*
screenshot, not the burst's own clip, lands while he is genuinely on screen. That is a still, not
an animation, so it is offered as the still it is rather than as a burst it would misrepresent.

`masked-pursuer-climbing.png` shows him mid-flight on the switchback, drawn at a diagonal angle
climbing toward the upper-left with a red danger caret above him — `GUARD_LUNGING_BY_VIEW`'s own
turned view read off his travel heading, not the single side silhouette
(`checkpoints/guard_lunging.svg` alone, mirrored east/west) the row drew before this branch. The
stair kit's own walkable geometry this capture stands on is established in
`docs/evidence/m112-escape-2026-09-10/README.md`.
