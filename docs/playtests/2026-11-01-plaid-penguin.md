# Playtest plaid-penguin — Total game time, route from the building, numbering, architecture tabs, test shared state

2026-11-01.

## #920

1. **Context** (the assistant's):

   Said in the chat on 2026-11-01, right after the orchestrator reported PR #919 (minty-quail hidden-statics part 1: the run calendar, which day and act it is, the day's dice, starting and finishing a day and the checkpoint, moves off the GameState autoload into RunCalendar). The report named one visible difference: going back to checkpoint zero no longer calls start_run(), it resets the run's registry and keeps the seed and who pushes the pram. A reviewer was checking that nothing else start_run() did is lost.

2. **The note.**

   > total game time should continue going up even when going back to a checkpoint or repeating a day

3. **The player's words.**

   > well checkpoint one is the same as resetting the game?

4. **Context** (the assistant's):

   The player asked "well checkpoint one is the same as resetting the game?". The orchestrator answered that going back to checkpoint zero is the game starting a new run on the same seed (same city, day 1, every nerve, the resistance's progress, settled places and scars cleared, the parent kept; no title screen, no new city), and that it zeroes the play time only because it reuses the start-a-run code. Read back: the rule covers checkpoint zero too, since the game sends her back for running out of nerves rather than the player choosing to start over, so the time keeps counting; only a new game from the title starts at zero. The player's next words answered that read-back.

5. **The player's words.**

   > okay

6. **Context** (the assistant's):

   Said in the chat on 2026-11-01 about PR #935 (the total-time fix). The orchestrator reported that the builder had read the held restart (holding the restart control, which clears the save and goes back to the title) as the 'new game from the title' case, so it resets the play time to zero, and asked whether the player wanted the held restart to keep the time instead.

7. **The player's words.**

   > holding restart is *restarting* there is no ambiguity about that it clears all state including the timer

## #936

1. **Context** (the assistant's):

   Answered on the Nappy board under route-rig-building, 2026-11-01. The question: when the route rig (the dev tool that plays a run hands-free with --route) starts in the escape's building section, should it walk the building too, or only press the building's brief and leave winning it to a person? It blocks the last --route item of the minty-quail refactor (route-from-the-building.md). Context given: today, started in the building, it stops on the building's brief; walking it means teaching it the building's rooms and stairs (one moderate PR). The orchestrator's pick: walk the building, so one command checks a whole escape run.

2. **The note.**

   > building is always the same so it's pretty trivial to set up. let's do it

3. **Read as:** (the assistant's interpretation, not the player's words)

   The route rig walks the building section too, from the building boot to an exit, hands-free; the open question in route-from-the-building.md is settled that way.

## #937

1. **Context** (the assistant's):

   Answered on the Nappy board under record-numbers, 2026-11-01. The question: should tools/new-name.sh look at open pull requests before it hands out the next numbered decision record for the refactor (2026-10-18-minty-quail-44.md and so on)? Context given: two PRs built in parallel drew the same next number four times that day (#919, #921, #925, #929), and one had to renumber each time. The orchestrator's pick was yes, with an offline fallback. In the player's text the word 'not' is in italics.

2. **The note.**

   > the whole point of the name system was to not use numbers. if it's only for the refactor let's wrap up with what we have but in general a numbering system is bad and you know why

3. **Read as:** (the assistant's interpretation, not the player's words)

   No change to tools/new-name.sh. The refactor's records keep the numbering they already have until the refactor ends. Beyond the refactor, records and entries are named, not numbered, since a number drawn on two branches at once clashes, which is what the name system exists to avoid (PLAYTEST-144 6).

## #938

1. **Context** (the assistant's):

   Answered on the Nappy board under architecture-md-tabs, 2026-11-01. The question: does the player have an editor or formatter open on docs/ARCHITECTURE.md in the main checkout? Twice that day the file had its leading spaces turned into tabs (whitespace only) in the main checkout, blocking every landing until reverted; no agent, hook or branch was found to write it. The orchestrator's pick: if nothing has it open, add a watcher that logs which process writes the file next time. It had not come back since the player's revert at 17:32.

2. **The note.**

   > does it keep happening? only do the watcher if it does otherwise it doesn't really matter. I don't think I have it open but also my editors wouldn't save it anyway if they did that

3. **Read as:** (the assistant's interpretation, not the player's words)

   No watcher unless the change comes back; the player's editors are not the cause.

## #939

1. **Context** (the assistant's):

   Answered on the Nappy board under tests-isolated-check, 2026-11-01. The question: should the test runner check, after each test file, that the file left no shared state changed, and fail the file that did? It blocks briefing the tests-isolated work of the minty-quail refactor (tests-isolated.md), which answers the player's 'if anything we need tests that are properly isolated and not flaky' (freckled-moose #914). The proposal, the filer's and not the player's ask: the runner records shared state before and after each test file (the key bindings, which keys the game thinks are held, the always-loaded game state, static values) and fails the file that changed it, naming what changed; cost one PR, slightly slower runs, and a batch of existing leaks found at once. The plainer option offered was fixing each leak when it shows up. The orchestrator's pick: the check.

2. **The note.**

   > yes

3. **Read as:** (the assistant's interpretation, not the player's words)

   The test runner gets the shared-state check: it fails a test file that leaves shared state changed and names what changed, and the leaks it finds are fixed rather than retried.
