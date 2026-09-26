## M152 — A turn's landing stands where its arc ended · built 2026-09-15

*(2026-09-15, [PLAYTEST-76](../playtests/PLAYTEST-76.md): "cars are super buggy now. when they
turn in the final stretch the teleport a car length somewhere else. also in some case instead
of routing a turn (or u turn) they just teleport.")* Two agent commits on
`feature/m152-car-teleport`, reviewed on the PR; the probe's output per commit and three
bursts are `evidence/m152-car-teleport-2026-09-15/`.

**The bisection, and what it did not find.** `tests/probes/m152_car_jumps.gd` walks a rig day
on three seeds over days 1 and 13, 40 s each, the field's centre walking between the day's
closure mouths where cars turn, and flags every frame a car moves more than twice its top
speed allows, classed and marked in or out of the play viewport (`Tuning.VIEW_HALF_EXTENT`;
`OUT_OF_SIGHT` lies outside its far corner, so a legal recycle never counts). In-view jumps:
3 at the base the day's merges were made onto, 3 after M146, 5 after M129, 5 after M149, 1
after the fix. M146's output is byte-identical to the base — the pocket branch never fires
for a car on these days. M129 touches no crowd file; it changes what stands in the streets,
and its counts move both ways. M149 is exonerated by its own suites: every packed region
equals its source in size and pixels, and the car views' anchors are pinned. So the defect
was older than the day, and why it read as new is not measured; the likeliest reading is
M129's redistribution putting more turns in front of the camera.

**The cause and the fix.** `_land_the_turn()` finished every turn by calling
`_join_the_back_of_the_queue()`, which drops a car a gap behind the rearmost car in its exit
lane — the merge a recycled car makes at the entry band, where further back is more
off-screen road. At a junction, further back is most of a street: seven of 532 landings
retreated 119 to 1472 px, two in view, and every one for a car that was never in the way,
because `_has_room_here()` compares absolutely and a follower whose brake undershot by a few
pixels reads like a car parked on the spot. The landing now decides nothing: the car stands
where its arc ended, the point `_has_room_to_land()` checked before the commit and
`_claim_the_turn()` has held every frame since, and a follower too close behind is what the
queue's front-to-back resolve moves. `docs/MECHANICS.md`'s sentence that the arrival gives way
is rewritten. The check in `tests/test_crowd_closures.gd` holds one arm of a junction under a
crowd, watches 30 s, and asserts no car in sight moves further than it drove; it took three
tries to stop being vacuous — sealing every arm empties the view, sealing two lands every turn
off camera — and what works is one shut arm plus a manufactured follower half a gap behind
every landing, with guards that fail if the rig goes blind. Red with the retreat, green
without. The bursts cannot show the defect, one contended landing in seventy turns; they show
traffic at a barrier reading right frame by frame.

**Open, and the player's.** The about-face `_turn_round()` has no arc — it flips heading and
lane in one frame, about 130 times over the probe's 240 s — and the first frame's unpack
still moves a car a car length in view; both are in `TODO.md` under M152.
