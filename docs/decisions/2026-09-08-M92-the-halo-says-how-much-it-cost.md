## M92 — The halo says how much it cost · built 2026-09-08

Three findings from [PLAYTEST-36.md](../playtests/PLAYTEST-36.md), then four more from
[PLAYTEST-38.md](../playtests/PLAYTEST-38.md) played on the branch, and a design conversation in between that
answered the question M89 had tabled. Built by two sub-agents from briefs; the design moved four
times while the first one worked, each time from the player, and the moves are the record.

**What the halo says now.** One rim per source, traced from its own silhouette (M89's shape,
unchanged), for every live event and every walker and car whose field clears `CONTRIBUTION_FLOOR`
(1.0/s) at her position, the strongest `MAX_SOURCES` (8). **Colour and transparency both read the
same number — the points that source actually put on the meter over the last five seconds — on two
different curves**: colour is linear, `Palette.HALO_WEAK` (pale yellow) through `HALO_MID` (a
saturated orange) to `HALO_STRONG` (red) at `SATURATES_AT_POINTS` (40 of the 100-point bar);
transparency is `MAX_ALPHA` times `sqrt(landed / LOW_EMPHASIS_POINTS)` (15), floored at
`MIN_MAGNITUDE` (0.2), so a single point is faint but present, five is clearly there and fifteen is
solid, and above that the hue carries the difference. Both channels ease toward their targets on
`EntityHalo`, in over `FADE_IN_SECONDS` (0.3) and out over `FADE_OUT_SECONDS` (0.8).

**The number is traced from the meter, never computed beside it.** *(2026-09-08: "what matters is
how much mass landed on the player. don't derive it from the source numbers but trace an increase
in excitement back to its constituents. if a honking car caused 35 excitement to the player that's
the number that informs the color of the halo. with 1/3 of the bar that's pretty red already".)*
`City.excitement_sources_at()` returns the same bodies `total_excitement_at()` summed, broken out;
`Baby._update_excitement()` sums them, applies `SLEEPING_SENSITIVITY`, and hands each source its
exact share through `accumulate_landed()`. Running and the alley trickle have no source and are
attributed to nobody. *Rejected on the way:* the halo pass re-computing `contribution_at() ×
delta` for itself — a second number that could disagree with the bar. *Also rejected:* colour from
the row's declared `intensity`, the fork playtest 36 closed before it was built, because `cyclist`
emits 18/s and ends the day while `protest` emits 42/s and cannot hurt her.

**A true five-second window, not an exponential average.** The brief proposed an EMA as the cheap
shape; the player's sentence above — 35 is *the number* — needs a burst to read as 35 for the whole
window and then drop, so each source keeps `[when, points]` entries pruned on read, allocated on
first landing. *(2026-09-08: "5s timeout is a rolling window so a slow accumulation lingers and a
sharp increase flashes".)* `tests/test_halo.gd` holds it on both classes, including a partial
ageing case.

**The crowd is in, whole.** M89 tabled *the crowd has no halo* with three shapes and none chosen;
the first brief took the narrowest — startled bodies only, since a honking car already draws a
caret — and the player answered the question from the model rather than the screen: *(2026-09-08:
"it was an easy shortcut to introduce a background noise dependent on flooring. we can keep that
to some degree (eg alleys) but excitement should come from visible objects. a busy street is noisy
because of cars and a busy sidewalk is noisy because of people ... that will allow us to attribute
the source exactly".)* Checked before answering: incoming excitement already had no ground floor —
every walker (4.2/s) and car (5.4/s) emits its own field and the alley's 3.0/s is the one
ground-based source — and what *is* ground-based is the decay multiplier, which stays: *(2026-09-08:
"we can leave the decay multipliers alone they make different places feel different. that is good.
that way an alley doesn't ease the nerves as well as a park.")* So `select_sources()` takes an
untyped array of anything answering `contribution_at()`, `accumulate_landed()`, `landed()` and
`set_halo_strength()` — the duck type is stated in `ExcitementHalo`'s class doc — and `Crowd`'s
agents are candidates on an event's terms. `EntityHalo` (`src/ui/entity_halo.gd`) is the ring and
its shared `ShaderMaterial` extracted so both classes draw the same way; `CrowdAgent` builds its
halo child lazily on first glow and frees it only once the fade-out has finished.

**Distance is not encoded, and that overturns playtest 36's third sentence.** The first build gave
brightness to *how far into its field she stands* — *"the intensity of the halo states how far away
I am"* — and the player played it and took it back: *(2026-09-08: "the transparency shouldn't show
distance since distance actually doesn't matter. only the actual received amount counts which might
depend on the distance but we don't need to encode the distance. this frees up transparency for also
encoding magnitude".)* Then the two curves: *(2026-09-08: "color and transparency shouldn't be the
same number. transparency can be used to emphasize low values. all changes should transition (hue
and transparency) instead of immediately showing the actual value".)* The easing steps each channel
a fixed distance per second rather than lerping a fraction — found rather than chosen: a
proportional lerp never arrives, a third of the gap still open after the whole fade time at 60fps.

**Playtest 38's four, on the branch.** *Cats and birds showed nothing*: a rig proved `cat_dash` and
the flock were selected and accumulating all along; what hid them was the distance brightness, and
its removal was the fix — the rig stays as the regression. *No fade to red beside the other
mother*: a rig held that a chat lands its 25 points on her rim, so the ramp was the defect — an RGB
lerp between a pale yellow and a red desaturates at the midpoint — and `HALO_MID` is a chosen
orange the ramp passes through; the capture at the end of a chat is
`docs/evidence/archive/session-captures/2026-09-08/shot-2026-09-08-seed4242-ea44b51-chatting-mother-chat-end.png`,
a solid orange rim at 37 on the bar. *The chatting mother's capture radius* grew from 33 to 48px —
three quarters of the pavement band — with `inner_radius` 34 → 56 to keep the capture strictly
inside it as `EventDef.validate()` requires, `outer_radius` 70 unchanged; asked for without a
number, chosen as the smallest reading, confirmed on sight *(2026-09-08: "yes let's check those
wider numbers")*.

**`MAX_SOURCES` stays 8 and was not exercised.** Two captures on the arterial with the whole crowd
eligible, capped and uncapped, each showed exactly two rims — the nearest car and the nearest
walker — so fewer than eight ever cleared the floor at her position in that window; the player's
"why eight strongest?" is unanswered by a picture and the honest answer is that the floor, not the
cap, is what keeps a pavement legible so far.

**Felt numbers, all open to move against a played day:** the 15-point knee and the 0.2 floor of the
transparency curve, the 0.3s and 0.8s fades, the 40-point red, and the mother's 48/56.
