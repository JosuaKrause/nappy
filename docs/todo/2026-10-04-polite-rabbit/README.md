priority: now

# polite-rabbit — Nothing reaches her through a wall · filed 2026-10-04

[freckled-goose, the robber through a wall](../../playtests/2026-10-04-freckled-goose.md) files
inbox #544, from playing the released v0.24.0 on a phone:

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

**Open, for whoever picks this up:** "excitement shouldn't go up behind a wall at least" is read
two ways: the robber's field only, or every source's field (a man shouting, a dog, traffic) when a
building stands between them and her. The second changes what every route costs and falls under
the **balance** rules; ask the player which before building it.

**Proposed, not asked for:**

- "Touches her" read as: his body and hers in contact, which is the existing catch reach with a
  clear line between them added, so no catch across a wall, a building corner or a fence; the 26px
  is not changed.
- "Behind a wall" read as: the straight line between him and her crossing an unwalkable tile.
- The lunge from behind a wall: he does not start a lunge at her across a wall either, since the
  lunge ends in a catch.
