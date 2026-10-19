# Playtest minty-lemur — The escape played, the chargers' one radius, the stairs, and a critical look at the codebase

2026-10-18.
Said over two sessions (2026-10-17 and 2026-10-18) as notes the assistant captured into the inbox
on GitHub Issues, #761 to #796, with the player's further words appended to them. Each note is
recorded as it holds: first what its words answered, then the words themselves, whole, and each
later word after what it answers. The questions and context are the assistant's; only the quoted
lines are the player's.

## #761

1. **What the note answered** (the assistant):

   Asked: the robber's walk toward her lasts only about 0.15s, since he closes from his 140px notice to his 116px stand-off; should he notice her from farther away (the agent's pick)? And should the guardsman out of a hunting van and the one a torn poster sends also raise a hand and stand during their notice (the agent's pick: yes)? And whether the steam's cost is the punishment wanted: from an empty meter one mistake at a late gate fails the basement walk in about 1 arrival phase of 11.

2. **The note.**

   > whether the robber notices her from farther away -- we can increase the noticing if the robber starts walking slowly
   >
   > whether the other two guards raise a hand too -- why would they? are they going to charge? the raising is to indicate a warning to the user
   >
   > what about the steam punishment?

   The line “what about the steam punishment?” above is not the player's: a correction on this note says so.

3. **Context** (the assistant's):

   PR #757 raised the alley robber's notice to 180px with a 40px/s alert walk; the chalk-mark guard and day 13's guard are the same alley_robbery row, so they woke from 180px too and three scene recipes failed. Asked: (A) 180px for all, (B) the street robber 180px with the slow walk and the mark/day-13 guards kept at 140px (the agent's pick), (C) another distance. The player asked why the guards would get the same, since guards warn without moving; the agent explained these 'guards' are the alley robber himself, drawn as the robber, placed to watch a mark.

4. **The player's words.**

   > why would the guards get the same? they warn without moving
   >
   > all visual robbers get the same warning method

5. **Context** (the assistant's):

   The agent read 'all visual robbers get the same warning method' as: the slow alert walk for all, with the street robber at 180px and the chalk-mark and day-13 guards kept at 140px.

6. **The player's words.**

   > that is 100% contradiction from what I just said

7. **The assistant's comment:**

   Answering your question "are they going to charge?": the hunting van's guardsman does charge. He steps out beside her, holds a 1.8s notice, then lunges. The teal-trout audit found he already shows three distinct stages (standing, his own warning, the charge), so PR #757 leaves him without the raised hand, as the filer's reading. The torn poster's guardsman arrives already charging, so he has no warning stage to show. Should the van's guardsman also raise his hand during his notice, or stay as he is?

8. **Context** (the assistant's):

   The agent reported that with every robber at the 180px notice, a one-block alley's chalk mark can be read without waking its guard only from a window about 11px long (about 0.12s at a walk; about 50px at the old 140px), so at a walk she nearly always wakes him and has to run.

9. **The player's words.**

   > It's fine. If there is enough heads-up the player can still properly get the chalk mark

10. **Context** (the assistant's):

    Continuing: the player had said the tighter chalk-mark window is fine with enough heads-up.

11. **The player's words.**

    > The reason for putting the robber far away was because it was impossible

12. **Context** (the assistant's):

    The agent listed four open questions: (1) the dog's SVG rest and alert against its comic PNG gallop, PR #757 question 1; (2) whether the robber's slow two-frame walk at 180px reads as a warning, PR #757 question 2; (3) whether the back and diagonal views of the chargers' poses on PR #745 hold; (4) the steam's cost, quoting this note's line "what about the steam punishment?" as the player's answer, with "from an empty meter one mistake at a late gate fails the basement walk in about 1 arrival phase of 11". On #764 it also asked (a) whether the patrol car's policeman (days 1-8) gets newly drawn raised-hand pictures and (b) whether the masked man on the escape's stairs counts as charging.

13. **The player's words.**

    > what about the steam punishment?
    >
    > I never said that. Also what do you mean by fails the run 1 in 11? For the other questions. Let's turn it around. I'll let you know if I notice something

    The line “what about the steam punishment?” above is not the player's: a correction on this note says so.

14. **Correction** (the assistant's): this line is not the player's, and the note holds it anyway:

    what about the steam punishment?

15. **Note** (the assistant's):

    The player says they never said this line ("I never said that.", on #765, where they asked for the correction to be recorded). It reached this note's body in the capture, and a later append repeated it as the first line of the player's reply, where the player was quoting it. Nothing is filed from it.

## #762

1. **What the note answered** (the assistant):

   The agent rewrote PR #756's rule to drop the quote and end with a link: ([woolly-penguin](../../../docs/playtests/2026-10-17-woolly-penguin.md), #759).

2. **The note.**

   > links shouldn't be ([woolly-penguin](../../../docs/playtests/2026-10-17-woolly-penguin.md), #759). -- that's more wordy than it was before

3. **Context** (the assistant's):

   The agent had converted the quotes in CLAUDE.md and the skills to links on existing words pointing at playtest heading anchors, e.g. [three times](../../../docs/playtests/2026-10-17-woolly-penguin.md#759).

4. **The player's words.**

   > why are you still using links like ../../../docs/playtests/PLAYTEST-63.md#a-car-crash-is-solid-where-its-picture-is-empty),? just say how to find it once and just point to the filename etc

## #763

1. **What the note answered** (the assistant):

   The agent said that once #750 (the robber's side alert swapped A to B, plus _b frames) and #757 (the wiring, drawn against main's side picture A) both land, #757's side view draws B and its strip picture and GRAPHICS sentence go stale, and it would reconcile that on #757 when merging main into it.

2. **The note.**

   > that needs to be updated in the PR that did it!

## #764

1. **The note.**

   > Van guardsmen that are about to charge should hold up their hands. It's one simple rule of an event doesn't spawn already charging it always needs a warning. If it will never charge it won't need a warning.

2. **Context** (the assistant's):

   The agent read #764 as: every man a vehicle lets out (the hunting van's two, the unmarked van's, the patrol car's one) raises his hand and stands still for his 1.8s notice, then charges; the poster's guardsman and the task-sent robber arrive charging and stay as they are. It asked (a) whether the patrol car's policeman, days 1-8, who has no raised-hand picture, gets five newly drawn views (the agent's pick: yes), and (b) whether the masked man on the escape's stairs, who waits, stands, then runs a fixed line up the shaft that kills her if she is on it, counts as charging and needs a warning (the agent's pick: yes).

3. **The player's words.**

   > Yes we probably need more graphics for warnings. The basement charger already charges so no warning

4. **The player's words.**

   > If not then it needs a warning

5. **The player's words.**

   > 3.6 is an excessive warning. That goes against all warning timings we already have
   >
   > Was that already the case?

6. **Context** (the assistant's):

   The agent explained the masked man's 3.6s notice dates from M102 (2026-09-12): the fairness rule for a lethal row faster than a walk counts his whole 120px field stretched forward, doubled, at walking pace, 3.53s. The other chargers warn for 1.8s; the charging dog warns for 4.5s and the abduction van 4.6s. Options at 1.8s: (A) shrink his field to about 60px so the rule allows 1.8s (the agent's pick); (B) shorten only the warning, which the fairness check refuses unless the rule changes. It also asked whether the charging dog's 4.5s should come down to match.

7. **The player's words.**

   > Shorten only the warnings

8. **The player's words.**

   > Actually what?
   >
   > Warnings are a different radius not time
   > What do you even mean by time here?

9. **Context** (the assistant's):

   The agent explained a charger's warning today starts at a radius (its notice distance) and ends on a timer (1.8s for most, 4.5s for the dog, 3.6s for the masked man) or when she steps inside its charge distance, whichever comes first, so standing at the edge or walking away still ends in a charge. It read "Warnings are a different radius not time" as: drop the timer; a charger warns while she is inside the warning radius and charges only if she crosses the inner charge radius, never if she stays outside or backs off. It asked whether that is it.

10. **The player's words.**

    > A warning happens when the player comes close. They can turn around. If they keep getting closer the charging starts. There are exceptions like van and police ie events that spawn with the sole purpose of charging

11. **The player's words.**

    > There it should be an indicator that they are about to charge

12. **The player's words.**

    > With the same heads-up as off screen chargers

13. **Context** (the assistant's):

    The agent read the vehicle men's "same heads-up as off screen chargers" as the badge's 1.0s alone (today 1.8s), and proposed that once she is back outside the warning radius a waiting charger goes back to waiting and can warn again, the robber walking back to his post.

14. **The player's words.**

    > Yes 1s. Only change the robber while slowly walking will stop if the player gets out of the radius

15. **Context** (the assistant's):

    The agent asked, from PR #770's open forks: (1) the door guard (the guard a street door sets on her when she walks under its raised boom, stepping out of the hut's wall beside her) be treated like the vehicle men, a 1.0s raised hand then the charge; (2) day 13's task guard, once the task sets him on her, the same; (3) the masked man on the escape's stairs runs once she is within about 450px; (4) accept that the robber just inside an alley does not charge a walker the wall hides from him; (5) keep GoatCounter's "dog-chased" firing only at a real charge, not at a warning.

16. **The player's words.**

    > What door guard? That one should spawn charging offscreen 
    >
    > Same with day 13 - any reasons why not? 
    >
    > What masked man? 
    >
    > doesn't charge a walker the wall hides - we specifically made it so. What's the question? 
    >
    > Dog-chased implies charge. Add a new warning level for those event telemetries

17. **Context** (the assistant's):

    The agent had said only the charging dog has GoatCounter chase events (dog-chased, dog-shaken, dog-outlasted, built for "dog tutorial" in PLAYTEST-141), and that the other chargers are counted already by seen-/influenced- per encounter and by lost-hard-fail-<event> when one ends the day, so only dog-warned would be added.

18. **The player's words.**

    > Ending a day and a charging counter are not the same thing

19. **Read as:** (the assistant's interpretation, not the player's words)

    Every charger gets its own charging counter in GoatCounter, separate from the day-ending events: an event when it warns (where it has a warning), when it charges, and when the charge ends without a catch (shaken or outlasted), the dog's set given to every charger.

20. **The player's words.**

    > Charging is independent of an ended day

21. **Read as:** (the assistant's interpretation, not the player's words)

    A charger's counter records its whole charge on its own, whatever the day does: a catch sends the charger's own -caught event as well as any day-ending event (and a catch that does not end the day, such as the patrol car's stop, sends it too), rather than the day-ending event standing in for it.

22. **Context** (the assistant's):

    The agent had said the day number in each dog event's name (day-3-dog-chased) tells the tutorial dog apart. It does not: charging_dog has max_per_day = 3, so day 3 can send up to three dogs, and every one of them sends the same day-3-dog-chased; only the first, the one EventDirector puts dead ahead of her with the tutorial tip, is the tutorial.

23. **The player's words.**

    > No it doesn't

24. **Read as:** (the assistant's interpretation, not the player's words)

    The dog tutorial gets GoatCounter events of its own (the one dog that carries the tutorial tip), so "dog tutorial" from PLAYTEST-141 is counted as asked rather than inferred from the day number.

25. **Context** (the assistant's):

    The agent had asked whether "the door guard" spawning off screen should replace the player's 2026-09-24 words "guards that pursue her should spawn at the huts". "Door guard" is the code's name (EventCatalogue._door_guard()) for the guard a checkpoint's door sets on her when she walks under its raised boom, who steps out of the hut's wall beside her.

26. **The player's words.**

    > That's not the for guard. That's the checkpoint guard. *Always* provide context for what you're saying. I don't know the made up names or references you think about

27. **Context** (the assistant's):

    The agent asked: (1) the checkpoint guard, who steps out of the hut beside her when she walks under a checkpoint's raised boom and today raises his hand 1.8s then charges: drop his warning to 1.0s like the vehicle men? (2) day 13's task guard, set on her when she completes the task: out of view, arrive charging from off screen with the 1s screen-edge badge; in view, raise his hand 1.0s and charge from where he stands? (3) the masked man in the escape's stairwell: a charge distance of about 450px so she has time to reach a door (a), or arrive already running (b)?

28. **The player's words.**

    > 1. when the player approaches the boom gate the guard should raise the hand (warning radius is around the boom gate not the guard) and when the player actually goes under it should immediately start charging
    >
    > 2. yes, we can do a 1s on screen and 1s off-screen warning if they were not visible
    >
    > 3. player should have to run to the door

29. **Read as:** (the assistant's interpretation, not the player's words)

    (1) A checkpoint's guard raises his hand while she is within a warning radius measured round the boom gate, and the moment she goes under the boom a guard charges her at once, with no further warning. (2) Day 13's guard: in view, a 1s raised hand then the charge; out of view, a 1s off-screen badge then he arrives charging. (3) The masked man's charge distance is set so that once he runs, she reaches the nearest door off his line at a run but not at a walk.

30. **Context** (the assistant's):

    The agent asked about the checkpoint guard at an alley's door, who under "when the player actually goes under it should immediately start charging" charges from beside her and catches her in about 0.03s: (a) keep it, passing the post is always a detention; (b) the guard who charges comes from further back so running past escapes, as at the boom gate (the agent's pick).

31. **The player's words.**

    > (b) how would we get the guard further back? it's already at the gatehouse? maybe 0.5s wait before charging after crossing?

32. **Read as:** (the assistant's interpretation, not the player's words)

    At an alley's door, after she passes the post the guard waits 0.5s, then charges; the road's boom gate keeps its immediate charge from the hut across the road.

## #765

1. **What the note answered** (the assistant):

   Note #761's body ends with the line "what about the steam punishment?", written into the body by the capture as the player's words. The player says they never said it. This note overrides that line: when #761 is filed, "what about the steam punishment?" is not the player's statement, and nothing is filed from it. (The steam's cost, 40 to 50 a blow, was built in PR #752, grassy-dolphin; the agent's question whether the basement walk's resulting cost is the punishment wanted is dropped.)

2. **The note.**

   > I never said that.
   >
   > Just create a new inbox overwriting that statement

3. **Context** (the assistant's):

   The agent explained "1 in 11": a rig walked the escape's basement past its three vents from an empty meter, arriving at 11 different points in the vents' cycles. Timed well, the meter never passed 61; caught by one blow at the second or third vent, it reached 100 (losing the basement section) in 1 of 11; caught at all three, in 2 of 11. It asked whether that is the punishment wanted, and said it would drop the question otherwise.

4. **The player's words.**

   > Well you gotta time the vents that's the whole point. You shouldn't get through without timing it

5. **Context** (the assistant's):

   The agent proposed a target for the escape's basement, from an empty meter: walking straight through without timing the vents loses the section every time, one mistimed vent of three still gets her through, a well-timed walk stays comfortable. Keeping 40 to 50 a blow, two ways: (A) the meter does not fall while she is in the basement corridor, so the blows add up (the agent's pick); (B) a blow stops her where she stands.

6. **The player's words.**

   > Sure let's not replenish the meter in the basement it's a tense situation.

7. **Context** (the assistant's):

   The agent reported PR #766 (the meter does not fall in the basement): a straight untimed walk now loses 2 of 22 arrival phases awake (was 1) and never asleep, and in 4 of 22 it is never hit. Options: (A) retime the vents so a steady walk cannot slip through (the agent's pick), (B) a blow stops her where she stands, (C) accept it. It also asked whether a sleeping baby, feeling about half of each blow (24), should stay spared.

8. **The player's words.**

   > Also accept it how steam is I will mention it again if I notice anything

## #767

1. **The note.**

   > For filling notes indicate when something is a direct quote and something is an interpretation. Edit the rules around that

2. **Context** (the assistant's):

   The agent had edited the inbox and playtest-feedback skills (PR #768) to say a note's body holds direct quotes only, a reading is labelled "Read as:", a stray line is corrected by a new note naming what it overrides, and a playtest file and a queue entry mark quotes and readings apart.

3. **The player's words.**

   > And the tooling. So it gets properly recorded when ingesting

4. **Context** (the assistant's):

   The agent had said the rules now hold a note's body and appended words to direct quotes only, with the agent's context in a separate first comment, and that the tooling agent would add a separate reading input, correction notes the tool understands, and an ingest command that writes the playtest file.

5. **The player's words.**

   > No, put all necessary context in addition to the direct quotes. And further notes. Just make clear marks that get read when ingesting

6. **Context** (the assistant's):

   The agent had said correction notes like #765, a new note naming a line of another note that is not the player's, stay.

7. **The player's words.**

   > And corrections go into a comment

## #769

1. **What the note answered** (the assistant):

   The agent researched it: since November 2025 Reddit's Responsible Builder Policy requires approval for any new API (OAuth) access, reportedly weeks and possibly refused for a personal script, while access that already existed keeps working (so an old app listed at reddit.com/prefs/apps may still work, through PRAW). The workable route without the API is Claude in Chrome on the player's logged-in account: reading needs no approval; every post or reply goes out as the player, so each is drafted into a file in the repo and posted only after the player approves it; at human pace, no scheduled or bulk posting; each subreddit's rules on self-promotion, developer affiliation and AI disclosure read before drafting; a rarely used account may be filtered by low-karma rules.

2. **The note.**

   > One thing to research. Can you check how you can read and post on Reddit? I have an account I don't regularly use and I want you to use it when we start sharing the game
   >
   > Yes, we will post and read responses together and decide together when and to what to reply. I might still have an old api key I will look for it later.

3. **Context** (the assistant's):

   The agent said it had wrongly tagged this note queue_later though the player named no band, and asked the player to remove the label if unwanted.

4. **The player's words.**

   > It's fine later it is

5. **The player's words.**

   > I have credentials for mr_birkenbot here: /Users/krause/workspace/clotho/example/creds.json

6. **Note** (the assistant's):

   The file holds a Reddit "script" app's user, client_id and client_secret, used read-only through PRAW by /Users/krause/workspace/clotho/example/reddit.py; it holds no password, so it can read but cannot post as u/mr_birkenbot. Whether Reddit still issues it a token after the November 2025 policy change is not yet checked.

7. **The player's words.**

   > I have credentials for mr_birkenbot here: /Users/krause/workspace/clotho/example/creds.json

8. **Note** (the assistant's):

   Checked 2026-10-17: the app in that file still gets read access. Through PRAW it read r/WebGames' two hot posts ("Find-A-Game Megathread!", "Looking for opinions on AI made web games"). Posting still needs the account's own sign-in (its password added to the app, or a browser login), or the Chrome route.

9. **The player's words.**

   > okay that's fine -- I always used that for reading anyway. then let's use a different account -- we can try via chrome

10. **Note** (the assistant's):

    Tried 2026-10-17: Claude in Chrome refuses reddit.com outright ("This site is not allowed due to safety restrictions"), so the Chrome route does not work as things stand; posting needs a script app with the posting account's password, or another way the player chooses.

11. **Context** (the assistant's):

    The agent had offered to set up Playwright, a browser-automation library, so it could post on Reddit through a browser the player logs into, after Claude in Chrome refused reddit.com and a new API app needed Reddit's approval.

12. **The player's words.**

    > actually, no. all you need is read access -- I can post things manually

13. **Read as:** (the assistant's interpretation, not the player's words)

    The agent reads Reddit only, through mr_birkenbot's existing app in /Users/krause/workspace/clotho/example/creds.json; it drafts each post or reply into a file in the repo, and the player posts it by hand.

14. **The player's words.**

    > copy over the credentials that you had from earlier here (gitignored) and write tooling for it

15. **Note** (the assistant's):

    The credentials are in the repository's git-ignored .env as REDDIT_CLIENT_ID, REDDIT_CLIENT_SECRET and REDDIT_USER (the file already holding GOATCOUNTER_TOKEN). A read-only tools/reddit.py is being built on branch feature/reddit-reader.

16. **The player's words.**

    > my account from which I will be posting from is going to be josua_krause

17. **The player's words.**

    > that's not secret information

18. **The player's words.**

    > I'm thinking of posting to https://www.reddit.com/r/ClaudeGameDev/ as first showcase of the project

19. **Note** (the assistant's):

    Read 2026-10-17: r/ClaudeGameDev, about 11,300 subscribers, "A community for AI game development using Claude". Rules: civility; promotion allowed but no spam and any cost stated; constructive criticism; "Must Use Claude": a submission must state how Claude was used in the workflow and what other tools, "I used Claude" alone not enough. Post flairs seen include Browser Game, Alpha, Release, Tips & Tricks; the month's top posts lead with process detail (time taken, commits, what Claude did).

20. **Context** (the assistant's):

    Reading r/ClaudeGameDev showcases, the agent found the reader's text view drops a post's own text when the post is a picture or video (it read them through --json), that --depth 0 (the post without comments) is refused, and it had written a one-off script for the subreddit's subscriber count, allowed post types and the flairs used on recent posts.

21. **The player's words.**

    > yes, keep improving the reader where you see gaps -- same with above where you had to write a custom script

22. **Context** (the assistant's):

    The agent offered titles for the first r/ClaudeGameDev post: (1) "Just a walk, until she sleeps: a browser roguelite built with Claude Code"; (2) "A stroller roguelite built with Claude Code (free, browser)"; (3) "Walk the baby to sleep: a roguelite built with Claude Code". Earlier the player said: "we have the trailer that we can embed in the post -- link is to the actual game".

23. **The player's words.**

    > we have the trailer that we can embed in the post -- link is to the actual game
    >
    > title 3

24. **The player's words.**

    > or 1

25. **The player's words.**

    > 3 is more actionable -- it's clear what the game is about

26. **Context** (the assistant's):

    The agent's draft of the r/ClaudeGameDev post (docs/sharing/2026-10-17-claudegamedev.md) had six sections: 1 the title, 2 the opening with the link, 3 "What Claude did", 4 "What went wrong" (agents overturning the player's decisions, docs going stale, the lock-up only on the player's phone), 5 "What I did" (the player's own part), 6 "One question" ("where did a danger surprise you, or where did you not know where to walk?").

27. **The player's words.**

    > is there something more interesting for 4? miscommunication is not really interesting and also not really game related. what do you mean by 5? 6 can be improved as well

28. **The player's words.**

    > yeah do a proper research
    >
    > for both bullet points
    >
    > when all the updates are done review the post text from the perspective of someone who has never seen the game. it shouldn't reference any things that you can only know when you played the game. lessons should be general no specific examples that need game context

## #771

1. **The note.**

   > The roadblock in escape shouldn't appear on the path or it should be in a way that luring away the guard is enough. Right now there are for guards and the player adds excitement by just being close. Luring away one guard (the challenge) is not enough to make the obstacle survivable

2. **The player's words.**

   > release after those changes and after the roadblock in the escape is fixed -- how are you fixing it?

3. **Context** (the assistant's):

   Said while PR #781 (one roadblock a street, the band silent once its guard is lured off) was open; the seed was one an earlier session gave for testing the escape.

4. **The player's words.**

   > the seed you gave me for testing the escape is still unwinnable. two roadblocks are right next to each other and the second guard is invisible (hidden) until it already charges

5. **Context** (the assistant's):

   Asked in the session (PR #781): after she lures off the roadblock guard on her side, the far guard keeps standing as a drawing that never acts. Should he leave too, so the band reads as unmanned? Options: "He leaves too (Recommended)" / "He stays standing".

6. **The player's words.**

   > He leaves too (Recommended)

## #772

1. **Context** (the assistant's):

   The agent had asked about "the door guard", the code's name (EventCatalogue._door_guard()) for the guard who steps out of a checkpoint's hut when she walks under its raised boom, which the player knows as the checkpoint guard; earlier in the session it had also used "the masked man" and "the door guard" without saying who they were, and the player had asked "What door guard?" and "What masked man?".

2. **The note.**

   > That's not the for guard. That's the checkpoint guard. *Always* provide context for what you're saying. I don't know the made up names or references you think about
   >
   > add the context stuff as rule -- it happened quite often

3. **Context** (the assistant's):

   PR #773 added to CLAUDE.md that a thing in the game is named the way the player knows it and said what it is in each message that mentions it, and strengthened the invented-names bullet. CLAUDE.md already holds, from woolly-finch 10: "A question carries all the context needed to answer it — what was asked, what it collides with, what each answer costs, and which you would pick — in the message that asks it, not in an earlier one."

4. **The player's words.**

   > 773 -- how about making a rule to add context for a question?

## #777

1. **The note.**

   > there is a /Users/krause/Library/Application\ Support/Godot/app_userdata/Nappy/telemetry/2026-10-17/run-170256-seed4216201080-v0.28.0-4-g2148e837/asked invisible wall exactly where I'm standing -- impossible to continue the escape

2. **Note** (the assistant's):

   The player's screenshot (asked/002-attempt1-asked.png in that run folder, which also holds run.log) shows the escape's city section on seed 4216201080, build v0.28.0-4-g2148e837 (main after PR #766): the mother on the sidewalk at tile 74,27, speed 0.0, 148.9s left, a roadblock band across the street north of her, a parked van to the west, and the nearest event an active abduction (age 18.4/4.6, 130px). The run folder is in the player's scratch telemetry; it is to be copied into docs/evidence/ with the fix.

## #778

1. **The note.**

   > Also if we redo the trailer. The zzz when carrying is not consistently over the parent's head. It moves around wildly. The dog in the charging scene suddenly disappears. We need to turn off despawning for recording that trailer segment

2. **Context** (the assistant's):

   Said after a /clear, on PR #780 (trailer fixes), which re-staged the chase shot around the roadblock guard that now warns by radius before charging.

3. **The player's words.**

   > for the trailer, just use a charging guard instead of one that gets triggered by proximity

4. **Context** (the assistant's):

   Asked in the session (PR #780): the chase shot's guard now charges from the first frame, but running shakes a pursuer off after 0.35s, so she walks the first part of the cut while he closes in and runs only at the end. Options: "Walk, then run (Recommended)" / "Run the whole cut". The player answered in their own words instead.

5. **The player's words.**

   > have him rigged to not give up

6. **Context** (the assistant's):

   Said after watching the re-rendered trailer (main at eb5506ed, PR #780 merged): the carried cue now sits BABY_CUE_LIFT + FIGURE_HEIGHT above her feet in every facing.

7. **The player's words.**

   > The zzz is still buggy. It's floating way too high (gap that the stroller would take)

8. **Context** (the assistant's):

   Said after seeing PR #790's stills sheet (eight facings of the carried mother; top row main at 82px above her feet, bottom row the fix at 52px):

9. **The player's words.**

   > The bottom row is correct (your picture)

10. **Context** (the assistant's):

    Asked in the session, with PR #790's picture mark-up-a-vs-b.png: when a warning mark is up over her head while she carries the baby, how far to the side should the zzz step? Options: "A: 34px, as built" (zzz close beside the mark, with a small gap) / "B: 56px" (clear space between the mark and the zzz, further from her).

11. **The player's words.**

    > A: 34px, as built

## #782

1. **The note.**

   > the guard in the escape stairwell should start charging when the player is at the end of the second stair -- otherwise you can just walk to the door and never enter the stairs of the guard.

2. **Context** (the assistant's):

   Asked in the session: where should the stairwell guard start his charge? B: as she reaches the first-floor landing beside the door (about 200px from him); the left stairwell stays a way out, but only with him already chasing her. D: every route to the lobby triggers him (the left stairwell's last flight and the first-floor hallway too), overturning MECHANICS.md's "the left one stays open too". Today he charges only within 150px of him, partway down his last flight. The player picked option B.

3. **The player's words.**

   > B: first-floor landing (Recommended)

4. **Context** (the assistant's):

   Said after the orchestrator asked three questions on PR #787 (the stairwell guard and the stairs): (1) the guard as built charges when she reaches the first-floor landing, but from 315-350px away, so a walker still reaches the door; should he wait higher so she must run (the player's earlier "player should have to run to the door", inbox #764)? (2) on the landing tile between two flights, should a sideways press take the flight going down? (3) a held climb up the top flight now carries her into the third-floor door; is that fine? The player rejected the question form and wrote:

5. **The player's words.**

   > bring up the questions again. and what is unclear in the first place? I explained exactly already.

6. **Context** (the assistant's):

   Asked in the session, four questions (options were neutral, no recommendation). (1) The stairwell guard runs when she reaches the first-floor landing, from 315-350px away, so a walker still gets out through the first-floor door; waiting higher up his stairs never separates walker from runner (the door is 0.27s away). Options: "Keep as built" / "Door must be a run". (2) On the landing tile between two flights, what should a plain left or right press do? Options: "Leave the press flat" / "Walk the flight down". (3) A held climb up the top flight now carries her straight into the third-floor door, whose tile touches the top step diagonally. Options: "Through the door" / "Stop on the landing". The player answered each in their own words, in order:

7. **The player's words.**

   > make the radius bigger to achieve the result -- don't place him higher up

8. **The player's words.**

   > I don't understand. if she is on a stair she goes diagonally up or down depending on which stair outside of a stair she goes into the direction

9. **The player's words.**

   > how would she go into the door? your question doesn't make sense

10. **Context** (the assistant's):

    Asked in the session after PR #787's second review: (1) the stairwell guard's warning is off screen (he warns from 900px, charges at 426px; the view reaches 180px above and below her; from the first-floor hallway his whole 1s warning is off screen). Options: "Edge badge while he warns" / "Camera shows the shaft" / "Accept off screen". (2) A walker holding plain left from the tile between the two flights still reaches the first-floor door with him 36-39px away; no single radius separates walker from runner on every path, and the margins are thin (24-26px against his 28px catch at the game's tick rate). Options: "Accept it" (keep 426px) / "Find another way". The player's answers, in order:

11. **The player's words.**

    > Accept off screen

12. **The player's words.**

    > Accept it

## #783

1. **The note.**

   > walking on the stairs should snap to 45 up or down angles -- if the movement is towards the left it should automatically snap to the angle that is 45 towards the left (up or down depending on which stair)

## #784

1. **The note.**

   > the title screen should show the mode name (Normal / Hard Mode) if the decision is already made (eg loading a save)

## #785

1. **The note.**

   > does the escape use the same placement rules as the regular game? it doesn't seem like it does. it should, though. I saw wood on the roof for example

2. **Context** (the assistant's):

   Asked in the session (PR #781 forks, item B of applying a day's placement rules to the escape): (1) apply the day's calm-park rule (nothing dangerous may reach a park she hasn't used) to the escape? It would remove about a third of the trucks, a sixth of the vans, over half the explosions over ten seeds. Options: "Don't apply (Recommended)" / "Apply the day's rule". (2) Keep the escape's own rules rather than a day's for the home's streets (a day places nothing on the front door's street or round the home block) and the per-day caps (e.g. four unmarked vans)? Options: "Keep the escape's rules (Recommended)" / "Apply the day's rules". The player's two answers follow, in order.

3. **The player's words.**

   > Don't apply (Recommended)

4. **The player's words.**

   > Keep the escape's rules (Recommended)

5. **Context** (the assistant's):

   Said after the orchestrator answered "what is the marble bag for escape?" with: the escape has no marble bag; the bags (the route bag choosing which director-sited events she meets, the torn poster's pursuit bag) are a normal day's; the escape places a fixed count of each danger per open street and a fixed set in the building. The v0.29.0 summary before it had said the escape uses "the regular game's rules for where things may stand".

6. **The player's words.**

   > what are the inbox notes about? why does the escape not have a marble bag? you said: the regular game's rules for where things may stand; so that's a false statement

7. **The player's words.**

   > so you prefill the events for escape but that doesn't justify not using a marble bag. those concepts are orthogonal

8. **Context** (the assistant's):

   Asked in the session: should the escape draw its dangers from a marble bag? Today each open street gets exactly one military truck, one van, one roadblock and one explosion; with a bag, each street keeps its slots and which danger fills each is drawn from one escape-wide bag by weight. Options: "Yes, use a bag" / "No, keep it fixed". The player answered in their own words:

9. **The player's words.**

   > nobody ever asked for all four events on *every* street. that doesn't make any sense and cannot feasibly work at all. that is why the density is so high that it's impossible to get anywhere. yes, a marble bag is absolutely needed with empty events (nothing happening) as well. we need a fair mix

10. **The player's words.**

    > plan out -- no implementation this session

11. **The player's words.**

    > more notes: 1) frequency order is trucks > explosions > vans > barriers > empty 2) explosions have to happen off-screen with a warning sign showing the explosion as mushroom or whatever indicates an explosion -- craters must already be there when the player walks towards them (right now they appear out of nowhere) -- an explosion is accompanied with a bright screen flash (matching the flashes from the apartment escape). don't make them too short to not be dangerous for viewers. 3) losing an escape should still state the reason like the rest of the game. nothing should be different. right now it doesn't and it just shows "Escape the city". not sure what led to this divergence. the escape is just like a normal day with some special settings 4) telemetry should work the same also in escape both apartment and city -- just making sure this is also proper

12. **The player's words.**

    > there really should be no separate code for escape

13. **Context** (the assistant's):

    Said after the orchestrator's plan said: the building runs its events outside the day's event system (InteriorEvents beside EventManager), so it is the likely gap for GoatCounter; and that the escape's loss screen skips the reason "deliberately", per the code.

14. **The player's words.**

    > if that is the case that's a really bad red flag

15. **The player's words.**

    > also have some random screen flashes as well indicating further away bombs. and for the closeby explosion have the screen shake a little

16. **The player's words.**

    > unify the codebase

17. **The player's words.**

    > this is really bad

18. **The player's words.**

    > having a separate way of placing events is okay but other things like movement code or goatcounter etc should not

19. **The player's words.**

    > The escape may keep its own way of placing events -- no the *building* escape may keep its own way of placing events *NOT* the city escape

20. **The player's words.**

    > all should be implemented through the regular game engine's means

21. **The player's words.**

    > do I have to teach you proper software design now?

22. **Context** (the assistant's):

    Said after the orchestrator offered to file today's inbox notes into the queue now, with a design round on the escape's unification as the first item, and asked "Shall I file it?".

23. **The player's words.**

    > no, I want you to have a critical look at the codebase

24. **The player's words.**

    > things to focus on (and you should know those principles): separation of concerns, composability, cohesion, coupling, architecture layering

## #788

1. **The note.**

   > chargers that warn and start charging by proximity need a bigger radius for starting to charge otherwise it's impossible to bait them out. right now the barrier guard in escape has a radius so short that it is impossible to bait him. also the barrier itself *still* causes excitement. and your self answers for the questions are wrong -- bring them up properly

2. **Context** (the assistant's):

   Asked in the session: the player's last recorded run was on main (before PR #781), where the band costs excitement manned or not; on PR #781 it costs nothing once its guard is lured off, and while he is posted the band's own field costs 9/s at the band. What does "the barrier itself still causes excitement" mean? Options: "No cost at all, ever" (in the escape the band never costs excitement, manned or not; only the guard is the danger) / "I played main".

3. **The player's words.**

   > No cost at all, ever

4. **The player's words.**

   > the charging radius of waiting charges needs to be tuned for a) it's possible to bait and b) the warning should be visible on screen. the remainder of your assessments is good. the escape doors should be in a way that the graphics is always under her right now the door can be drawn on top of her. you can push and merge prs when they're ready.

5. **The player's words.**

   > band costing nothing should also apply to a normal day

6. **The player's words.**

   > the challenge is the guard not the concrete

7. **Context** (the assistant's):

   Asked in the session (PR #781): (1) the alley robber waits and lunges at 116px, the player's earlier choice ("116px, keep every rule", tall-osprey); baiting him needs a turn within about 0.2s. Option B: the waiting robber gets the bait radius (charges at 142px, warns from 189px), task-sent robbers keep 116px. Options: "Keep 116px" / "B: bait radius". (2) In the escape the far roadblock guard walks off with his lured partner; on a normal day he stays standing. Options: "Escape only" / "Days too". The player's answers, in order:

8. **The player's words.**

   > B: bait radius

9. **The player's words.**

   > Days too

10. **The player's words.**

    > I have an better idea. Right now there are two radii. We should do one radius and warn inside it for 2s. If the player leaves the radius nothing happens and the warning stops. If they stay within the charge starts. We can apply this to all cases and can mostly keep the original radii. Only the basement guard needs to keep his new radius

11. **Context** (the assistant's):

    Asked in the session about the one-radius proposal: (1) who is "the basement guard"? (the game has no basement guard; the masked man at the foot of the escape building's right-hand stairwell has the new 426px radius) — does he take the 2s warning too? Options: "Stairwell man, with 2s" / "Stairwell man, no 2s". (2) Which of each charger's two radii (outer warning, inner charge; e.g. the roadblock guard's 180px and 106px) becomes the one radius? Options: "The outer warning one" / "The inner charge one". The player answered both in their own words, then added a third line:

12. **The player's words.**

    > Stairwell. Measure how what warning would make sense

13. **The player's words.**

    > Before we started implementing two radii

14. **The player's words.**

    > That solves the too short charge completely

15. **The player's words.**

    > But whatever makes sense

16. **The player's words.**

    > If the bigger of the two makes now sense let's go with that

17. **The player's words.**

    > The crossing radius case is similar. The actual crossing will start the timer and if the player goes back no charge happens but if they stay crossed the charge will start. Warning starts when the player is crossing

18. **The player's words.**

    > So we need to time each case since there is now a heads-up

19. **Context** (the assistant's):

    Asked in the session (PR #781 review 4): the stairwell guard (masked man) now waits a 1s warning before he runs under the one-radius model; the warning is off screen in the stairwell, so it is only a delay; with it a walker gets out through the first-floor door on 4 of 5 ways down; with no delay (main) a walker was caught on 3 of 5. Options: "No delay, as on main" (he runs the moment she comes within 426px; the one exception to the warning rule) / "Keep the 1s delay" / "Bigger radius + delay".

20. **The player's words.**

    > No delay, as on main

21. **Context** (the assistant's):

    Said after the orchestrator answered "Is there an offscreen warning?": only once he is running; a screen-edge badge points at anything off screen closing on her, so the stairwell guard appears at the edge the moment he runs; nothing points at a charger waiting or warning off screen; with no delay the badge is his only heads-up.

22. **The player's words.**

    > Let's show that at least

23. **The player's words.**

    > For the stairwell guard I mean

24. **Context** (the assistant's):

    Said after the orchestrator described PR #781 review 5's finding (day 9's boom task done free via two doors at one corner: under door A's boom, then within A's 2s under the named door B, which counts at once, then back out under both before A's 2s are up) and said the fix was being built; then "props to whoever finds it":

25. **The player's words.**

    > props to whoever finds it

26. **The player's words.**

    > not fixing that

27. **The player's words.**

    > well if the fix makes the code generally more sound we should do it -- but we shouldn't do it if it complicates things

28. **The player's words.**

    > then let's fix it after all

## #789

1. **Context** (the assistant's):

   Said in the same message as the player's charging-radius note (inbox #788), about the escape building's doors:

2. **The note.**

   > the escape doors should be in a way that the graphics is always under her right now the door can be drawn on top of her.

## #791

1. **Context** (the assistant's):

   Said after the orchestrator reported that PR #781's third review found the roadblock guard on her side walking off straight through his own concrete band, in her view, after a lure, and that it was being fixed:

2. **The note.**

   > walks off straight through his own concrete band, in view. -- I mean that happens with a lot of events (eg cat / bike just completely ignoring buildings; neighbor walking through barricades) we need to do a fix for this at some point but not now. so this shouldn't be a blocker either

3. **Context** (the assistant's):

   Said after the orchestrator listed the cat, the bike, the neighbor and the roadblock guard as the events walking through buildings and barricades:

4. **The player's words.**

   > those are examples not an exhaustive list

## #792

1. **Context** (the assistant's):

   Said on 2026-10-18 while review agents ran headless test suites. Godot crashed (SIGABRT, macOS crash dialog on the player's screen) at 11:47, 12:57, 13:19, 15:20 and 15:46.

2. **The note.**

   > your agent keeps crashing godot]

3. **Note** (the assistant's):

   The PR #781 reviewer traced the 15:46 crash: one `tools/test.sh` call with eleven suites died in test_resistance about 8 minutes in with "Message queue out of memory" and about 1.38 million "Object was deleted while awaiting a callback." lines; every suite passes alone. Likely cause: `tests/run_tests.gd` (line 54) runs every suite inside one `_ready()`, so deferred calls are never flushed between suites. Not yet reproduced on main. The 15:20 crash fell during that review's `check.sh`, whose headless import step hides its output while check.sh still printed OK.

## #793

1. **The note.**

   > I've been thinking of maybe switching over to three.js what are the pros and cons of that?

2. **Context** (the assistant's):

   Said after the orchestrator laid out the pros and cons and recommended staying on Godot (a full rewrite of about 82k lines of src/ and 90k of tests/, three.js is a 3D renderer with no engine, the headless rigs and the trailer's movie writer are Godot's; if load time or phone performance is the driver, measure and shrink the Godot web export first):

3. **The player's words.**

   > Okay fair enough

## #794

1. **The note.**

   > file the findings as a refactor ticket. be precise about it. for immediate next step: check the bug and also make escape winnable with minimal changes (fixing event distribution in some cheap way) then patch release then full refactor. all of that next session though. stop after filing everything

2. **The player's words.**

   > oh, almost forgot -- use dependency injection to allow for more modular and testable code

3. **The player's words.**

   > what does "layered architecture" mean to you?

4. **The player's words.**

   > okay, I was just checking. since I saw some things written about graphic layers. just wanted to make sure you didn't take layered architecture as graphics guideline
## #796

1. **Context** (the assistant's):

   Said after the codebase review was filed as the refactor ticket minty-quail (PR #795), whose lens was the player's "separation of concerns, composability, cohesion, coupling, architecture layering" and "use dependency injection to allow for more modular and testable code" (inbox #785 and #794, filed in minty-lemur).

2. **The note.**

   > also make it so the software principles are going to be mentioned in a code writing / designing rule(?) whereever it makes most sense
