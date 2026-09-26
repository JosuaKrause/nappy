## M121 — The halo follows its owner, and a turning car's picture and lane · built 2026-09-13

*(2026-09-12, [PLAYTEST-66](../playtests/PLAYTEST-66.md): "the halo doesn't update when the drawn
sprite updates. so a turning car will have the original halo while turning (burst 5 and 6 and a
couple more). also while turning the car might get weirdly offset (burst 5 and 6). a car doing a
u-turn into a lane with traffic reset the other lane (burst 1)", and "the halo issue is not
specific to cars you can see the same for when you walk close to birds you will get a freeze frame
of their position as halo while they keep flying".)* Prioritised with the round.

**The rim re-traces every frame it is drawn.** `EntityHalo._process()` asks for a redraw on every
frame its drawn alpha is above zero, easing or not, plus the frame a fade reaches zero so the last
rim clears. That is the one rule that covers a turning car, a flying flock, a walker swapping gait
frame and any owner not yet written; the alternative — every owner calling the halo's
`queue_redraw()` beside its own — was rejected without measuring because it is a rule each owner
has to remember and the next kind would silently lack it. The cost is bounded by the selection,
`ExcitementHalo.MAX_SOURCES` (8) rims of twelve body re-draws, whatever the crowd is doing.
`tests/test_halo.gd` asserts the state the drawing reads, since headless never calls `_draw()`.

**And a mirrored view had no rim at all, since the halo landed.** Found while reviewing, confirmed
by reading and then by capture: Godot's `draw_set_transform` replaces the canvas transform and
nothing can read the old one back, so the flip inside `Sprites.draw_standing()` discarded the
halo's per-copy offset for the three west-facing sectors of every family that mirrors an east
picture — crowd cars, crowd walkers, the event people — and twelve copies landed on the body with
no rim outside it. The same replacement threw away `EventInstance._draw()`'s bob for a west-facing
event walker, and the trim layer of any mirrored sprite lost its offset even where the body kept
it. `Sprites` now carries a base transform a caller publishes, `mirrored_transform()` composes the
mirror under it, and the flipped branch restores the caller's transform rather than identity; the
two callers that set a transform around a body draw both publish. With the composition removed the
new test reports all twelve copies at one point, which is the defect verbatim; the burst under
`evidence/m121-halo-follows-owner-2026-09-13/mirrored-views/` shows a west-facing walker with a
complete rim. Both the **cues** and **godot** skills told a reader to mirror with the replacing
call and now carry the trap instead.

**The picture's offset was a per-view anchor, not the turn.** Against the M108 capture rather than
the playtest burst: `_car_body_anchor()` answered per view and the five views did not share a rule
— the side view sat at the node, 14px north of its own strike box's south edge, with the box's top
edge running through the wheels. On an arc that fixed error became a jump, because
`EightDirection` swaps the texture at a sector boundary and the anchor jumped the whole difference
in one frame while box and shadow rotated smoothly. One rule now, read off the live heading: the
drawn content's bottom edge lands on the strike box's southernmost point, `26·|heading.y| +
14·|heading.x|`, plus that canvas's bottom alpha margin (`CAR_CANVAS_BOTTOM_MARGIN`). Two visible
consequences, open to the player's eye: east- and west-bound cars' pictures sit 14px further south
than before, and front and back views 2px. Silent choice: the strike box is the datum, since the
two cardinals disagreed and the entry named neither; the rejected readings are in the commit.

**"Reset" was the front-to-back resolve, and the lane's own following rule fixes it.** A turn books
its landing at commit, a run-up plus an arc before the car stands there, and nothing told the exit
lane's traffic; the frame it landed, `Crowd.space_out_the_traffic()` shunted everybody behind it by
the overlap plus everything moved ahead, compounding down the queue — with the fix reverted a car
already in the lane is thrown 62.4px backwards in one frame. `Crowd._keep_room_for_the_turning()`
hands the booking to the lane as a stopped leader so the nearest follower keeps a headway to it,
and `_land_the_turn()` is the backstop: if the gap closed anyway the arrival drops in behind the
rearmost car, the same merge a recycle makes, after `TrafficIndex.give_back()` removes its own
reservation so it does not merge behind itself. Rejected: projecting the lane's cars over the arc,
since `TrafficIndex` carries no speeds. The test is an arm turn in `tests/test_turns.gd` rather
than the about-face the entry named: a car only about-faces because the way ahead is shut, so no
queue can stand behind that landing, and the code path is the same.

**What the captures could not catch.** Three bursts on the playtest's seed produced one usable run,
which shows walkers passing with rims tight on their bodies every frame but no turn, no flock and
no about-face; `--spawn event:pigeon_flock` can never work because the row is placed ahead of the
player rather than in the day's plan the rig reads, which is a dev-flag gap worth its own item.
Whether rim and picture read as one body through a real turn is in `REVIEW.md`.
