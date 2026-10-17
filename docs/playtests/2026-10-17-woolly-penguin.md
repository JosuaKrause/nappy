# Playtest woolly-penguin — Answers on the escape, Hard Mode and the chargers, and how a question and a review are handled

2026-10-17.
Said in one session as five notes the assistant captured into the inbox on GitHub Issues, #746,
#747, #748, #758 and #759, with the player's further words appended to them. Each note is recorded as
it holds: first what its words answered, then the words themselves, whole, and each later word after
what it answers. The questions and context are the assistant's; only the quoted lines are the
player's.

## #746

1. **What the note answered** (the assistant):

   Asked about crisp-owl (inbox #742, the escape clock): the escape's clock label is rewritten only
   once a second, because M124's throttle on DayController also throttles the escape's clock, so the
   three digits after the point sit still and jump. Rewriting it every frame fixes that; which
   precision should it show: hundredths (2:59.43, the agent's pick, changes every frame and keeps
   M102's faster-looking clock), tenths (2:59.4), or whole seconds (2:59, drops M102's "appear
   faster")? The ending screen's run length stays at milliseconds. Also asked, for plaid-goose (inbox
   #740, Hard Mode cannot be selected), on which device and which title (a new game's first, after an
   ending, a resumed save) selecting failed.

2. **The note.**

   > escape clocke we can try 100s but it's not going to be much better? framerate is too low? all of this was on phone.

3. **What the next words answered** (the assistant):

   The agent was working on plaid-goose (inbox #740, Hard Mode cannot be selected); the diagnosis had
   found the Hard Mode box is shown only on a new game's title (TitleScreen.open with new_game true,
   which main.gd passes as "no saved run"), not on the title after an ending or on a resumed save.

4. **The player's words.**

   > I don't see the hard mode button at all locally

5. **What the next words answered** (the assistant):

   The agent had said the Hard Mode box appears only on a new game's first title (no saved run), and
   asked the Hard Mode agent to pin down which titles hide it.

6. **The player's words.**

   > I see the hard mode selection after restarting the game (fresh save) but I cannot click on it locally either. I clicked on the text and the button. the whole bounding box should trigger

7. **What the next words answered** (the assistant):

   Continuing the player's words on the Hard Mode box: "the whole bounding box should trigger".

8. **The player's words.**

   > +5% of course

9. **What the next words answered** (the assistant):

   Asked (plaid-goose, review item docs/review/2026-10-17-plaid-goose.md): should Hard Mode stay
   new-game only once a run is saved (the agent's pick), with the title saying a held restart starts
   a new game? The alternatives were showing it on the resume title (ticking discards the save),
   letting it switch the saved run's mode, or a new-game control on the resume title.

10. **The player's words.**

    > yes, hard mode is new game only. you cannot change in the middle of a run.

## #747

1. **What the note answered** (the assistant):

   Asked about grassy-dolphin (inbox #741, the escape is broken), after the diagnosis. Steam:
   unchanged since it was built; one blow costs her about 25 of 100 points awake (about 14 asleep),
   two vents trapping her 43-47; options (a) intensity 14 to about 22 (35-45 points a blow, the
   agent's pick), (b) full strength through the blow, (c) a wider field, (d) longer blows, (e) a
   physical effect. City route: a regression from #663 (the escape's vans stay parked and solid on
   the sidewalk) and #676 (the roadblock bands stand for the whole walk): with every body standing no
   seed of 8 reaches an exit; asked whether a roadblock is a guard to get past with its band on the
   road and a sidewalk always open (the agent's pick) or a chain street never carries one, and
   whether the parked vans and their men stay on the escape's streets. Guidance: the escape never had
   markers; options (a) the M145 yellow curb tint on the chain streets (the agent's pick), (b) a red
   arrow like a task's, (c) none. The fire: the agent said it would fix the fire to the second floor
   every time (left-right-left) unless the player objected.

2. **The note.**

   > steam should be 40 to 50. roadblocks currently are impossible to get past. one sidewalk must be open if they're en-route. the escape's street should not have fully blocking events like in the normal game. also, yes, of course the yellow tint. we spent the whole game establishing that why would it be different in the last section?

## #748

1. **What the note answered** (the assistant):

   Asked about teal-trout's second sheet (PR #745): whether the back and diagonal views hold; the
   robber's side alert, row 3 (approved on #726) or row 4 (bolder, the agent's pick); whether an alert
   walks: while warning, the dog, the robber and the roadblock's guard close on her at pursuit speed
   so one still picture glides, (a) a stride frame per view for each alert pose (the agent's pick) or
   (b) the pursuer stands still for its notice; and whether the guard's raised palm reads as "he's
   onto me" or "wait here".

2. **The note.**

   > robber can walk towards her but guards should lift their hand in warning.

3. **What the next words answered** (the assistant):

   The agent read the answer back: the robber's alert gets walking frames, so he walks toward her
   while warning; the guards keep the raised palm and stand still while warning (the roadblock's
   guard stops gliding during his notice). It asked whether the dog, which also closes on her while
   warning, walks too or stands still; which robber side alert, row 3 (approved on #726) or row 4
   (bolder); and whether the new back and diagonal views hold.

4. **The player's words.**

   > yes, dog also doesn't walk -- only one is the robber. not sure what row 3 or row 4 is? the two images?

5. **What the next words answered** (the assistant):

   The agent opened PR #750 to ask which side alert is the robber's: one row showing, left to right,
   waiting, alert A (approved on #726), alert B (bolder), and the lunge, and asked "A or B?",
   recommending B.

6. **The player's words.**

   > I read 750 as one animation cycling between A and B
   >
   > for walking

7. **What the next words answered** (the assistant):

   The agent asked: should B be his alert pose in every view, so that his front and diagonal views
   each need an A-style partner to make the two-frame walk (three more drawings)? And does the dog
   only rest and alert, with no walk?

8. **The player's words.**

   > I just explained, no? since he is walking I read A and B as animation frames
   >
   > nobody walks -- only the robber

9. **What the next words answered** (the assistant):

   The agent proposed wiring the charging dog with the approved SVG rest and alert poses now (the
   gallop stays the comic PNG), the player judging the style switch in the game, with comic versions
   made in Codex later if it bothers them.

10. **The player's words.**

    > yes that's what I've been saying all along

## #758

1. **What the note answered** (the assistant):

   Said after PR #745 asked the player to choose between two robber side alerts by pointing at rows
   3 and 4 of a six-row review sheet.

2. **The note.**

   > yeah 745 is *not* how to present results if you have a question like this -- I do see the 6 row sheets but it's not clear what I'm supposed to decide here

## #759

1. **What the note answered** (the assistant):

   Said unprompted mid-session, while several pull requests were going through rounds of adversarial
   review (#749, #751, #752, #754, #755 had each come back not ready at least once).

2. **The note.**

   > add a rule / note that if a review returns unsuccessful three times the approach should be rethought

3. **What the next words answered** (the assistant):

   The agent opened PR #756 adding the rule to the pr-review skill, with its own proposal for the
   edges marked: the count is per PR, over full and delta reviews; it restarts after a written
   rethink; the rethink decides how findings are fixed, not whether.

4. **The player's words.**

   > per PR, yes. rethinking also involves analyzing whether the chosen solution is the right way

5. **What the next words answered** (the assistant):

   The agent reported that #756 quotes the player's words inside the pr-review skill, as the skills
   have done for earlier rules.

6. **The player's words.**

   > where is the playtest recording my words? recording my words inside the skill are not very useful, no?

7. **What the next words answered** (the assistant):

   Continuing on #756 and where the player's words are recorded; the agent said it would file a
   playtest and point the skills at it.

8. **The player's words.**

   > keeping quotes in skills and claude files is just distracting -- just do short links to the actual quote files

9. **What the next words answered** (the assistant):

   Continuing: "keeping quotes in skills and claude files is just distracting -- just do short links
   to the actual quote files".

10. **The player's words.**

    > that's a rule
    >
    > things must stay clean

11. **What the next words answered** (the assistant):

    Continuing on the rule that skills and CLAUDE.md link the player's words instead of quoting them;
    the agent was filing it as an entry that keeps a skill's own reason for each rule.

12. **The player's words.**

    > it's the job of the reviewer to establish that the interpretation is correct. once that is established we don't have to do it on *every* read of the file
