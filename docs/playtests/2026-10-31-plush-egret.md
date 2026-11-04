# Playtest plush-egret — Questions a PR answers against architecture drift

2026-10-31.

## #892

1. **Context** (the assistant's):

   Said in the chat on 2026-10-31, unprompted, while minty-quail's shared-components PRs were going through review. Every PR there gets one adversarial review agent (pr-review skill: semantic first, then code), posting as claude-reviewer, with delta reviews after each push; PRs #888-#891 each took two to four review rounds.

2. **The note.**

   > should we introduce different reviewer roles? like security, adversarial, correctness, intentionality, architecture, style, extensibility, etc. not sure what the right level of granularity would be, also not sure how to best structure it. would it just be more expensive approval process? how can we test/confirm it is worth it?

3. **Context** (the assistant's):

   Said in the chat on 2026-10-31, in reply to the orchestrator's answer to this note: keep one reviewer, which caught real bugs on #888-#891 and missed depth rather than a lens; split only where a lens needs different evidence (intent, correctness, evidence for play changes, security for hooks/tools); test a three-lens panel by replaying the four PRs' pre-review heads (board question reviewer-roles).

4. **The player's words.**

   > I think the current process works well with finding potential bugs. what I'm worried about is that the architecture starts to drift again once the refactor is complete.

5. **Context** (the assistant's):

   Said in the chat on 2026-10-31, in reply to the orchestrator's proposal against architecture drift after the refactor: a layer check in CI (the layer map as data, no upward names, no fetching in simulation layers, exceptions listed so they only shrink), a size and copy watch, an architecture lens in the review of feature PRs (which layer, reuse or copy, mode configured or forked, fetched or handed), and a periodic drift audit filing into the queue; tested by running the layer check on main before the refactor.

6. **The player's words.**

   > I guess it could be framed as series of questions a PR needs to answer

7. **Context** (the assistant's):

   Said in the chat on 2026-10-31, in reply to the orchestrator's first cut of questions a PR answers: 1 which layer each new or changed piece belongs to and why; 2 what it depends on, each dependency on its layer or below (answered by a layer-check script, the PR explaining a listed exception); 3 what it is handed and what it fetches (a group lookup, autoload or static read in a simulation layer named and justified); 4 whether something like it already exists (reuse, or why not; a mode configured, never copied); 5 whether a fix lands in the shared mechanism or in a branch keyed on one row or picture; 6 what a test hands it (built with fakes, no scene tree); 7 which docs say where it lives (docs/ARCHITECTURE.md's listing). The author answers them in the brief and the PR description, CI checks they are present, the reviewer verifies them against the diff.

8. **The player's words.**

   > also "can this be tested in isolation" although there is some overlap to Q6

9. **Context** (the assistant's):

   Said next, answering the orchestrator's question: should this be filed as a queue item under minty-quail, built in the PR that closes the refactor together with the layer-check script, retiring the board question reviewer-roles?

10. **The player's words.**

    > yeah I like this

11. **Context** (the assistant's):

    Said next, while the orchestrator was filing this note and C2b (the crowd yields to event figures, minty-quail shared-components) was being built: whether the PR questions and the layer check can be built beside it rather than in the refactor's closing PR.

12. **The player's words.**

    > can we build this in parallel?
