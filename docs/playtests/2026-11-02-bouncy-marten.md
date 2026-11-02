# Playtest bouncy-marten — Review items keep their own board tab, sound waits, phone test after the release, no file watcher

2026-11-02.

## #948

1. **Context** (the assistant's):

   Said in the chat on 2026-11-01, in the same message that confirmed closing 150 of the 152 review items under docs/review/ and putting the 2 kept ones on the Nappy board. The review items are the files of things waiting on a person (a run to play, a look to take); the Nappy board is the shared Claude Doc holding open questions, running work and recent merges.

2. **The note.**

   > my question. is that old review system redundant now? does the board replace it or amend it? we could always have the board be the point for them but record the answers in either playtest or review depending on the type of question

3. **Context** (the assistant's):

   Written on the Nappy board under review-system, 2026-11-01, on the You line of the orchestrator's question whether the board should replace the review items under docs/review/ (a: an ask becomes an item file in its queue entry, shown on the board as a question with the steps, docs/review/ and its tooling go; b: review items stay as files and the board links them). The orchestrator's pick was (a).

4. **The player's words.**

   > are the board queue entries checked in?

5. **Context** (the assistant's):

   Written on the Nappy board under review-system, 2026-11-01, after the orchestrator answered the player's 'are the board queue entries checked in?' with: yes either way; under (a) each ask is an item file in its queue entry under docs/todo/, under (b) the review item files stay checked in under docs/review/; still open: (a) board replaces the review items, or (b) the board amends them (review items stay as files and the board lists them).

6. **The player's words.**

   > I think the best would be (b) since it keeps different kind of asks separated. We can even keep them in separate tabs in the board. The current board has items that are mostly design decisions that block ongoing work. Whereas the review items are confirmations to sign off work. Often they need a specific setup or running the game in a certain environment. They cannot be answered by just reading them like the other board items. The other board items I can batch together while the review items I have to spend time to answer one by one. Let's keep them in different tabs with the same overall style. Just make sure that review items are properly synced, too

7. **Read as:** (the assistant's interpretation, not the player's words)

   Choose (b): review items stay as their own kind under docs/review/ (sign-off checks that need a setup or a run), separate from the board's design questions. The board gets a separate tab for the review items, in the same style as the main tab's questions, and the tab is kept in step with docs/review/.

## #950

1. **Context** (the assistant's):

   Written on the Nappy board under sound-lab-listen, 2026-11-01, answering the question kept from the review-items audit: listen to the sound lab's pass 4 (tools/sound-lab.sh; new subtler footsteps and quieter wheels against pass 3) and say whether the steps are subtle enough, the wheels sit below them and both still sound like what they are; it blocks coral-newt (the sound tools). It is the review item docs/review/2026-09-26-run-tools-sound-lab-sh-and.md.

2. **The note.**

   > no, not working on this before we revive the sound items. the current sound is bad -- I already heard that back then (and told codex) -- nothing has changed since

3. **Read as:** (the assistant's interpretation, not the player's words)

   No listen now. The sound lab's current sound is bad, the player heard it before and said so to Codex then, and nothing has changed since; the listen and the sound work wait until the sound entries are revived. The review item for pass 4 closes.

## #951

1. **Context** (the assistant's):

   Written on the Nappy board under phone-dpr-test, 2026-11-01, answering the question kept from the review-items audit: on the phone, which pixel density (?dpr=2, 1.5, 1 against a baseline frame record on seed 67, day 14) still looks right, and does drawing fewer pixels make the frames cheaper; it blocks downy-hare (the web build drawing fewer pixels). It is the review item docs/review/2026-10-12-polite-gull.md.

2. **The note.**

   > bring that question up again after the latest release

3. **Read as:** (the assistant's interpretation, not the player's words)

   Ask again once the next release is published; until then the question waits and the review item stays.

## #955

1. **The note.**

   > also, I haven't seen any ARCHITECTURE whitespace changes. I think you changed something that fixed the issue so I don't think another file watcher is necessary

2. **Context** (the assistant's):

   Said in the chat on 2026-11-02, after #952 merged (every tool that starts Godot on the project puts project.godot and docs/ARCHITECTURE.md back on exit, undoing only the known rewrite: whitespace in the file tree and stripped comments). The board's Recently done row for #952 said what rewrites the two files was still unknown, and the previous session had been about to set up a file watcher to catch whatever rewrites them.

3. **Read as:** (the assistant's interpretation, not the player's words)

   No file watcher is built to find what rewrites docs/ARCHITECTURE.md; the player has seen no rewrite since #952 and treats the issue as fixed by it.

## #957

1. **Context** (the assistant's):

   Said in the chat on 2026-11-02, answering the orchestrator's question after filing inbox #950 (no listen of the sound lab's pass 4 before the sound items are revived): coral-newt (the sound and art tools learn from the chirp study) is in the band `next` while the player said the sound work waits until it is revived; should it move to `later`? The orchestrator had left the band as it was.

2. **The note.**

   > how is it being next a contradiction to we only act on questions when the item actually gets picked up and discussed?

3. **Read as:** (the assistant's interpretation, not the player's words)

   coral-newt stays `next`: its questions, the listen included, are taken up when the entry is picked up and discussed, and picking it up is the revival of the sound work, so its band does not contradict #950.
