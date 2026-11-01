# Playtest plaid-raven — Inbox batch: the title's street, the crowd yields, the PR questions' wording, agent sizing

2026-10-31.

## #883

1. **Context** (the assistant's):

   Answered on the Nappy board, question `street-behind-title`, 2026-10-31. The question: on a day the city keeps running behind the title screen (events age, repeat timers run, traffic lights change, the crowd walks), so the state when the player presses start depends on how long the title was up; should the day stop playing on behind the title? Options: (a) keep the living street behind the title as it is (the start state varies a little); (b) freeze the simulation behind the title and show a still street; (c) keep the street moving but start each day from a fresh copy independent of the time on the title. The orchestrator's pick was (c). Raised by the review of events-composed 4c (#881), which made the day's clocks count only the ticks the walk stepped (#866).

2. **The note.**

   > (a) a little bit of variety is fine. in a seed of the day setting you would do a whole run anyway without restarting in the middle. so only the first day would be affected which is the day where we create a predictable initial scene by moving the camera away first anyway. on other days it's fine. you can't eek out an advantage by staring at the title screen and picking a good start since no events ever spawn at the home block anyway. the pedestrian/car crowd doesn't really matter here.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Option (a): the city keeps running behind the title screen as it does; no reset at the start of a day. The shared-components step's PR T reduces to stating this in the docs.

## #884

1. **Context** (the assistant's):

   Answered on the Nappy board, question `who-gives-way`, 2026-10-31. The question: once event figures (the charging dog, a robber, the cyclist, an officer) and the crowd see each other in the shared-components step's separation pass, who steps aside when they meet? Options: (a) the crowd yields: walkers step aside or are pushed, cars stand for a figure on the road; event figures keep their courses and timings and do not separate from each other; (b) everyone separates both ways, moving catch timings and route costs; (c) only cars stop for figures and walkers still overlap. The orchestrator's pick was (a).

2. **The note.**

   > (a) the crowd yields. a charging dog doesn't care but a pedestrian doesn't want to get overrun. same applies to other events.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Option (a) for every event, not only the dog: the crowd yields to event figures, and event figures keep their courses and timings. This settles fork F5 of the shared-components plan and unblocks its separation PR (C2b).

## #894

1. **Context** (the assistant's):

   Said in the chat on 2026-10-31, after the filing pull request #893 (plush-egret #892, the minty-quail item pr-questions.md) was reviewed: its review had found that the earlier "yeah I like this" agreed to filing the first cut of the questions rather than to their wording, and that "can we build this in parallel?" was a question read as asking to build it now. The first cut: 1 which layer each new or changed piece belongs to and why; 2 what it depends on, each dependency on its layer or below; 3 what it is handed and what it fetches; 4 whether something like it already exists (reuse, or why not; a mode configured, never copied); 5 whether a fix lands in the shared mechanism or in a branch keyed on one row or picture; 6 what a test hands it (built with fakes, no scene tree); 7 which docs say where it lives. The player's own addition was "can this be tested in isolation", overlapping 6.

2. **The note.**

   > I accept the wording of the questions (maybe we can expand Q6 or have my question as additional question). okay, let's build this in parallel to other work that is currently going on. we want to use this as soon as possible.

3. **Context** (the assistant's):

   The player's answers to five open points the orchestrator listed, with its picks: 1 which PRs answer the questions (pick: every PR changing src/, tests/ or tools/, one line when nothing new is added; docs-only and queue-only exempt); 2 whether the layer check blocks or warns (pick: blocks on a new violation and on a stale listed exception); 3 the layer map itself, which src/ folder or file sits in which layer and where view/UI sit, the target layers being the orchestrator's proposal from the refactor's planning (plush-kestrel) (pick: the builder proposes the map as a table in the PR description and the player reviews it before merge); 4 from when (pick: the first PR opened after this merges, C2b exempt; the refactor's remaining PRs answer too and prune exceptions they fix); 5 the two ideas left out, a file-size and near-copy watch and a periodic drift audit (pick: leave out until the questions and the layer check have run a while).

4. **The player's words.**

   > 1 -- whatever makes most sense
   > 2 -- if it has few false positives we can make it blocking
   > 3 -- yes the layer was reasonable otherwise we wouldn't have started the refactoring. but sure let's review it in the PR
   > 4 -- yes
   > 5 -- let's see if the current thing works before adding more features on it

## #896

1. **Context** (the assistant's):

   Said in the chat on 2026-10-31, quoting the orchestrator's explanation of why C2b's builder (minty-quail shared-components, the crowd yielding to event figures) had run 1h30 and about 420k tokens: the orchestrating skill's size rule (a builder hands over past about 100-150 turns or 300k tokens, inbox #874 in minty-dolphin) was policed by the builder itself, which cannot see its own token count, and the orchestrator had not acted on the counts its notifications showed (C1's builder 325k, C2a's 356k). The orchestrator had proposed acting on the count in every notification, a size line in tool calls, and splitting a brief that combines building with long measurement or captures.

2. **The note.**

   > -- The builder is supposed to police itself, -- that's just stupid. it shouldn't work like this. scope out tasks so they stay under the limit by construction

3. **Context** (the assistant's):

   Said next, while the orchestrator was writing the skill fix (PR #897), whose draft kept a backstop: the orchestrator reading each notification's token count and telling an agent past about 300k to commit, push and report, and briefs carrying a size line for the builder.

4. **The player's words.**

   > don't tell builders to police themselves -- that would be counterproductive and they would spend most of their tokens just figuring how much they have left. the same with you actively doing it. that is just waste of tokens

5. **Context** (the assistant's):

   Said next, quoting the clause the skill fix (PR #897) dropped after the player's previous words: review fixes went to a fresh agent "unless the builder is warm and its notification shows it far under the limit". The token count arrives in each agent's completion notification without any extra call.

6. **The player's words.**

   > -- notification shows it far under the limit. -- if you get that information for free use it

7. **Context** (the assistant's):

   Said next, after the orchestrator proposed: review fixes go back to the builder when it is warm and its finishing notification shows it well under the limit, otherwise to a fresh agent; the free counts inform the next brief's size; nobody counts while an agent runs.

8. **The player's words.**

   > also add another rule that if the agent is warm reuse it if rebriefing another agent would be expensive. rebriefing costs a lot of tokens, too. so as long as a subagent is not super huge reusing the existing context safes the rebriefing tokens
