# Playtest gray-dolphin — Tests that mock what they do not test, one object per derived fact, and no live reachability check

2026-11-07.

## #1134

1. **Context** (the assistant's):

   The assistant had just reported on PR #1133 (the rule-loading hooks check, tools/test_rules_hooks.sh, moved out of CI's gates job into a job of its own): "The builder also found that 69% of the hooks check's time goes to the write-guard cases. Each of them is re-run for every mode and for three switch settings. Running those cases in parallel would keep every check. Cutting the repeats would drop coverage, so that one would come to you as a board question first."

2. **The note.**

   > yeah, let's be smart about the tests

3. **Read as:** (the assistant's interpretation, not the player's words)

   Make tools/test_rules_hooks.sh faster: run its cases in parallel, and drop a write-guard case's repeat for a mode or switch value only where that repeat takes the same path through the guard as one kept (the repeats that check a different behavior stay). No other test suite is meant.

## #1145

1. **Context** (the assistant's):

   The assistant had just reported on PR #1144 (three heavy sweeps trimmed, from the player's ci-speed answer, inbox #1130 in brisk-moose): "The trims go slightly beyond the pick you accepted in two places, and I've asked the reviewer whether either sweep ever caught a real bug:
   - the masked man's respawn test now stops once five men have come;
   - one more crowd window, the plain edge on four sides, is cut from 20 s to 10 s."

2. **The note.**

   > it's fine

3. **Read as:** (the assistant's interpretation, not the player's words)

   The two trims beyond the accepted pick stay in PR #1144: the masked man's respawn test stops once five men have come, and the plain-edge, four-sides crowd window is 10 s instead of 20 s.

## #1154

1. **Context** (the assistant's):

   The player asked "if it has abstract does it also have override? so it's clear that a method comes from the interface?" The orchestrator answered, after testing on Godot 4.7.2:

   "No, there's no `@override`. Godot 4.7.2 rejects it with `Parse Error: Unrecognized annotation: "@override"`. I checked on the installed engine.

   `@abstract` does give you part of what `@override` would. I tried both cases on a base class with an abstract `f() -> int`:
   - **A subclass that leaves `f` out fails to load:** "must implement "Base.f()" … or be marked as "@abstract"".
   - **A subclass whose `f` has a different signature fails to load too:** "The function signature doesn't match the parent".

   What it doesn't catch is a misspelled name, such as `func ff()`. That just becomes a new method, and a reader can't tell from the subclass alone which methods come from the base. The only way to mark that inline is a convention, like a `## Overrides Base.f.` doc comment. If you want, I can queue a lint check that holds such a comment true against the base class."

2. **The note.**

   > let's do the comment and lint

3. **Read as:** (the assistant's interpretation, not the player's words)

   Every method that overrides a method of a project ancestor class carries a `## Overrides <Ancestor>.<method>.` doc comment line, and a lint check run by `tools/lint.sh` fails on an override without the line and on a line that names no ancestor method. Built now rather than queued. Proposed, not asked for: engine virtuals such as `_ready` and `_draw` are exempt (they override engine classes, not the project's), and the line names the nearest ancestor that declares the method.

## #1155

1. **Context** (the assistant's):

   Written on the board's You line under the question crowd-lanes-on-navigator: "should the crowd's lane movement (how walkers and cars follow their sidewalk and road lanes, step by step) move onto the map's one navigator, the piece that steers her and the pursuers, as part of the refactor?" Its context said moving it is a behavior change, not a refactor step, and the orchestrator's pick was no: close shared-components with the reason in its record and file it as a later idea.

2. **The note.**

   > what's the benefit of the new design over the old?

3. **Context** (the assistant's):

   The player quoted the orchestrator chat reply "gains very little" (on crowd-lanes-on-navigator: the lane movement already asks the same blocked record as the navigator; the navigator would add its swept step and one code path, against the costs of lane-following on top, a per-frame check in the busiest loop, slightly different motion, and a bug never seen) and asked this.

4. **The player's words.**

   > gains very little. -- what is the gain from a design standpoint?

5. **Context** (the assistant's):

   Answers the orchestrator chat reply: "What stands against it is cost, not design: every walker and car would move slightly differently, so it needs pictures and remeasuring." with the changed pick to file lanes on the navigator as its own piece of work right after the refactor's remeasuring.

6. **The player's words.**

   > slightly differently as in...? bad differently or good differrently? not sure we need remeasuring, though -- of what?

7. **Note** (the assistant's):

   The board question crowd-lanes-on-navigator is removed at the player's words in the next item, said in the session as a rule for the board's questions that were fully discussed in the chat. Its standing pick, from the chat: lane movement on the navigator is not part of the refactor; it is filed as a piece of work of its own after the refactor's remeasuring, with the navigator's header corrected meanwhile to name the crowd's lane step as the exception.

8. **The player's words.**

   > remove questions that we already fully discussed in the chat session.

## #1156

1. **Context** (the assistant's):

   Written on the board's You line under the question spoiled-ground-test-day: "is a test day built by closing nearly every street acceptable as the one check of the "spoiled calm ground" rule?" Its context named the rule as `EventScheduler._is_spoiled()`, which decides which calm ground (a park or quiet block) the walkability repair keeps a route to when it has to drop event bodies: a clean one over one an event has spoiled. Options were (a) keep the check PR #1147 built, (b) no check, (c) remove the rule; the orchestrator's pick was (a).

2. **The note.**

   > is spoiled is a property of the city state (or something along that line). why is it in EventScheduler as private property? Where should that flag live?

3. **Context** (the assistant's):

   The player quoted the orchestrator chat reply "nothing stores "spoiled"" (on spoiled-ground-test-day: spoiled is worked out while the day is planned, from the planned events on a calm area, so it belongs to the day's plan, not the city; the same reading is written twice in EventScheduler) and asked this.

4. **The player's words.**

   > nothing stores "spoiled". -- how does it survive game loads?

5. **Context** (the assistant's):

   Answers the orchestrator board reply on spoiled-ground-test-day: the same spoiled check is written twice in EventScheduler (_ensure_one_usable_park and _is_spoiled); pick (1) one shared check now, (2) later the day's plan as an object of its own with "which events spoil this area" as its public question; and that what survives a load is the input (the seed, the day, SettledState), not the result.

6. **The player's words.**

   > have an object that contains the derived information -- don't rederive over and over again -- then pass that object around -- that way you don't need a private method and you don't have to worry about inconsistent resolution

7. **Context** (the assistant's):

   Follows the player's previous words on this note ("have an object that contains the derived information -- don't rederive over and over again -- then pass that object around ..."), said while the orchestrator was answering.

8. **The player's words.**

   > like you have a save file and a save state those are not necessarily the same thing

9. **Read as:** (the assistant's interpretation, not the player's words)

   The save file holds the inputs (the run seed, the day, SettledState); a state object built from them holds what is derived (which calm areas the day spoiled and by which events), once, and is handed to whoever asks. The derived state is not written to the file; it is rebuilt from the file on load.

10. **Context** (the assistant's):

    Two messages in a row, following "like you have a save file and a save state those are not necessarily the same thing" on this note.

11. **The player's words.**

    > you can store the game however you like as long as you have a unified way of reading information from it
    > that has the job of deriving the current state

12. **Context** (the assistant's):

    Follows "you can store the game however you like as long as you have a unified way of reading information from it" / "that has the job of deriving the current state" on this note.

13. **The player's words.**

    > that's what encapsulation and isolation means

14. **Context** (the assistant's):

    Follows the orchestrator chat reply that the spoiled check is written twice in EventScheduler over the raw plan list, and the design-first build of one object that derives the day's state and is handed around.

15. **The player's words.**

    > try finding more such cases -- that's a code smell

16. **Read as:** (the assistant's interpretation, not the player's words)

    Search the code for the same smell elsewhere: one fact derived in more than one place from raw data (or a private method re-deriving what another place already worked out), where an object holding the derived state, read through one interface, should own it.

17. **Context** (the assistant's):

    Said after the orchestrator put the day-plan object design (draft PR #1158) and the eight further re-derived-state cases on the board.

18. **The player's words.**

    > the resulting objects should be injectable so you can mock them in tests. that should simplify a lot of tests, too

19. **Context** (the assistant's):

    Follows "the resulting objects should be injectable so you can mock them in tests. that should simplify a lot of tests, too" on this note.

20. **The player's words.**

    > since you only need to check the actual logic once (for the real object)

21. **Context** (the assistant's):

    Answers the orchestrator chat reply: "The revised design will list the suites that build a whole city and day today just to reach one of those facts, and what each would hand in instead."

22. **The player's words.**

    > explore what those tests want to get out of the city and use that to inform the design of the state object. then mock that out -- the city should never be built for tests that don't test the actual city

23. **Read as:** (the assistant's interpretation, not the player's words)

    Survey every test that builds a city (or a day, or main) and what it actually reads from it; let those reads shape the state object(s) and their public questions; then tests that do not test the city itself hand in a fake of that object instead of building a city. Only city tests build a city.

24. **Context** (the assistant's):

    Board question day-plan-design: "build the day's plan as one object, as designed in draft #1158? (blocks the build)". My pick: yes.

25. **The player's words.**

    > yes

26. **Context** (the assistant's):

    Board question day-plan-after-dawn: "does the plan object's live form after dawn come in a PR of its own, right after the dawn one?" My pick: yes, its own PR right after, with the door-body fix in it.

27. **The player's words.**

    > yes

28. **Context** (the assistant's):

    Board question day-plan-name: "what is the plan object called?" Context: the designer first called it DayPlan, beside DayPlanner.Plan. My pick: DayEvents.

29. **The player's words.**

    > DayState? DayEnvironment? DayEvents works also -- name after what you get out of it, not how you construct it

30. **Context** (the assistant's):

    Board question re-derived-state-cases: "build the eight cases in the order of my pick?" Pick: case 1 (what blocks the way) in the day-plan object's live form after dawn; case 2 (door flag) in the same PR; cases 5 and 8 join the day-plan build; cases 3, 4 and 6 one small PR each; case 7 once the plan object exists.

31. **The player's words.**

    > yes

32. **Context** (the assistant's):

    Answers the orchestrator's chat relay of the new designing-classes sentence in PR #1162, written from the player's board words "name after what you get out of it, not how you construct it" (this note).

33. **The player's words.**

    > - "A class is named for what a caller gets out of it, not for how it is built." --- I think it's worth clarifying that this applies to interfaces/base classes/abstract classes. the concrete implementation then is named after what the implementation is

34. **Context** (the assistant's):

    Answers the orchestrator's chat relay of the new designing-classes sentence in PR #1162.

35. **The player's words.**

    > - "A state object's interface is chosen from what its readers want out of it." -- there is some additional nuance here. there are two tests to check the quality of an API: 1) would anyone miss it if we removed a method/argument/etc 2) can we swap out the underlying implementation without having to break the interface? a good rule of thumb is that three distinct implementations typically confirm robustness of an API. but that is clearly not a requirement. we don't want to force at least three implementations just for the sake of it

36. **Context** (the assistant's):

    Answers the orchestrator's chat line: "The fakes give us a second implementation for free: each fake the day-plan and hand-in work adds tests whether its interface can be swapped."

37. **The player's words.**

    > fakes are not really implementations since all they do is provide a look-up for what the API should return in a given situation. a mock doesn't provide meaningful return values for inputs outside of its test so they're not a proper/valid implementation of an interface. in case that's what you meant

## #1159

1. **Context** (the assistant's):

   Said in the session after "explore what those tests want to get out of the city and use that to inform the design of the state object. then mock that out -- the city should never be built for tests that don't test the actual city" (inbox #1156), while a survey of the ~179 tests that build a city was running.

2. **The note.**

   > no test should build a real object that it doesn't test (it should mock it) and test modules should only test the module they are named for. only combine testing responsibilities if there is a good reason

3. **Read as:** (the assistant's interpretation, not the player's words)

   A rule for every test, not only the city: a test hands in fakes for every collaborator it does not test; a test file named for a module (test_<module>.gd) tests that module alone; a suite covering several modules needs a stated reason (an integration check).

4. **Context** (the assistant's):

   Said right after the rule captured in this note, while surveys of what tests build and read were running. The refactor (minty-quail) made components take their dependencies handed in (minty-lemur #794) but kept every test as it was (test parity, inbox #813 in curly-moose).

5. **The player's words.**

   > I feel like asking you to refactor to use dependency injection fell kind of flat since you didn't actually make use of that during testing

6. **Context** (the assistant's):

   Follows the orchestrator's reply owning that the dependency-injection refactor never handed fakes in tests, and its plan: every design says what its tests hand in, the repairs become a public piece handed the day-plan object, and a test pass where each module's suite fakes everything else.

7. **The player's words.**

   > you can use what is currently being built in the tests to inform what values to set when mocking

8. **Read as:** (the assistant's interpretation, not the player's words)

   When a test switches to a fake, the values the fake is set to come from what the real objects the test builds today actually answer, so the test keeps checking the same situation.

9. **Context** (the assistant's):

   Follows "you can use what is currently being built in the tests to inform what values to set when mocking"; the orchestrator had proposed a recording wrapper that logs each question a test asks a real object and its answer, as the fake's setup.

10. **The player's words.**

    > in general -- if you want realistic mocks, first actually create the whole state and then in the next step replace the state with only its external information via mock. the final PR in that case wouldn't contain the original fully created object but only the mock

11. **Read as:** (the assistant's interpretation, not the player's words)

    A method in two steps while building a converted test: first build the whole real state and read off the external information the test uses; then replace the state with a mock holding only that information. The committed test holds only the mock, never the real build or a recording step.

12. **Context** (the assistant's):

    Answers the orchestrator chat reply: "The trap: any test whose recorded values are the very thing it checks. Faking those would make a test that can't fail, so they stay on the real object."

13. **The player's words.**

    > you need to make sure you only mock what you don't want to test. and ideally you only want to test one thing at a time (the <x> from your test_<x>)

14. **Read as:** (the assistant's interpretation, not the player's words)

    Not "such a test keeps the real object": a test keeps real only the <x> it is named for and mocks the rest; a check whose subject is another object's answers belongs in that object's own suite, and moves there.

15. **Context** (the assistant's):

    Follows the rule that test_<x> keeps only <x> real and mocks the rest, with a check of another object's answers moving to that object's own suite.

16. **The player's words.**

    > this should result in test becoming much faster, too

17. **Context** (the assistant's):

    Said in the session while the writing-tests skill (PR #1162) was being fixed. The moved testing policy keeps relationship tests between Tuning constants, such as CAR_HORN_TIME >= required_horn_time(), and deletes a test that only reads a design decision back to itself (PLAYTEST-67).

18. **The player's words.**

    > another thing: a test must never test configuration settings

19. **The player's words.**

    > does that rule make sense to you or do you want me to elaborate further?

20. **Context** (the assistant's):

    The orchestrator's reply between the two: "Mostly, yes. I read it as: a test never asserts what a setting is. For example, a test checking `act_for_day(4) == 2` only restates the act table, so changing a number means editing the test too, and it can never catch a bug. The current testing policy already deletes those, but as a judgment call. Your rule makes it absolute.

    There's one case I'd like you to elaborate on: tests that check a relationship between settings rather than a value. The policy keeps a few of these on purpose. An example is "the car's horn sounds for at least as long as she needs to react" (`CAR_HORN_TIME >= required_horn_time()`). It encodes why a number has a floor, and it fails when someone lowers the horn time below what's fair.

    Is that testing configuration too, so it goes? Or does it stay as a check of a fairness guarantee? I'd keep those few. Every other test that reads a setting only to restate it goes."

21. **The player's words.**

    > that's fine

22. **Read as:** (the assistant's interpretation, not the player's words)

    A test never asserts what a setting is (absolute, no judgment call); the few tests of a relationship between settings that encode a fairness guarantee stay.

23. **Context** (the assistant's):

    Board question test-isolation-plan: "convert the tests in the order of my pick?" Pick: 1 fix the full-run and balance tests to start days the game's way; 2 the day-plan object and its live form; 3 hand-ins for the six classes that demand a whole city, main.use_city_map(), a shared writer for small test maps; 4 convert and split the tests module by module with suite times before and after; 5 cache the cities a few rigs rebuild.

24. **The player's words.**

    > yes

25. **Context** (the assistant's):

    Board question test-mocking-is-a-rule: "is mocking what a test does not test now a hard rule?" Context: before today "a test is designed around one isolated component, as guidance rather than a hard rule" (inbox #1018 in brisk-ferret); the new writing-tests skill (#1162) wrote it as the old guidance made a rule on 2026-11-06. Pick: a rule; a test module tests only its own module unless its header states the guarantee that spans modules.

26. **The player's words.**

    > as written it obviously didn't work. we need it to be a hard rule with exceptions only with good reasons

27. **Context** (the assistant's):

    Board question test-real-city-suites: "which suites may still build a real city?" Context: #1162 lets any suite checking "wiring" (events retiring, successors, scars) build one; the narrower reading is only a named suite whose header states the cross-module guarantee it checks, such as the three full-run suites. Pick: named suites only, each stating its reason in its header; "wiring" is not a category of its own.

28. **The player's words.**

    > give reasons for any case that is not a direct city test

29. **Context** (the assistant's):

    Board question test-plain-values: "are plain values and data built as they are, not mocked?" Context: the rule says mock every real object a test does not test, but not what that means for a value (a position, a color, a day's spec). Pick: yes, only collaborators that do something are mocked.

30. **The player's words.**

    > yes

31. **Context** (the assistant's):

    Board question test-convert-on-touch: "does a PR that touches an old suite for another reason convert it?" Context: about 100 suites build real objects they do not test; the conversion goes module by module (test-isolation-plan). Pick: only as far as the PR's own change reaches.

32. **The player's words.**

    > only as far as the pr goes

## #1161

1. **Context** (the assistant's):

   Asked after the session's rules on tests (inbox #1159: mock every real object not under test, test_<x> tests only <x>, realistic mocks built in two steps with only the mock committed, only mock what you do not want to test) and on design (inbox #1156: an object holds derived state, built once, read through one interface, injectable, encapsulation and isolation; re-derived facts are a code smell; inbox #1154: overrides marked).

2. **The note.**

   > are those rules captured in a writing tests skill? so future tests don't have the same issues? also what about a designing classes skill that makes sure of the other rules from this session?

## #1163

1. **Context** (the assistant's):

   Said after the orchestrator put several board questions that each bundle more than one choice: day-plan-design (build it, plus three open choices), re-derived-state-cases (which to build and in what order), test-rules-strictness (two choices plus two proposals).

2. **The note.**

   > keep one question per question on the board

3. **Context** (the assistant's):

   The board then held crowd-lanes-on-navigator, spoiled-ground-test-day and the settled day-plan-test-copy, all discussed in the chat; and day-plan-design, day-plan-after-dawn, day-plan-name, re-derived-state-cases, test-isolation-plan, test-mocking-is-a-rule, test-real-city-suites, test-plain-values and test-convert-on-touch, which were not.

4. **The player's words.**

   > remove questions that we already fully discussed in the chat session.

5. **Context** (the assistant's):

   Said about the board, after the orchestrator answered questions on their Me lines (each question has one You line and one Me line under My pick).

6. **The player's words.**

   > also when adding your reply always add the next You:  already

7. **Read as:** (the assistant's interpretation, not the player's words)

   When the orchestrator writes its reply on a Me line, it adds a fresh empty You: stub (and its Me: stub) right after, so the player can answer again in line without making the line themselves.

8. **Context** (the assistant's):

   Said about the board, whose open questions each held their Context as one long paragraph.

9. **The player's words.**

   > use formatting in the board. your walls of text are unreadable. also use images if you want

10. **Context** (the assistant's):

    Follows "use formatting in the board. your walls of text are unreadable. also use images if you want".

11. **The player's words.**

    > if they help you communicate

12. **Context** (the assistant's):

    Said about the board, whose questions numbered their options inside one paragraph, e.g. "(1) ... (2) ... (3) ...".

13. **The player's words.**

    > regarding board formatting I don't want to see inline numbered lists -- they are unreadable

## #1167

1. **Context** (the assistant's):

   Asked in the session after the board rules on formatting ("also use images if you want" / "if they help you communicate", inbox #1163).

2. **The note.**

   > can you do svgs in the board? can you create a tab on the board with a full er diagram (potentially simplified if it gets too cluttered) of the whole system

3. **The player's words.**

   > or mermaid if the board renders it

4. **The player's words.**

   > is that the current design or the proposed design?

5. **Context** (the assistant's):

   The orchestrator answered the first: the System map tab shows the current design on main at #1160 (0f5999af), with the proposed DayEvents/CalmAreas (#1158) and DayStreets/CityFronts hand-ins (#1166) not in it; it offered a third "after the planned changes" diagram.

6. **The player's words.**

   > recreate it when the current redesign is complete

## #1168

1. **The note.**

   > is there any coding a subagent could do in parallel?

2. **Context** (the assistant's):

   The orchestrator answered the first question with three pieces of work that touch nothing the after-dawn design (DayEvents after dawn) or the city hand-ins (draft #1166) touch:
   1. Booted suites write into the player's user://telemetry: suites that boot main without --no-telemetry write rig run folders there (breaks "tests touch nothing real", inbox #984 in brisk-pelican). Fix in the test runner and suites only.
   2. test_telemetry's about 15 TelemetryObserver checks move to an observer suite on the fake log (tests/recording_log.gd), under writing-tests (test only).
   3. bake-atlases.sh runs Godot's pre-import only when the class cache is missing.
   It proposed: "My pick is 1 and 2 in parallel on Sonnet, each in its own worktree and PR. Shall I start them?" The player's "do it" answers that.

3. **The player's words.**

   > do it

4. **Read as:** (the assistant's interpretation, not the player's words)

   Start 1 and 2 now, on Sonnet, each in its own worktree and PR; 3 stays unbuilt.

## #1172

1. **Context** (the assistant's):

   Said in the chat on 2026-11-07, in reply to the orchestrator's explanation of the board question city-hand-ins-design (draft PR #1166, the six classes that demand a whole City take narrow hand-ins). The part of that explanation it answers, as shown:

   "**Checked before designing.** A city builds and runs on a hand-drawn map with no errors, and the crowd stays on the streets.
   - **Size limit:** the street network and the crowd's lanes are fixed to the full 11×11 blocks. On a smaller map, 4 of 234 walkers walked off its edge. So a "small" test map means a few streets painted on a full-size map.
   - **Not for full game days:** such a map is never handed to a booted day. It planned 473 events and has no home and no calm ground."

   and "**One shared tool writes the test maps.** The generator's street-painting step moves into its own class (`StreetLayout`), and a test fixture paints streets with it."

2. **The note.**

   > use hand drawn maps where you want to test specific interactions between the player and their environment. hand crafting here makes it easier to construct edge cases (since you don' need to find the right seed). if you test realistic walks you need a real map (otherwise the crowd walks off) and the measurements wouldn't come from something that is proven to exist.

3. **Read as:** (the assistant's interpretation, not the player's words)

   A rule for choosing a test's map: a test of a specific interaction between her and her surroundings (an edge case) uses a hand-drawn map, built to the case rather than found by searching seeds; a test of a realistic walk, and any measurement, uses a real generated map, because a hand map lets the crowd walk off and a measurement must come from a city the generator can produce. Belongs in the writing-tests skill; #1166's test-map writer is for the first kind only.

## #1173

1. **Context** (the assistant's):

   Board question city-maps-later, answered on the You line on 2026-11-07. Question: "does main.use_city_maps() move from this step to the city-cache step? (does not block)". Context as shown: "You approved: it as part of this step (test-isolation-plan step 3)." / "The designer found: nothing in this step could hand main an honest map yet; the existing recipe copy of a map loses its calm blocks and fails validation." / "Step 5: caching the cities rigs rebuild needs a real map copy anyway." My pick: "Yes: build it with the cache in step 5, once a map can be copied whole." / "If you leave this, it moves."

2. **The note.**

   > yes

3. **Context** (the assistant's):

   Board question observer-route-tree, answered on the You line. Question: "should the run-log observer use the city's route tree instead of growing its own? (does not block)". Context: "Today: the city grows the day's route tree before the closures; the observer grows its own after them." / "Risk: the run log may describe a different route tree from the one she plays." / "Same smell: one fact worked out in two places." My pick: "Yes: the observer reads the tree from DayStreets." / "First check whether the two trees ever differ, and report it if they do." / "If you leave this, it is built that way."

4. **The player's words.**

   > why would the run log do its own tree? of course, the observer needs to read the actual tree from DayStreets

5. **Context** (the assistant's):

   Board question settings-guarantees, answered on the You line. Question: "does the exception for tests that compare two settings cover only fairness, or any guarantee between settings? (does not block)". Context: "Your rule: 'a test must never test configuration settings'; you said 'that's fine' to keeping fairness checks between two settings." / "The skill now keeps: only comparisons that guard fairness." / "Tests that are not about fairness:" "A late day holds more events than an early one: the difficulty ramp." / "The building's distant window flashes average the wait their setting names: a second number is solved from it, and the test catches the two going out of step." / "The city generator's check that crossing a calm block fills a real share of the sleep meter but never the whole of it, and that the three block sizes are within half of each other." My pick: "Any guarantee between settings stays: fairness, the difficulty ramp, a derived number kept in step with its setting." / "A test that only restates one setting's value goes." / "If you leave this, the skill keeps fairness only and the tests above go."

6. **The player's words.**

   > yes

7. **Context** (the assistant's):

   Board question after-dawn-design (draft #1169), the player's reply on the You line. Question: "build the day's events after dawn as designed in draft #1169? (blocks the build)". Context: "What it is: the next step of your one-object rule: #1158 did the day's plan at dawn; this does the live events after dawn." / "One reader: WalkEvents holds the walk's events and keeps what blocks her way, the checkpoint doors and her reachable ground in step as events appear, are placed and finish. Every place that asks reads it, handed in." / "One rule for what blocks her way:" "Today four places work it out for themselves and disagree." / "After: one rule (placed, not finished, not a checkpoint door, and a body or a hard fail), asked by all four." / "Deliberate differences stay as settings: the resistance counts the soft seals; the park cordon counts the checkpoint huts, since a guard there stops her." / "The checkpoint door, decided once: one flag on the plan, set where the doors are made; three of the other ways move to it." / (the bug it fixes, not moved, size) My pick: "Yes." / "If you leave this, it is built that way."

8. **The player's words.**

   > why a rule? what is the interface here?

9. **Context** (the assistant's):

   Board question finished-events-block, the player's reply on the You line. Question: "should an event that has already played out stop counting as blocking her way? (blocks one commit of #1169; the rest goes on)". Context: "Today: only the park cordon (the fence round a spent park) skips finished events; the other three places still count a finished event's ground as shut." / "Effect: after dawn, some events would land in places they are refused today, since less of the street reads as shut." / "Cost: it changes where things land, so it gets its own commit and measurement, like the door fix." My pick: "Yes: a finished event no longer blocks anything, so it should not count." / "If you leave this, it is built that way."

10. **The player's words.**

    > can you elaborate how a finished event can block a placement of a new event? it's not like we're placing events on the same location multiple times

11. **Context** (the assistant's):

    Board question walk-events-name, answered on the You line. Question: "is WalkEvents the right name for the reader of the walk's live events? (does not block)". Context: "What a caller gets: the events of the walk under way: what blocks her way, the checkpoint doors, where she can still get to." / "Beside it: DayEvents is the day's events as planned at dawn." My pick: "WalkEvents." / "If you leave this, it stays."

12. **The player's words.**

    > yes

13. **Context** (the assistant's):

    Board question city-hand-ins-design, the player's reply on the fresh You line. Orchestrator's Me reply it answers: "your map rule from the chat is folded in (inbox #1172). One part is still open." / "Hand-drawn map: for a test of one interaction between her and her surroundings, built to the edge case instead of hunting for a seed. The shared map writer in #1166 is for this kind only." / "Real generated map: for a realistic walk and for every measurement, so the crowd stays on the streets and the number comes from a city that can exist." / "The writing-tests skill gets this rule." / "Still open: yes to building it in three PRs? I would also move one happenings test onto the fake event manager and the fake fronts in the second PR, so no new seam lands without a test using it (inbox #1156)." / "Ready now: the first PR (DayStreets) can start; #1158 and #1160 have merged."

14. **The player's words.**

    > yes three prs is fine

15. **Context** (the assistant's):

    Board question after-dawn-design (draft #1169), the player's reply on the fresh You line. Orchestrator's Me reply it answers: "there is no separate rule object; "rule" was my word on the board, and a poor one. The interface is WalkEvents, the walk's live events:" / "obstructions(besides): the events blocking her way right now, kept up to date as events are added, finish or are placed. besides leaves out the one being moved." / "shut_ground(as_the_arrow_reads): the tiles shut to her: the closed streets plus those bodies. Asked with true, it adds the sidewalk a soft seal shuts, which the resistance needs because the red arrow cannot walk it." / "door_bodies(): the checkpoint huts, booms and guards standing. The park cordon adds them, since a hut stops her." / "grid(), calm(), doors(): the walk's reachability grid built once, the day's calm areas, where the doors stand." / "Who asks it: the placing of events ahead of her, the resistance and the park cordon. Today each filters the raw list of plans itself, four different ways." / "What I called the rule: one method on each placed event, "does this one block her" (placed, not finished, not a door, and a body she cannot pass or a lethal field). Only WalkEvents after dawn and DayEvents at dawn ask it, to keep their lists. No consumer asks it." The player's reply quotes two phrases of it between "--" marks.

16. **The player's words.**

    > -- Today each filters the raw list of plans itself -- this should not happen. that's what we have interface for. -- one method on each placed event -- yes that makes sense. provide a consistent interface for events that can be used without knowing details of the event. that applies to all aspects of events. that's kind of object oriented design 101 but don't forget about composition over inheritance

17. **Read as:** (the assistant's interpretation, not the player's words)

    Yes to building #1169. A principle for events in general: whoever uses an event asks it through one consistent interface and never reads its details (its fields), for every aspect of events, not only what blocks her; behaviour is put together by composition rather than by subclassing. Outside src/events, 20 files under src/ read an event definition's fields directly (for example obstructs_radius, redetains, hard_fail, detain_seconds), so "all aspects" reaches past #1169; asked on the board as events-one-interface.

18. **Context** (the assistant's):

    Board question finished-events-block, the player's reply on the fresh You line. Orchestrator's Me reply it answers: "it never blocks the spot. It skews the check of whether a new spot cuts her off." / "The check: before a mid-walk event is placed (day 3's fire, day 11's added mast, day 13's roadblock and barricade), the code paints everything already blocking onto the map and floods out from her. With the new event there, home and a calm area she has not used must still be reachable." / "The ghost: a finished event (a fire burned out, a roadblock gone) stays in that list. Its disc still paints its street shut, though nothing stands there." / "Example: she has two ways home, streets A and B. A held a roadblock that has since left. A barricade offered on B is refused: A still reads shut, so B looks like her last way. In truth A is open." / "Other direction: ..." / "Size: not measured yet. ..." / "Only the placing ahead of her moves: the resistance takes its snapshot before anything finishes."

19. **The player's words.**

    > are you talking about multiple days here? otherwise how does the fire burn out?

20. **Context** (the assistant's):

    Board question finished-events-block, the player's reply on the fresh You line. Orchestrator's Me reply it answers: "no, one day. My example was wrong: a fire does not burn out within the day. What finishes within one walk:" / "Set-piece copies: the day offers the fire engine on every route she might take. Once she meets one, the copies on the other routes are spent without ever entering the street." / "An event that has run its course and does not repeat." / "A departure streamed out: someone leaving as she walks away does not come back." / "Taken away: the plans the park cordon clears from inside its fence." / "Corrected example: she has two ways home, streets A and B. A carried a copy of the fire engine, spent because she met the engine on another route. A barricade offered on B is refused: A's copy still reads shut, so B looks like her last way. In truth A is open." / "The map already knows: each of these gives its ground back in the map's exact record, so walkers pass. Only the placing check still counts it."

21. **The player's words.**

    > why are there copies on the other routes? we designed so that the event is placed dynamically -- the whole statement doesn't make any sense

22. **Context** (the assistant's):

    Board question events-one-interface, the player's reply on the You line. Question: "does "all aspects of events" mean a pass of its own over every place that still reads an event's details, after #1169? (does not block)". Context: "You said: events get a consistent interface usable without knowing their details, for all aspects of events; composition over inheritance (on after-dawn-design)." / "#1169 covers: what blocks her way and which bodies are checkpoint doors, both asked of the event instead of read off it." / "Still reading details: 20 files outside the events code read an event's settings directly: how wide its body is (25 reads), whether it holds her again (16), how long it holds her, whether it ends the day." / "Who reads them: the HUD, the resistance, the park cordon, the crowd, the city, the run log, the page counter, the cause of a lost day, the developer's rigs." / "Composition: an event's abilities (a body, a hold on her, a lethal field, a pursuit) become parts it has, each answering its own questions, instead of subclasses or settings read from outside." My pick: "Yes: #1169 applies it to everything it touches; a survey of the rest comes to the board as its own design after the hand-ins." / "The designing-classes skill gets the principle now." / "If you leave this, it is done that way."

23. **The player's words.**

    > yes. also never read fields directly. always read through a method (does gd support python style properties?) so you can swap out a field with a computation if needed. fields are not API interaction between different objects need to go through APIs. those are fundamental principles -- not sure why you don't apply fundamentals in your designs

24. **Read as:** (the assistant's interpretation, not the player's words)

    A rule for every class, not only events: no object reads another object's fields; every interaction between objects goes through the other object's API (a method, or a Python-style property if GDScript has one), so a stored field can later become a computation without changing its readers. The player expects these fundamentals in every design, the orchestrator's included.

25. **Context** (the assistant's):

    Board question finished-events-block, the player's reply on the fresh You line. Orchestrator's Me reply it answers: "you're right, and my statement was wrong. The fire is placed dynamically: the day owes it to her walk and sites it on her way once her heading is clear. No copies exist in play." / "Where the copies came from: an older placing mechanism is still in the code: a set piece offered at every site of a covering set, the rest spent once she meets one. No catalogue row reaches it today; the fire, the only one-shot, takes the dynamic path. I read its doc comment as live. It is dead code, and its removal goes in the queue." / "What can really be spent within one walk: an event that ran its course and does not repeat; someone streamed out while leaving; the plans the park cordon clears from inside its fence." / "Whether any of those still blocks her way: not known. It counts only if it has a body she cannot pass or a lethal field." / "Next: the builder counts it on the six probe seeds. ..." / "My pick stays yes: a spent event is gone, so one rule skips it." The player quotes its first item between "--" marks.

26. **The player's words.**

    > -- an event that ran its course and does not repeat; -- then it was never blocking to begin with. give me a concrete example of your question

27. **Context** (the assistant's):

    Board question api-methods-or-properties, answered on the You line. Question: "does one object read another's value through a method, event.radius(), or may it use a property, event.radius with a getter? (does not block)". Context: "You said: never read fields directly; read through a method so a field can become a computation; fields are not API." / "GDScript 4 has Python-style properties: var radius: float: get = _get_radius. A caller writes event.radius either way, and the field can become a computation without touching callers." / "The catch: at the call site a property and a plain field look the same, and GDScript has no private fields, only the underscore convention. A reader cannot tell API from internal, and a script cannot easily check it." / "Methods across objects: event.radius() is visibly API, and a check like the existing test-only-members check can flag any read of another class's plain field." / "Properties allowed: shorter to read, but the check has to look up each member's declaration to tell a property with a getter from a plain field." My pick: "Methods across objects; a property only inside its own class." / "If you leave this, it is built that way."

28. **The player's words.**

    > yes

29. **Context** (the assistant's):

    Said in the chat on 2026-11-07, discussing the board question finished-events-block (the player asked to discuss it in the chat). The orchestrator's message it answers listed three options: "1. Ended events stop counting. WalkEvents' "what blocks her now" skips them, so the placement check agrees with the map's record. ... It's my pick." / "2. Keep counting them. ..." / "3. Go further: after dawn, the placement check reads the map's record directly, plus the lethal fields of the events still live ... its own PR". Before that the orchestrator had explained, with a street A / street B picture, that the check before a mid-walk placement asks whether she can still get home and to an unused calm area, so a stale finished event on street A changes whether a barricade on street B is allowed.

30. **The player's words.**

    > why would the live state influence the route? the safe routes are established before the day starts. event placeholders are placed alongside the routes. when the player walks they get filled in with non-blocking events from the bag. a blocking event is never placed. and there is no reason to check whether a route is open during game play because it cannot be closed to begin with. you're not making any sense

31. **Note** (the assistant's):

    The code as it stands: the bag's placeholders are filled with non-blocking rows as the player says, but a few authored beats are placed during the walk with a reachability check (EventScheduler.WalkSiting._still_leaves_a_park_reachable): day 3's burning building (sited late on her way, PLAYTEST-117), the barricade day 13's police column leaves (docs/EVENTS.md, military_convoy row: placed "at the first such point whose barricade still leaves her a way home and to a calm area"), day 13's task roadblock and day 11's added mast. Put to the player as whether those beats stay live-placed blockers.

32. **Context** (the assistant's):

    Said in the chat on 2026-11-07, answering the orchestrator's two questions: "1. Remove the live check? Should the beats placed during the walk keep to the dawn routes, so the live reachability check can go? Those beats are day 13's police-column barricade, day 13's task roadblock, day 11's added mast and day 3's fire. This would replace #1169's held commit. My pick is yes." / "2. If yes, which form: may the barricade and roadblock stand only off the day's safe routes, or are they decided at dawn?"

33. **The player's words.**

    > we cannot move them to the dawn route since they get placed close to the player. what we can do is replace already placed off-route blocking events with them off screen. of course only replace events that were placed there, not things like guard houses or district barriers. there should be no live reachability check. that's a hard no. what do you think?

34. **Read as:** (the assistant's interpretation, not the player's words)

    No live reachability check anywhere (a hard rule). A blocking beat that has to land near her during the walk takes the place of a blocking event the day already placed off the safe routes, swapped in out of sight; only events the day's plan placed are replaced, never the region wall's guard houses, doors or barriers.

35. **Context** (the assistant's):

    Said in the chat on 2026-11-07, answering the orchestrator's reply on replacing off-route blocking events. The parts it answers, as shown: "The swap rule I'd write: the beat replaces an event plan the day placed, off the day's routes and out of her sight; its footprint is no wider than the one it replaces, so it closes no more than dawn already closed; it never replaces the region wall's bodies, the checkpoint huts and booms, or the road closures, which aren't event plans at all." / "There will be candidates. From act IV, which starts on day 12, the day places hard-seal barricades on streets off its routes every morning." / and the closing picks: "1. Only the barricade and the roadblock swap. 2. The resistance's check moves to dawn. 3. The cordon's gap check stays."

36. **The player's words.**

    > the off route events need to be route adjacent. anything deep wouldn't be reachable at all. I agree on the rest.

37. **Read as:** (the assistant's interpretation, not the player's words)

    The event a blocking beat replaces must be off the day's routes but adjacent to them (on a street touching a route), since one deep off the routes is somewhere she would never reach. The rest of the orchestrator's proposal is agreed: only the column's barricade and the task roadblock swap; the added mast and the fire are not blockers and are sited like the bag's events; the resistance's reachability check moves to dawn; the park cordon's gap check stays.

## #1177

1. **Context** (the assistant's):

   Said in the chat on 2026-11-07, in reply to the orchestrator's answer on which walk-placed beats have a red arrow and what day 13's column barricade is. The orchestrator had said: day 3's fire has no marker and is "on your way guaranteed"; the column's barricade is left by the rear of three army trucks on the main road, out of sight beyond her, a solid band 62px across, staying for the rest of the run; and asked whether, under the swap rule (a blocking beat replaces a route-adjacent, off-route blocking event the day placed), the rear truck should turn off the main road to the swapped spot, or the barricade be the swapped-in one round a corner.

2. **The note.**

   > day 3 file is non-blocking so it doesn't need the swap, no? the column barricade is also non blocking so none of the blocking rules apply anyway. it can be placed whenever

3. **Read as:** (the assistant's interpretation, not the player's words)

   "day 3 file" is read as day 3's fire. Neither day 3's fire nor day 13's column barricade blocks her way, so neither takes the swap: the column's barricade is placed whenever and wherever the column stops, like any non-blocking event. The swap applies only to a beat that really closes a street: day 13's task roadblock. Checked against the code: the barricade row is a band laid along the middle of the roadway (`GroundShape.band(62)`), streets are 6 tiles with 2-tile sidewalks each side, so she passes it on the sidewalk; only the act IV hard seals repeat it across the whole width.

4. **Context** (the assistant's):

   Said in the chat on 2026-11-07, answering the orchestrator's proposal: "One proposal for it, open to your correction: any roadblock counts for that day's task, and the red arrow already picks among the day's roadblocks. So the task should prefer a route-adjacent roadblock the day already placed, and swap one in only when none is near."

5. **The player's words.**

   > yes only swap if you can't find one. but we could also place roadblocks route adjacent during dawn. swap only is needed if there is nothing close by

6. **Read as:** (the assistant's interpretation, not the player's words)

   Day 13's task uses a roadblock the day already placed when one is close by; dawn may place roadblocks route-adjacent so one usually is; the swap (replacing a route-adjacent, off-route blocking event the day placed, out of sight) is used only when nothing is close by.

## #1179

1. **Context** (the assistant's):

   Said in the chat on 2026-11-07, answering the orchestrator's question: "So: is the roadblock non-blocking, so day 13 needs no swap? My pick is yes, with the docs corrected to say it leaves the sidewalks open. If you mean it to close the street, its body has to grow to the full width, and then the swap plan stands." The orchestrator had reported the builder's measurement: day 13's task roadblock's body covers two road tiles and the inner sidewalk tile, and both sidewalks keep an open tile at all 2,334 sites sampled.

2. **The note.**

   > even if she can technically walk through it everything about it tells the player to not do that. so let's not assume that a player would use it.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The roadblock counts as blocking her way for planning: what a street shows the player decides it, not whether the body leaves a tile open. So day 13's task roadblock keeps the swap plan (a nearby day-placed roadblock first, route-adjacent roadblocks placed at dawn, a swap only when nothing is close by), and its body is not widened.

4. **Context** (the assistant's):

   Said in the chat right after the note's first words ("let's not assume that a player would use it"), as their continuation.

5. **The player's words.**

   > unless there is a gap with a full sidewalk

6. **Read as:** (the assistant's interpretation, not the player's words)

   An event counts as blocking her way unless it leaves a gap at least a full sidewalk wide (Tuning.SIDEWALK_WIDTH, 2 tiles) for her to pass.

## #1180

1. **Context** (the assistant's):

   Said in the chat on 2026-11-07, after the orchestrator reported that the covering-set path (`EventScheduler._place_a_set_piece`, a set piece offered at every site of a covering set) is reached by no catalogue row any more, and that the orchestrator had earlier read its doc comment as live behaviour and told the player the fire had copies on every route.

2. **The note.**

   > remove dead code or code needed for features that don't exist anymore. it adds to the cost of maintaining the code base and confuses you. if we want a feature back we can just implement it fresh which also guarantees that it adheres to the new design principles.

3. **Read as:** (the assistant's interpretation, not the player's words)

   A standing rule: code nothing reaches, and code that only serves a feature the game no longer has, is deleted rather than kept, since it costs maintenance and misleads whoever reads it; a feature wanted back is built fresh under the current design principles. Applies now to the covering-set path, and to a sweep for the rest.

## #1182

1. **Context** (the assistant's):

   Board question tests-read-fields, answered on the You line on 2026-11-07. Question: "does a test count as "another object" under fields-are-not-API, so it too reads its subject only through methods? (does not block)". My pick: "Yes: a test is a caller like any other, and writing-tests already reads a test that reaches into internals as a sign of testing too much." / "If you leave this, it is built that way."

2. **The note.**

   > yes

3. **Context** (the assistant's):

   Board question field-read-check, answered on the You line. Question: "should a script fail a change that adds a read of another class's plain field? (does not block)". Context: "How: a check like the existing test-only-members check finds every read under src/ of a var another class declares." / "Today's reads: listed once in a shrinking list, as the test-only list does; a new one fails CI." / "Cost: one new tool and its list; no game change." / "Without it: the rule rests on review alone." My pick: "Yes, with the shrinking list." / "If you leave this, it is built that way."

4. **The player's words.**

   > yes

5. **Context** (the assistant's):

   Board question barricade-reads-as-blocking, the player's reply under the orchestrator's "settled:" Me line. That Me line read: "settled: non-blocking by your full-sidewalk rule. The far sidewalk stays fully open at all 360 column stops, and the same holds for the task roadblock at all 2,334 sites, so neither takes a swap and the four roadblock questions are gone. Both are placed near her, out of sight, under the day's normal placement rules; a test holds that each leaves a full sidewalk open." The question's context: the column barricade's body covers two road tiles and the inner sidewalk tile (the builder's later count: per line across the street, the far sidewalk keeps both its tiles and the near side keeps 1).

6. **The player's words.**

   > You: if you place it in the middle of the street it is blocking. The gaps are at either end not contiguous so they don't read as opening.

7. **Read as:** (the assistant's interpretation, not the player's words)

   A body placed in the middle of the street counts as blocking even when tiles stay open beside it, because the open tiles on either side are not one contiguous gap and do not read as a way through. So the column's barricade and day 13's task roadblock, both mid-street, count as blocking; the orchestrator's "settled: non-blocking" is overturned. (The leading "You:" was typed by the player as part of the line.)
