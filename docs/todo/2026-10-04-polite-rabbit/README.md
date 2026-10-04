priority: now

# polite-rabbit — Nothing reaches her through a wall · filed 2026-10-04

[freckled-goose, the robber through a wall](../../playtests/2026-10-04-freckled-goose.md) files
inbox #544 in [freckled-goose](../../playtests/2026-10-04-freckled-goose.md), from playing the released v0.24.0 on a phone:

> The new robber reach is worse in a way I just got killed by a robber that was behind a wall. He couldn't reach me. But it was instant

> Even then the distance would not physically connect so counting it as caught would be unfair. Only if the Robert touches the player should it end instantly

> Also excitement shouldn't go up behind a wall at least

**Asked for:** the robber ("Robert" in the note) ends her day only when he touches her, never from
the far side of a wall; and excitement does not rise from behind a wall.

**What exists.** A catch is `EventInstance.is_lethal_at()`: the straight-line distance from him to
her against `def.lethal_reach()` (26px for the alley robber since
[tall-osprey](../../decisions/2026-09-27-tall-osprey.md), his lunge stand-off 116px), with no
question about what lies between. His chase already stops at walls:
[M54](../../decisions/2026-08-31-M54-the-resistance-says-something-and-the-robber-stops-at-walls-not-started.md)
slides each chase step along an unwalkable tile ([PLAYTEST-16](../../playtests/PLAYTEST-16.md),
finding 8: "he can run through walls"). An event's excitement falls off with straight-line
distance too (`Tuning.falloff()` in the field sums), through buildings alike.

**Every source, blocked from the middle of the wall** (inbox #554, answering whether it is the
robber's field only or every source's):

> Excitement should not go through any wall but it's not straightforward. If the player is partially in a wall they should not be protected so the blocking should happen in the middle of the wall (or one tile deep)

So no source's excitement reaches her through a building, and grazing a building's edge shields
nothing: the line counts as blocked only once it passes the middle of the wall, or one tile deep.

The catch through a wall is built ([polite-rabbit](../../decisions/2026-10-04-polite-rabbit.md));
what is left is the excitement half, waiting on its scope.
