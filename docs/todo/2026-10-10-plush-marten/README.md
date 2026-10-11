priority: now

# plush-marten — Day 12's park is closed by a police cordon · filed 2026-10-10

[azure-puffin](../../playtests/2026-10-10-azure-puffin.md), inbox #666:

> the park "closing down" is not diegetic -- the material changes in front of the player. we need
> to think of a better effect there

Offered three effects (A, diggers churning the grass in from the edges; B, a police line sweeping
in from the edges and stringing tape behind it, the park's people pushed out; C, a fence crew
closing the gates), the player answered:

> (B) for the park with the added danger that you can get trapped inside (which would end the day).
> the policemen must come from offscreen

and, asked how the police close it since a line from every edge at once leaves her no way out,
chose "Cordon closes round the edge (Recommended)": officers walk in from offscreen to the park's
edge and tape it one stretch at a time, working round from where they arrived, while others walk
the park's people out; the open part of the edge shrinks to a last gap, and if that gap is taped
while she is inside, the day ends; the ground stays grass.

This replaces the closing `docs/NARRATIVE.md` describes for day 12 ("its grass going to mud from
the edges in") and `Tuning.PARK_CLOSING_SECONDS`'s ring-at-a-time mud in
`src/resistance/happenings.gd`. The work is [the-cordon.md](the-cordon.md).
