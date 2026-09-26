## The decisions that govern the next milestones

Taken at the end of the M16/M18 session and easy to miss, because they are decisions rather
than code. All of them are written up in `PLAYTEST-02.md` (decisions 9–14).

1. **The beginning is challenging too.** Not extremely difficult, but a player who never
   meets danger never learns to deal with it. The measurement below says act I and act II
   currently cost nothing at all, and "the early game teaches events are safe, then act III
   kills you" is the worst of both. **M19 has to make an act I street cost something.**
   *(Done, and then some: M19 gave the street bodies and M27 put three or four times as many
   of them where she is looking. Whether act I now costs too much is the open question, and it
   is the one a human has to answer — see the fourteen seconds above.)*
2. **Difficulty is self-selected through the extra quests.** The resistance is the dial. That
   is why the base game has to be hard on its own — the dial *adds* difficulty, it does not
   supply it. Consequence: "how visible should the resistance be" stopped being a curiosity.
   A player who never finds the dial is locked to the easiest setting and never told there
   was one.
3. **The act I/II numbers are set from data, not argument.** Build the mechanisms (M19), ship
   telemetry (M23), read real runs, then pitch. This made M23 a gate rather than a
   recommendation, which is why it went first. **The gate is open** — M19's balance half is
   now waiting on runs, not on code.
4. **Telemetry is an ordered log, not a metrics dump** — what happened, in what order,
   readable top to bottom with no tool. It records what the code *cannot* recompute, above all
   the **random outcomes that branch a run** (a one-shot that fired, a block arc that
   advanced, an alley trap that was set): those depend on run history, so no seed reproduces
   them. Anything derivable from the seed, `Tuning` or the catalogue stays out. *(Shipped in
   M23; [TELEMETRY.md](../TELEMETRY.md) is the version to work from now.)*
5. **The resistance stays hidden and loses its key.** *(Closes an open question carried since
   M8.)* No marker, no quest log — wanting the difficulty dial and finding it are the same
   behaviour. But `E` appears in exactly one line of the game, so the hold becomes automatic
   on proximity: the cost was always standing still in an alley, never the keypress. M26.

   **Overturned by the player on 2026-08-31, and only the first half of it.** *(Playtest 16, finding
   7: "I'm not sure if I ever did the resistance. I walked on one chalk symbol once but there was no
   indication at the end of the day or any guidance what to do next. During the day brief there
   should be instructions from the chalk marks to tell me what the next task is. Only the first
   encounter (the chalk mark) should come without hint.")* This is the first playtest ever to reach
   a chalk mark, so it is the risk in *"Things deliberately not done"* being run — *"a player may
   finish a run never knowing the good ending existed"* — and not paying off.

   What survives is decision 2 and the **first encounter**: finding the dial is still the player's
   own doing, with no hint at all, deliberately including the HUD line that exists today. What is
   overturned is everything after it — once she has found a mark, the resistance speaks to her in
   the day brief. See M54.
