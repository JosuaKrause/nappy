## M100 — Small, real, and nobody's · the checkpoint as played: the boom, the approach, the hold and the latch, 2026-09-12

*(2026-09-11, playtest 57: "the gate for the cars is too high up. it needs to be further down";
"the checkpoint should activate when I get close. with the new stroller hitbox I cannot reach the
checkpoint entrance."; and on M113's hold, "the camera makes a huge jump from somewhere to the
checkpoint. the checkpoint house disappears. the camera doesn't move at all after the 2s. also,
if I don't move I get sent back afterwards. all this is incorrect." Then 2026-09-12, playtest 58:
"she just spawns further away now? it should work that she has a flag 'just spawned' that only
resets once she leaves the area.")* Four agent commits on `feature/checkpoint-as-played`,
reviewed here.

**The boom.** The cause was the placement anchor, not the siting and not the SVG: the gate body
already sits on the carriageway's centre line, level with both huts, and each boom SVG's
documented ground anchor is the base of the post nearest the camera, but that anchor was used as
the *placement* anchor, so the whole arm hung to one side of the gate, an east-west boom's arm
running entirely above the carriageway. Each boom is now anchored midway between its two posts,
read off the same post box, and the raised state shares the constant. Chosen where silent: the
post midpoint rather than the arm's, since the posts are what stand on the ground. A test asserts
over every street door of every sampled day that the boom is level with the huts, its ground
point on the carriageway, its arm across the lanes and never past the door's solid line; the old
anchor failed it hundreds of times.

**The approach.** `detain_radius` had been a radius from the row's *centre* (48px) against a 32px
body, so it worked only while it exceeded the body plus whatever she pushes: her bare body stops
at 46px, the pram's stopped at 78px along a street and never reached it. It is now a reach past
the row's own solid edge, `Tuning.CHECKPOINT_DETAIN_REACH` (48px, the same number measured from
the right place), and `EventDef.detain_distance()` (body plus reach) is the one form validation,
detection and release read. The rows' inner radii moved up to keep the invariant *captured means
fully charged* (hut and post 84/98, gate 84/120), so a hut's field is now a 98px disc where it was
66 — a cost taken to keep the invariant rather than relax it, and listed in `REVIEW.md`.
`chatting_mother` has no body, so her number is unchanged. Also found and fixed: `_check_detentions`
had no `break`, so every eligible body in range captured her on one frame; only the nearest does,
and nothing captures while a hold runs. A test asserts the relationship rather than a number:
wherever she comes to rest against the hut, on either approach, she is inside the trigger, read
off the pram's live collision shape.

**The four faults.** The camera jump: `top_level` leaves the node's local position as its global
one, `Vector2.ZERO`, so the ease started from the world origin, a 7800px jump the rig measured.
`Stroller.camera_screen_center()` now answers where the camera is drawing from (smoothing, the
look-ahead offset, the limits), the camera is put on that point, its offset zeroed and its own
smoothing switched off for the hold, since the ease is the smoothing. The hut vanishing: the
suppression predicate is split into `is_its_guard_inside()`, which takes only the guard out of a
hut's drawing, and `is_suppressed_by_its_own_hold()`, now true only of `checkpoint_post`, where the
guard is the whole picture. The camera not returning and being sent back were one event seen
twice, with two causes: `signf(0.0)` is zero, so crossing the street exactly level with the body
multiplied the release clearance to nothing and set her down where she was; and a door's bodies
queued up, the next body along starting a hold on top of the one just released, charging the meter
twice. **The latch.** The agent's first answer, a release clearance stated against the trigger,
was overturned by the player the same morning: she comes out exactly on the far side of the door,
inside the trigger, `Tuning.CHECKPOINT_RELEASE_MARGIN` back at 8px, and `src/world/release_latch.gd`
(`ReleaseLatch`: `arm`, `update`, `holds`) keeps the trigger off her until she is measured outside
the circle. Found only by running it: a street door's three reaches overlap, so the boom's far
side is inside a hut's reach and the first run let her out of the boom straight into the hut. The
latch is therefore armed for every redetaining body whose reach she lands in, so one crossing is
one toll. The class is shared on purpose: the crowd's door hold and the building's doors reuse the
same rule. Tests drive the hold end to end and each fix was confirmed load-bearing by reverting
it. Evidence: `docs/evidence/m100-inspection-2026-09-12/`, a README and the whole run folder
with two bursts and their clips; the run log shows one `chat` and one `checkpoint` line in eleven
seconds. Four windowed runs were spent where two were budgeted, because the release design changed
twice mid-task. **Left open, filed in the queue**: the gate detains but draws no guard.
`docs/EVENTS.md`'s cost table still lists a row called `checkpoint`, the `roadblock` row's old
name, untouched here.
