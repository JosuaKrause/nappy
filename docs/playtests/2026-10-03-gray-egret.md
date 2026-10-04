# Playtest gray-egret — Scenes to play each day's target and the fire truck; the verify-each-task note

2026-10-03. Three notes from the inbox, filed together: #497, #498 and #499. Each is copied word
for word, after what its words answered.

## #497 — Mode 1 budget carries over; a crafted scene to play the station door; added mast only if silenced; near counted along the path

Answers on 2026-10-03, one per line, to: (1) PR #475 breezy-walrus mode 1: "you said "as many
graphics as needed are prepared in one frame". The old all-at-once code it restores also had a 2ms
budget, so a frame that needs more than 2ms of preparation finishes the rest next frame. Keep that
budget?" Options "No budget (Recommended)", "Keep the 2ms budget". (2) PR #480 station door: "the
burnt building's rule (50.6px from the door) reaches both pavement tiles in front of it, but not
their two far outer corners (57.7px away). Is that "half the sidewalk"?" Options "Fine as is
(Recommended)", "Cover both tiles fully". (3) PR #480 day 11: "the mast put up near the mark stays
on later days only if she silenced it... Right?" Options "Only if silenced (Recommended)", "Always
stays". (4) PR #480: ""near its mark" is 576px (one block + the street + half a block); with
targets kept off-screen they land 450–570px away. Keep 576px?" Options "Keep 576px", "Closer",
"Farther".

> if we keep the 2ms budget then it also should apply to the next frame and so on
> can I spawn this event in a crafted scene so I can test it directly? actually, this is a good idea for tests like this. just build a scene and let me play it out
> Only if silenced (Recommended)
> 576px and larger -- two/three blocks is okay *if* it's a straight line -- count along the path not as the crow flies

## #498 — Merge feathery-marmot as is; a new task: playable scenes for each day's target and the fire truck

Said in conversation on 2026-10-03 after #497, where the player had asked "can I spawn this event
in a crafted scene so I can test it directly? actually, this is a good idea for tests like this.
just build a scene and let me play it out" (about the station door's far pavement corners at 57.7px
versus the 50.6px door radius) and answered that "near its mark" should be "576px and larger --
two/three blocks is okay *if* it's a straight line -- count along the path not as the crow flies".
The assistant had sent both to the feathery-marmot agent (PR #480). "My word on the radii" refers
to #493 ("with every door do what you did with the burnt building...") and sandy-egret statement 2
as built in merry-koala.

> for now let's just use my word on the radii and we merge feathery marmot as is. create a new task to create scenes (mark + enough gap blocks + target) for testing each day's target. also create a scene to test the fire truck event

## #499 — The scenes come after the release; each task is verified with them

Said in conversation on 2026-10-03, right after #498 ("create a new task to create scenes (mark +
enough gap blocks + target) for testing each day's target. also create a scene to test the fire
truck event"), while the minor release v0.23.0 was pending.

> we pick those scenes up after the release
> and just keep a note that we want to verify each task with the scenes

## Routing

1. **Playable scenes for testing each day's task target, and one for the fire truck event**
   (#497 line 2, #498, #499) → the new queue entry
   busy-raven ([the entry](../todo/2026-10-03-busy-raven/README.md)), band `now`. #499's "after
   the release" is the order the player gave, stated in the entry; the entry is not parked.
2. **#497 line 1, the 2ms budget carrying over to the next frame and so on** → already handled:
   it answers PR #475's question about mode 1's budget, which that pull request holds.
3. **#497 line 3, "Only if silenced"** → already handled: it answers PR #480's day-11 mast
   question, which that pull request holds.
4. **#497 line 4, "near" counted along the path, 576px and larger** → already handled: the path
   measure is held by the entry `docs/todo/2026-10-03-feathery-marmot/` on PR #480's branch
   (`feature/feathery-marmot-task-targets`). No second entry is filed for it.
5. **#498's "merge feathery marmot as is" with the radii left as the player's word** → an
   instruction for PR #480, which carries it; nothing to file.
