# silver-egret — The swing frame stands on its feet and the riot and moving vans on their wheels · 2026-11-25

*(minty-hedgehog 1, inbox #423: a shadow sits where the object meets the ground, not across its
whole picture.)* One agent branch, `feature-silver-egret-swing-and-vans`, building the entry's two
open items after the vehicles (the record silver-egret). The swing frame is built on the
orchestrator's pick on the board (swing-frame-shadow, open to the player's overturn): ovals under
the frame's legs, and day 12's touch spot kept at today's size and place, found by its red arrow
with no mark of its own, below. The pick first also asked for the chalk task's usual mark at the
spot; that part is corrected on the board and is not built.

**The riot van and the moving van.** Their ground shape is the scene round them
(`EventVehicleLook.SCENE_SHAPED`: the night raid's 44px disc holding its officers, the moving van's
band along the street under its ramp), so their wheels now stand under a body of their own
(`EventVehicleLook._wheel_shape()`): a point reaching `SCENE_BODY_SHARE` (0.9) of half the length
the vehicle's side picture is drawn, the share the other vehicles' bodies keep to their pictures
(the delivery van's 22px under its 48px side picture, the lorry's 28 under 62, the army truck's 26
under 60). That puts the riot van's two pairs 14.6px either side of its centre, round the tyres its
54px side picture draws 13px either side, and the moving van's (drawn 56px long) 15.1px either side.
The ovals are laid as every vehicle's (`GroundShape.paired_shadow_outlines()`). The moving van now
takes its wheel axis from the way it stands, as the burnt-out car does: side on along an east-west
street, end on along a north-south one, the one rule for both stationary vehicles. The ground
shapes are untouched, so what the scenes block and where the officers stand does not move.
**Rejected**: putting a shadow shape for the two looks in their catalogue rows, which would have
been the plainest data, since the catalogue is another branch's file now (M199); and a table of
each picture's wheel positions, more code for three of the moving van's tyres where two ovals read.

**The swing frame.** Its ground shape is now a segment from one A-frame to the other
(`Prop._playground_frame_shape()`): its spine's ends `SWING_A_FRAME_SHARE` (0.5) of half its
width from its middle, under the middle of each A-frame's two feet (`swing_frame.svg` stands them
at 6 to 21 and 35 to 50 of its 56px), and its rounding half its picture's height, read as the
frame's depth as before. Its shadow is one oval per A-frame, the cars' ovals
(`GroundShape.paired_shadow_outlines()`) on its picture's bottom row: 17px wide and 14px deep
each, where the capsule was 56 by 34 across its whole picture. `Prop.shadow_outlines()` is what
the prop draws and what the debug view's shadow layer traces, so the two agree; `Prop.shape()`
had the debug layer as its one game reader and is gone, its suite reading the shadow instead.

**Day 12's touch spot is the size and place it was.** It is read off the frame's picture
(`Prop.swing_frame_base()`: half its width across and half its height deep, 28 by 17px), not off
the shadow, centred on `CityMap.swing_position()` as before. Both ovals lie inside it, so
stepping onto the shadow still completes the task. `tests/test_resistance_arrow.gd` holds the
spot to the picture, from eight bearings a pixel inside and two pixels clear of it, and the
shadow's two ovals inside it. `ResistanceDirector._swing_base()`, which read the shadow through
a private member of `Prop`, is gone; `_shape_the_touch()` asks `Prop.swing_frame_base()`.

**The spot is found by its red arrow, with no mark.** The shadow no longer shows the spot, and
nothing is drawn in its place: the red arrow ends on the frame's base, as every red-arrow task's
does, and the two ovals lie inside the spot. A red-arrow task's destination draws no chalk mark (the
record snowy-kestrel, azure-koala 6: "red arrow tasks show a chalk mark at their destination", which
the player called wrong: the alleys have one, the tasks should not), and day 12's swing is one of
the four destinations that record took the mark off, so a mark there would overturn the player's
words. The pick's first version drew the chalk task's usual mark at the spot; it was corrected on
the board to this reading, and with it built the entry has no item left and its folder goes.

**Evidence** (`docs/evidence/silver-egret-swing-and-vans-2026-11-25/`): the vans sheet, the riot
van at every sector and the moving van side on and end on, before and after; the swing frame sheet,
before, after, and after with the touch spot traced; and two in-game before-and-after stills of day
12's swing frame, one on the task's stretch with the tree in front of it taken out, one on the whole
city with the tree. `tests/probes/silver_egret_shadow_sheet.gd` draws the sheets.

**Tests.** `tests/test_event_views.gd`: the riot van at every sector and the moving van side on and
end on cast two ovals no wider than the picture drawn for that view, where the raid's scene is wider
than the van. `tests/test_atlas_decoration.gd` reads every prop's shadow, the swing frame's two
ovals under its A-frames included, off the region table. `tests/test_resistance_arrow.gd` as above.

**Open to overturn.** The swing frame's pick, the player's on the board (swing-frame-shadow): the
other answer there, changing the touch spot with the shadow, replaces this. `SCENE_BODY_SHARE`
and `SWING_A_FRAME_SHARE` are the builder's, chosen by eye on the sheets.
