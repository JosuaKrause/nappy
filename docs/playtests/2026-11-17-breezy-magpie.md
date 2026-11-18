# Playtest breezy-magpie — The three board answers on placement step 4 and the bug band

2026-11-17 (the board read on 2026-11-18 UTC).

The player's answers on the Nappy board to its three open questions: which band a bug the refactor
finds is filed in, where day 6's second man shouting and day 7's second van land after the mark, and
whether a beat may change what the unit it lands in draws. Each note opens with the question as it
stood on the board.

## #1519

1. **Context** (the assistant's):

   The player's answer on the Nappy board (Main tab), on its You line under the question `refactor-bug-band`, read on 2026-11-18. The question as it stood on the board:

   refactor-bug-band
   **Question:** when a refactor step finds a bug (the code does something your decisions say it should not), which band is its entry filed in? (built on my pick)
   **Context:** what an answer needs.
   **What you said (silky-lemur #1450):** to my "If it turns out to be a bug, it goes in the bug lane. Otherwise I'll leave it noted." about day 6's masts, you said "yes, refactor surfacing bugs is a positive outcome", then "we need to fix those".
   **What it meets:** your rule that an entry is filed bug only when you name it (mossy-ferret #710). Your "yes" answered a sentence that named the lane for that one case.
   **bug**** for every such bug:** it starts at once, ahead of everything, beside the refactor.
   **The band you give each one (my pick):** each bug is an entry of its own, filed now; you move one to bug when you want it ahead of everything. Nothing is filed bug on my reading.
   **Changing later:** one sentence in the rule the spotted-trout entry writes (a bug the refactor surfaces is fixed, never only noted).

2. **The note.**

   > bug is higher than now. bug is a bug. what would be the point of bug band if you'd never use it?

## #1520

1. **Context** (the assistant's):

   The player's answer on the Nappy board (Main tab), on its You line under the question `beats-on-her-street`, read on 2026-11-18. The question as it stood on the board:

   beats-on-her-street
   **Question:** after she reads day 6's mark, where does the second man shouting land, and after day 7's mark the second delivery van: on the street she is walking just out of view, or in the next stretch of city not yet filled in ahead of her? (blocks polite-tapir step 4's last pull request)
   **Context:** what an answer needs.
   **What you said:** after the mark, a second man shouting is guaranteed within the next events (olive-koala 2), and day 7's mark does the same with a van. You approved the design review's step 4 (inbox #1268): every beat her walk places takes "a location in the next undrawn unit ahead of her, before it draws". A unit is one street, junction box, alley or park, filled in all at once as she comes near.
   **The collision:** the units round her are filled in before she gets there, so "the next undrawn unit" is at least 900px ahead, ten to fifteen seconds of walking. Today these two beats stand on her own street just out of view, 312 to 889px away: seen on 8 of 12 walks (the man) and 9 of 12 (the van). They were moved there because the far band did not work: the man was seen on 1 of 12, the van on 0 of 12 (records sandy-magpie, olive-badger-2).
   **The item's letter:** both land in the next unfilled unit, like day 3's fire. One rule for every beat. Cost: met about as rarely as the far band measured, and a van rarely finds room on a street her routes run along.
   **On her street (my pick):** both take the nearest free spot ahead of her on the street she is walking, out of view, as today, but chosen by location instead of the old random roll. Cost: these two are the exception to "before it draws".
   **What is built meanwhile:** the first three pull requests keep today's place for both; the item's letter is one change in the last pull request.
   **Changing later:** one method and two tests.

2. **The note.**

   > the draw doesn't have to happen at the point where she touches the mark. the bag gets the biased bag in front (via the chained bags mechanism) and the next draw (whenever that happens) will guarantee the shouting man

## #1521

1. **Context** (the assistant's):

   The player's answer on the Nappy board (Main tab), on its You line under the question `beat-changes-its-unit`, read on 2026-11-18. The question as it stood on the board:

   beat-changes-its-unit
   **Question:** may a beat (day 3's fire, a poster crew, day 11's added mast) change what the unit it lands in draws round it, so that on a retry walked another way the two or three units round each beat hold different rows? (blocks polite-tapir step 4's last pull request)
   **Context:** what an answer needs.
   **What you said:** a retry is "the same day exactly how the player encountered it the first time this run. exact same state at the beginning of the day" (PLAYTEST-119 27), and a retried day 3's fire is sited "from the walk she takes then" (PLAYTEST-119 26). You agreed to drawing a whole street at once, seeded by the day and the street, "so a street holds the same events whatever her path", and approved step 4's "a location in the next undrawn unit ahead of her, before it draws" (inbox #1268).
   **The collision:** if a beat takes its spot before its unit draws, the unit draws one thing fewer and keeps clear of the beat, and so do the units touching it. Walk a retry another way and the fire lands elsewhere, so those few units differ from the first attempt. Every other unit is the same, and the day's start is the same.
   **Yes, the item's mechanism (my pick):** a beat is a marble like any other; nothing is drawn mid-look to make room for it (the worst frame on main, 983 ms, goes), and a beat is never refused for what a unit drew round an empty spot.
   **No:** a beat stands only where a filled-in unit left a spot empty, as today. Every unit draws the same whatever her path. Cost: "before it draws" is not built, a unit with no empty spot refuses the beat until she walks on, and the units keep drawing during a siting.
   **What is built meanwhile:** the first three pull requests are the same either way.
   **Changing later:** the last pull request, built or not.

2. **The note.**

   > repeating the day has the exact same preconditions. if the player does something differently different things might happen. if the player were to do exactly the same everything would behave exactly the same. beats are marbles, yes
