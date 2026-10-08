# M226 — Camera expiry and affordable offscreen running

Final source: `c6b5ec910d0bc3e1f1a16e7f8c36f4533285e7fa`, Godot 4.7.2, macOS. The evidence
addresses the camera-only warning-expiry failure and the player-approved running policy in
[tall-owl](../../playtests/2026-10-07-tall-owl.md). It is targeted evidence; the full suite is CI's.

## Retained files

- `gold-final.log`: the committed warning-lead probe, including both-axis dog gold timings
  and sent robber/guard walk, stand and run responses. Its earlier generic table measures a
  different reach/floor comparison; the M226 table is the chase-timing measurement cited here.
- `measured-final.log`: the actual awake Baby with an accelerating Stroller, plus 88 focused
  checks for camera expiry and both sent rows. Immediate running gives up without catch or
  crying, at 4.0475146 excitement points out of 100 in each printed case.
- `nappy597-fixes.gd` and `nappy597-fixes.tscn`: the original small driver, unchanged. The scene
  retains its original absolute script path; the commands below place it there to reproduce.
- `camera-before.log`: the two failures when the player remains fixed but the camera moves
  during the warning, in tap and joystick schemes.
- `escape-before.log`: the developing regressions fail with the discarded first-visible
  escape gate; the actual Baby reaches crying. This earlier driver also asserted that every
  horizontal run stays unseen, which acceleration does not promise. The final assertions
  keep the vertical unseen check and require affordable escape for all starts. Check counts
  therefore differ; this log is a failed trial, not the final test specification.
- `affected-after.log` and `focused-after.log`: the affected-suite result and focused pass.

The before logs come from the regression-development pass against the earlier PR runtime;
they do not carry an independently recorded exact dirty-tree hash. The committed final source
and unchanged final driver identify the reproducible passing experiment.

## Reproduce the final measurements

From a checkout of the source above after `./tools/check.sh` imports the project:

```sh
./tools/test.sh probes/m207_warning_lead.gd
cp docs/evidence/m226-review-fixes-2026-10-07/nappy597-fixes.gd /private/tmp/nappy597-fixes.gd
cp docs/evidence/m226-review-fixes-2026-10-07/nappy597-fixes.tscn /private/tmp/nappy597-fixes.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . /private/tmp/nappy597-fixes.tscn -- --no-save
```

The evidence folder is added after the measured source; copy its two driver files into that
checkout or use their absolute retained paths for the two `cp` sources. The driver calls the
committed resistance fixtures rather than reimplementing pursuit or Baby behavior.

The timing probe starts the player's run at the requested speed and reports 0.87s from badge
to give-up for both sent rows on both axes. The separate actual-Baby fixture accelerates from
rest and reports cost; it starts at zero excitement, excludes world noise and recovery, and
stops on crying instead of counting a later timeout as success. Vertical cases stay unseen.
Horizontal cases first enter view 0.1s after creation during acceleration. These are bounds
on the isolated response, not a claim that every noisy city situation has the same total cost.

Camera coverage invokes the actual pending warning expiry with a stationary player and moved
camera. Whole-view exclusion includes the joystick corners. These headless measurements do
not claim to show animation or replace the separately retained production corner capture.
