# Playtest silky-lemur — Bugs the refactor surfaces are fixed, and the later days are judged by how hard their events are as well as how many

2026-11-17.

## #1450

1. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-13, answering the orchestrator's report on the dawn phases' second pull request (#1449), whose builder found that the code and the docs disagree about day 6's loudspeaker masts:

   > **A possible day-6 bug that predates the refactor:**
   > - **The code:** on the curfew day, every loudspeaker mast gets both its ordinary broadcast and the curfew announcement, which is half again stronger.
   > - **The catalogue and `docs/EVENTS.md`:** they say the announcement replaces the ordinary broadcast, but the catalogue also says the ordinary mast stays to draw the pole and lamp.
   > - **Effect:** if both broadcasts' fields act on her, day 6's masts hit harder than the docs say. Otherwise it's only loose wording.
   >
   > Should I spend a small Sonnet investigation on it? If it turns out to be a bug, it goes in the bug lane. Otherwise I'll leave it noted.

   The second line came a moment after the first, while the investigation was being set up. The code in question is `EventScheduler._place_masts()` (on `main`), `DawnMasts` after #1449, and the catalogue row `_curfew_announce()` in `src/events/event_catalogue.gd`.

2. **The note.**

   > yes, refactor surfacing bugs is a positive outcome

3. **The player's words.**

   > we need to fix those

4. **Read as:** (the assistant's interpretation, not the player's words)

   Investigate the day-6 masts; and a bug the refactor surfaces is fixed, in the bug lane, not only noted. Fixed to what the player decided for the thing (the records and playtests that built it), not to whichever of the code or the doc happens to read better.

5. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question curfew-stack (2026-11-13). The question as shown:

   - Question: on day 6, should the curfew announcement add to the loudspeaker masts' ordinary broadcast, or replace it? (built on my pick)
   - What happens today: on the curfew day every mast plans its ordinary broadcast (intensity 20) and the curfew announcement (30, fading over about 26 seconds) at the same spot. Both act on her, so for those seconds a mast hits at 50.
   - Add: nothing changes in play; the two "instead of" sentences become "on top of" (#1451, open).
   - Replace: the ordinary field turns off on day 6 while the mast still draws; a small bug-lane change in the masts' phase, with tests.
   - My pick: add. Day 6 is the day she is told of the curfew, so a brief, stronger broadcast fits it.

6. **The player's words.**

   > it felt fine during play so let's keep and change the wording instead

7. **Read as:** (the assistant's interpretation, not the player's words)

   Stacking stays (the day-6 announcement adds to the ordinary broadcast); the wording fix already merged as #1451, so nothing more is built for day 6's masts.

## #1454

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question bash-edit-gap (2026-11-13). The question as shown:

   - Question: should builders be stopped from editing files through the shell, so the rule that they read a file's skills before editing it always fires? (built on my pick)
   - The rule: a hook refuses an agent's first edit of an area of the code until it has read the skills that govern it (for example the balance rules before a balance number).
   - The gap: the hook only watches the edit tools. An agent that edits with sed or a script never meets it.
   - What it cost today: the timing switch (#1447) and the dawn phases' second pull request (#1449) skipped their skills that way; each review caught stale text, and each cost a round.
   - Fix A: one line in the agent contract: files are edited with the edit tools only. Cheap, but an agent can still slip.
   - Fix B: the hook also checks shell commands that write into the code folders. Holds for sure, more work.
   - My pick: A now; B only if it happens again. Nothing is built until you say.

2. **The note.**

   > how about just telling them to read first?

3. **Read as:** (the assistant's interpretation, not the player's words)

   Neither fix A nor fix B: the agent contract tells every agent to read, before its first change to a file, the skills that govern that file, whichever tool it edits with (the edit tools, sed, a script). No hook change and no ban on shell edits.

## #1455

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question balance-reach (2026-11-13). The question as shown:

   - Question: should the new files that now hold balance numbers come under the balance rules? (built on my pick)
   - The balance rules: before a number a player can feel is changed, the balance skill is read; a hook enforces it for a fixed list of files, the event scheduler among them.
   - What moved out of that list: the dawn phases' refactor moved numbers into new files the list does not name: the roadblocks' close-by distance and the location judge's two weights (#1448), the day the curfew is announced (#1449), and the park spoilers' three numbers (the third pull request, being built).
   - Yes: one small pull request adds those files to the hook, CLAUDE.md's table and the hook's own test.
   - No: those numbers can be changed without the balance skill being read.
   - My pick: yes, once the third pull request has merged, so the list is written once.

2. **The note.**

   > don't put it somewhere that is always read. the main goal of the files is that it becomes visible in a PR diff automatically which draws the attention if something changes. but also make sure they are named correctly so you are able to find them if needed

3. **Context** (the assistant's):

   Said in chat on 2026-11-13, after the orchestrator asked on the board's balance-reach Me line what "the files" meant. The orchestrator's reading there was that the numbers would move into tuning.gd and CLAUDE.md would not grow. The alternative it gave was that the numbers stay in the phase files and only the hook's list grows, which needs CLAUDE.md's table too. "The measurements table" is read as docs/COSTS.md. That table is generated by tools/cost-table.sh and checked by CI's cost-table job. Its header lists, one line each, the constants its figures are computed under, "so a change to any of them shows here as this line moving".

4. **The player's words.**

   > I thought you were talking about the measurements table? is that not it?

5. **Context** (the assistant's):

   Written on the Nappy board's balance-reach question on 2026-11-13. It answers the orchestrator's Me line, which had said the question was about the hook's file list and not the measurements table (docs/COSTS.md), and had offered COSTS.md header lines as a new pick. The original proposal on the board read: "Yes: one small pull request adds those files to the hook, CLAUDE.md's table and the hook's own test." The pick under it read: "yes, once the third pull request has merged, so the list is written once."

6. **The player's words.**

   > oh, my bad. I got that wrong. forget what I said. let's do your original proposal, then

7. **Read as:** (the assistant's interpretation, not the player's words)

   The original proposal stands, and the player withdraws the earlier words about an always-read place and the PR diff. One pull request, after the dawn phases' third PR (#1452) merges, adds the new files that hold balance numbers to the balance row of .claude/hooks/project-rules.sh, of CLAUDE.md's path table, and of tools/test_rules_hooks.sh. Those files are the roadblock ground judge and the location judge (#1448), dawn_masts.gd (#1449), and dawn_spoilers.gd (#1452). Nothing goes into docs/COSTS.md.

## #1456

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question walksiting-lift (2026-11-13). The question as shown:

   - Question: should the walk's siting (about 580 lines still inside the event scheduler) get a file of its own now, or when placement step 4 rewrites it? (built on my pick)
   - What it is: the code that places events as she walks (WalkSiting). The scheduler breakup gives every dawn phase a file, but names none for it.
   - Now: a fourth pull request moves 580 lines that step 4 then rewrites.
   - At step 4: it is lifted out as it is rewritten; until then the scheduler stays about 1,500 lines.
   - My pick: at step 4, the dawn phases' designer's proposal, since moving code about to change is work done twice.

2. **The note.**

   > yes, and make it so you can inject it which will allow for it to be mocked easily

3. **Read as:** (the assistant's interpretation, not the player's words)

   WalkSiting gets a file of its own at placement-by-construction step 4, as it is rewritten, not in a fourth dawn-phases PR; and the event scheduler is handed it (dependency injection), so a test of the scheduler can pass a mock in its place.

## #1460

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question long-routes (2026-11-14). The question as shown:

   - Question: in the new street-by-street draw, do the dog walker, the police patrol and the military convoy keep their long routes? (built on my pick)
   - What changes: placement step 2 draws each street, junction box, alley, park or square as one unit, the first time she comes near it. That way the day is the same whichever way she walks. A unit's draw can look only at its own unit and the units touching it.
   - The clash: three rows travel further than that. The dog walker's route is 30 tiles, the police patrol's 40 and the military convoy's 50, while a street is 8 tiles and a junction box 6. The far part of such a route lies in units its draw cannot see.
   - Cut, the designer's default: the route ends at the far side of the junction boxes at its street's two ends, at most 20 tiles, then leaves as any finished route does.
   - Keep, unchecked: full length, checked only against what its own draw sees.
   - Keep, at dawn: those three are placed at dawn by a phase of their own.
   - Changing later: one setting or one class, whichever is picked.
   - My pick: cut. It keeps every guarantee, and a shorter patrol still crosses her street. The pull request that builds it shows pictures of the three.

2. **The note.**

   > okay

3. **Context** (the assistant's):

   Written on the Nappy board, Main tab, question route-draw (2026-11-15), on its You line. The question as shown:

   - Question: may the three long-route events be drawn for the whole city as the day starts, before any street draws? (blocks the routes PR of the draw redesign)
   - What you asked: "everything that matters must be drawn together. if you draw a convoy that is 50 tiles you need to draw for all locations and segments along those 50 tiles at the same time" (inbox #1461).
   - The three events: the dog walker (a man walking a dog down a sidewalk, route 30 tiles), the police patrol (a patrol car driving its road, 40 tiles), the military convoy (trucks driving a road on days 13 and 14, 50 tiles). A street is 8 tiles; today their routes are cut to at most 13 tiles.
   - Taken literally: every street waits for every unit a 50-tile route it might draw could reach. Measured by the designer: 95 to 98% of the city draws as the day starts, 1.0 to 1.8 s, and nothing is left to draw as she walks.
   - Routes first: each street's first marble is drawn as the day starts, and only a dog walker, patrol or convoy can stand then, at full length. Everything along a route draws later, as she comes near, with the route already standing, so the two never contradict, though they are not drawn in the same instant.
     - A street a patrol or convoy drives holds nothing else; a sidewalk a dog walker walks holds nothing else.
     - Cost: 0.13 to 0.41 s at the day's start; about 40% of the city draws then, as today.
     - A patrol drives far enough again to reach her and let a man out, which the cut had made too short.
   - Keep the cut: routes stay at most 13 tiles, and a patrol never drives far enough to reach her and let a man out.
   - What it collides with: your ask to meet the dog walker "at least twice on day one" (PLAYTEST-05 6). Routes first makes the route events rarer: the design has about 3 dog walkers a day across the whole city. So the routes PR would also have to keep day one's dog walkers to that floor, which the design does not settle yet. The first PR keeps the floor: the dog walker stays an ordinary small marble there.
   - What waits: only the redesign's second PR, the routes. Its first PR (a marble drawn before it is placed, a unit of mixed views drawing from its most passable view's bag) does not depend on this answer.
   - My pick: routes first. It keeps the convoy and the patrol at full length and consistent with everything along them, at a fraction of the literal cost.

4. **The player's words.**

   > neither of these should be drawn at the beginning. they all should be drawn when the player is close by to guarantee an encounter. what is the purpose of making their route so long?

5. **Read as:** (the assistant's interpretation, not the player's words)

   The player's answer on route-draw (2026-11-15), "neither of these should be drawn at the beginning. they all should be drawn when the player is close by", rejects both options that draw at the day's start: the literal "drawn together" and routes first. The dog walker, the police patrol and the military convoy stay drawn by their street when she comes near, with their routes cut to the street and the junction boxes at its ends, as main has done since #1462. The draw redesign's PR 2 (the long routes drawn first at full length) is not built. Settled on the board the same day.

   Their question "what is the purpose of making their route so long?" was answered on the board: no record or playtest gives a reason for 30, 40 and 50 tiles (all set on 2026-08-26 with the rows' first versions). With the cut, no test or contract fails, and day one's dog walkers still arrive. Not yet measured: how often a cut patrol gets to stop and let a policeman out (from heat 3, within 150px along a clear line, only while still driving its route). A small PR fixes the three sentences the cut made untrue and measures that; a rare result goes back to the player.

6. **Context** (the assistant's):

   Said in chat on 2026-11-15, answering the orchestrator's explanation of "cut". The text answered, as shown:

   **What "cut" means:** in the catalogue, the police patrol's route is 40 tiles of road. Since #1462, a patrol drawn by a street doesn't drive that far. Its route stops at the far edge of the junction box at the end of its street, 6 to 13 tiles. A "cut patrol" is one whose route has been shortened that way.
   - **Why it matters:** a patrol can only stop and let a policeman out while it's still driving its route. A cut one drives about 4 seconds on average, against about 17 seconds at full length, so it has less time to pass close to her.
   - **The measurement:** the Opus builder working on the cut routes is counting how often a drawn patrol actually lets a man out, with the cut and without it. That's the number I said I didn't have yet.

   The player's earlier words on route-draw, appended above: "neither of these should be drawn at the beginning. they all should be drawn when the player is close by to guarantee an encounter. what is the purpose of making their route so long?"

7. **The player's words.**

   > a patrol can only stop and let a policeman out while it's still driving its route.  -- my whole answer to that point was -- why do you have such a route in the first place? just spawn in the car just ahead of the player? then you guarantee an encounter

8. **Read as:** (the assistant's interpretation, not the player's words)

   This replaces the reading appended above ("The dog walker, the police patrol and the military convoy stay drawn by their street when she comes near, with their routes cut…"), which misread "drawn when the player is close by" as the street draw main already does.

   The three route rows (the dog walker, the police patrol, the military convoy) are not laid on a route by a street's draw at all. When she comes near, each is put in the world just ahead of her, so that she is sure to meet it ("to guarantee an encounter"). "They all" in the route-draw answer names all three, so the same holds for the dog walker and the convoy, not only the patrol. The design's PR 2 (routes drawn first at full length) is still not built. The cut, and the whole-street size #1471 gives the patrol and the convoy, stand only until this is built. How far ahead, from which side, how often, and the warning a lethal one owes (as day 13's column, which is already created just off screen ahead of her, is warned of first) are the design's to work out from these words. Placement step 2, polite-tapir, `fable-only`: a Fable design.

9. **Context** (the assistant's):

   Said in chat on 2026-11-15, right after "why do you have such a route in the first place? just spawn in the car just ahead of the player? then you guarantee an encounter" (appended above), about the police patrol. It confirms the reading appended with those words: all three route rows (the dog walker, the police patrol, the military convoy) are put in the world just ahead of her when she comes near.

10. **The player's words.**

    > the same for the dog walker and the convoy

11. **Context** (the assistant's):

    Said in chat on 2026-11-15, right after "the same for the dog walker and the convoy" (appended above), while the orchestrator was correcting its reading that the three route rows stay drawn by a street on cut routes.

12. **The player's words.**

    > the route only matters *after* it was spawned

13. **Read as:** (the assistant's interpretation, not the player's words)

    No route is laid or judged before one of the three is put in the world. It is spawned just ahead of her, and only then does it get a route: the way it walks or drives on from that spot. So nothing about a route is drawn with the day or with a street; whatever the route must respect (her free line, other rows, the map) is settled at the moment it is spawned. For the Fable design of what step 2 still owes.

14. **Context** (the assistant's):

    Said in chat on 2026-11-15, right after "the route only matters *after* it was spawned" (appended above), about the dog walker, the police patrol and the military convoy, which are to be spawned just ahead of her.

15. **The player's words.**

    > and then only if the player follows them around

16. **Read as:** (the assistant's interpretation, not the player's words)

    After one of the three is spawned, its route matters only while she follows it around. The way it goes on is worked out as it goes, as far as she can follow it, and is never planned out to a fixed length in advance; once she stops following, where it goes is no longer the game's concern (it can leave once out of her sight). Builds on the reading appended with "the route only matters *after* it was spawned". For the Fable design of what step 2 still owes.

17. **Context** (the assistant's):

    Said in chat on 2026-11-15, right after "and then only if the player follows them around" (appended above), concluding the run of messages about the dog walker, the police patrol and the military convoy being spawned just ahead of her. It confirms the reading appended with that message: the route is worked out ad hoc, as the row goes, not planned in advance.

18. **The player's words.**

    > so the route can be ad-hoc

19. **Context** (the assistant's):

    Written on the Nappy board, Main tab, question sent-ahead-pace (2026-11-15), on its You line. The question as shown:

    - Question: when the dog walker, the police patrol and the military convoy are sent just ahead of her, should they come in place of some of what is sent at her today, or on top of it? (built on my pick)
    - What you asked: "just spawn in the car just ahead of the player? then you guarantee an encounter", and "the same for the dog walker and the convoy" (inbox #1460).
    - How the design does it: the event director, which already sends things at her from just off screen (the cat, the loose dog, the cyclist), sends the three too, from the same bag, at the same clock: one thing every 11 to 26 s of walking.
    - In the bag: the dog walker 9 marbles, the police patrol 6 (from day 4), the military convoy 4 (days 13 and 14), beside the cat's 5, the loose dog's 6 and the cyclist's 3.
    - In place of: same clock. She meets about as many things sent at her as today, and fewer of them are cats, loose dogs and cyclists.
    - On top of: a faster clock. The cats, loose dogs and cyclists stay as they are, and the three come on top, so more is sent at her overall.
    - Measured, now built on my pick (PR #1477, 12 seeds): she meets about as much as today (9.6 things sent at her a day against 9.7). Day one is mostly dog walkers: about 6 a walk, with cats and loose dogs at about half today's. By day 14: about 2 dog walkers, 2 police patrols and 1 military convoy a day, with cyclists at about a third of today's. A convoy comes at most once a day.
    - Changing later: one constant, the director's clock.
    - My pick: in place of. The day's count of moments stays what it is, and the mix can be tuned after the first playtest.

20. **The player's words.**

    > yes, that's correct

21. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: in place of. The dog walker, the police patrol and the military convoy are marbles of her route's bag at the director's unchanged clock, so she meets about as many things sent at her as before, and fewer of them are cats, loose dogs and cyclists. As PR #1477 builds it.

22. **Context** (the assistant's):

    The player's answer on the Nappy board, 2026-11-16, under the question `followed-convoy`, on its You line. The question as shown:

    - Question: when she follows the military convoy (the army truck sent down the road beside her on days 13 and 14), should it stay loud while she can see it, even if that ends her day? (built on my pick)
    - The case: the convoy now comes only from ahead. If she turns round when its badge goes up and walks away, it comes up behind her, and it stays loud beside her while she can see it.
    - Measured: about 226 to 240 meter points over about 21 s. The meter is 100, so that walk ends the day. Before the PR, the truck went quiet after its first leg, and the same walk cost 14 to 77. Walking past it the usual way costs 30 to 32 either way.
    - Keep it loud (my pick): following the truck is her choice, and stepping away from it stops the cost.
    - Quiet after its first leg: the truck still drives on while she sees it, but stops costing anything once its first stretch is done.

23. **The player's words.**

    > the lesson to learn is to step away (which is the original lesson from the fire truck) so yeah, it should end the day if she follows

24. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: keep it loud. A sent military convoy stays live, and costs her, as long as she can see it, so following it can end the day; stepping away is the lesson, as with the fire truck. PR #1487 builds this.

25. **Context** (the assistant's):

    The player's answer on the Nappy board, 2026-11-16, under the question `day3-charging-share`, on its You line. The question as shown:

    - Question: with the dog walker now in day 3's route bag, should the charging dog keep its share of the bag (2 in every 16 things sent at her), or stay at 2 marbles in a bigger bag? (built on my pick)
    - What changed: the dog walker is now sent ahead of her from the same bag. Day 3's bag grows to 25, so the 2 charging dogs become 2 in 25: about 1 in 12 things sent at her instead of 1 in 8.
    - Keep the share: the charging dog gets marbles enough for 2 in every 16 (about 3 in 25). Day 3 meets charging dogs as often as you set.
    - Keep the marbles: 2 charging dogs in the bigger bag; she meets about a third fewer on day 3.
    - My pick: keep the share.

26. **The player's words.**

    > sgtm

27. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: keep the share. Day 3's route bag gives the charging dog marbles enough for 2 in every 16 things sent at her (about 3 in 25), as #1477 built.

## #1461

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question line-reach (2026-11-14). The question as shown:

   - Question: may two events at opposite ends of a street, whose draws don't see each other, together leave her walked sidewalk with no free line through it? (built on my pick)
   - The rule today: the sidewalk she walks on a route street always keeps a free line, a way through with no cost. Every nearby event's reach is added up to check it.
   - What step 2 sees: a unit's draw sees only its own unit and the units touching it. Two rows in units at the two ends of a route street, each reaching three tiles or more into it, are never checked together.
   - Lethal events stay safe: a new rule refuses a lethal row any spot where its field would reach a unit its draw cannot see.
   - Leave it open, the designer's default: the probe that counts free lines runs before and after, and its numbers go on the pull request.
   - Close it: keep events' reach out of every route street beyond what the draw sees. That thins events near every route corner.
   - My pick: leave it open, and close it only if the probe shows free lines lost.

2. **The note.**

   > sure

3. **Context** (the assistant's):

   Said in chat on 2026-11-14, right after the player answered "sure" on the board's line-reach question. The design keeps the item's touching relation: a unit's draw looks only at its own unit and the units touching it, meaning those sharing a junction box or bordering the same alley, park or square.

4. **The player's words.**

   > in general you can look at more than just the adjacent units, no?

5. **Context** (the assistant's):

   Written on the Nappy board's line-reach question (2026-11-14), on the You line under the orchestrator's Me reply, which said the question settles with touching-reach. The question: "may two events at opposite ends of a street, whose draws don't see each other, together leave her walked sidewalk with no free line through it?" Context shown: a unit's draw sees only its own unit and the units touching it. Two rows in units at the two ends of a route street, each reaching three tiles or more into it, are never checked together. The design's unit is already one whole street (three sections, six sidewalk locations), plus junction boxes, alleys, and parks or squares as units of their own.

6. **The player's words.**

   > how about drawing an entire street at once instead of drawing each individually. that way you can plan out the full street in one go and you cannot get any contradictions

7. **Context** (the assistant's):

   Written on the Nappy board's touching-reach question (2026-11-14). The question: "should a unit's draw look further than the units touching it? (built on my pick)". Context shown:
   - The day stays the same on every path as long as the relation is symmetric, a draw reads only units in it, and the lower-ranked unit always draws first.
   - A wider relation pulls in far more units at once: with the item's relation, a median of 7 to 13 units per pull and at most 77 to 140, at 2 to 3 ms a unit.
   - Widened to about 270px it closes line-reach.
   - "a 50-tile convoy route would need a reach of about 50 tiles, which is close to drawing the whole city at dawn again. So long-routes stays cut either way."
   - My pick: PR 2 builds the item's relation, kept in one class so its reach is one setting; PR 3's probe prints the pull for both, and you decide on those numbers.

8. **The player's words.**

   > everything that matters must be drawn together. if you draw a convoy that is 50 tiles you need to draw for all locations and segments along those 50 tiles at the same time. that way you can control that there are no inconsistencies

9. **Context** (the assistant's):

   Said in chat on 2026-11-14, after the orchestrator's board reply on line-reach. That reply said a street is already drawn whole, all six sidewalk locations in one go, and that the case is an event in the junction box at the street's end, or on the next street, reaching into it. It said the "drawn together" answer under touching-reach covers it.

10. **The player's words.**

    > the rest of the street has a biased draw depending on what was already drawn at that street.

11. **Context** (the assistant's):

    Written on the Nappy board, Main tab, question free-line-density (2026-11-15), on its You line. The question as shown:

    - Question: the marble-first draw (#1471) loses the free line on 10 of 299 routes. The breaks sit at five places: four are density, one is the case you agreed to close (asked below, line-reach-close). For the density: merge it as it is, with step 3 checked against main's number, or add a rule in #1471 first? (blocks merging #1471)
    - The free line: on a route street, the sidewalk she walks keeps a way through with no cost. A probe counts the routes that keep it.
    - What you said (line-reach): "sure" to leaving open the case of two events in units whose draws don't see each other, and closing it only if the probe shows free lines lost (inbox #1461).
    - What the probe shows: main 294 of 299 routes keep the line, #1471 289. Counting a pacing event over its whole beat: 229 against 176. 24 planned days on 6 cities.
    - The cause: (corrected) at four of the five places the line breaks, rows from draws that see each other (one street, or two that touch) together leave no line. That is density: the new draw puts more events on sidewalks (14,010 → 17,735 placed). At the worst place (seven routes, one crossing), cafe tables and the man shouting, drawn by two neighbouring streets. An earlier version of this line named a leaf blower and an ice-cream van; they stand three blocks away and are not part of the cut.
    - Merge as it is: main already carries a denser day until step 3 (inbox #1464), whose one declared table is seeded from main's measured placements. Step 3's PR is checked against main's 294; if lines stay lost there, a street rule follows.
    - Rule first: #1471 gains a street rule now: a street's own draw keeps her walked sidewalk's line clear through its end junction box. Costs a build and review round, and thins events near route corners.
    - My pick: merge as it is. The loss is the density step 3 exists to fix, and you play nothing before the release.

12. **The player's words.**

    > I don't understand how can two draws cause such a situation?

13. **Context** (the assistant's):

    Written on the Nappy board, Main tab, question line-reach-close (2026-11-15), on its You line. The question as shown:

    - Question: the case you left open showed up once; close it, as your condition says, in the routes PR? (built on my pick)
    - What you said: leave open the case of two events in units whose draws don't see each other, and close it only if the probe shows free lines lost (inbox #1461, line-reach); later, "everything that matters must be drawn together" (inbox #1461, touching-reach).
    - What the probe shows: once in 24 planned days (seed 129517, day 1), a leaf blower and the man shouting stand at the two ends of a street she walks, drawn by two streets that don't touch. Each alone leaves her a free line; together, none. That route also has a second cut from one street's own rows, so closing the case saves no route by count.
    - Closing it: a unit's draw also sees every unit whose events could reach into the same route street, so its two ends are judged together. Measured by the designer: the day's start draws about 57% of the city instead of 40%, and events near route corners thin.
    - Where: the routes PR, which already widens what is drawn together (route-draw).
    - My pick: close it in the routes PR, as your condition says; it is what "drawn together" asks for anyway.

14. **The player's words.**

    > the musicians are drawn before the adjacent street so the street can make sure that it doesn't block the other sidewalk

15. **Context** (the assistant's):

    Said in chat on 2026-11-15, answering the orchestrator's report of its board reply on free-line-density. The text answered, as shown:

    - **`free-line-density`, which still blocks #1471:**
      - The two draws aren't the cause. Each of the draw's three line rules checks one piece, and none follows her line through a crossing. So they pass these rows even when one draw sees the other, or when both are judged together.
      - Example: cafe tables close the far sidewalk, and the man shouting's beat covers the corner where her sidewalk enters the crossing.
      - `main` has the same gap and loses 5 of 299 routes to it. #1471 loses more because it places more events.
      - New option C: merge #1471 as it is, then one PR before the release adds a rule that follows her line the way the free-line probe does. C is my pick.

    The board's option C read: "merge #1471 as it is, then one PR, part of polite-tapir and before the release, gives the draw one rule that follows her line the way the probe does, from the crossing onto her sidewalk, for every row that lands near her route."

16. **The player's words.**

    > C is my pick. -- sure

17. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: option C. PR #1471 (placement step 2, a marble is drawn before it is placed) merges as it is. Then one PR inside polite-tapir, before the release, gives the draw a rule that follows her line the way tests/probes/m129_zero_cost_line.gd floods it: from the junction box onto the sidewalk she walks, for every row that lands near her route. The three rules today (the junction rule, the walked-sidewalk rule, the pacing-opening rule) each check one piece and never follow the line through a junction box. The same PR builds the line-reach-close answer (c) recorded below.

18. **Context** (the assistant's):

    Said in chat on 2026-11-15, answering the orchestrator's report of its board reply on line-reach-close (the player's earlier words there: "the musicians are drawn before the adjacent street so the street can make sure that it doesn't block the other sidewalk"). The text answered, as shown:

    - **`line-reach-close`:** I asked which musicians you meant.
      - The street musician stands only in parks and squares, and he's in none of the five places the line breaks.
      - Today, which of two neighbouring units draws first is a coin toss (a hash of the day and the unit's name), not its kind.
      - The choices: (a) the street musician, (b) the leaf blower and the man shouting in that case, or (c) whatever a neighbouring unit drew first. My pick is (c), read with your note #1465 that a block on one sidewalk keeps the other sidewalk free. I'm recording no reading until you answer.

    The board's pick read: "c, read with #1465: a street drawing after its neighbours keeps one sidewalk open, given what they drew, built with option C's rule."

19. **The player's words.**

    > My pick is (c), -- sure

20. **Read as:** (the assistant's interpretation, not the player's words)

    "The musicians" means whatever a neighbouring unit drew before the street. A street that draws after its neighbours takes what they drew into account and keeps one of its sidewalks open: it does not block the other sidewalk (inbox #1465, "if one sidewalk is blocked then the other sidewalk cannot draw a block again"). Built in the same PR as free-line-density's option C, since both are rules a street's draw asks about what already stands next to it. The order in which units draw stays as built (by rank).

## #1464

1. **Context** (the assistant's):

   Written on the Nappy board's day-density question (2026-11-14). The question: "with the daily caps gone, the day nearly doubles. Does main carry that until step 3's declared table lands? (built on my pick)". The options shown:
   - Merge as it is (my pick): main carries the doubled day until step 3 merges, with no release before then, and step 3's Fable design starts as soon as PR 2 merges, beside PR 3.
   - Scale now: PR 2 scales each capped row's weight down to main's average.
   - Hold PR 2: nothing merges until step 3 is built on top of it.
   - My pick: merge as it is, with step 3 next beside PR 3. "Don't play-test main until step 3 lands; I'll say when."

2. **The note.**

   > I will only playtest after the refactor and follow up items are done (after the next release)

3. **Read as:** (the assistant's interpretation, not the player's words)

   The pick stands: #1462 merges as it is, and main carries the doubled day until step 3's declared table lands. The player plays nothing before the next release, which comes after the refactor and its follow-up items.

4. **The player's words.**

   > the release doesn't come after minty-quail

5. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-14, answering the orchestrator's status report. The report had said: "After polite-tapir, the queue's other refactor entry, minty-quail (one engine: the codebase refactored by layer, the escape a day spec), closes, and then the release you'll playtest."

6. **Read as:** (the assistant's interpretation, not the player's words)

   Read as: the next release does not follow straight on from the refactor (polite-tapir and minty-quail). It comes after the refactor's follow-up items too, as the player's earlier words on this note say ("after the refactor and follow up items are done"). The follow-up items are read as the entries queued to wait on the refactor, whose `after:` lines name minty-quail and polite-tapir. These words do not settle which of those count: the seven in the `now` band (spry-raven, amber-ibis, tawny-wombat, lilac-marten, snowy-goose, grassy-beaver, amber-puffin), or also sunny-osprey and golden-newt in `next`.

7. **The player's words.**

   > that's not a correction. it has been established a long time ago
   > what comes in the release?

8. **Context** (the assistant's):

   Said in the orchestrating session of 2026-11-14, right after the orchestrator appended the words above to this note as a correction, with a reading that listed every entry waiting on the refactor as the release's follow-up items.

9. **Read as:** (the assistant's interpretation, not the player's words)

   Read as: the release's contents were settled long ago and are recorded in the queue entry lilac-marten (curly-moose #803, minty-dolphin #834, gentle-owl #1231), and this replaces the reading appended just before it, whose list was wrong. The minor release (v0.30.0) waits for: the refactor (minty-quail and polite-tapir); snowy-goose, explosions in the escape city; all three items of lilac-marten (the fuller escape, the shorter charger warnings with a larger radius, the total time on the ending screens); and grassy-beaver, a day one that teaches. spry-raven, amber-ibis, tawny-wombat, amber-puffin, sunny-osprey and golden-newt also wait on the refactor but are not part of the release. It is cut only on the player's go-ahead in the session that cuts it.

10. **Context** (the assistant's):

    Written on the Nappy board, Main tab, question row-weights (2026-11-15), on its You line. The question as shown:

    - Question: may step 3's one pass also set a weight on each row that comes out more than twice as common, or as rare, on one kind of ground as on main? (built on my pick)
    - Context: what an answer needs.
    - Step 3: placement step 3, "one declared table replaces the fitted ones". The six fitted density tables go. One table of events per hundred locations, by view, kind of ground and act, is seeded once from main as it stood on 2026-11-09, and one probe run scales a view that comes out off. You agreed to this as option (b) of the design review (inbox #1268).
    - Found: the Fable designer built it as a throwaway on #1471's head, over 18 cities and 14 days. After the one pass the day's total is right: 99.2 events a city-day, as on main then. Some rows are not: the abduction comes 2.7 times as often as on main, and protests a seventh as often in the crossings.
    - Why: the daily caps used to hold four rows down: the abduction, the charging dog, the chatting mother and the military convoy. The caps are gone, and each row's catalogue weight was tuned with them in place.
    - Option A: the same run that scales the views also sets a weight on a row, on the one kind of ground where it is off from main by more than a factor of two. Twelve weights, set once, written on the catalogue rows, never refitted.
    - Option B: touch no row. The counts above stand until a playtest says otherwise, as you said the real test comes from playtests (inbox #1268).
    - Option C: seed every row's weight from main: about forty fitted numbers on the catalogue. Closest to main, and the most like the fitted tables you wanted gone.
    - Changing later: twelve numbers on catalogue rows, and nothing else rests on them. Step 3 is built only after #1471 merges, so your answer can still come before it is written.
    - My pick: A. Abductions at 2.7 times main's rate would skew the first playtest after the release, and twelve declared numbers set once are not a chain of tables tuned against each other.

11. **The player's words.**

    > I've never seen an abduction during play. so I don't mind a higher rate. is that option B?

12. **Context** (the assistant's):

    Said in chat on 2026-11-15, answering the orchestrator's report of its board reply on row-weights (the player's earlier words there: "I've never seen an abduction during play. so I don't mind a higher rate. is that option B?"). The board reply as shown:

    - Me: yes, B is "touch no row". But B leaves every row as it comes out, not only the abduction. These rows are off by more than a factor of two:
      - Streets: the abduction (a van whose two men get out and hunt her; a catch ends the day) 4.3 times main's share; the charging dog 3.6 times; the chatting mother 2.6 times; the military convoy (days 13 and 14) 12 times; the delivery van, the poster crew and the roadblock under half.
      - Junction boxes: the abduction 2.2 times; the charging dog 2.2 times; the chatting mother 5 times; the military convoy 17 times; the protest (the crowd a resistance task sends her to stand in) a fifth.
      - Parks and squares: the charging dog, the leaf blower, the market stall, the pigeons and the poster crew 2.5 to 8 times, each still a few hundredths of a ground where the street musician is nine tenths.
      - How measured: each row's share of the events on that kind of ground, on the designer's run before the one pass, against main on 2026-11-09. The question's 2.7 times and a seventh counted events after the pass, so the figures differ.
      - Option D: A without the abduction's two weights: ten weights. The abduction stands higher, as you don't mind; the convoy, the protest and the rest come back to main's share.
      - My pick: D. A convoy on days 13 and 14 twelve times as often, and protests a fifth as often in the crossings, would show in the first playtest after the release.

    The chat report's line answered: "`row-weights`: answered earlier this turn; option D is my pick."

13. **The player's words.**

    > option D is my pick. -- okay

14. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: option D for placement step 3 ("one declared table replaces the fitted ones"). The one pass sets a weight on a row, on a kind of ground where its share is off from main on 2026-11-09 by more than a factor of two, set once and never refitted, except the abduction: its two weights (street 0.23, junction box 0.45 in the design's table) are not set, so the abduction stands higher than on main. The other weights in the design's section 5.2 stand.

15. **Context** (the assistant's):

    The player's answer on the Nappy board, 2026-11-16, under the question `box-rows-after-the-pass`, on its You line. The question as shown:

    - Question: after the dog walker, the police patrol and the military convoy stopped being drawn into the day (they are sent just ahead of her now), which rows should take their place in the junction boxes? (built on my pick)
    - The branch's reading (a row's share among the rows a box still draws): charging dog 5.0 a city-day (2.2 on the 2026-11-09 build; in the junction boxes 3.9 against 1.2); chatting mother 4.2 (2.0); unmarked van 7.7 (2.3); delivery van, poster crew, reversing lorry and roadblock back at 1.0 to 1.3 times; whole day 93.3 (102.8); day 14 is 1.11 times day 1 (1.28).
    - The other reading (a row's share against the whole seed): charging dog 2.9 (in the junction boxes 1.9); chatting mother 3.6; unmarked van 10.8; the four street rows at 0.7 to 0.9 times; whole day 98.4; day 14 is 1.14 times day 1. One event per block holds under both.
    - My pick, the other reading: it brings the charging dog much closer to its old share, and the whole day and the ramp closer to the old build too. Its cost: the unmarked van rises further and the street rows sit a little under.

16. **The player's words.**

    > okay

17. **Read as:** (the assistant's interpretation, not the player's words)

    Settled: the other reading. Placement step 3's one pass reads a row's share against the whole seed, so the junction boxes' share of the three sent rows is not handed whole to the rows a box still draws. PR #1488 applies it.

18. **Context** (the assistant's):

    The player's answer on the Nappy board (Main tab), question `late-days-denser`, as asked:
    - Question: with the declared table, late days are barely denser than early ones. Raise the later acts' density now, or wait for the refactor's end re-measure? (built on my pick)
    - What you said: day one relatively easy is okay "if the difficulty increases" (PLAYTEST-05 5); and a refactor step is accepted when its suites pass and what moved is listed, with one re-measure at the end (inbox #813 in curly-moose).
    - What moved (PR #1488, merged): day 14 places on average 1.14 times day 1's events, against 1.28 on the 2026-11-09 build. Across ten cities: on main before it, 8 of 10 had day 14 at least a fifth over day 1; now 4 of 10, and on 2 day 14 places fewer than day 1. Later days still bring the nastier rows (the vans, the hunting guards), so difficulty still rises; it is the count of things that barely does.
    - Wait for the end re-measure (my pick): it is listed there now, and steps 4 and 5 still change where things stand. Then, if still flat, the later acts' cells of the declared table are raised by declaration (the table is meant to be edited that way).
    - Raise them now: a small PR raising acts III and IV's cells so day 14 is about 1.25 to 1.3 times day 1 again; steps 4 and 5 may move it once more.
    - Changing later: a few numbers in one data file.

19. **The player's words.**

    > sure, we can do that. but also event density is not the only way to tweak difficulty. events themselves are also more difficult to deal with

20. **Read as:** (the assistant's interpretation, not the player's words)

    Settled on the pick: nothing is raised now, and the end re-measure judges whether the later days are hard enough. That judgment counts how hard the later days' events are to deal with (the nastier rows that arrive later), not only how many events each day places. The later acts' cells of the declared table are raised by declaration only if the later days still read as too easy with both counted.

## #1466

1. **Context** (the assistant's):

   Said in chat on 2026-11-14, in the run of messages about placement step 2's unit draw (after #1465). How a unit draws today (PR 2, #1462, merged): `LocationDraw` takes a unit's locations in an order shuffled on the unit's own stream, a street's sections first (the designer's choice 3). For each location in turn it draws a marble from the bag of that location's view and judges it there. A row the earlier draws make invalid is left out.

2. **The note.**

   > also don't immediately tie a draw to a position. like if you always draw the top left first there will be a bias for that position. what you should do instead is do the draw and then depending on what it is place it in the street and draw more

3. **Read as:** (the assistant's interpretation, not the player's words)

   A unit draws a marble first, then places it on the location in the unit that suits what it is, if any does. Then it draws the next marble, which is judged against what is already placed. This repeats until the unit's locations are filled or its bag runs out, rather than walking the locations in an order and drawing one marble for each. Open for the design: which view's bag a marble comes from when a unit's locations have different views, and what happens to a marble no location takes.

4. **Context** (the assistant's):

   Said in chat on 2026-11-14, right after the words above on this note ("don't immediately tie a draw to a position"). A street unit is three sections (segments), each with a sidewalk location on either side, six locations in all.

5. **The player's words.**

   > if the draw takes up the whole street you're done. if it takes an entire segment you need to do at least two more draws and when everything is drawn you can place them in the street

6. **Read as:** (the assistant's interpretation, not the player's words)

   Each drawn marble takes up a share of the street: the whole street, one whole segment, or less. The street keeps drawing until its space is spoken for. A marble that takes the whole street ends it at once; one that takes a segment leaves two segments, so at least two more draws follow. Only when the draws are done is everything placed in the street, together. So a street's contents are decided as a set first and positioned after.

7. **Context** (the assistant's):

   Said in chat on 2026-11-14, answering the open point the orchestrator named after the words above: how marbles smaller than a segment add up to fill one.

8. **The player's words.**

   > if you draw a marble that is smaller than a segment you need to draw another one (with a filter to only include also small marbles)

9. **Read as:** (the assistant's interpretation, not the player's words)

   A marble smaller than a segment leaves the rest of that segment to fill. The next draw for it comes from the same bag filtered to the small marbles only, the ones that fit what is left, so a segment is filled by small marbles or by one segment-sized marble, never a mix that overruns it.

10. **Context** (the assistant's):

    Said in chat on 2026-11-14, answering which bag a unit draws from when its locations have different views. Context shown: a street's view is decided per street (Corridor.view_of()), so its six sidewalk locations share one. A park's or square's view is decided per cell (Corridor.view_of_ground()), so a park cut a route runs through is on the route while the rest of the park is route-adjacent or off the route. The orchestrator's pick was that each view's part draws from that view's bag.

11. **The player's words.**

    > the more permissive (in terms of traversability) view gets priority

12. **Read as:** (the assistant's interpretation, not the player's words)

    A unit whose locations have different views draws all of them from the bag of the view that keeps her way most passable: on the route before route-adjacent before off the route. A park a route cuts through draws from the on-route bag. This replaces the orchestrator's pick of one bag per view's part.

13. **Context** (the assistant's):

    Said in chat on 2026-11-14, two messages in a row, right after "the more permissive (in terms of traversability) view gets priority". Read with it, they offer a second way: the most permissive view decides which marbles are valid, rather than the unit drawing from its bag. The player leaves the choice to whichever is easier to implement.

14. **The player's words.**

    > or gets to decide which marbles are valid

15. **The player's words.**

    > whichever is easier to implement

16. **Read as:** (the assistant's interpretation, not the player's words)

    Either the unit draws from the bag of its most permissive view, or that view filters which marbles are valid. The designer picks whichever is simpler to build and says which.

17. **Context** (the assistant's):

    Said in chat on 2026-11-14, right after "whichever is easier to implement", on how the most permissive view decides a mixed unit's marbles.

18. **The player's words.**

    > you could do a capabilities approach allows_blocks allows_... but I think that's overkill

19. **Read as:** (the assistant's interpretation, not the player's words)

    A view described by capabilities (allows_blocks and the like) is an option the player names and sets aside as overkill. The design uses one of the two simpler ways above, and reaches for capabilities only if both fail, saying why.

## #1467

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question route-overlay (2026-11-14). The question: "should the developer view get a layer that draws each event's own route, so a change to routes can be shown in pictures? (built on my pick)". My pick: build it, and merge #1462 without route pictures. The Me line before the answer said: built on my pick and merged as #1463; debug layer 7 (key 7, `--layers 7`) draws each live event's route in pink, from a dot at its start to a square at its end.

2. **The note.**

   > okay

## #1474

1. **Context** (the assistant's):

   Said in chat on 2026-11-15, three messages in a row, after the orchestrating session (a background job) had three times asked the player to run a `cp` copying a Fable design out of the job's scratch folder (`~/.claude/jobs/<job>/tmp`, deleted when the job ends) into `.claude/briefs/designs/`.

   The orchestrator's answers, as shown:
   - To the first: "I can, and I should have." Its Write and Edit tools are refused in the shared checkout, and an early copy into `.claude/briefs/designs/` was refused, so it had handed copies to the player since. Small Python scripts writing into the shared checkout had gone through all along. It would copy design files itself from then on.
   - To the second: the folder is the background job's scratch space, `~/.claude/jobs/2641961b/tmp`, deleted with the job. It had put briefs, probe output and design files there because the job's setup says temporary files go there. A design is meant to last and belongs in `.claude/briefs/designs/` from the start. "From now on designers write straight to `.claude/briefs/designs/`, and if that's refused I copy the file there by script myself. Scratch is only for throwaway work: briefs for one-off agents, probe output, and patch scripts."

   "okay please do" answered the second.

2. **The note.**

   > why can't you copy yourself?
   >
   > why did you write them in the global claude folder?
   >
   > okay please do

3. **Read as:** (the assistant's interpretation, not the player's words)

   A design, and anything a later agent or session reads (its probe outputs, the scripts a builder reruns), is written to `.claude/briefs/designs/` from the start, never to a session's scratch folder (`$CLAUDE_JOB_DIR/tmp`, deleted with the job). The orchestrator copies a file there itself, by script where its edit tools are refused, and never asks the player to. Done on 2026-11-15 for the three placement designs and their evidence. The rule goes into the orchestrating skill, as a fix to a gap, flagged to the player.

## #1491

1. **Context** (the assistant's):

   Said in chat on 2026-11-16, answering the board question `roadblock-off-her-routes`, which read:

   - Question: on a street none of her routes runs along, should a roadblock still close the street fully, as you asked in September? (built on my pick)
   - What you said in September: "close the street fully" (PLAYTEST-135 7), because she could walk round every roadblock on one sidewalk. Queued as M199 (the roadblock closes its whole street), band now, not built yet.
   - What you said today: one sidewalk has to be open, and the roadblock is sized to one sidewalk plus the road (inbox #1465, filed as spry-plover). That is being built now as downy-llama.
   - The overlap: the one-sidewalk rule only binds the streets her routes run along. Off them, nothing needs a sidewalk open.
   - Both hold (my pick): on her routes' streets a roadblock is one sidewalk plus the road; off them it closes the whole street, as M199 asks. Cost: the roadblock gets two widths by where it stands, and M199 stays queued to build the second.
   - Today's answer replaces M199: every roadblock is one sidewalk plus the road, wherever it stands, and M199 is dropped.

   The player's quoted phrase is M199's title.

2. **The note.**

   > "the roadblock closes its whole street", there are two kinds of roadblocks. one that is open and one that is closing the street.

3. **Read as:** (the assistant's interpretation, not the player's words)

   M199 stands, as a second kind of roadblock: an open roadblock (its band covers its own sidewalk and the road, downy-llama) and a closing roadblock (its band closes the whole street, M199). They are two kinds, not one row whose width depends on where it stands. Where the closing kind may stand follows the rules already built: the one-sidewalk rule refuses it on the streets her routes run along, so it stands off them.

## #1501

1. **Context** (the assistant's):

   Said in the orchestrating session on 2026-11-17, in answer to the orchestrator's report that PR #1500 (eleven owed decision records, five of them polite-tapir's) carries the `fable-only` label because polite-tapir is a fable-only entry, and so would wait for a Fable review in the next session, since the player had ruled out more Fable work for the rest of this session. The label's rule (playtest-feedback): every pull request that builds an item of a `fable-only: true` entry carries the label; Fable designs the code and reviews it, and the Fable designer decides whether the coding is handed to a lower model.

2. **The note.**

   > let's change the fable only label to let opus do the review

3. **Read as:** (the assistant's interpretation, not the player's words)

   The review half of the `fable-only` rule changes: a pull request carrying the label may be reviewed by Opus instead of Fable. The design half stays as it is (Fable designs, and decides who codes). It applies to every fable-only entry from now on, and so lets PR #1500 be reviewed by Opus now.

4. **Context** (the assistant's):

   Said right after the words above, while the orchestrator was briefing an agent to rewrite the label's rule. The rule as it stands: Fable designs the code and reviews it, and the Fable designer decides whether the coding is too complex to hand off, writing it itself if so and otherwise handing it to the lowest model that can do it.

5. **The player's words.**

   > also fable is only allowed to write down the design -- no implementation and no review -- it needs to provide enough context for both in its design

6. **Read as:** (the assistant's interpretation, not the player's words)

   On a `fable-only` entry, Fable's part is the written design alone. It never writes the code and never reviews it, so the clause that let the Fable designer code a part too complex to hand off goes. The code goes to another model, and the review to Opus. The design carries enough context for the builder to implement it and for the reviewer to review it. This replaces the first reading on this note (that the design half stayed as it was).

7. **Context** (the assistant's):

   Said in answer to the orchestrator's report of its reading: "on `fable-only` work, Fable only writes the design, with enough context to build it and to review it. Another model writes the code and Opus does the review. Fable no longer codes a part it judges too complex to hand off."

8. **The player's words.**

   > that means it cannot decide to do those things by itself either

9. **Read as:** (the assistant's interpretation, not the player's words)

   "Those things" are implementing and reviewing. Fable may not take either up on its own judgment, not even for a part it judges too complex to hand off. No exception remains for it to invoke. The choice of who codes and who reviews is not Fable's: the orchestrator picks the builder's model, and the review is Opus's.

## #1504

1. **Context** (the assistant's):

   The player's answer on the Nappy board (Main tab), question `fable-outside-the-label`, 2026-11-17, as asked:
   - Question: does "Fable only writes the design, never the code or the review" hold for every design Fable writes, or only for work under the fable-only label? (built on my pick)
   - What you said today (inbox #1501): Opus may review fable-only work; Fable writes only the design, with enough context for building and reviewing it, and cannot decide to code or review it itself. My read-back said "on fable-only work".
   - What it meets: an older rule of yours, separate from the label: when Fable designed something, Fable reviews it (grassy-trout #1299, statement 9, confirmed as permanent in #1303). It covers Fable designs outside the label too, for example a planning task given to Fable because it was hard.
   - Only fable-only work (my pick): the label's work follows today's rule; a Fable design outside the label is still reviewed by Fable under the older rule. Nothing older is overturned without your word.
   - Every Fable design: Fable never codes or reviews anything; the older rule goes, and Opus reviews every Fable design.
   - Changing later: one row of the model table in the orchestrating skill and a sentence beside it.

2. **The note.**

   > every fable work item

3. **Read as:** (the assistant's interpretation, not the player's words)

   The second option: the rule of inbox #1501 holds for every piece of work Fable takes part in, under the fable-only label or not. Fable writes only the design, with enough context to build and to review it; it never writes code or reviews, and cannot decide to. The older rule that Fable reviews what Fable designed (grassy-trout #1299, statement 9) is overturned by the player's word here, and Opus reviews every Fable design.
