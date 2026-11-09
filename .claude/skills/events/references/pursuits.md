# Pursuits

Read this before touching `EventDef.pursuit`, `EventDef.notice`, `PursuitSpec`, `NoticeSpec`,
`EventPursuit`, `EventNoticeRun`, or any charger, robber or guard.

The mechanics — the stand-off, the break-off as a rate, the waiting state — are
`docs/MECHANICS.md`, "Running that matters" and the sections under it. **A fairness contract about
a moving encounter is stated over distance and checked by walking**, never by asserting the numbers
it was written from.

**Three things bind a change to any pursuer, and `SKILL.md`, "The telegraph fairness contract",
states them**: the day-3 dog's separate notice floor, the clock a pursuer that waited for her warns
on, and verifying escape with the actual Baby meter.

## The traps

- **Clamping the approach at zero is not a stand-off.** The pursuer stands still while *she* closes
  the gap and dies on the first lethal frame. It closes to its stand-off
  (`PursuitSpec.standoff()`) and lunges the moment she reaches it, so the chase starts at the
  stand-off however she came. **A pursuer that stands still for its notice
  (`PursuitSpec.stands`) closes nothing and keeps every lunge**, which
  is what keeps standing from being this trap for one that comes for her (woolly-penguin #748);
  one that waited for her charges on its warning's clock instead (next trap); one that sets off
  beside her charges from where it stood once its notice has run. A wall between them that holds the lunge back is the same trap: at an
  alley mouth the line clears with her already inside the stand-off. The notice, the lunge and the
  catch all ask for a clear line, so a held lunge is not deferred until the line clears: the pursuer
  holds the ground of one that sets off beside her (`EventPursuit.lunge_held`) — it stands while
  she is nearer than the stand-off and follows at it once she is further, or only stands if it
  stands for its notice — and lunges once she is back at the
  full stand-off; a timed notice does not run out while she is inside it (`_pause_a_held_notice()`)
  — a notice ending there is the same trap, reached by her standing still.
- **A waiting charger has one radius and charges on a clock, never on a distance.** Charged at a
  stand-off while she walks into it, `PursuitSpec.PURSUIT_REACTION` of its approach is worth about a fifth of a
  second, too short to turn and run. So every charger that waits for her (the waiting dog, the
  alley robber, the hunting roadblock's guard) warns for its row's `PursuitSpec.warns_for` from
  the frame it notices her inside its one radius, and charges only if she is still inside once
  that has run; out of the radius first, it waits again (`EventInstance.warns_by_radius()`,
  `notice_time()`; inbox #788 in minty-lemur). **Running while it warns counts for nothing**: `EventPursuit` adds to
  `PURSUIT_SHAKEN_OFF`'s count only once it has charged, or a half-second run beside a roadblock's
  band would send its guards off with no lure. Behind a wall at that moment it goes on warning until the line
  clears. A late notice, at an alley mouth, is answered by the warning: she has its whole length to
  leave. It notices her only with its warning picture in the camera's view
  (`EventInstance._would_stand_in_her_view()`, the view `EventManager` hands it as `player_view`);
  an instance stepped directly with no view handed to it gets the radius alone, so a test of the
  view hands it one (`tests/escape_roadblock_rig.gd`, `view_round()`). **The masked man is the one
  exception**: he runs a line rather than pursuing, so neither his notice nor his run asks the
  clear line, his notice asks no view, and he runs the moment she comes within his
  `NoticeSpec.runs_within` from outside it, with no warning clock; one who noticed her already
  inside it warns for `Tuning.WARNING_ALONE_MAX` first (`EventNoticeRun`; inbox #788 in minty-lemur): in the stairwell his warning is off screen, which the player
  accepted (inbox #782 in minty-lemur), so a clock before he runs is no heads-up she can see.
- **The checkpoint guard is the one pursuer exempt from the stand-off, by the player's choice**
  (inbox #764 in minty-lemur, inbox #788 in minty-lemur). His warning comes before he exists — from the frame she crosses a
  door's line, the hut's guard across the road (or the post's) raises his hand for
  `CheckpointController.CROSSING_WARNING`; back across first, it is called off — and once it has run with her
  still across he charges from that hut or post, inside his own stand-off
  (`PursuitSpec.Start.CHARGES_AT_ONCE`: no notice of his own, telegraph 0). So his charge is not met at the
  stand-off: the answer is the warning — go back, or go on running — which
  `tests/test_checkpoints.gd` walks. **No other row may start `CHARGES_AT_ONCE` without the player's
  word**: on any other pursuer it is exactly the trap above.
- **A break-off stated as a distance needs two inequalities, and they fight.**
  `Tuning.PURSUIT_SHAKEN_OFF` ends a chase at a **rate** — the gap opening — which only running can
  do, and it is stated over *her*, because a proxy over the pursuer's geometry resets at every
  corner and kerb.
- **Check it with a rig that accelerates.** Nobody turns round in nought seconds; reversing a walk
  into a run takes `(WALK + RUN) / ACCELERATION`, and the contract includes it.
- **A rig that runs on a timer runs into it.** The director sites a pursuit in front of the
  direction she is *actually travelling*, so a `--flee` that starts early puts the pursuit in front
  of the run. It waits for the chase.

## The waiting state

Two more, about the waiting state (`EventDef.notice`): **whatever follows it starts when it notices
her**, not at dawn — for a pursuer its warning's clock, for anything else its telegraph; and **whatever draws it asks `is_waiting()` as well as `is_telegraphing()`** — each is
false in the other's phase, so a picture that asks only the second holds its whole wait in the
wrong posture.
