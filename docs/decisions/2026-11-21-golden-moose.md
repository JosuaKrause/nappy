# golden-moose — A mark's rigged row is a marble of her route's bag again · 2026-11-21

**What was asked.** The entry golden-moose, a change Fable wanted in its review of #1548 (the beats become rigged
marbles in the units ahead of her), a pull request of the fable-only entry polite-tapir that merged on an Opus design
while Fable's quota was out (the record calm-lemur). After day 6's and day 7's marks, the second man shouting and the
second delivery van came from no bag: a second call chain through four classes appended the row straight to her
walk's list, where the player had named the chained bag (olive-koala 2; inbox #561 in coral-bunny, inbox #586 in
olive-hedgehog, inbox #1520 in breezy-magpie). The player accepted Fable's changes: "yes, fables complaints are valid.
get the fix and then let fable review again". Built by a Sonnet agent as #1615 from Fable's design, then reviewed
adversarially and by Fable.

**What was built.** Days 6 and 7 rig her route through `rig_her_route()`, the path day 11's second mast takes, with
the bag of 2 restored (`TASK_CONTACT_WITHIN_THE_NEXT` and `VAN_WITHIN_THE_NEXT`, read as the smaller end of "2 or 3");
laying the rigged row just ahead of her is a setting of the rig, asked of the step
(`Step.lays_its_rigged_row_just_ahead()`), and the director lays a drawn marble's plan just ahead where it is set.
`rig_the_next_draw()` and its run-log line go from all four classes. Day 11's mast is untouched.

**Measured** (`tests/probes/calm_pelican_day7_van_met.gd`, which holds the day 6 and the day 7 case, twelve walks each,
on main as #1548 built it and on the branch): the man shouting is seen on 9 walks (8 on main) and the van on 6 (8 on
main). The rigged row now joins her walk as one of the next two marbles handed out after the mark, so it can come up to
about 52 walking seconds later rather than at the mark. Of the five walks that never lay the van, three never lay it on
main either; on the two new ones its marble is handed out at 84 and 92 seconds of a 105-second walk, after which the
probe walks home by the shortest way, off the day's routes, where no siting lays anything. The just-ahead siting never
failed where it should have succeeded. The van's two fewer sightings meet, and do not cross, the stop Fable's design set
(more than two below the built row); Fable's review of this pull request judges it. `placement_rows.gd` prints the same
on main and the branch.

**Rejected:** a bag of one, the other reading of "the next draw will guarantee" (inbox #1520 in breezy-magpie), which
would lay the row at the next handout but makes the mark's row no marble of a chained bag of the size the player set
("2 or 3", inbox #586 in olive-hedgehog); and laying day 11's second mast just ahead too, which would delete the setting but
moves where a mast stands with no word of the player's asking for it (it belongs to freckled-penguin, rethink the masts,
if anywhere; Fable's design).
