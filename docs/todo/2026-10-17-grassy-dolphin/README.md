priority: bug

# grassy-dolphin — The escape's fire, steam and city route work again · filed 2026-10-17

[fluffy-kestrel](../../playtests/2026-10-17-fluffy-kestrel.md), #741, "Escape is broken":

> The fire in the house moved one floor down from what it was before breaking the escape sequence left right left which existed before. The steam should have a stronger impact. In the city there is no route that is available and no guidance markers on the road

Three things the player found in the escape, the finale after the last day, each an item:

- **The fire is one floor lower than it was**, which breaks the left, right, left order the escape
  had. Where the fire stands is said by its words and `InteriorScene.inner_floor_approaches()`
  ([M165, the escape after the corrected stairs](../../decisions/2026-09-19-M165-the-escape-after-the-corrected-stairs.md)).
  The fire goes back to the floor it was on, and the commit that moved it is named.
- **The steam has a stronger impact.** The basement's steam is the timing puzzle the player asked
  for in [PLAYTEST-85](../../playtests/PLAYTEST-85.md) ("have multiple fixed locations with steam
  that fully block the path and have them turn off an on in different intervals so it becomes a
  timing puzzle"). Whether its impact fell with a recent change or was always this weak is still
  to be found; **how much stronger, and in what way** (a larger cost, a wider block, a block that
  holds her rather than one she walks through) is open, and goes to the player with today's numbers
  before it is built.
- **The city section has a route and its guidance markers.** In the escape's city section the
  player found no route available and no guidance markers on the road; both come back, and the
  commit that lost them is named.

*Proposed, not asked for:* one entry for the note, with the three as items, since they were
reported together and may share a cause.

Items: [the-fire-is-on-its-floor.md](the-fire-is-on-its-floor.md),
[the-steam-hits-harder.md](the-steam-hits-harder.md),
[the-city-section-has-a-route.md](the-city-section-has-a-route.md).
