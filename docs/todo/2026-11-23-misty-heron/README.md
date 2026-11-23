priority: later

# misty-heron — No test sees the raid's check that its vans are out of her view · filed 2026-11-23

No player's words name this finding; it is the filer's, and the band `later` is the filer's proposal, not asked for.

**Found** by the review of pull request #1654 (minty-quail row 5, the resistance's second part).

**What holds today.** `ResistanceHappenings._maybe_raid()` (`src/resistance/happenings.gd`) holds the day 10 raid back while any of its two vans' drawing boxes would show in her view (the loop over `_raid_vans` asking `SpawnSiting.Rule.DRAWING_OFF_THE_VIEW`), and separately while the patrol car's drawing box would show anywhere on its beat (the loop over `_raid_beat`). The beat runs `RAID_PATROL_REACH_TILES` either side of her door, further than the vans' `RAID_VAN_OFFSET_TILES`, so every view the raid cases in `tests/test_resistance_happenings.gd` aim at a van also holds some of the beat, and the patrol car's check refuses first. Only the beat has a case of its own (`_test_the_raid_waits_for_the_patrol_cars_beat_to_be_out_of_her_view`, which asserts that its view holds the car's far end and neither van). Nothing is the vans' alone. To show it: delete the `_raid_vans` loop in `_maybe_raid()` and run `tools/test.sh test_resistance_happenings`; the review of #1654 found the suite stays green. It was not re-run when this entry was filed.

**What the fix must hold.** A case in `tests/test_resistance_happenings.gd` whose view holds a van's drawing box and none of the beat (the mirror of the beat's case, which asserts that its own view holds no van), so that the raid holds back there and arrives once the view moves off the van; deleting the vans' loop in `_maybe_raid()` then fails the suite. The case asserts that its view really holds a van and not the beat, as the beat's case does.

**Proposed, not asked for:** the band `later`, and the case as the fix.
