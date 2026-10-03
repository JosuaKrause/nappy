priority: now

# feathery-marmot — A task's target is near its mark, and touching it completes it · filed 2026-10-03

> "the arrow correctly points to the van but touching the van doesn't solve the task. also, the van
> should spawn close to the mark not across the city. lastly, the robber should be 2/3rds through
> the alley not pressed against the edge of it" · "this applies to almost all tasks"

[minty-hedgehog](../../playtests/2026-10-03-minty-hedgehog.md), statement 3 (note #432 and the player's comment on it). Three asks:

1. **Touching the van completes the task.** Since M222 (PR #414) the red arrow ends on the van, but
   the touch point is `_reachable_offset()` in `src/resistance/resistance_director.gd`: one random
   bearing 72px from the van's centre (its `obstructs_radius` 22 + `PLAYER_BODY_RADIUS` 14 +
   `ContactPoint.REACH` 36), completing within 36px of that point, so touching any other side
   fails. Day 8's burnt shell used the same offset; PR #415 changes day 8 to the burnt building's
   door with a radius covering half the sidewalk (sandy-egret). **Proposed, not asked for:** the
   same for every task that rides an object with a body, so touching it from any reachable side
   completes it; the player confirmed "almost all tasks" only for where a target is placed (ask 2).
2. **A task's target is placed near its mark, for nearly every task** — the player's "this applies
   to almost all tasks" is read as where a target is drawn, and the player confirmed it ("yes your
   read matches"). `_place()` picks the van, doors, masts, swings and the station door each from a
   city-wide pool (`_pick_reachable`), with no limit on distance to the mark; the M181 record left
   "day 11's mast is a random reachable one and can be the map's corner" open with the player, and
   this is the answer. Targets whose place is fixed keep it: day 12's swing park, day 14's station
   door, day 9's district door and day 10's neighbor (his timed walk home).
3. **The robber stands about two-thirds through the alley, not at its edge**, "so the robber is not
   at the edge of the alley which makes him easier visible and easier to avoid", and keeps M213's
   floor: "touching the mark shouldn't wake him from the correct side and if the alley is long
   enough" — at least 176px from the mark (his 140px `pursues_within` plus the 36px reach).
   **Open question, for whoever picks this up:** where he stands in an alley too short for both;
   the filer's proposal is as far in as the floor allows. This replaces M213's "on the far end tile, or up
   to three tiles in" (from PLAYTEST-142's "always place the [robber] at the other end of the
   alley"), which the PR quotes.

**This answers part of a review item.** `docs/review/2026-09-26-M213.md` asked whether "Day 7's red
arrow ends on the van": yes ("the arrow correctly points to the van"); and its day-6 robber "at the
far end" is replaced here.

**Proposed, not asked for:** "near its mark" as within the mark's own block or the next one, its
distance a number the builder measures and names; and whether two-thirds applies in a courtyard
passage, where M213 keeps him at the courtyard's inner end (crisp-moose), is left as M213 has it.
