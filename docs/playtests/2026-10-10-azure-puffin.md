# Playtest azure-puffin — Bollards close the road, the chalk is in the alley, the park is cordoned, and day 9 on is looser

2026-10-10.

Said in a session after playing `main` at v0.26.1 plus #660, captured into the inbox as they were
said, and two answers to questions the session asked.

## #664 — five findings from playing

The note, [issue #664](https://github.com/JosuaKrause/nappy/issues/664):

> I did some playtesting. 1) let's add the bollards back. it will make the middle of the road
> impassable when going from street to pedestrian road. that's okay. this is intended 2) I take it
> the policeman chase hasn't been released yet. I was chased by police cars still which is just
> silly. 3) let's move the chalk mark one tile into the alley so I actually have to enter the alley
> to activate it 4) when the guard houses are set up the city gets much harder to navigate let's
> loosen the density of the hard blocking events in that case. let's treat every street from that
> day on as if it was on a path (but keep the path calculations still the same for connectedness,
> distances, routing etc) 5) the guarded barriers disappear after shaking off the pursuer. that
> doesn't make sense.

The session then asked about point 4 (the agent's side, as it was posted with the answer):

> Asked about point 4: the guard huts are the region doors' gatehouses, from day 9. Read literally,
> "treat every street from that day on as if it was on a path" means from day 9 no seals (the
> barrier today put on every street off the day's route tree), no road closures (placed only off
> the tree), and wall-type events weighted as on a path everywhere; the region walls and gatehouses
> stay, routing unchanged. Options: "Literal: all three (Recommended)", "Seals only", "Seals and
> closures".

The player's answer:

> fewer of all three. gatehouses stay and remain on the actual paths

**Filed as:**

- Point 1: [cozy-lemur](../todo/2026-10-10-cozy-lemur/README.md), the bollards close the
  carriageway at a precinct's mouth.
- Point 2: no entry. The policeman on foot is sandy-ferret, a torn poster's pursuit is instant, on
  foot, built in PR #663 and not yet merged or released when this was played, so the police car
  still chased her on the build the player had.
- Point 3: [feathery-hare](../todo/2026-10-10-feathery-hare/README.md), the chalk mark stands one
  tile into its alley.
- Point 4: [bouncy-egret](../todo/2026-10-10-bouncy-egret/README.md), from the gatehouse day on,
  fewer hard blockers.
- Point 5: a re-report, added to
  [spotted-wombat](../todo/2026-10-07-spotted-wombat/README.md), the guard leaves a steady barrier
  behind.

## #665 — L and R on the joystick buttons

The note, [issue #665](https://github.com/JosuaKrause/nappy/issues/665):

> in the start screen add a little L and R to the two joystick buttons to make it clear that they
> lead to different settings

**Filed as:** [spry-pelican](../todo/2026-10-10-spry-pelican/README.md), the title's two joystick
buttons say L and R.

## #666 — the park closing is not diegetic

The note, [issue #666](https://github.com/JosuaKrause/nappy/issues/666):

> the park "closing down" is not diegetic -- the material changes in front of the player. we need
> to think of a better effect there

The session then offered three effects (the agent's side, as it was posted with the answer):

> Asked: day 12's park today turns grass to churned mud a ring at a time from the edges in, over
> 12s once she reaches the swing (NARRATIVE: "the parks are being fenced off… she gets the key out
> as the park is taken"). Three diegetic versions of the same shrinking:
> A. Diggers churn it — small excavators/rollers drive in from the edges and the mud is their
> tracks; the mechanic stays exactly as it is (recommended).
> B. A police line sweeps in — officers walk in from the edges stringing tape behind them, the
> park's people pushed out ahead of them; fits the late crackdown, adds a new crowd of figures.
> C. A fence crew closes the gates — workers put up panels round the edge; the danger becomes
> being shut in rather than losing ground, a mechanic change.

The player's answer:

> (B) for the park with the added danger that you can get trapped inside (which would end the day).
> the policemen must come from offscreen

The session then asked how the line closes, since a line sweeping in from every edge at once
leaves her no way out once it starts (the agent's side, as it was posted with the answer):

> Asked: with option B and being trapped, a police line sweeping in from every edge at once leaves
> her no way out once it starts, so how should the police close the park? Options: "Cordon closes
> round the edge (Recommended)" — officers walk in from offscreen to the park's edge and tape it
> one stretch at a time, working round from where they arrived, while others walk the park's
> people out; the open part of the edge shrinks to a last gap, and if that gap is taped while she
> is inside, the day ends; the ground stays grass. "Line sweeps from one side" — a line enters on
> one side and crosses the park taping behind it; caught before leaving by the far edge ends the
> day. "Sweep from all edges, gates last" — today's rings from the edges in as police lines, gates
> open until the line passes them.

The player's answer:

> Cordon closes round the edge (Recommended)

**Filed as:** [plush-marten](../todo/2026-10-10-plush-marten/README.md), day 12's park is closed
by a police cordon.

## #667 — leaving a gatehouse

The note, [issue #667](https://github.com/JosuaKrause/nappy/issues/667):

> oh and there is a bug when leaving the guard huts that the player keeps moving in the previous
> direction. let's reset the movement to 0 when leaving so the player has a choice.

**Filed as:** [downy-lark](../todo/2026-10-10-downy-lark/README.md), leaving a gatehouse, she
stands still.
