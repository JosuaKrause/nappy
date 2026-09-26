## M196 — The roadblock is end-on on a vertical street, and has a guard on each side · built 2026-09-25

*([PLAYTEST-135](../playtests/PLAYTEST-135.md): "the barrier is still the sideway view for each
segment in vertical" · "also the guards are on top of the barrier?" · "have one guard on each
side?" · "only the guard on her side can chase since the other one will be blocked" · "only the
barrier doesn't actually reach the full width/height is that intentional?" · "lgtm".)*

**What is built.** A roadblock down a north-south column draws `roadblock_segment_vertical.svg`
(20×30), the broadside panel's materials turned on their side, with stripes repeating every 15px
so stretched copies meet in phase; `_roadblock_segment_texture()` picks it by the spread's axis,
as roadworks picks its end-on picture. Two guards stand at every roadblock, one on each side of
the band, each 2px clear of the barrier's picture: 23px west and east of a column, 32px north and
46px south of a band across a street. When a heated roadblock notices her (within 180px of the
band's centre, unchanged), `_guard_side_toward()` picks the guard on her side, the node steps to
his post (`_set_off_from_the_near_post()`), and `_chase()` walks it from there; the band's body
stays pinned where it was built and the other guard stays at his post.

**The stand-off is measured from the catch reach.** `_chase()` uses
`Tuning.pursuit_standoff(pursue_speed, lethal_reach())`, the number `Tuning.validate_pursuit()`
already stated its contract over. Only `roadblock` sets `lethal_radius`, so only its stand-off
moved: 164px to 106px. Without it a guard setting off 23–46px nearer her would have been inside
his stand-off at notice and lunged on the first frame. Rejected: widening his field by the post
distance, and holding his ground through the warning. `docs/COSTS.md` does not move.

**An end-on spread covers the ground its body closes.** `_draw_spread` stood every segment's feet
at the middle of its slice, which put an end-on column half a segment up the screen — 15px for the
roadblock, about 11px for roadworks. `_spread_slice_feet()` stands end-on feet at the near end of
each slice, and it is shared, so roadworks, stall, rubble, barricade, scaffolding and collapsed
frontage move the same way. Broadside was already exact.

**What the picture fix exposed is not fixed here**: the catalogue band is 120px on a 192px street,
16px off its middle, so a 52px gap on one sidewalk lets the pram past. The player chose to close
the street fully, after the release (M199, the roadblock closes its whole street). With two
guards on every body, a region wall crossing draws six; the player asked for four (M200, a region
wall has a guard on each sidewalk).

**Choices made where the design was silent, open to overturn:** when she is level with the band's
line the south or east guard chases; drawing the second guard restores the view sector so the
chaser's facing is undisturbed; the end-on picture is flat fills without outlines, matching the
broadside `roadblock_segment.svg`. Left as they are: each posted guard sorts at the band's centre
rather than his own position (splitting guards into child nodes would need nested y-sort and
`EntityHalo` taught about children); the halo outlines both guards and the band while it charges;
a column's near end post stands inside the column's foot, as roadworks' does. And "his whole
1.8s warning" is not spent standing, for any pursuer: `_chase()` closes to the stand-off during
the telegraph and lunges as soon as she is inside it, which leaves her `PURSUIT_REACTION` (0.6s)
of his approach; straight across, he is noticed 133–156px from her and lunges from 106px after
about 0.2–0.4s. Whether a full 1.8s standing warning is wanted is a question for every pursuer.
