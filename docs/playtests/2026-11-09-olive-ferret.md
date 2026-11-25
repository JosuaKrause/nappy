# Playtest olive-ferret — The refactor's design review, the rules review, the board answers on the events' interface, and typing

2026-11-09.

## #1264

1. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-09, right after the player set the session's model to Fable 5.2, while the session was picking up the refactor (minty-quail) and about to choose a model for the delta review of pull request 1262. It bears on the orchestrating skill's table of which model takes which kind of agent task (Sonnet, Opus, Haiku today).

2. **The note.**

   > also consider using fable for tasks that need planning / complex reasoning

3. **Context** (the assistant's):

   Three messages sent one after another on 2026-11-09, while the session was preparing the four pull requests that apply the rules review (the list of decisions above, whose first point proposed four pull requests). The third is also the player's further word on the topic of issue 1264, which model does which kind of agent task.

4. **The player's words.**

   > for code I'm fine with your choice as long as fable did the design and for the rule/skill/claude changes I want fable to do it directly

## #1265

1. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-09, a few minutes after the note about using Fable for planning and complex reasoning (issue 1264), while the refactor (minty-quail, one engine: the codebase refactored by layer) was the only work running and its placement-by-construction step of the walk draws (pull request 1262) was in delta review.

2. **The note.**

   > have a fable agent review the design of the refactor

## #1267

1. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-09, while a Fable agent was already reviewing the design of the refactor at the player's request (issue 1265) and the 45-minute check's skill change (pull request 1266) was set to merge.

2. **The note.**

   > have another fable agent review all skills/claude/rule files

3. **Context** (the assistant's):

   Said on 2026-11-09 in answer to the session's relay of the Fable agent's review of CLAUDE.md, the 29 skills and the hooks (asked for above). The relay summarised the review's 18 findings (the rules arrive as a 2 KB preview because almost every hook injection is over the harness's inline limit; a builder is told to read about 280 KB of rules; false sentences such as the telemetry skill's frame-timing API and test suites that do not exist; the same rule in three to six files with drifted copies; gaps in the hook rows and the doc lint; the tool catalogue restating each tool's help; the rule files breaking the present-tense and explain-every-name rules) and ended with this list, as shown:

   **Decisions for you**

   1. **Apply it at all, and how?** I'd do it as four PRs, each reviewed:
      - the false sentences and missing hook rows (mechanical);
      - the delivery fix in the hooks;
      - the de-duplication, with one owner per rule;
      - the size cuts and moves to reference files.
   2. **Should the first edit in an area be refused until the skills are read?** It costs one extra step per area per session and guarantees the rules are seen. The alternative is the index alone, which a session can ignore. I'd refuse.
   3. **Board:** read at session start, when you say "doc", and before each write, not every turn. I'd take that; it matches your words.
   4. **Define the orchestrating session** as the top-level session you started to run the queue; any other session merges nothing and writes neither the board nor the restart prompt. I'd take that.
   5. **Branch names:** the skills say `feature/<thing>`; 19 of 20 real branches are `feature-<thing>`. I'd make the dash form the rule.
   6. **Move the "proposed, not asked for" markings to one list per file.** I'd take that.

4. **The player's words.**

   > let's do all the suggested changes for the hooks/skills/claudes etc

5. **Context** (the assistant's):

   Three messages sent one after another on 2026-11-09, while the session was preparing the four pull requests that apply the rules review (the list of decisions above, whose first point proposed four pull requests). The third is also the player's further word on the topic of issue 1264, which model does which kind of agent task.

6. **The player's words.**

   > four PRs is fine with me -- can we parallelize?

7. **The player's words.**

   > let fable do the rule/skill/claude rewrites, though

8. **The player's words.**

   > for code I'm fine with your choice as long as fable did the design and for the rule/skill/claude changes I want fable to do it directly

## #1268

1. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-09, answering its relay of the Fable agent's design review of the refactor (minty-quail, one engine: the codebase refactored by layer; the review was asked for in issue 1265). The message answered, as shown, in its order and numbering:

   **Verdict:** the target is what you asked for and most of it is honestly built. The escape's clock, goal, loss, finish and dawn planning run on the day's code, and the new placement classes are small and tested with fakes. Three things matter most: findings 1, 3 and 4–6 below.

   1. **Placement closes on about 200 fitted numbers.** Density is a chain of correction tables that multiply, each tuned until the new draw reproduces the old algorithm's counts. Five of the listed differences from your design would still stand at close, including "an event drawn from the bag is the event that appears, no rejection" and a street's other locations narrowing once one is drawn. The fitting script lives outside the repo.
      - **Question for you:** is main's measured mix the target or the starting point?
        - (a) Keep refitting to main's counts.
        - (b) Show parity once, then replace the tables with one declared table inside the refactor.
        - (c) Do that as the first entry after the refactor.
      - The reviewer picks (b).

   2. **The walk draws (#1262) are heavy machinery for six events:** the dog walker, the man shouting, the chatting mother, the pigeon flock, the alley mouse and the police patrol. The dawn draws every location and throws away the non-blocking results; the walk then draws them again from a second set of bags with its own correction table. Two disjoint bags from the start would need neither.
      - **Consequence nobody has put to you:** those six now depend on her path, so a retry redraws them. `docs/MECHANICS.md` still says "A retry is the same day… the whole event plan is deterministic from the seed and the day number", and #1262 does not touch that sentence.
      - The reviewer reads your "a retry always rolls new" (PLAYTEST-119 26) as allowing it. I have asked #1262's reviewer to check it.

   3. **A day is finished by one controller but started in three places.** The escape's start is still hand-built in the main scene, with its own run-log path. That is where the fuller escape and the explosions would land next.

   4. **133 listed layer breaks have no owner in any open item.** Four groups have no home in the design: the global signal bus, the city scene building the event manager and crowd, the map interface's world half, and dawn planning reading live-event geometry.

   5. **The event scheduler is a 3,453-line hub** that 65 source files and 119 test files name, and no item breaks it up.

   6. **The order converts the tests before the event code they read,** so the largest test group would be mocked against fields and redone. The reviewer suggests going module by module instead.

   7. **The single remeasure at the end has no stored "before".** No baseline commit is named and no winnability or route-cost numbers from before the refactor are saved. Capturing them now blocks nothing.

   8. **The escape city's draw is still a second loop** with its own marble rules. Low urgency; the reviewer would fold it into the fuller-escape entry.

   Smaller points:
   - The field-read check skips about two thirds of reads because it cannot tell the receiver's class.
   - The entry's README layer list is stale.
   - The entry has no stated end.

2. **The note.**

   > 1. (b) also the real test will come from playtests -- so it's not super important that the numbers are exactly the same. 2. why do we draw at dawn at all? we only put a few defined events at dawn and let the rest be drawn during the day 3. can we improve this? 4. let's not forget about those 5. what is its suggestion on how to break it up? 6. yeah module by module makes sense and can be parallelized 7. sure 8. yeah let's simplify. "The field-read check skips about two thirds of reads because it cannot tell the receiver's class." isn't that the point of a class hierarchy? it should be made working. "- The entry's README layer list is stale.
   > - The entry has no stated end." also good points

3. **Context** (the assistant's):

   Sent a few minutes after the answers above, before the session had replied to them; the suggestions are the design review's, as relayed in the list above.

4. **The player's words.**

   > let's apply the suggestions

5. **Context** (the assistant's):

   Said after the session's two replies to the answers above. The first reply said, among other things: on point 2, that the dawn draws happen because the code keeps routes open with a whole-city reachability flood (the reach rule) and the session had ruled every event with a solid body to dawn, which "was wrong against your design"; that the fix is street-scoped rules, with dawn holding only the routes, the region wall and its doors, the closures, the seals, the masts, the ambient events, day 13's roadblocks and the scripted events; and "My proposal: draw a whole street at once when she first comes near it, seeded by the day and the street, so a street holds the same events whatever her path" (for retries, PLAYTEST-119 27). On point 5 it gave the reviewer's three parts (the record of one placed event into its own file; the ground judges and the density tables moved out; the dawn as a list of phases handed one context object). On point 3: one start(spec) for every kind of day. Under "What I'm applying": exact parity dropped as the bar and the fitted tables replaced by one declared table seeded from main's measured counts; points 4, 6, 7, 8, the field-read check, the stale layer list and the entry's end each going into the refactor's queue entry, the remaining order module by module; and pull request 1262 not merged as it stands. The second reply reported pull request 1262's review as not ready (a retry is not the same day for the events the walk draws; an event sited during the walk can be invisible to the walk's own draws) and said the session would not send those back as fixes, since point 2 replaces that pull request's dawn/walk split.

6. **The player's words.**

   > agree on all design review points. let's do it

7. **Context** (the assistant's):

   Sent right after "agree on all design review points. let's do it". The relayed design review's point 2 had said of pull request 1262: "The dawn draws every location and throws away the non-blocking results; the walk then draws them again from a second set of bags with its own correction table. Two disjoint bags from the start would need neither."

8. **The player's words.**

   > and get rid of the redundant historic double draw

9. **Context** (the assistant's):

   Said after the session's next message opened with: "Your 'get rid of the redundant historic double draw' is captured with the rest of your design answers (inbox #1268) and goes into the placement rework." The player is pointing back at "agree on all design review points. let's do it", appended above.

10. **The player's words.**

    > "get rid of the redundant historic double draw" -- that wasn't the only comment -- I agreed with the rest as well.

11. **Context** (the assistant's):

    Said on 2026-11-09 while the session was writing the design review's decisions into the refactor's queue items (pull request 1269). The player is quoting a marker the session had put in those items, on the mechanisms the design review designed (for example in the item on the field-read check: "*Proposed by the design review, not asked for, open to the player's correction:* the engine sees what the script cannot ...").

12. **The player's words.**

    > *Proposed by the design review, not asked for, open to the pl
    > ayer's correction:* -- I saw the review and approved it -- why you're saying it is proposed but not asked for?

## #1278

1. **Context** (the assistant's):

   Written by the player on the Nappy board on 2026-11-09, on the You line of the question event-settings-files. Question as shown: "where do the new settings files of an event's parts live? (built on my pick)". Options as shown: "Option a: a new folder `src/events/parts/` for the seventeen small files, and the full split of the events folder by layer after placement closes." / "Option b: split the whole events folder by layer now, about sixty files moved while placement is being rewritten in it." My pick: "a. It touches nothing the placement work edits."

2. **The note.**

   > a

3. **Context** (the assistant's):

   On the You line of the board question car-strike-part. Question as shown: "does a car's strike become part of an event's \"ends the day\" part? (built on my pick)". Options as shown: "Option a: \"ends the day\" keeps meaning a place that ends the day, and the strike stays with the car's driving." / "Option b: one part says everything that can end her day, in three kinds. It reads better, but every rule keyed on \"ends the day\" (a wall kept off the routes, a field kept clear, the doubled warning margin) needs a second question, at a risk to parity for no change in play." My pick: "a."

4. **The player's words.**

   > a

5. **Context** (the assistant's):

   On the You line of the board question plan-live-event. Question as shown: "how does code get from an event's plan for the day to the live event standing in the world? (built on my pick)". Options as shown: "Option a: the plan answers what callers want of it (is it in the world, where does it stand now, which way does it face), and the event manager hands out the live event to the few callers that command it." / "Option b: the plan hands out its live event directly, which adds one listed layer break." My pick: "a."

6. **The player's words.**

   > a

7. **Context** (the assistant's):

   On the You line of the board question event-tests-twice. Question as shown: "may the events' tests be touched twice? (built on my pick)". Options as shown: "Option a: a mechanical script rewrites their reads to the new methods first; the conversion to one module per suite comes later, group by group." / "Option b: each test file is opened once, so rows written as parts wait until every suite is redesigned." My pick: "a. Otherwise the suites are converted before rows can be built the new way, which is the redoing the design review warned of."

8. **The player's words.**

   > a

9. **Context** (the assistant's):

   On the You line of the board question event-frame-cost. Question as shown: "is a small measured cost per frame acceptable for the events' conversion? (built on my pick)". Context as shown, in part: "You accepted one measured cost in this refactor: 4.5% of the crowd's tick for the shared mover base"; "The same kind of conversion on the crowd's lane code measured about 7 to 9% of the crowd's tick in a debug build. You have not accepted a cost of that size anywhere." Options as shown: "Option a: a rise is measured by named probes, reported in the pull request and listed for the end remeasure; above about a twentieth of the events' step the builder finds the loop and fixes it before review." / "Option b: no rise is accepted; each step holds the probes' times within their spread." My pick: "a."

10. **The player's words.**

    > get the clean design first no matter the cost. We can optimize back down later. We have the numbers to know where to look

11. **Context** (the assistant's):

    On the You line of the board question event-wrong-answers. Question as shown: "do three answers that are slightly wrong today stay as they are until the end remeasure? (built on my pick)". Context as shown: "An event's field is measured from its centre, though a long body's field is really a capsule around the body. Fixing it changes when the run log says \"out of range\" and when the unmarked van stops its take." / "The ground a lethal event shuts is its field's core, not its full lethal reach." / "The ground an event that ends the day shuts is stated four different ways in four places." Options as shown: "Option a: keep all three and list them for the end remeasure. Your words on the refactor are \"test parity is enough\" and \"remeasuring at the very end\"; they set the bar a step is checked to, they do not say a known-wrong answer is kept." / "Option b: fix each in the step that names it, as a change made on purpose with pictures." My pick: "a."

12. **The player's words.**

    > the shape change is desired. as I said earlier the main real measure will be playtests. This will tell us what needs fixing. Let's not obsess over theoretical numbers. We currently have no established base anymore since we changed a lot. Playtest will decide which deviations need to be fixed

13. **Context** (the assistant's):

    On the You line of the board question code-drawn-symbols. Question as shown: "do three symbols that are drawn in code stay that way, or become picture files like every other symbol? (built on my pick)". Context as shown: "your rule is that a picture is an image file, never assembled from draw calls (PLAYTEST-29)." / "The caret above an entity that is costing her, amber or doubled red." / "The arrow that points home on the way back, and to the day's task." / "The pointer on the screen-edge badge that says something lethal or fast is coming from off screen; the badge's backing disc is drawn in code too." My pick: "leave them as they are, say in the skill that a new symbol is a picture, and file the three as an open point for after the refactor."

14. **The player's words.**

    > yes we would want to move to pictures only eventually. That will allow us to experiment with variations. So make todos for them but not part of the refactor

15. **The player's words.**

    > whatever is the *correct* implementation. if that is b then let's do that

16. **Context** (the assistant's):

    Written on the Nappy board, question `event-wrong-answers`, on 2026-11-09, on the second You line. It answers the orchestrator's read-back on the Me line above it: "I read this as b, not a: each of the three is made right, the field's real shape first, and nothing is kept wrong to hold old numbers. Each is its own small pull request after the step that names it, saying what it changes, and playtests decide what then needs fixing. Tell me if you meant only the field's shape." Option b on that question is: "fix each in the step that names it, as a change made on purpose with pictures." The three answers are: an event's field measured from its centre though a long body's field is a capsule around the body; the ground a lethal event shuts being its field's core, not its full lethal reach; the ground a day-ending event shuts stated four different ways in four places.

17. **Read as:** (the assistant's interpretation, not the player's words)

    All three are made correct (option b), not only the field's shape; the two readings in `docs/todo/2026-10-18-minty-quail/event-interface.md` section 7 point 6 collapse to this one.

## #1280

1. **The note.**

   > wait, they weren't typed before???
   >
   > is that a limitation of the type system?
   >
   > yeah, let's not make that a habit. we type when we can. with the public seams tests you won't have to keep things untyped to make it work

2. **Context** (the assistant's):

   Said in the chat on 2026-11-09, three messages in a row, about the typed-access pull request (#1277, minty-quail's `field-reads.md`: the engine fails any access it cannot type, and a file not yet fully typed carries a first-line opt-out).

   The first message answered the orchestrator's report that after #1277 a new test suite written the usual way (`func run(t)` with an untyped `t`) no longer parses, and its ruling "new files are fully typed everywhere, tests included", with seven open pull requests having to type their new test files.

   The second answered the orchestrator's count: of 302 script files under `src/`, 231 are already fully typed and 71 need the opt-out; of 414 under `tests/`, 49 are fully typed and 365 need it, 330 of them opening with `func run(t)` where `t` is the test runner passed in untyped; "GDScript makes types optional, and until #1277 nothing in the project enforced them"; and the plan to type the runner header across the 330 suites by one mechanical script right after #1277.

   The third answered the orchestrator's reply that the tests' case was habit and not a limitation (the runner parameter can be typed), with the real limits listed: a property read on an untyped value is never warned; collections typed one level deep; no interfaces, unions or nullable types, so "a fake standing in for a real class has to extend a shared base class or go untyped"; callables and signals carry no signature; no private members. "the public seams tests" is the player's name for the entry's test items that have a test hand a fake in through a public seam (`tests-public-seams.md`, with `tests-one-module.md`).

3. **Read as:** (the assistant's interpretation, not the player's words)

   The orchestrator's reading: code is typed wherever the language can type it, tests included, and leaving something untyped is not a habit to keep; a test that hands its fake in through a public seam has a typed thing to hand in, so it needs no untyped value. It confirms the ruling that new files are fully typed everywhere, and the plan to type the suites' runner header.
