# Playtest freckled-moose — Model per task, freezing Codex, sibling layers, walkers and cars, and how PRs land

2026-11-01.

## #900

1. **Context** (the assistant's):

   Said in the chat on 2026-10-31, in reply to the orchestrator's proposed model-per-task table for the orchestrating skill: build at test parity, Sonnet; build that changes play or designs a seam, Opus; investigate an unexplained result, Opus; measure (long probe batches, many-seed statistics), Sonnet; capture pictures for a PR, Sonnet (drawing stays Opus); review fixes, the builder's model reused while warm; review of play-changing or design PRs, Opus; review of queue, docs, skill wording or a small delta, Sonnet; waiting, merging, polling, no agent (the landing script in a background shell). The orchestrator had noted it had used Opus for almost every builder that day under the skill's "stronger model by judgement" clause.

2. **The note.**

   > Capture pictures for a PR -- why not haiku?
   >
   > Review fixes -- well, only if the builder didn't spend too much already
   >
   > Measure: long probe batches... -- also haiku, no?
   >
   > two ways to cut this. remove all guidance and let judgement do the work or provide a more granular table and revise after experiments or statistics

3. **Context** (the assistant's):

   Said next, after the orchestrator proposed recording model and kind in each brief's header, adding each agent's token count and tool calls from its finishing notification, and a script tallying per kind and model the tokens, review rounds before approval and blocking findings, to revise the model table after 15-20 tasks.

4. **The player's words.**

   > can we have a counter maybe outside the repo that just keeps track of how often which agent did what and whether it needed correction or did a good/bad job

5. **Context** (the assistant's):

   Said next, after the orchestrator built the counter outside the repo (~/.claude/nappy-agent-stats/: stats.py with add, summary and list, and log.jsonl; kind, model, PR, tokens, tool calls, correction rounds and a good/ok/bad grade per agent; 15 agents backfilled) and had earlier proposed that a Haiku measurer run the batch and report while the interpretation of noise stays with the orchestrator.

6. **The player's words.**

   > would versioned actually be better or would it just add PR overhead and potential conflicts? also, how can we capture if you don't trust the model enough and would basically do the heavy lifting all by yourself? like what you suggested with doing with haiku. if you don't trust the noise filtering (which I doubt and what we need to actually test via the table) and get the raw result either way you are basically doing the full task yourself

7. **Context** (the assistant's):

   Said next, after the orchestrator answered: keep the counter outside the repo (one shared log file would conflict between parallel pull requests); hand a task out whole and grade the agent on its own conclusion, the reviewer checking it, with a --redone field counting any time the orchestrator redid or overrode an agent's conclusion; C2b's measuring and capturing to go to Haiku whole.

8. **The player's words.**

   > can the log file be a hook? if you want to try out haiku you can do the same task with both haiku and sonnet and compare their results. if they match that's a win for haiku

9. **Context** (the assistant's):

   Said in the chat on 2026-11-01, after the orchestrator reported the Haiku-against-Sonnet run on one brief (C2b's measurements, pictures and conclusion, PR #895): identical numbers; Sonnet called a borderline rise in box collisions unresolved by a sign test where Haiku called it flat on the standard error, and Sonnet saw the yielding in three picture pairs where Haiku saw one and missed a walker clear of the dog; Haiku took 128k tokens and 54 minutes, Sonnet 143k and 43. The orchestrator's read: Sonnet for measuring with interpretation, Haiku for a pure batch with a fixed table and no conclusion, Haiku able to take pictures but not to judge them.

10. **The player's words.**

    > update your model choices guided by the experiment

11. **Context** (the assistant's):

    Said next, while PR #906 (the model table's measuring rows following the Haiku/Sonnet comparison, with a line that running a task on both models side by side is how a row is tested further, now and then) was merging.

12. **The player's words.**

    > no current need to do more sbs experiments for now -- let's go with the updated table and let statistics tell -- if there are still ambiguous cases after a week we can do more sbs

## #901

1. **Context** (the assistant's):

   Said in the chat on 2026-10-31, after the orchestrator measured what supporting Codex costs: tools/codex-hooks.py (252 lines) and its tests (887), .codex/hooks.json and config.toml, the Codex model reference, the codex-coder and codex-reviewer identities, CLAUDE.md's Codex integration section (about 340 words loaded in every session), about 98 mentions across twelve skills, and CLAUDE.md's rule that a hook change checks the adapter and its tests; Codex's last commit here was 2026-10-08, 23 commits in all; it is the only route for generating a raster image. The orchestrator proposed freezing it (keep the adapter, drop the requirement to keep it in step, note it may lag) rather than removing it, asking whether the player still planned to use Codex.

2. **The note.**

   > okay, let's freeze codex -- I'm not currently actively using it

## #904

1. **Context** (the assistant's):

   Said in the chat on 2026-11-01, about the board question layer-map, part A: PR #899's layer check puts the view (HUD, badges, touch controls) in a layer of its own above the observers (the run log and telemetry), while minty-quail's filed layering puts the UI inside layer 6, the observers. Following minty-quail lists 164 exceptions instead of 167, the three gone being the run log and telemetry naming two screen classes (the drawn frame, the danger edge). The orchestrator's pick had been to follow minty-quail.

2. **The note.**

   > how is the HUD comparabale to log and telemetry? those are different things -- I don't think a one above the other works here anyway

3. **Context** (the assistant's):

   Written on the Nappy board's You line of the question layer-map (part A: where the view, the HUD, badges and touch controls, sits against the observers, the run log and telemetry; part B: the map lookup WorldMap, kept by the builder with the city maps in the domain model, where minty-quail puts one map interface in the world; the orchestrator's pick for B was to keep it with the maps, called a correction to the plan, since in the world layer six bottom-layer files would name it). Then in the chat, after the orchestrator read A back as: the view and the observers are sibling layers on top of the run flow and the simulation, neither may name the other, the three places telemetry names screen classes stay listed until telemetry is handed what it reports, and the check enforces that siblings do not name each other.

4. **The player's words.**

   > let's make A siblings and use the improvement for B

5. **The player's words.**

   > see doc. your read for A is correct and for B let's use the improved variant

## #905

1. **Context** (the assistant's):

   Said in the chat on 2026-11-01, answering the orchestrator's question about PR #895 (minty-quail shared-components C2b, the crowd yields to event figures): the builder made only event movers that have moved count as figures the crowd gives way to, so walkers still walk through a figure that has not moved yet, such as a street musician standing still, a stall, or a dog crouched before its charge; is that within the player's words (plaid-raven #884), or a gap?

2. **The note.**

   > if it's people or dogs it's fine. if it's a restaurant or car they should avoid

## #909

1. **Context** (the assistant's):

   Written on the Nappy board on 2026-11-01, on the question car-meets-standing-figure about PR #895 (minty-quail shared-components C2b, the crowd gives way to event figures): when a crowd car meets an event figure standing still in its lane, should it stand behind it or drive through it? The builder had made a car drive on through a figure standing more than a second; the review found this only with the patrol car (stopped at red lights and while its officers get out). The orchestrator's pick: cars stand behind any figure in their lane as long as it stands, with no 1-second limit; things placed on the street that never move (a hut, a stall) stay a blockage cars turn round at; cost: a fire truck that drives in and parks would hold its lane for the rest of the day, cars behind it waiting or turning back.

2. **The note.**

   > cars should initiate a turn around if they stand behind a figure that won't move

## #914

1. **Context** (the assistant's):

   Said in the chat on 2026-11-01. #911 and #912 each passed their own CI and were landed back to back; main's CI then failed (an order-dependent test_touch failure seen only with both merged). Asked how a merge was possible with main not green, the orchestrator explained that main's ruleset requires the PR's own checks, not a branch up to date with main, and offered (1) landing one PR at a time and waiting for main's CI between merges, or (2) turning on "require branches to be up to date". The player answered with the words below: no change to the landing process, provided a fix for main lands.

2. **The note.**

   > it's fine as long as we land a fix on main

3. **The player's words.**

   > we don't need either (no merging one at a time and no require branches to be up to date)

4. **The player's words.**

   > if anything we need tests that are properly isolated and not flaky
