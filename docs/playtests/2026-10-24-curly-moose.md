# Playtest curly-moose — A day one that teaches, the sound tools, and the notes since the refactor began

2026-10-24.

## #803

1. **Context** (the assistant's):

   Said right after v0.29.1 shipped, the release with PR #801 (the escape's city draws one danger or nothing per street from one marble bag of 10 army trucks, 8 explosions, 3 unmarked vans, 2 roadblocks and 1 empty; record 2026-10-18-downy-tapir-2) and PR #800 (the baby is handed the city's world after the building). The open review item docs/review/2026-10-18-downy-tapir.md asks whether that bag is still the climax or should be two draws a street. "The charging" is the waiting chargers that warn before they come at her (the roadblock guard, the stairwell guard and the other waiting chargers given one radius each in PR #781). Queue order today: minty-quail (the refactor by layer) next, then snowy-goose (explosions in the escape city).

2. **The note.**

   > for after the refactor: the escape is basically empty now. the charging timins are off -- the warnings should be shorter and the radii slightly larger. the end screen doesn't show the total game time -- only the current day's completion time. *all* end screens must show both

3. **Read as:** (the assistant's interpretation, not the player's words)

   Three things, all to be done after minty-quail: (1) the escape's city is now too empty — more dangers than the v0.29.1 bag places (bears on the open review item docs/review/2026-10-18-downy-tapir.md); (2) every waiting charger's warning is shorter and its radius slightly larger; (3) every end screen, win or loss, day or escape, shows both the day's completion time and the total game time.

4. **Context** (the assistant's):

   The player's answer to the agent's reading of this note. The first paragraph answers the reading "every waiting charger warns for less time and notices her from slightly farther away; these are the ones that warn before coming at her, such as the roadblock guard and the stairwell guard" (the note's context block wrongly named the roadblock guard and the stairwell guard as the chargers meant). The second answers "every end screen shows both the day's completion time and the total game time, win or loss, day or escape".

5. **The player's words.**

   > how could you misinterpret my statement this badly? I'm not talking about the stairwell guard (it is the exception to the regular warning anyway). I'm talking about *every* charger in the game
   >
   > what do you mean "day or escape"? I'm talking about *ending* screens *not* day/scene completion screens (those keep their segment's time)

6. **Read as:** (the assistant's interpretation, not the player's words)

   Replaces the note's first reading of points (2) and (3). (2) Every charger in the game, not only the waiting ones, gets a shorter warning and a slightly larger radius; the stairwell guard is the exception to the regular warning and is not what this is about. (3) The screens that end the game (not the screens that complete a day or a scene) show the total game time as well as their segment's time; a day's or a scene's completion screen keeps its segment's time only.

7. **Context** (the assistant's):

   Asked what the escape roadblock guard's timing is, the agent answered: he notices her within 180px of the band (Tuning.HEAT_HUNTS_WITHIN, the radius a roadblock's guard gets at the heat where it hunts), warns for 2.0s with his hand raised while she stays inside (Tuning.CHARGER_WARNING, which every waiting charger reads), then charges at 130px/s (HEAT_HUNTS_SPEED) for up to 30s; she walks at 92px/s and runs at 168px/s. The player's reply follows.

8. **The player's words.**

   > yes 180px is way too small and 2s is too long -- *in general*

9. **Context** (the assistant's):

   Said on 2026-10-19 while minty-quail's first PR (#806, the test runner lets frames pass between suites) was in revision. The released version is v0.29.1. Queue order: minty-quail (the refactor by layer), then snowy-goose (explosions in the escape city, from minty-lemur #785), with this note's three fixes for after the refactor.

10. **The player's words.**

    > After the refactor and the fixes from the last playtest let's cut a minor release

11. **Read as:** (the assistant's interpretation, not the player's words)

    Once minty-quail is closed and this note's fixes have landed (the escape's city fuller; every charger's warning shorter and its radius larger; the screens that end the game show the total game time), cut a minor release, v0.30.0. This is the player's go-ahead for that release when those are done. Open: whether snowy-goose, also from the last playtest file (minty-lemur), is among "the fixes" the release waits for.

## #813

1. **The note.**

   > let's do remeasuring at the very end and not get blocked by it during the refactor
   >
   > for the refactor test parity is enough

2. **Context** (the assistant's):

   Said in session on 2026-10-19 about minty-quail (one engine: the codebase refactored by layer), after the orchestrator said some steps change behavior on purpose (world passability, escape as a day spec, world map, escape placement) and so need more than the existing tests to verify.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Each refactor step is done when the existing tests pass on it, moved to the new seams where the code moved (test parity). No measurement sweeps per step (winnability across seeds, route costs, GoatCounter comparison, cost tables, pictures of behavior that changed); they are collected into one remeasuring step after the last refactor item.

4. **The player's words.**

   > once the refactor is done let's rewrite the tests with dependency injection and through public APIs

5. **Read as:** (the assistant's interpretation, not the player's words)

   Read as: tests-public-seams.md (tests drive public seams with injected fakes) moves from "with each extraction" to one pass after the last refactor item, alongside the remeasuring. During the refactor a test is changed only as far as parity needs.

6. **The player's words.**

   > you can also do it as a bit with each step as long as the final result is the same

7. **Read as:** (the assistant's interpretation, not the player's words)

   Read as: converting tests to injected fakes and public APIs is allowed within a step where it is convenient, not required; the pass after the refactor finishes whatever is left, so the end state is every test on public APIs with injected dependencies.

## #819

1. **Context** (the assistant's):

   Said on 2026-10-24 after the GoatCounter and Reddit read since 2026-10-19 (saved as docs/stats/2026-10-24-goatcounter.md): of 10 fresh runs, day 1 had 12 attempts and 1 win (8%, against 31% over the three weeks before), so most new players stopped on day 1. A commenter on the player's r/ClaudeGameDev post (2026-10-20) said, in rough summary, that from the starting block they could not tell which way led to calm ground, and suggested a first-day line of text pointing at the yellow-tinted safe sidewalks. The player then said they have ideas of their own for day 1 to discuss; those will be appended to this note.

2. **The note.**

   > I agree that we need a better day one experience but I don't think the "warm pavement" line is it.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Day 1 needs to be easier for a new player to read (which way leads to calm ground), and a line of text naming the tinted sidewalks is not the fix. The fix itself is open until the player's ideas are discussed.

4. **Context** (the assistant's):

   Said on 2026-10-24, the start of the discussion this note was opened for, before any proposal from the orchestrator. "The pavement" is the yellow-tinted safe sidewalks that mark the cost-free routes to a calm area.

5. **The player's words.**

   > we need a proper day one tutorial. we have a day 3 run tutorial which works well so I'm confident we can pull it off for day 1, too. what is the goal that we want the player to learn at day one? a) they should go to a park to get the baby sleeping b) they should avoid objects that cause noise c) they should turn around when there is a deadend / both sidewalks are blocked d) they should cross the street when one sidewalk is blocked e) they should time their approach for moving obstacles f) they cannot go the same way every day..
   > I deliberately don't focus on the pavement since the pavement itself is an attempt to patch up issues from getting lost. there are multiple options and tools in our toolbox but I also want you to come up with some ideas that we can discuss.
   > toolbox:
   > - we can place hints in the world (eg a street sign pointing in the right direction)
   > - we can use on screen text (eg "this street seems to be blocked let's turn around")
   > - we can handcraft day 1 to force a certain order of events (still within a generated city; just manipulating spawn order)
   > - we can get rid of the two bars and replace them with a more obvious indicator (eg diegetic face)
   > - we can use more subtle hints (eg make the pavement more obvious by eg also adding fallen leaves or something)
   > - we can have some NPC walking towards a park that the player can follow
   >
   > some ideas. also think about some yourself. let's discuss the pros and cons of each

6. **Context** (the assistant's):

   Said on 2026-10-24 right after the day-one tutorial goals and toolbox above, while the orchestrator was gathering context for the discussion.

7. **The player's words.**

   > maybe also do some research on psychology (or whatever field is best here) to see whether there are some techniques we could use

8. **Context** (the assistant's):

   The player's answers, point by point, to the orchestrator's day-one proposal after the onboarding research (2026-10-24). The proposal: day 1 teaches (a) a park makes her sleep, (b) avoid noise, (d) cross where one sidewalk is blocked, as one hand-crafted sequence of spawns (noise on a wide sidewalk, noise with less room, one sidewalk blocked so she crosses, then the park); (c) turning back at a dead end and (e) timing traffic move to day 2, the loud car accident comes off day 1; a fellow mother with a pram walks ahead to the park for the player to follow; an opening shot (the camera starts on the park and glides to her door, skippable); a moving cue toward the park at each junction; one line of on-screen text at the twist, as the mother's own thought; a thought bubble with an icon over the mother (the orchestrator's own idea); a reacting face over the pram added beside the two bars (the excitement and sleepiness meters); freezing on what caused a loss before the retry; GoatCounter events for day-1 milestones (first obstacle passed, first crossing, park reached, asleep, home) and watching new players. Open questions asked: whether signs and moving cues exist only on days 1-2, whether the player wants the fellow mother. "We already have a fellow mother but she's an obstacle" is the chatting mother, an existing event.

9. **The player's words.**

   > 1) let's hand craft
   > 2) also, let's have one park relatively close
   > 3) that also teaches day two to go somewhere else (player can just retry the same path again and will find the park blocked)
   > 4) following NPC let's explore that
   > 5) sign at junctions if they're in a way that can stay across all days
   > 6) on-screen text -- when it becomes relevant otherwise players will forget and it will make the intro a slog. we want to start right into the action -- but also see below
   > 7) thought bubbles -- I really like that idea for immediate feedback especially since it doesn't need reading. it can be a direction to a park (on day 1), a hint to avoid an obstacle, a hint to cross the street, a hint to turn around, etc.
   > 8) I don't want to add the face yet especially if also keeping the bars. I don't want the UI to be cluttered and also take away more visual space
   > 9) dead end in day 2 sounds good as well
   > 10) showing what causes a loss is also a good idea -- show not tell
   > 11) agree with the goat measuring
   > 12) I'm not convinced of the opening shot yet but I can see how it could work. with a closeby park. we could have the camera on the park for a brief moment then follow the desired path back to the home then start. allow skipping. is the opening shot only on day one? should we use it every day to highlight parks that are open? maybe that makes a fellow mother obsolete. we already have a fellow mother but she's an obstacle. so we don't need two types with different purpose which makes it unclear whether approaching is good or not

10. **Context** (the assistant's):

    The player's answer to the orchestrator's follow-up on 2026-10-24: drop the NPC to follow (the chatting mother is already an obstacle, so a guide mother would blur whether approaching someone is good or bad); an opening shot on day 1 (the camera rests on the nearby park, follows the intended path back to her door, skippable, skipped on a retry) and on days 2 and on a quick glance at which parks are open with no path; thought bubbles over the mother as the main voice (a tree and a direction to a park, an obstacle crossed out, an arrow across the street, a U-turn), on-screen text kept for the rare moment an icon cannot say it, the bubble distinct from the danger exclamation mark; park signs at junctions kept on all days, saying where a park is, not whether it is open; the day-one entry as day 1 hand-crafted with a close park, bubbles, signs, text only when relevant, freezing on the cause of a loss, the opening shot, GoatCounter milestones, the dead end and traffic timing on day 2, no face, no NPC to follow; the sound and art ideas as their own entry. "File everything" answers the question whether to file the batch #819, #823, #826 and #827 now, asked beside a note that #803 and #813 were still open and could wait for after the refactor. "Guard huts" are the checkpoint huts at the region walls' doors.

11. **The player's words.**

    > for the day 2 and on opening shots -- how would showing the park tell anything if it's not placed anywhere via route? I think we can leave the opening shot to day 1 for now. but let's experiment
    >
    > agree with the thought bubble. it might even make the text obsolete but we should make it so it only shows a few times for each new lesson. we don't want to clutter everything with constant thought bubbles. but it will become useful eg to also show that guard huts can be walked through
    >
    > we should sparingly use signs at junctions since they become permanent markers and might be confusing later on
    >
    > how do you plan to do traffic timing on day 2 only? you don't want any traffic on day 1?
    >
    > the rest sounds good
    >
    > yes, file everything

## #823

1. **Context** (the assistant's):

   Said on 2026-10-24 with five links to public GitHub repositories of Claude Code skills by one author: github.com/uilianks/pxl, github.com/uilianks/vex, github.com/uilianks/kiln, github.com/uilianks/loom, github.com/uilianks/chirp. The project already has a sound-effects skill (synthesized sound auditions, tools/synthesize-sfx.py) and no music.

2. **The note.**

   > have a (careful) look at those skills and see whether we can learn anything from that. I'm especially interested in sound related skills. one person told me they had claude research music theory etc maybe that's something we could look into later on as well

3. **Context** (the assistant's):

   The player's answer on 2026-10-24 to the study of the five repositories. The study recommended, rebuilt in the project's own stdlib Python and never importing or running their code: a waveform-and-spectrogram picture with loudness, brightness, pitch track and clip count beside each sound; a resonant (RBJ biquad) band-pass/high-pass filter with sweeps, and pink and brown noise; later, seamless loop folding and a final peak limiter for ambience beds; recipes as named layers with per-layer levels; several takes of anything that repeats; and, once music is wanted, chord and scale helpers and pattern strings. For the art skills: a checker that names a defect at its coordinates (stray pixels, colours off the family palette, near-duplicate colours), and previews with rulers in asset units. Not adopted: the repositories as tools, recordings, OGG output, audio-sprite banks, MIDI, the chiptune style, and the live annotate servers.

4. **The player's words.**

   > adopt the chirp's and other useful ideas

## #824

1. **The note.**

   > gemini had some comments:
   > Browser games live and die by their first 10 seconds
   >
   > some ideas where to go next when the day one is fixed:

2. **Context** (the assistant's):

   Followed by Gemini's suggestions (an AI's, not a person's) for where to cross-post the game next, each framed for its subreddit's culture: r/Godot (the architecture: the orchestrator session, file sizes, how agents handled the node structure), r/daddit and r/Mommit (the theme only, not the AI: the relatable stress of walking the baby to sleep), r/WebGames (a short pitch: free, no sign-up, roguelite, in the browser), r/roguelites (the design philosophy: the marble bag, the fixed map with daily events, telegraphed fast hazards). The posting is the player's own; tools/reddit.py's rules and about commands read a subreddit's self-promotion rules before a post.

## #826

1. **Context** (the assistant's):

   Said on 2026-10-24 after the orchestrator reported that the filed rule on other people's feedback (downy-beaver #820, PR #822) extends the player's own words: no username or title of theirs, and the conversation as well as the repository, issues and pull requests, are the orchestrator's extension, which the player agreed to with the rest and could overturn.

2. **The note.**

   > The extension to usernames, titles, and chat -- this is important and was a good addition.

## #827

1. **Context** (the assistant's):

   Answer on 2026-10-24 to the orchestrator's question on PR #825 (minty-quail's draw-layers step: one draw-layer list, and every object longer than a tile drawn as feet-anchored slices that sort against her one by one): the café's tables and sitters are drawn as one node, all sitters before all tables; slicing it like the other long objects lets each table and its sitters sort against her and each other, and changes the café's look a little (sitters and tables interleave). The orchestrator recommended slicing it.

2. **The note.**

   > yes, slice the cafe tables
