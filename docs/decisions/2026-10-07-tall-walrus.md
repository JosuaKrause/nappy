# tall-walrus — A precinct's post is a body, and the gaps between posts let her through · 2026-10-10

[Azure-koala](../playtests/2026-10-07-azure-koala.md), finding 3, inbox #601:

> bollards on the pedestrian zone do not block the player

Asked whether each post stops her with the gaps and sidewalks passable, or the row bars passage
(inbox #648 in [leafy-puffin](../playtests/2026-10-10-leafy-puffin.md)): "gaps still passable".

**Each post is a body.** A bollard `Prop` carries a `StaticBody2D` whose circle is the post's own
`GroundShape`, 4.8px, the shadow's 0.4 of the 12px picture, so the body, the shadow and the drawn
ground contact are one shape ([M61](2026-09-10-M61-one-shape-per-object-the-shape-the-shadow-and-the-body.md)).
Trees, sacks and piles stay without a body. Posts are circles, so walking into one off-centre
slides her sideways toward the gap or the pavement; head-on, she stops.

**The posts stand 40px apart, two on the 64px carriageway band, where
[M53, the bollard](2026-09-08-M53-the-bollard.md) stood five 14px apart.** With bodies, M53's
spacing leaves 4.4px between two posts against her 28px body (`Tuning.PLAYER_BODY_RADIUS`, 14px),
so "gaps still passable" cannot hold at five posts: the band fits at most two posts with a gap she
passes. At 40px the clear gap is 30.4px, 2.4px of slack. The other answer, five posts barring the
band with only the pavements open, is the one the player did not choose. *Open to overturn, and
the player's to judge by eye:* whether two posts still read as a street closed on purpose, which
is what M53 drew them for; the review item [tall-walrus](../review/2026-10-07-tall-walrus.md) asks.

**No route changes.** The posts stand only on the carriageway band; the pavements either side have
no body and no tile the planner uses is covered, and the post-row checks in `tests/test_generator.gd`
hold. Built in PR #656: `tests/test_bollards.gd` sweeps her real body and pram circles with
`move_and_collide` through the posts `City.bollard_positions` places on a generated map: a post stops
her, the gap between two posts and the pavement beside the row let her pass, and every gap on six
seeds holds her body. On `main` the post case, the post's body and the gap clearance fail. The
stills are in [bollards-2026-10-10](../evidence/bollards-2026-10-10/): stopped at a post, through
the gap, past on the pavement, and the first two with the collision outlines drawn.
