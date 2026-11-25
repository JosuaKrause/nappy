# Playtest mossy-bunny — Fable-only is the two reviews' items, and new work opens an entry of its own

2026-11-11.

## #1387

1. **The note.**

   > minty-quail didn't have fable-only label

2. **The player's words.**

   > maybe one pr of it had

3. **Context** (the assistant's):

   Said to the orchestrating Claude Code session on 2026-11-11, after it explained that minty-quail (the refactor: one engine, the codebase refactored by layer), amber-ibis (what the rules review found outside the rule files) and gentle-finch (the caret, the home arrow and the edge badge's pointer as picture files) carry `fable-only: true` in their queue entries' opening blocks. The line was written by #1302 on the orchestrator's reading (inbox #1299 in grassy-trout, its reading 19) that the player's "all of these work items should be organized by fable", followed by "yes let's build that", named every item from the two Fable reviews of 2026-11-09 as fable-only. CI (`tools/ci_fable_only.py`) then required the label on every pull request that builds an item of those entries.

4. **Read as:** (the assistant's interpretation, not the player's words)

   The player never named minty-quail as fable-only: the entry's line was the orchestrator's reading, and at most one of its pull requests carried the label on the player's word. The line comes off minty-quail, so its pull requests no longer need the label: their design and review follow the orchestrating skill's model table (Fable is considered for planning and complex reasoning, and work Fable itself designed is reviewed by Fable). Read the same way, "organized by fable" asked for Fable to plan the order of the reviews' work, not for the label, so amber-ibis, from the same reviews, was not named either. gentle-finch came from the player's own board ask, not from a Fable review. The line comes off all three in one pull request, open to the player's correction there.

5. **Context** (the assistant's):

   Said after the orchestrator went back through the transcript of 2026-11-10 (session c021c586). There it had asked whether "all of these work items should be organized by fable" meant every item from the two Fable reviews becomes fable-only, or only that Fable plans their order. It had then read the go-ahead "yes let's build that", given to building the queue line, as answering that question too, and #1302 put the line on minty-quail, amber-ibis and gentle-finch as whole entries.

6. **The player's words.**

   > there were two reviews run by fable and the resulting items from that were the only ones that were approved to get fable-only

7. **The player's words.**

   > nothing else

8. **The player's words.**

   > we're not going to remove the label from PRs but work items that shouldn't have it need it removed

9. **Context** (the assistant's):

   Said after the orchestrator listed minty-quail's open items by origin and explained that the line marks a whole entry: CI tells which entry a pull request builds from the record it adds, and records name the entry, not the item. Five items came from the design review (inbox #1265 and #1268 in olive-ferret, written into the entry by #1269): `placement-by-construction.md`, `scheduler-breakup.md`, `one-start-for-every-spec.md`, `standing-layer-breaks.md` and `baseline-measurements.md`. Thirteen did not: `field-reads.md`, `method-without-parentheses.md`, `event-interface.md`, `typed-everywhere.md`, `city-hand-ins.md`, `comments.md`, `dead-code-sweep.md`, `re-derived-cases.md`, `system-map.md`, `tests-one-module.md`, `tests-own-class-members.md`, `tests-public-seams.md` and `tests-unseen-reads.md`. The player asked why the items had been attached to minty-quail at all. The orchestrator answered that #1269 wrote the review's findings into the entry they reviewed, and that the mistake was #1302 marking the whole entry when the player had asked for the label on "todo items".

10. **The player's words.**

    > if the mechanism doesn't support it then let' smove those items out and put the label then

11. **Read as:** (the assistant's interpretation, not the player's words)

    Replaces this note's first reading. fable-only belongs to the work items that came out of the two Fable reviews of 2026-11-09, and to nothing else: the rules review (inbox #1267 in olive-ferret), whose items are amber-ibis and gentle-finch, and the refactor's design review (inbox #1265 and #1268 in olive-ferret), whose items are the five above. The five move out of minty-quail into an entry of their own that carries `fable-only: true`, and minty-quail loses its line. amber-ibis and gentle-finch keep theirs. No pull request loses the label it already carries, and an open pull request that carries it keeps a Fable review.

12. **The player's words.**

    > Putting the items in minty-quail (#1269, 2026-11-09) was a reasonable call at the time.  -- no it wasn't -- don't keep stacking more work on existing items -- you have enough tools to control exactly the work order

13. **The player's words.**

    > even if not including it in another work item

14. **Context** (the assistant's):

    Said in reply to the orchestrator's explanation, of which the player quotes its first sentence: #1269 wrote the design review's findings into minty-quail because the review was of that entry's plan, the queue's usual practice being that an item sits with the work it changes.

15. **Read as:** (the assistant's interpretation, not the player's words)

    New work is filed as an entry of its own, never added to an existing entry, even when it changes or follows that entry's work: its place in the order is set by the queue's own means (`after:`, `upnext:`, the band), which order it exactly without nesting it in another entry. That covers `placement-by-construction.md` too, which existed before the review but now holds the review's five steps, so it moves with the other four. The rule goes into the filing rules (playtest-feedback and the inbox skill's filing) in the pull request that moves the five.

16. **The player's words.**

    > anyway let's fix it

17. **The player's words.**

    > and make it note on opening new work items instead of piling work onto existing items

18. **Context** (the assistant's):

    Said while the orchestrator was briefing the pull request that moves the five design-review items into an entry of their own.

19. **Read as:** (the assistant's interpretation, not the player's words)

    The go-ahead for that pull request, and for it to write the rule into the filing rules: new work opens a new entry, never piled onto an existing one.
