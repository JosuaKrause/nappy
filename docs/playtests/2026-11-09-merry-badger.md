# Playtest merry-badger — A sub-agent at 500k tokens is reassessed, and a model switch is a new brief

2026-11-09.

## #1298

1. **The note.**

   > another guidance: if a subagent grows to like 500k it should be reassessed whether that agent model is suitable for that kind of work or whether it got stuck or into an infinite loop

2. **Context** (the assistant's):

   Said in the orchestrating session (c021c586) late on 2026-11-09, after a night of fix rounds in which several builders grew past 250k tokens (the #1277 fixer about 270k, the #1262 builder about 267k, the placement agent of an earlier week to 776k as the usage review found) and the resume-guard hook (#1287, refusing once a resume past about 300k or after an automatic compaction) was in review.

3. **Read as:** (the assistant's interpretation, not the player's words)

   When a running sub-agent reaches about 500k tokens of context, the orchestrator stops and judges, before it goes on or gets more work: whether its model suits that kind of work, whether it is stuck, and whether it is looping. Proposed, not asked for: the 45-minute stuck-check reads each running agent's size as well.

4. **The player's words.**

   > also never switch a model with the full context. when switching a model do a new brief

5. **Context** (the assistant's):

   Said right after the guidance on reassessing a sub-agent near 500k tokens (inbox #1298), in the same exchange about agent size and model choice; tonight the orchestrator had moved work between models several times (an Opus reviewer of #1287 stopped and a Fable reviewer started, Fable fixers on PRs built by Opus or Sonnet).

6. **Read as:** (the assistant's interpretation, not the player's words)

   Work never moves to another model by carrying the old agent's context over (a fork, a transcript handed on, a resume under another model): the new model's agent starts from a new brief written for it.

7. **The player's words.**

   > do a script that tells you which agents to reassess

8. **Context** (the assistant's):

   Said after the orchestrator measured the running sub-agents from their transcript files with a one-off script (context size, turns, minutes since the last write), in answer to the player's "you can inspect subagents without stopping them, no?", following the guidance that an agent near 500k is reassessed (above).

9. **Context** (the assistant's):

   Said on 2026-11-09 in the usage-review session (d7cb9274, not the orchestrating one), the player's words in that conversation on agent size and model choice, in order. The first two are questions. The first followed this session's report that three tooling PRs (#1286, #1287, #1289) were with the orchestrator. The second followed this session's answer to it: the limit in orchestrating's `references/writing-a-brief.md` is about 150 turns or 300k tokens of context; every turn re-reads the context, so cost grows with the square of the turns; median sizes since Friday were Opus builds 110 turns / 290k, Sonnet builds 43 / 100k, Opus reviews 79 / 211k, Sonnet reviews 13 / 58k; 66 of 629 sub-agents in the last 7 days ended past the limit.

10. **The player's words.**

    > what is too big for a subagent?
    >
    > when do things become costly and what were sesions that got stuck how big were they?

11. **Context** (the assistant's):

    Said on 2026-11-09 in the usage-review session (d7cb9274, not the orchestrating one), right after this session listed the sub-agents an orchestrating session had to nudge or stop since 2026-10-31, with their size when nudged: the placement design agent (Opus, nudged at 799 turns / 486k, final 2,295 turns, 967k, 3 automatic compactions, $293 at API prices), Fix #1169 (Opus, 270 turns / 494k, final 694k, $43), Field reads: other classes (Sonnet, 117 / 228k then 278 / 440k, final 471 turns, 672k, $24), Shared-components PR C2b (Opus, stopped at 204 / 421k), Event callers (Opus, 166 / 366k), Baseline measurements (Sonnet, 73 / 134k); and that an Opus turn costs about $0.04 under 100k context, $0.09 at 300–400k and $0.20 past 800k. The words were a new question, not an answer to a list.

12. **The player's words.**

    > what would be a good guidance for when to reassess whether we chose the right model (ie the context grew larger than it should so a better model would have solved it quicker potentially?)

13. **Context** (the assistant's):

    The words that follow answer this session's reply to the question above, which was, as shown:

    > I'd reassess the model at the points where the orchestrator decides anyway, never while an agent is running (you ruled out policing a run, inbox #896). Escalate on clear signs that the agent is struggling, not on size alone.
    >
    > When to reassess: 1. At a hand-back. The finishing notification already gives tokens and turns for free. 2. At a refused resume. The hook in #1287 forces a fresh agent there, and choosing that fresh agent's model is the natural moment. 3. When a review comes back "not ready" a second time on substance, not on nits.
    >
    > Signs the model was too weak. Any one of these means the next agent goes up a tier (Sonnet → Opus, Opus → Fable), rather than a fresh agent on the same model: it hit the limit (150 turns or 300k) without finishing the core change (a big agent that finished isn't evidence of anything); a loop that stopped improving (a fit that oscillates, the same test failing after two fix attempts); it got a fork wrong, or the orchestrator redid its conclusion (`--redone` in agent-stats); the task turned out to need design (the agent rewrote the plan or reported several forks), which is Fable's row in the model table.
    >
    > Why this pays: at the same context, an Opus turn costs about 2–2.6× a Sonnet turn, and Fable about 1.5–1.8× Opus between 200k and 400k; total cost grows roughly with the square of the turns. Field reads (Sonnet) ran 471 turns for $24, against a median Opus build of about 110 turns and $7.50. By your note this is for information: the real gain is a stronger model finishing work the weaker one can't.
    >
    > What I'd hold back from: escalating for size alone.
    >
    > How it would land (proposed, not built): one sentence by the model table in orchestrating; the same in one line of the resume-guard refusal text in #1287; a grade note in agent-stats when an agent outgrew its model (for example `outgrew: sonnet`).

14. **The player's words.**

    > (of course there are exceptions)
    >
    > I'm considering a rule 500k tokens or more trigger a reassessment whether it's the right model

15. **Context** (the assistant's):

    The words that follow answer this session's reply, which was, in short as shown: 500k is a good threshold, rare, expensive and clearly beyond the normal limit. Since 2026-10-31 it would have caught 7 of 874 sub-agents (under 1%), together 16% of all sub-agent spend: the placement design agent (Opus, 967k, $293), the three agents of the #1169 task (Fix 694k $44, Replace 500k $25, After-dawn 544k $23), the day plan state object design (Opus, 574k, $32), telemetry handed in (Opus, 546k, $30) and field reads: other classes (Sonnet, 672k, $24). How it would fit: 300k / 150 turns a fresh agent; 500k a fresh agent plus a reassessment (moving up a tier, splitting the task, or keeping things as they are, recorded in the grade's note), at the hand-back or a refused resume; the number beside 150/300k in `references/writing-a-brief.md`. Exceptions it proposed to write down: an agent whose context is mostly run output (measuring, capturing), an agent that finished its change cleanly, an agent already on Fable.

16. **The player's words.**

    > what about 400k? can you check with the orchestrator what they implemented and whether it matches your assessment?

17. **Context** (the assistant's):

    The words that follow answer this session's reply on 400k, which was, in short as shown: keep the reassessment at 500k. At 300k, 74 agents (8.5%, 45% of sub-agent spend); at 400k, 28 (3.2%, 29%); at 500k, 7 (0.8%, 16%). The 21 agents between 400k and 500k are mostly healthy: Opus builds that finished their PR for $15–25, Fable agents with no tier above them (the rules rework, the event-interface design), three Sonnet builds at about 440k for $7–10; no wrong-model case among them, so 400k would roughly quadruple the reassessments and most would end in "fine as is". It also reported that the orchestrator's version follows this note's words, and that the exceptions above are this session's, not the player's. The player said "record my words in the same github issue" and then, while that was being done, the words below.

18. **The player's words.**

    > let's go with 500k

19. **The player's words.**

    > the other agent added some color to the 500k rule. let's file that and do it next

20. **Context** (the assistant's):

    Said after the usage-review session appended the player's words from its conversation to this note (five quotes: what is too big for a sub-agent, when to reassess the model, "(of course there are exceptions)", 400k considered, "let's go with 500k").

21. **Read as:** (the assistant's interpretation, not the player's words)

    File this note (#1298) now, alone, and build its rule next: the reassessment at 500k and a new brief when switching models go into the orchestrating skill.

22. **The player's words.**

    > check with the budget agent whether those numbers make sense

23. **Context** (the assistant's):

    Said after the orchestrator traced the brief guide's limit (about 150 turns or 300k tokens, orchestrating/references/writing-a-brief.md) to an orchestrator's proposal in #875 (2026-10-31), still marked proposed, and noted that the resume-guard hook (#1287), approved and set to merge, enforces it. "The budget agent" read as the usage-review session (doctor-improvements-weekly-review).

24. **The player's words.**

    > what about 400k? note, this is different than the 500k rule for reassessing agents -- this should kick in earlier since it's about resuming agents, no? -- forward those questions to mr budget

25. **Context** (the assistant's):

    Said after the orchestrator relayed the usage-review session's recommendation for #1287's resume refusal: tokens only at 500k (keep the auto-compaction trigger, drop the 150-turn trigger), with 400k or the written 150 turns / 300k as the alternatives.

26. **The player's words.**

    > 2. okay, fable can design and review 1. yes, we can let fable finish

27. **Context** (the assistant's):

    Answer to the orchestrator's two admissions: (1) the agent building the fable-only queue line is Fable although the tooling is not a named item; (2) the #1287 fix need not be written by Fable, only reviewed by it.

28. **Read as:** (the assistant's interpretation, not the player's words)

    (1) The Fable agent building the label line finishes. (2) #1287's change to a 400k resume refusal is designed and reviewed by Fable; its coding may go to another model. 400k read from the player's own "what about 400k? ... this should kick in earlier since it's about resuming agents" and the budget session's matching recommendation.

29. **The player's words.**

    > yes, 400k as mr budget said

30. **Context** (the assistant's):

    Answer to the orchestrator's question whether #1287 refuses a resume at 400k as the usage-review session ("mr budget") recommended: tokens only, plus any automatic compaction, no turn trigger; the refusal text asks own-PR follow-up (resend) versus new work (fresh agent from a brief); the 500k reassessment on top; writing-a-brief.md keeps about 300k as the scoping size.

31. **The player's words.**

    > no turn count

32. **Context** (the assistant's):

    Said right after "yes, 400k as mr budget said"; read as: no limit counts turns, neither the hook's refusal nor the brief guide's limit sentence (about 150 turns or 300k tokens today).

33. **Context** (the assistant's):

    Said later in the same usage-review conversation (2026-11-09/10). Between the words above and these, the player had asked, through the orchestrator, whether the resume refusal (#1287) should come earlier than the 500k reassessment ("what about 400k? note, this is different than the 500k rule for reassessing agents -- this should kick in earlier since it's about resuming agents, no?", said in the orchestrating session), and then here "what about turns? what's the recommendation there?" and "or should we not base anything on that?". This session's answer, in short as shown: refuse a resume once at 400k tokens of context, tokens only, plus any automatic compaction, the refusal answered by kind (a follow-up on the agent's own pull request is resent, new work goes to a fresh agent); and base no rule on turns, since a 150-turn trigger would add 37 refusals in 9 days to catch $49 of long follow-ups and a turn costs whatever its context costs; turns stay a stuck signal shown for information. The words below are those two questions and then the player's answer to that reply.

34. **The player's words.**

    > what about turns? what's the recommendation there?
    >
    > or should we not base anything on that?
    >
    > no turn counters is fine I think -- context is a better measure. so which one is 400k and which one is 500k?

35. **The player's words.**

    > it comes from mr budget but I fully agree

36. **Context** (the assistant's):

    Said right after the player pasted the usage-review session's table into the orchestrating session: 400k context, the resume refusal (the hook in #1287): when the orchestrator sends a follow-up to a sub-agent past 400k or one that compacted automatically; an own-PR follow-up (fix, delta review, merging main, a stop) is resent and goes through, new work goes to a fresh agent from a brief. 500k, the model reassessment (#1298): any agent that reaches 500k, flagged by the agents-to-reassess script or the 45-minute check, running or not; is the model right for this kind of work, or is the agent stuck or looping; switch models only through a new brief. 300k, a sizing target, not enforced: when writing a brief, scope the task so it finishes under about 300k. No turn counters anywhere.
