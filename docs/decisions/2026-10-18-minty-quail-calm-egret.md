# minty-quail — The roadblock's look is handed its barrier post, and its band and its far guard are handed their look · 2026-11-11

**The ask.** "never read fields directly. always read through a method" (inbox #1173 in
gray-dolphin), and a component is handed what it depends on (minty-lemur #794). The last pull
request of row 2b of `event-interface.md`, after minty-quail-polite-newt, -mossy-hedgehog,
-tall-toad, -busy-badger and -merry-magpie.

## What was built

- **`RoadblockLook` is handed the barrier post** by `EventLooks.for_row()`, which
  `EventInstance.setup()` passes once the behaviours are composed (null for a row with no post),
  and it reads no field of its event but what the base look keeps.
- **The band and the far guard's nodes are handed what draws them**: `RoadblockBand.new(look)` and
  `FarGuard.new(look, post)` hold those by a `WeakRef`, as a slice does, and call the look's public
  `draw_the_band()` and `draw_the_far_guard()`.
- **The far guard's `_at`, `_heading`, `_walked`, `_walking_for`, `_way` and the post's `_far` are
  private.** 17 test lines changed to ask the post (`tests/test_world_passability.gd`, `tests/finale_rig.gd`,
  `tests/test_event_behaviours.gd`). `tools/field_reads.txt` lost 13 reads and gained none.

## Questions added

- On `EventBarrierPost`: `where_the_far_guard_walks()`, `which_way_the_far_guard_walks()` and
  `how_far_the_far_guard_has_walked()`, answered by `RoadblockFarGuard` methods of their own, asked
  by the look and the far guard's node; and `sides_still_posted()`, every side of the row's but the
  chaser's and none once the far guard has left, asked by the look and the suites.
- `EventInstance.is_only_its_barrier()`, asked by the look.

## Reads left, each with its reason

- `EventInstance.barrier_post` stays public: streaming, the warning board, a scene recipe, the
  composer and the suites read it.
- **`EventInstance.look` and `EventInstance.phase` stay public with no game file outside
  `event_instance.gd` reading either.** About 114 test lines read the first and 22 the second. The
  `[kept]` lines the brief planned for them are not written: `tools/check_test_only_members.py`
  judges by name, counts namesakes such as `officer.phase` and `VisibleView.look()`, and refuses
  the lines as read by another file.
- The reads row 2b leaves listed, each because the natural name is a standing field's or the file
  is another track's: the live event's `age`, the row's `guard_sides`, `warning_picture`,
  `flock_spread` and `abduction`, `AbductionSpec.taken_over` and `standing_offset`, and
  `WorldMap.world`.
- `send_the_far_guard_off()` keeps its own loop over the sides other than the chaser's, a near copy
  of `sides_still_posted()`, outside the step's fence.

## Parity

The look probe's `LK` lines (`a12e4cc9…`, 63070 lines), the excitement fingerprint (`7510c1d0…`)
and the events tick sweep's chains (`bf69e949…`) hash the same on `main` at `313e574fc` and on
`812ce1124`, and the run log is line for line what it was. The sweep exits 1 on both trees with
the same six failures of its own check. The three `_draw_shadow()` calls are drawn straight on the
canvas where no probe sees them; only what decides whether each is reached changed. Nothing was
timed, and the times section 6 of `event-interface.md` asks for are owed.

## History taken out of the comments

From `roadblock_look.gd` and `event_barrier_post.gd`, each now a citation with the rule in the
comment's own words:

- "the guard needs to be at the barrier from the beginning, standing. only then does it make sense
  for it to start pursuing." (2026-09-19; PLAYTEST-94 13)
- "have one guard on each side?" (2026-09-25; PLAYTEST-135 3), with the comment's "since the other
  one will be blocked"
- "the masked pursuer and the heated roadblock guard face where they are heading" (PLAYTEST-128 1)
- "the guard pursuer makes his barrier jump up and down" (azure-koala #601)
- Asked whether the far guard should leave as well once his partner has been lured off, "He leaves
  too" (inbox #771 in minty-lemur, 2026-10-18); then, asked whether that holds on a day as well,
  "Days too" (inbox #788 in minty-lemur)
- "the guarded barriers disappear after shaking off the pursuer. that doesn't make sense."
  (azure-puffin #664)

## Open to the player's overturn

- **The question "has the far guard left" is not written.** Once the look asks
  `sides_still_posted()` only tests would read it, so the suites ask
  `sides_still_posted().is_empty()`; `RoadblockFarGuard.has_left()` stays, read by the post. The two
  answers differ on a row with no side but the chaser's and on the region wall's body; every
  converted test stands a heated roadblock with both sides, where they agree.
- **The two kept lines are not written**, as above: a comment on each member says why it is public,
  and `tests-own-class-members.md` and `event-interface.md` hold when each goes private. The plainer
  alternative was converting the suites here.
- **The far guard's node holds the post by a weak reference as well as its look**, so with its event
  gone it stays where it is and draws nothing, which is what its old `is_instance_valid()` guard
  meant.
- **The names**, the builder's: every question above but `is_only_its_barrier()`, which is the
  design's, and `draw_the_far_guard()`.
