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

**The posts stand 46px apart, two on the 64px carriageway band, 9px in from each edge, where
[M53, the bollard](2026-09-08-M53-the-bollard.md) stood five 14px apart.** What has to pass is her
body (`Tuning.PLAYER_BODY_RADIUS`, 14px) and the pram's 8px circle, held 14px out along her facing,
which follows the input rather than her velocity: holding a diagonal she is up to 2 × 14 + 8 =
36px across the row. M53's spacing leaves 4.4px between two posts, so "gaps still passable" cannot
hold at five posts, and the band fits at most two posts with a gap she passes. At 46px the clear
gap is 36.4px; at 40px (30.4px) a walk through the gap's middle facing 45° off her way stops at
the row. The other answer, five posts barring the
band with only the pavements open, is the one the player did not choose. *Open to overturn, and
the player's to judge by eye:* whether two posts still read as a street closed on purpose, which
is what M53 drew them for; the review item [tall-walrus](../review/2026-10-07-tall-walrus.md) asks.

**No route changes.** The posts stand only on the carriageway band; the pavements either side have
no body and no tile the planner uses is covered, and the post-row checks in `tests/test_generator.gd`
hold. Built in PR #656: `tests/test_bollards.gd` sweeps her real body and pram circles with
`move_and_collide` through the posts `City.bollard_positions` places on a generated map: a post stops
her, the gap between two posts lets her pass facing straight through and turned 30° and 45° either
way, the pavement beside the row lets her pass, a held diagonal from seven offsets along the row
gets her past it, and every gap on six seeds clears 36px. On `main` the post case, the post's body
and the gap clearance fail. The stills are in [bollards-2026-10-10](../evidence/bollards-2026-10-10/):
stopped walking south at a post, through the 46px gap, walking the pavement beside the row, and the
first two with the collision outlines drawn.

**What the player sees at the stop**: the pram is drawn about 24px ahead of her, so walking into a
post east, west or north the pram picture covers the post where its circle stops her; only walking
south does the post stay in view. Crowd walkers have no bodies and still walk through the posts.
