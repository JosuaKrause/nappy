# Playtest curly-rabbit — Tests that hold nothing, test-only functions, the stairwell masked man's late start, and the reviewers' standing permission

2026-11-05.

## #1086

1. **Context** (the assistant's):

   Answered on the Nappy board's Main tab, question masked-man-late-run, on its You line. The question as shown:

   Question: the masked man in the stairwell no longer catches her when she starts running 0.3 s after he does. Keep the game as it plays and re-pin the test, or make him catch a late start again?

   Context: the masked man is the stairwell pursuer who bursts out of his shaft on the second floor and runs her down unless she makes for the first-floor door. The interior test pinned three things: a walker on some lines is caught, a runner gets through on every line, and the margin is thin, so she is caught if she starts running 0.3 s late. That last claim was measured on a test rig that pushed her body by hand without sliding along walls. Moved onto the game's own physics (her real slide along walls), she gets through when she starts 0.3 s late, and even 1/3 s late; on the tightest runner's line he comes within 36.4 px of her centre instead of 24.6 px, against his 23.5 px catch. Which walker lines are caught, and every runner getting through, are unchanged. So the game you play has been this forgiving all along; only the test's claim was wrong.

   My pick: keep the game. Measured on real physics: starting up to 10 ticks (1/3 s) after he does, she gets through; from 13 ticks (0.43 s) on she is caught (12 ticks squeaks through by 1.4 px). The test now pins 16 ticks, about half a second, as caught, in PR #1081. Changing his catch or speed would change play everywhere he appears. Without an answer, that is what happens.

2. **The note.**

   > the only case that really counts is not running at all. running 0.3s late and still succeeding is actually good

3. **Read as:** (the assistant's interpretation, not the player's words)

   Keep the game as it plays (as merged in PR #1081): the masked man's catch and speed do not change. The check that matters is that she is caught when she does not run at all (the walker lines); getting through after a 0.3 s late start is intended forgiveness, not a gap. The test's late-start pin (16 ticks caught) is not something the player asked to hold.

## #1094

1. **Context** (the assistant's):

   The first line is the player's answer on the board question review-post-denied (Main tab, 2026-11-05). The question: Claude Code's auto-mode classifier refused the reviewer agents' approvals of PRs #1090, #1091 and #1092 (as "External System Writes" and "Unrequested Commit in a Connected App") and refused spawning a reviewer for #1093 (as "Self-Approval"). The other lines were said in the chat the same day. The classifier takes consent only from the player's own messages or settings, never from CLAUDE.md, so the standing merge permission there never reached it.

2. **The note.**

   > add standing permission

3. **The player's words.**

   > what's the problem with that you can't spawn reviewers and let them post reviews? do I need to add standing permission for that, too?

4. **The player's words.**

   > the whole point of adding the standing permission was that I *don't* have to spell it out in the chat

5. **The player's words.**

   > let's add wording akin to what is in claude.md to that line as well

6. **Note** (the assistant's):

   Done the same day, outside the repo: the player ran a script that adds two allow rules to ~/.claude/settings.json for reviewer posts as claude-reviewer (the review command and the reviews endpoint of the GitHub API), and one autoMode.environment line stating the standing permission for spawning reviewers, posting verdict reviews, and merging once the merge gates hold, with a release still needing its own go-ahead. Still to do in the repo: the pr-review and committing skills say that a standing permission reaches the classifier only through the player's Claude Code settings, not CLAUDE.md.

## #1095

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question members-no-reader, as it stood:

   - Question: some functions in the game's code are public only so that tests can call them; the game itself never does. Should they go, with their tests rewritten to check what the game actually shows? (blocks three test builds: the resistance director's queries, the events' and pictures' queries, the atlas library's page counts)
   - Context: the test refactor's rule is that a test checks the game only through what the game itself uses: what is drawn, the events in play, real input and real frames. PR #1088 found about 80 functions that only tests call. Two earlier refactor steps added some on purpose. One set answers questions about the red arrow that points her to a resistance task: which target, the nearest one, its lead, whether it is sweeping, which mast is in play. The other answers questions about day 9's checkpoint: where the door is, which way it faces, the trap. Another is the atlas library's count of who holds each picture page. Deleting them means the tests check the drawn arrow, the events in play and the pages drawn instead: more test work, no change to play. Keeping them means the rule gets an exception for functions kept only for tests.
     - My pick: delete them and keep the rule. If a check cannot be done through what the game shows, its builder brings it back here. The other test builds go on meanwhile; these three wait for your answer.

2. **The note.**

   > delete them if possible. most cases should allow similar things via mocking the affected object. if it is absolutely not possible to get this information otherwise *and* this information is necessary for the test to make sense / confirm the desired behavior we can keep it. although those cases might be hints that the design of that module is suboptimal

3. **Read as:** (the assistant's interpretation, not the player's words)

   Delete the test-only public functions. A test that needs the information gets it by handing the object a fake (a mock) or by reading what the game shows. One may stay only when both hold: the information cannot be had any other way, and the test cannot confirm the behavior without it. Each one kept is recorded as a sign that its module's design may need rethinking.

## #1097

1. **Context** (the assistant's):

   Said in the chat about PR #1096 (the save, run, telemetry and screen tests moved off functions only tests call), answering this line of the orchestrator's report: "Lost check: one, "resistance progress never goes negative", because no game path lowers progress." The check called `RunState.penalise_resistance`, which nothing in the game calls, and was dropped with it.

2. **The note.**

   > that was a completely pointless test to begin with
   >
   > good that it's gone

3. **Read as:** (the assistant's interpretation, not the player's words)

   The dropped check is no loss and #1096 needs no replacement for it. A test of a state no game path can reach, set up through a function only the test calls, is worth nothing.

4. **Context** (the assistant's):

   Said in the chat right after the words above, about the dropped check ("resistance progress never goes negative", set up through `RunState.penalise_resistance`, which only the test called).

5. **The player's words.**

   > can we audit tests for those kind of useless ones and remove them?

6. **Context** (the assistant's):

   Said in the chat, quoting back this list from the orchestrator's message on the audit it had started:

   - Unreachable setup: a state only the test can create, like the one that just went. Input the game doesn't control, such as a corrupted save on disk or a browser's answer, doesn't count, since it can really happen.
   - A design decision read back: the check goes red only because a number changed, not because what the number is for broke.
   - Can't fail: it would pass with the code deleted, or it checks a value it just set itself.
   - Duplicates: the same behavior already tested by another suite.

7. **The player's words.**

   > let's make sure those tests also won't enter the codebase again

## #1098

1. **Context** (the assistant's):

   Said in the chat, answering the board question self-only-members (Nappy board, Main tab), which read:

   - Question: about 250 functions in the game's code are public, but only their own class and the tests call them. Should they become internal (an underscore), with their tests checking what the class does from outside, or stay public?
   - Context: GDScript has no real private; a leading underscore marks a name internal by convention, and the test refactor's count only flags underscored names. So a helper without one passes the count even when only its own class uses it: the loophole you named in chat. The game needs every one of these (its class calls it); only their being public is in question. [The big groups followed: the building's drawing pieces, the touch controls' geometry, the frame recorder's record, the park cordon, the event scheduler's plan helpers, the resistance director's guard and contact spots, the title screen's hard-mode controls, the save's has-a-save, the figures' picture lists.] Making them internal is roughly as much test work as everything the refactor has filed so far.
     - My pick: close the loophole by the same rule as members-no-reader, but as its own pass after the current test builds, owner by owner: each becomes internal and its tests check outward behavior, and one stays public only where nothing outward can confirm the behavior, with its reason written down. The new CI check for test-only functions would then also flag a member only its own class and tests call.

   Just before, in chat, the player had asked: "so basically they're not part of the API but tests use them to probe the state? so they're kind of a loophole".

2. **The note.**

   > we should add the underscore

3. **Read as:** (the assistant's interpretation, not the player's words)

   A public member whose only callers are its own class and the tests becomes internal (a leading underscore), and its tests check what the class does from outside, as the pick said. The pass runs after the current test builds; the CI check for test-only members counts a caller in the member's own class as no caller.

4. **Context** (the assistant's):

   Said in the chat, quoting back the orchestrator's sentence: "My pick is to close the loophole by your members-no-reader rule, in its own pass after the current test builds. Each function becomes internal and its tests check what the class does from outside. A function stays public only where nothing outside can confirm the behavior, with the reason written down."

5. **The player's words.**

   > yes, that's cleaner

## #1100

1. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question dog-gold-timing. Question: the day-3 dog's chase test pins its timing two ways. Keep both halves, or only the measured one? Context (abridged): half of it is the dog's catalogue row typed again (the half-second warning badge, the 4.5 s approach, 130 px/s), which goes red only when the row changes; the other half is measured on real frames as she walks into the dog (0.35 s walking toward it, 0.60 s standing, 2.05 s walking away, which loses, with the warning being the half-second badge). My pick: keep the measured half, drop the hand-typed half.

2. **The note.**

   > the measured half

3. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question rings-gone-check. Question: the danger test checks that the old warning rings stay deleted. Keep it or remove it? Context (abridged): it asserts three removed names (the ring-drawing code) do not exist; it tests no behavior, it pins the decision that danger is never shown as a ring; the cues skill already says no rings. My pick: remove it.

4. **The player's words.**

   > remove

5. **Context** (the assistant's):

   Answered on the Nappy board, Main tab, question pause-wording-checks. Question: the pause screen's test checks its exact wording. Keep the wording checks or remove them? Context (abridged): the checks compare the pause screen's hint, body and caption against text typed again in the test, and check the hint is empty in five situations. My pick: remove the wording checks, keep the ones that a hint is or is not shown.

6. **The player's words.**

   > agreed

7. **Context** (the assistant's):

   Asked on the Nappy board, Main tab, question goatcounter-names-table, on its You line. Question: the visit counter's test pins the GoatCounter event names sent for the chargers. Keep it or remove it? Context (abridged): the names are what the player's GoatCounter dashboards and docs/stats/ count, so a rename splits the numbers. My pick: keep it.

8. **The player's words.**

   > does it touch the live service?

9. **Note** (the assistant's):

   Answered on the board: no. The test hands the visit counter a recording counter that lists the names it would send; nothing is sent, and no page or JavaScriptBridge is involved.
