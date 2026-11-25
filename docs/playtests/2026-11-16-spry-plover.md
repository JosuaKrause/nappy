# Playtest spry-plover — A street that must keep a sidewalk open is drawn so it does, and the roadblock covers one sidewalk and the road

2026-11-16.

## #1465

1. **Context** (the assistant's):

   Said in chat on 2026-11-14, right after "the rest of the street has a biased draw depending on what was already drawn at that street", while placement step 2 (each street drawn as one unit the first time she comes near it) was being discussed. The rules today: on a street a route uses, the sidewalk she walks keeps a free line, and a van may stand only on the far side (RouteSidewalkRule). In the escape, each street of the walk keeps one sidewalk open (WalkOpenRule, DaySpec.keeps_the_walk_open). Nothing stops two blocks facing each other across any other street of an ordinary day.

2. **The note.**

   > if one sidewalk is blocked then the other sidewalk cannot draw a block again

3. **Read as:** (the assistant's interpretation, not the player's words)

   On every street of every day, a block on one sidewalk keeps the other sidewalk free of blocks, where a block is a body she cannot pass, as RouteSidewalkRule and WalkOpenRule already count it. So every street keeps one sidewalk she can walk. The escape's rule is extended to ordinary days, built as a street rule the unit draw asks, since a street's two sidewalks draw together.

4. **Context** (the assistant's):

   Written on the Nappy board, Main tab, question open-sidewalk-reach (2026-11-15), on its You line. The question as shown:

   - Question: does the rule that one sidewalk of a street stays walkable past bodies hold on streets far from her routes too? (blocks that part of the rule)
   - What you said (#1465): "if one sidewalk is blocked then the other sidewalk cannot draw a block again" (2026-11-14, while each street's draw was being discussed).
   - What it collides with: PLAYTEST-17 (M50): "areas that outside the paths should have blocking events all over — we don't want the player to step in those areas and it ranges from very costly to deadly". Today, streets off her routes can have walls on both sidewalks.
   - Every street: your words taken literally. Off-route streets always keep one sidewalk she can walk past bodies, so those areas are softer than M50 asked.
   - Near her routes only: streets her routes use and the streets touching them keep one walkable sidewalk; further off, blocking events all over stays as it is.
   - What waits: only the setting for which streets the rule covers. The rule itself is built now, set to near her routes, since that undoes nothing you asked for.
   - Changing later: one setting.
   - My pick: near her routes only. It keeps M50's denied ground and still gives every street she might sensibly take an open sidewalk.

5. **The player's words.**

   > what I said was *if* a street needs to have one sidewalk walkable *then* the placement of the drawn events needs to make sure of that

6. **Read as:** (the assistant's interpretation, not the player's words)

   This corrects the orchestrator's earlier reading of #1465 ("On every street of every day, a block on one sidewalk keeps the other sidewalk free of blocks"). #1465 does not make one walkable sidewalk a requirement of any street. It says that where a street is already required to keep one sidewalk walkable, the draw that places its events makes sure of it by construction, rather than leaving it to chance or a later repair. The streets with that requirement today: her routes' own streets (the sidewalk she walks keeps its free line, and a roadblock on her route leaves one sidewalk open, woolly-penguin "one sidewalk must be open if they're en-route"), and the escape's walk (its own rule). Streets off her routes, and the route-adjacent ones, keep PLAYTEST-17's blocking events all over. For PR #1476: the one-sidewalk rule covers only the streets a rule requires to stay walkable, not the route-adjacent view.

7. **Context** (the assistant's):

   The player's question on the Nappy board, 2026-11-16, under the question `heated-roadblock-body`, on its You line. The question as shown: "from heat 4, when the checkpoint guard at a roadblock hunts, does a roadblock on one of her routes' streets still leave one sidewalk open? (built on my pick)". The heading's word "heated" was the orchestrator's shorthand; the player asks what it means. Answered on the board's Me line.

8. **The player's words.**

   > what is a heated roadblock?

9. **Context** (the assistant's):

   The player's reply on the Nappy board, 2026-11-16, under the question `heated-roadblock-body`, on its second You line. It follows the orchestrator's Me line explaining "heated": the heat is how many resistance tasks she has done (0 to 5); the roadblock is the police barrier band across a street with a checkpoint guard at his post beside it; below heat 4 the guard only stands there; from heat 4 he leaves the post and runs at her when she comes near, and catching her within 86px ends the day. The question: does a roadblock on one of her routes' streets still count as leaving the far sidewalk open (the orchestrator's pick, the band as its body), or does the guard's 86px reach count as closing both sidewalks, which takes every roadblock off her routes' streets once she has done four tasks?

10. **The player's words.**

    > are the roadblocks predominantly on one side of the street? if more than half the street is open in a contiguous opening it counts as open even if the player has to bait the guard away

11. **Read as:** (the assistant's interpretation, not the player's words)

    A rule for what "open" means for the one-sidewalk rule: a street counts as open when more than half of its width is one contiguous opening, even where she has to bait the hunting guard away to pass. So the hunting guard's catch reach does not by itself close the street; the roadblock's band, and how much of the street it leaves in one piece, decides it. The player also asks whether roadblocks stand mostly on one side of the street; that is answered on the board from the code.

12. **Context** (the assistant's):

    The player's answer in the chat, 2026-11-16, to the board question `roadblock-opening`, as shown:

    - Question: a roadblock leaves only about a quarter of the street open in one piece. By your "more than half" rule, should a roadblock then stand on her routes' streets at all? (built on my pick)
    - Is it on one side? Mostly, yes, but it is wide. A street is 192px across: sidewalk 64, road 64, sidewalk 64. The roadblock stands in one lane, and its concrete band reaches 60px either way across the street, so it covers its own sidewalk and the whole road. What stays open is the far sidewalk, about 52 of its 64px: about a quarter of the street.
    - Keep one sidewalk as open (my pick): the far sidewalk counts, as your one-sidewalk rule says, so roadblocks keep standing on her routes and she squeezes past on the far side, baiting the guard if he hunts.
    - More than half, literally: no roadblock stands on her routes' streets at any heat, only beside them, unless the band is narrowed to one sidewalk and part of the road.
    - Changing later: one function in the street rules, or the band's width in the catalogue.

13. **The player's words.**

    > okay let's use the one sidewalk has to be open and match the roadblocks size to one sidewalk + road

14. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: the one-sidewalk rule stands (a roadblock on her routes' streets must leave one sidewalk open), and the roadblock's concrete band is resized to cover exactly its own sidewalk and the road (128px of the 192px street), leaving the far sidewalk whole (64px) rather than about 52px of it. To be built as a change to the roadblock row's band and its siting.
