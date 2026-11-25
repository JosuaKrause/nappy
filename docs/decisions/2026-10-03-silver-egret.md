# silver-egret — A car's shadow lies under its wheels: one oval per wheel pair · 2026-11-25

*(minty-hedgehog 1, inbox #423: a shadow sits where the object meets the ground, not across its
whole picture, a car's only where its wheels would be; azure-koala 10, inbox #601: the police car's
shadow makes it look floating.)* One agent branch, `feature-silver-egret-shadows`. The player gave
two ways and chose neither; this builds the entry's proposed reading, the first way, open to their
overturn: the ovals stay, drawn from each object's `GroundShape` (the M61 record, one shape per
object), and their number and extent change. The second way, a custom shadow per object, is the
alternative the review item names.

**What it is.** `GroundShape.paired_shadow_outlines()` (`src/ground_shape.gd`) gives a thing that
stands on two pairs of wheels one oval per pair: a segment's pairs at its spine's two ends, reaching
its rounding to either side; a point's `POINT_WHEEL_SHARE` (0.6) of its radius from its centre and
as far to either side. The nearer pair is set down on the picture's own ground line — the body's
southern reach for a car drawn over its body (`CarLook.ground_line()`, the crowd car's strike box;
`EventLook._ground_line()`, the police car's and fire engine's capsule), the node for every vehicle
drawn standing on it — and the far pair behind it at `WHEEL_DEPTH` (0.6) of the ground's distance,
since the pictures foreshorten what lies behind (a diagonal view draws its far tyre about 0.6 of the
ground's distance above its near one). Each oval is level on the screen like every point shadow, as
wide as the pair looks from where the picture is drawn (a tyre's width side on, the vehicle's width
end on) and as deep as the point shadow of something the vehicle's width, centred on the pair, so it
reaches a little below the tyres. **Read as:** "adjust their number" is how many ovals an object
casts (one per wheel pair), the entry's own reading; the other reading, how many objects cast one,
is not built.

**Who casts it.** The crowd car (`CarLook.shadow_outlines()`), and every event vehicle through
`EventVehicleLook.shadow_outlines()`: the police car, the fire engine, the delivery, ice-cream and
unmarked vans, the reversing lorry, the army truck and the burnt-out car. The fire engine, the
ice-cream van, the lorry, the unmarked van and the burnt-out car are beyond the four the entry named
first; they share the one vehicle look, and the fix lands in the shared mechanism rather than a list
of four pictures. **Left with their whole body's shadow**: the riot van and the moving van
(`EventVehicleLook.SCENE_SHAPED`), whose ground shapes are the scene round them (the night raid's
44px disc holding its officers, the moving van's band along the street under its ramp), so they say
nothing about where the wheels are; drawn from those shapes the ovals were two discs wider than the
van. **They keep what the player's note complains of, an oval across, and wider than, the whole
van, so they are left queued by name, not dropped**: the entry stays open with the item
`riot-and-moving-van.md`, which asks for a shadow shape of their own (the picture's drawn width,
say, as `_draw_stationary_vehicle()` already reads for the moving van). Their rows are on the vans
sheet as they look now.

**One derivation of what a shadow covers.** A look now says what its shadow covers
(`AgentLook.shadow_outlines()`, `EventLook.shadow_outlines()`, reached through
`CrowdAgent.shadow_outlines()` and `EventInstance.shadow_outlines()`), and both the draw and the
debug view's shadow layer (`DebugLayers`, `--layers 2`) read it, so the layer traces the ovals and
an event's every solid piece rather than its row's one shape. `GroundShape.casts_a_shadow()` is the
half-pixel rule `draw_shadow()` already kept, pulled out for the readers that fill outlines
themselves.

**The tall props were looked at and left.** The trees' ovals lie at the trunk's foot already. The
swing frame's capsule casts a shadow as tall as the frame under all of it, the worst of the props,
and was built as one oval under each A-frame and reverted: day 12's task is touched at the ellipse
at the swing frame's base, 28 by 17px (`ResistanceDirector._swing_base()`), which
`docs/NARRATIVE.md` calls the extent of the shadow it casts there, so the shadow is the task's
visible target and changing it changes that task. It is a question for the player, asked on the board as
swing-frame-shadow with the orchestrator's pick (ovals under the frame's legs, day 12's touch spot
kept at today's size and place with its own chalk-task mark), and the entry stays open with the item
`swing-frame.md` built on that pick; the review item holds only what a run answers.

**Measured.** The M139 record's desktop walk (`tools/shot.sh out.png 20 --seed 3265820891 --day 1
--walk 3s17e`, the mean of the run log's `frame` entries from two seconds in, one run each): before
281.4 draws, 3842 primitives, 115.8 fps, 21.7ms physics; after 284.8 draws, 3947 primitives,
114.4 fps, 21.6ms physics. A vehicle on screen fills two polygons where it filled one; the crowd's
tick does not move. The plaid-chipmunk entry, shadows from pictures on their own atlas page, is
where a polygon's draw call goes away.

**Tests.** `tests/test_shapes.gd`: a side-on car's two ovals sit under its spine's ends on the ground
line, do not meet, and reach no higher than a point shadow of its width; end on, the far pair lies
behind the near one and nearer than the ground's distance; a point vehicle's two pairs stand inside
its reach; the half-pixel rule. `tests/test_car_views.gd`: at every sector the crowd car's shadow
stays below its picture's roof, which the capsule broke end on. **Evidence**:
`docs/evidence/silver-egret-shadows-2026-11-25/`, two before-and-after sheets of every changed
vehicle at every sector drawn by `tests/probes/silver_egret_shadow_sheet.gd`, the police car's
second ride frame among them, and two in-game before-and-after stills.

**Open to overturn.** The reading of the first way and every number in it (`POINT_WHEEL_SHARE`,
`WHEEL_OVAL_SHARE`, `WHEEL_DEPTH`) are the builder's, chosen by eye on the sheets. **The reading of velvet-marten #700**, in the
plaid-chipmunk entry: it answered an optimisation candidate of M159's frame-record investigation,
drawing shadows as pictures on an atlas page for cost, and says yes to that; its "the ellipse ones
don't work well" repeats minty-hedgehog 1's complaint and does not choose between its two ways. On
2026-11-01 (tiny-lark 18-19) the player kept this entry with the choice between the two ways
described as unmade, so building the first way overturns nothing, and the review item names the
second way as the alternative if the ovals still read wrong.
