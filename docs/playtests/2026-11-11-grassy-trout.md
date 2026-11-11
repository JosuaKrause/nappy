# Playtest grassy-trout — The agent tooling, the Fable rules, tooling first, test times from CI, and three board answers

2026-11-11.

## #1282

1. **The note.**

   > One alternative is still open: giving the runner script a class name would make the header one line instead of two across about 330 suites. -- that sounds good! let's do it

2. **Context** (the assistant's):

   Said in the chat on 2026-11-09. The first sentence is the player quoting the orchestrator's own report back; the player's words are "that sounds good! let's do it". The report was about the typed-access pull request (#1277) and the typed header a new test suite opens with, written into the test-writing skill as two lines: the runner script (`tests/run_tests.gd`) preloaded as a constant named `Runner`, and `func run(t: Runner) -> void:`. The orchestrator's sentence in full: "One alternative is still open: giving the runner script a class name would make the header one line instead of two across about 330 suites. I kept the two-line form for now because it needs no code change, and will revisit it in the scripted rewrite that types every suite." It follows the player's rule on typing filed as inbox #1280 in olive-ferret (we type when we can).

3. **Read as:** (the assistant's interpretation, not the player's words)

   The test runner script gets a class name, and a suite's typed header is the one line `func run(t: <that class>) -> void:` with no preload. The player names no class name and no pull request; the orchestrator builds it in #1277, where the header is being introduced, so the two-line form never lands.

## #1284

1. **The note.**

   > I have another agent that is building some tooling for token analysis and a hook that automatically rejects reviving subagents that are too large

2. **Context** (the assistant's):

   Said in the orchestrating session (c021c586) after it had resumed several warm sub-agents (the typed-access fixer at about 200k tokens after a lock-out, the #1276 fixer at about 260k) and reported the lock-out its own EnterWorktree call caused. Not a question answered; a heads-up from the player about work in another session.

3. **The player's words.**

   > I will have it notify you when it is done so you can review and merge

4. **Context** (the assistant's):

   Said right after the orchestrator answered #1284 (it would start a fresh agent from the brief when a revival is refused, and noted a possible overlap with its Fable rule fix in the orchestrating skill).

5. **Read as:** (the assistant's interpretation, not the player's words)

   The other session's pull request comes to the orchestrating session to be reviewed (by a fresh reviewer, as pr-review says) and merged under the standing merge permission once its gates hold.

## #1290

1. **The note.**

   > the approval is in the other chat

2. **Context** (the assistant's):

   Said in the orchestrating session (c021c586) after it reported that the usage-review session (doctor-improvements-weekly-review) had handed over three tooling pull requests for review and merge: #1286 (tools/agent-stats.py ungraded, the finished agents nobody graded), #1289 (tools/usage-report.py, usage over date windows) and #1287 (the resume-guard hook refusing once a resume of a sub-agent past the brief guide's limit or compacted automatically), and that the player's approval of them sat only in that other session, with no inbox note, so the skills could not cite it.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The player approved the three tools in the usage-review session on 2026-11-09 (the hook, the usage report, the ungraded list); this note records that the approval exists, so the rule sentences #1287 adds may cite it rather than stand as the filer's proposal.

4. **The player's words.**

   > hook yes, usage report script yes, and the ungraded agent list

5. **Context** (the assistant's):

   Said in the usage-review session (d7cb9274, the session named doctor-improvements-weekly-review) on 2026-11-10 at 00:04 UTC (2026-11-09 local), copied here from that session's transcript at the player's word ("you can read the transcript"). It answered the player's own question "what changes would you propose based on what we see?", to which that session proposed, numbered as it wrote them:
   1. a hook that runs before every SendMessage to a sub-agent and refuses the resume when that agent has already compacted automatically or is past the limit in orchestrating's references/writing-a-brief.md, naming the fresh-agent rule; it changes no limit, only checks at the moment of resuming and spends no model tokens (the placement agent had grown to 776k tokens across #1248 and #1249 and compacted three times, about 129M tokens, 18% of the week);
   2. a script for that week's usage analysis, tools/usage-report.py with --since/--until windows, keeping its data under ~/.claude/nappy-agent-stats/usage/ (the second time it was done by hand, woolly-finch 23);
   3. flagging agents nobody graded: agent-stats listing the runs with no matching grade;
   4. optional: a grade's note saying why a stronger model was picked.
   "hook yes" accepts 1, "usage report script yes" accepts 2, "the ungraded agent list" accepts 3; 4 is not named. The three were built as #1287, #1289 and #1286.

6. **The player's words.**

   > you can read the transcript

7. **Context** (the assistant's):

   Said right after "the approval is in the other chat", while the orchestrating session was recording it; the player pointing the orchestrator at the other session's transcript, from which the approval above was copied.

## #1291

1. **Context** (the assistant's):

   Said on 2026-11-09 in a Claude Code session (not the orchestrating one) that analysed the week's sub-agent usage. The player asked "what changes would you propose based on what we see?", and the words below answer this list, as it was shown:

   **1. Stop resuming an agent onto the next pull request of a plan (main proposal).** The skills already say a split plan gets a fresh agent per pull request and no agent grows huge, but "reuse a warm agent" won every single decision. The placement design agent's hand-backs reported 507k, 628k, 733k and 776k tokens across #1248 and #1249, it was given more work each time, then hit the ceiling and compacted automatically three times, about 129M weighted tokens, 18% of everything since Friday. Since the written rule did not hold, make it mechanical: a hook on `SendMessage` to a sub-agent that refuses the resume when the agent has auto-compacted or is past the limit in `references/writing-a-brief.md`, naming the fresh-agent rule. It fires only at resume time and costs no model tokens, so it respects "scoped by construction, never policed" (inbox #896), and it changes no limit, so it fits "no rule changes"; it just makes the existing rule hold where "a bit over" became 2,295 turns.

   **2. `tools/usage-report.py`.** This analysis was the second by hand, which the repo says becomes a script (woolly-finch 23): `--since`/`--until` windows, the table above, data under `~/.claude/nappy-agent-stats/usage/`.

   **3. Ungraded agents surfaced.** The costliest agent has no grade after #1249, and #1254/#1256 are ungraded, so the agent-stats summary undercounts the agents worth looking at. The SubagentStop hook already logs every agent's tokens in `runs.jsonl`; `agent-stats.py summary` could list runs with no matching grade. A tool change, not a rule.

   **4. Optional: say why a stronger model was picked.** Opus did 9 test-parity builds since Friday against 1 the week before, about 2.5× a Sonnet parity build's tokens, while Sonnet's parity builds grade 82% good. Most were built from Fable designs, where the table leaves the model to the orchestrator, so nothing was broken; a note in the grade on why Opus was picked would let the next review tell judgement from drift.

   **Not proposing:** Fable reviews (a one-off for the rules review, all good), compaction, the 1-hour cache: all working.

   The player picked 1, 2 and 3, not 4. They became #1287 (the hook), #1289 (the usage report) and #1286 (the ungraded list).

2. **The note.**

   > hook yes, usage report script yes, and the ungraded agent list

3. **Context** (the assistant's):

   Said in the same session on 2026-11-06, while the agent was working, during the review of how the previous /doctor improvements had worked over the week. The improvements reviewed were the 1-hour sub-agent prompt cache, and the agent-size rule in **orchestrating** added by PR #875, "An agent stays on one task, and no agent grows huge" (inbox #874); the review found both had worked. The player had just asked "what's a restart limit?", and the words answer this message, the last one shown before them:

   > A "restart limit" was my name for a rule I hadn't written yet. Once the main session's context passed about 400k, it would write the restart prompt and ask you to start a fresh session. That needs you to act, so it isn't hands off. Checking whether the session really never compacted, and whether automatic compaction can be set to start earlier.

   On 2026-11-09 the proposals in this note were made against these words: the hook in proposal 1 changes no limit and adds no restart rule, it enforces the existing agent-size rule at the moment of a resume.

4. **The player's words.**

   > no rule changes -- that worked well. it's fine if it goes a bit over now and then

5. **Context** (the assistant's):

   Said in the same session on 2026-11-09, while the three builds ran. The answer then: Fable agents and sessions came to about $351 of $1,801 (19.5%) at API prices since 2026-11-06 16:47Z, against $234 for the same tokens at Opus 5.5 prices (about 1.5×). That is why `tools/usage-report.py` (#1289) prices every turn per model and has a column pricing each family's tokens at Opus prices.

6. **The player's words.**

   > how much of my tokens did the fable agents use up?
   >
   > (it was definitely worth it but I would like to be able to compare to running opus)

7. **Context** (the assistant's):

   Said on 2026-11-09 in the same session, after the note above was captured. "The opus equivalent for fable" is the comparison this session reported and #1289's `tools/usage-report.py` prints as a column: each model family's tokens priced also at Opus 5.5 prices. As this session put it to the player:

   > So Fable cost about 1.5× what Opus would have for the same tokens. A median Fable review cost $10.60 against $4.80 for an Opus review, but most of those Fable reviews were the large rules reviews, so the two aren't the same kind of task. The new report script will make this comparison a single command.

   The report's own caveat on that column, as briefed, says only that "the same tokens" is an assumption.

8. **The player's words.**

   > one note. the opus equivalent for fable is slightly misleading since fable gets things done more efficiently and does things that opus wouldn't be able to do. while it is important to compare costs directly we shouldn't act on cost alone.

9. **Context** (the assistant's):

   Said right after the words above, while this session was appending them; this session had just said it would ask for #1289's caveat on the Opus-price column to carry the point. "This" is that column.

10. **The player's words.**

    > maybe add a note that this is for information only

## #1292

1. **The note.**

   > yes, let's fix the guard

2. **Context** (the assistant's):

   Answers the orchestrating session's report that the GitHub write guard (.claude/hooks/github-write-guard.sh) refuses a command that only writes text mentioning the GitHub command-line tool: the usage-review session reported that a cat heredoc whose body merely mentions the GitHub CLI is refused, and the orchestrating session met the same (a brief appended with a heredoc naming tools/update-pr.sh was refused until the text went in as cat > FILE <<'EOF' as the whole command). It offered that fixing it is a small change to the guard.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The guard stops refusing a command whose only GitHub-looking words are text it writes to a file (a heredoc body), while still denying every real write and anything the shell would run (command substitution, an unquoted heredoc that expands).

## #1293

1. **The note.**

   > for the fable's work have fable review and fable write

2. **Context** (the assistant's):

   Said in the orchestrating session (c021c586) right after it listed the Fable work not yet merged: the typed-access rule sentences on #1277 (written by Fable), the resume-guard hook #1287 (built with Fable in the usage-review session, being reviewed by an Opus agent), the ungraded-agents list #1286 (a Fable agent fixing its review findings, the review by Sonnet), and the write-guard fix (a Fable agent building it, inbox #1292). The model rules standing before it: Fable for designs and for rule-file changes; Opus for play-changing builds and reviews, Sonnet for queue and docs reviews.

3. **Read as:** (the assistant's interpretation, not the player's words)

   Work Fable wrote is reviewed by a Fable reviewer, and any fix to it is written by Fable: a pull request with Fable's work in it gets a Fable review, and its review findings go to a Fable fixer. Read as also covering a pull request that mixes Fable's work with another model's (its review is Fable's).

4. **The player's words.**

   > let's get them merged

5. **Context** (the assistant's):

   Said right after the note above, while the orchestrating session was recording it; "them" read as the open pull requests holding Fable's work (#1277, #1286, #1287 and the write-guard fix).

6. **The player's words.**

   > can we get a PR label that indicates "use fable for reviewing and writing code only"

7. **Context** (the assistant's):

   Said right after the two messages above (Fable's work reviewed and written by Fable; let's get them merged).

8. **Read as:** (the assistant's interpretation, not the player's words)

   A GitHub label on a pull request tells every session that its code is written and reviewed by Fable only; the orchestrator reads it when choosing the model for a builder, a fixer or a reviewer on that pull request.

9. **The player's words.**

   > that way we can make this information survive the session

10. **Context** (the assistant's):

    Said right after asking for the PR label above: why a label, so which pull requests are Fable-only outlives the session that knew it.

11. **The player's words.**

    > wait why is the hook and the agent stats fable only?

12. **Context** (the assistant's):

    Said after the orchestrating session put the fable-only label on #1287 (the resume-guard hook, built with Fable in the usage-review session) and on #1286 (the ungraded-agents list, built by Sonnet, its review fixes being written by a Fable agent). The orchestrator answered that #1286's label was its mistake (not Fable's work) and removed it, and that #1287 followed the reading that Fable's work is reviewed and written by Fable, open to the player's correction.

13. **The player's words.**

    > fable did exactly two kinds of work tonight -- skill/rule/claude file review and design review -- what happened to those?

14. **The player's words.**

    > no implementation? well this is fable only

15. **Context** (the assistant's):

    Said after the orchestrating session listed which open pull requests Fable had built (only the resume-guard hook #1287 and the write-guard fix) and asked what "the actual Fable PRs" meant. To the first, the orchestrator answered that the rules review merged as #1270, #1271, #1272 and #1274, and that the refactor's design review was filed by #1281 and became the minty-quail items being built by Opus and Sonnet (#1275, #1283, #1288 merged; #1277, #1276, #1262 in review). The second followed that answer.

16. **The player's words.**

    > neither

17. **Context** (the assistant's):

    Answer to the orchestrator's read-back of "well this is fable only": (a) the label is for Fable's own work, so nothing carries it and #1287's label comes off; or (b) the pull requests built from Fable's designs (#1277, #1276, #1262) become fable-only, switched at their next round. The orchestrator had guessed (a).

18. **The player's words.**

    > the label "fable-only" means the code design and review (the coding itself can be handed off to someone else) must happen via fable. the label applies to work that I mention should have fable-only

19. **Context** (the assistant's):

    The player's definition of the fable-only label, after "neither" to the orchestrator's two readings and its request for a sentence saying which pull requests carry it.

20. **Read as:** (the assistant's interpretation, not the player's words)

    fable-only: the code's design and its review are Fable's; writing the code may go to another model. The label goes only on work the player names as fable-only; the orchestrator never adds it on its own reading. #1287's label, added on the orchestrator's reading, comes off.

21. **The player's words.**

    > like the two items above

22. **Context** (the assistant's):

    Said right after the label's definition above; "the two items" read as the two kinds of work the player named Fable as doing tonight: the review of the skills, rule files and CLAUDE.md, and the refactor's design review.

23. **The player's words.**

    > let it play out but didn't we say resume-guard hook (#1287) is *not* a fable task?

24. **Context** (the assistant's):

    Said after the orchestrator reported it had started a Fable agent, from a new brief, to fix #1287's review findings (the hook's name resolution and hardening, plus the orchestrating skill's sentences and citation), after the fable-only label had been taken off #1287.

## #1294

1. **The note.**

   > let's hold off on constantly restarting agents

2. **The player's words.**

   > let's figure it out first then we do action

3. **Context** (the assistant's):

   Said in the orchestrating session (c021c586) while it was, in quick succession: stopping an Opus reviewer of #1287 and starting a Fable one after the fable-only label was made; stopping a looping reviewer of #1286; spawning fresh fixers for each review round (on #1262, #1276, #1277, #1286) because each builder had grown large; resuming a fixer on #1276 to delete one more unreachable check; and about to start a Fable agent for #1277's skill sentences. The player had just asked why #1287 and #1286 were labelled fable-only (#1286's label was the orchestrator's mistake and was removed).

## #1295

1. **The note.**

   > the later bands is not suitable for work that has to come after the refactor

2. **Context** (the assistant's):

   Said after the orchestrating session reported that #1279 filed the rules review's leftovers as the entry amber-ibis (8 items: citations after a comma, closures through the planner, the lethal field across a day, no pelican picture, old briefs, small false sentences, suites that do not exist, tool help gaps) with priority: later and after: 2026-10-18-minty-quail, the band and the wait being the filer's proposal.

3. **The player's words.**

   > now of course with after

4. **Context** (the assistant's):

   Answer to the orchestrator's question whether amber-ibis (the rules review's leftovers, waiting on minty-quail by its after: line) goes in the now or the next band; the orchestrator had picked now.

## #1299

1. **The note.**

   > this is specifically talking about the changes we made today -- not in general -- "rule/skill/claude changes" was one task item

2. **Context** (the assistant's):

   Said after the orchestrator showed where its "standing rule that rule-file changes are written by Fable" comes from: the player's words in inbox #1264 in olive-ferret ("for code I'm fine with your choice as long as fable did the design and for the rule/skill/claude changes I want fable to do it directly"), said on 2026-11-09 while the four pull requests of the rules review were being prepared, which the filing (#1281) wrote into the orchestrating skill's model table as a general row: "A change to a rule file: a skill, CLAUDE.md, a hook's text | Fable, directly (inbox #1264 in olive-ferret)". The orchestrator had applied that row to tool pull requests touching one catalogue line or a hook's comments.

3. **Read as:** (the assistant's interpretation, not the player's words)

   The "rule/skill/claude changes" of inbox #1264 were one task item of 2026-11-09, the rules review's changes, not a general rule; the orchestrating skill's row making every rule-file change Fable's misreads the player and goes.

4. **The player's words.**

   > A task that needs planning or complex reasoning              │ Fable is considered -- this is the only rule I mentioned today -- everything else you filed as rule was me giving an instruction for a single work item

5. **Context** (the assistant's):

   Said after the orchestrator listed every mention of Fable in the orchestrating skill: line 17 ("a design and a change to a rule file are Fable's"), the model table's four rows citing inbox #1264 in olive-ferret (planning or complex reasoning: Fable is considered; the design code is built from: Fable; code built from a Fable design: the orchestrator's choice; a change to a rule file: Fable, directly), and two "Proposed, not asked for" bullets on the last two.

6. **Read as:** (the assistant's interpretation, not the player's words)

   Of the Fable rules filed from inbox #1264, only the table row "A task that needs planning or complex reasoning | Fable is considered" is a rule. The design row, the row on code built from a Fable design, the rule-file row, line 17's clause and the two proposal bullets go: each came from an instruction for one work item of 2026-11-09.

7. **The player's words.**

   > that and the github label

8. **Context** (the assistant's):

   Said right after the note above, while the orchestrator was removing the other Fable rows; read as: the two Fable rules are the planning row and the fable-only GitHub label (inbox #1293).

9. **The player's words.**

   > and we can do a third rule that if fable designed something fable needs to review

10. **The player's words.**

    > all the other stuff has to go

11. **Context** (the assistant's):

    Said right after "that and the github label", while the orchestrator was rewriting orchestrating's model table to the planning row and a row for the fable-only label.

12. **Read as:** (the assistant's interpretation, not the player's words)

    The model table holds three Fable rules: a task that needs planning or complex reasoning considers Fable; a pull request the player labels fable-only has its code designed and reviewed by Fable; and whatever Fable designed is reviewed by Fable. Every other Fable rule filed from inbox #1264 goes.

13. **The player's words.**

    > all of these work items should be organized by fable

14. **Context** (the assistant's):

    Said after the orchestrator listed what the two Fable reviews of 2026-11-09 proposed: the refactor's design review (eight findings: placement drawn as she walks, the walk's draw cut, one start for every spec, the standing layer breaks, the scheduler's breakup, the order as parallel tracks, baseline numbers, the escape city's draw; smaller: the field-read check made to see every read, the README's layer list, freezing the entry, four cuts) and the rules review (eighteen findings, built by #1270-#1274, leftovers in amber-ibis; gentle-finch's symbols itemised from the player's board ask).

15. **The player's words.**

    > can we put the label in the todo items in the repo? would it be clear that that would mean the PR gets the label and the label means that fable does the design and review (but can hand off coding)

16. **Context** (the assistant's):

    Said after the orchestrator read back "all of these work items should be organized by fable" as: every work item from the two Fable reviews becomes fable-only, its open PRs labelled, a Fable agent planning the order.

17. **The player's words.**

    > yes let's build that

18. **Context** (the assistant's):

    Answer to the orchestrator's proposal: a `fable-only: true` line in a queue entry's opening block (minty-quail, amber-ibis, gentle-finch), docs/TODO.md saying every pull request building an item of that entry carries the fable-only label (Fable designs and reviews, may hand off the coding), tools/queue.sh printing and checking it, the model table's label row naming the entry line, and a CI check failing such a pull request without the label.

19. **Read as:** (the assistant's interpretation, not the player's words)

    Built as proposed, in one pull request designed and reviewed by Fable; the open pull requests building those entries' items (#1262, #1276, #1277) get the label now, the player's "all of these work items should be organized by fable" read as confirmed by this go-ahead.

20. **The player's words.**

    > how is building the label equivalent to the label itself?

21. **The player's words.**

    > "A Fable agent then changes the hook and the guide, and it merges after a Fable review. " -- why are you planning a fable agent here?

22. **Context** (the assistant's):

    Said after the orchestrator said a Fable agent was building the fable-only queue line (and had briefed it to label its own PR fable-only), and planned a Fable agent to change #1287 for the 400k resume refusal.

23. **Read as:** (the assistant's interpretation, not the player's words)

    Building the label mechanism is ordinary tooling, not a fable-only item; its PR carries no label. A fix to a Fable-designed PR (#1287) is written by a model chosen by the normal table; only its review is Fable's (inbox #1299).

## #1303

1. **Context** (the assistant's):

   The player had asked which of eight rules from the evening of 2026-11-09 are permanent rules and which are only notes in the handoff file. The orchestrator answered with this table, and the player's numbers answer its rows:

   1. Planning considers Fable. Permanent: a row of the orchestrating skill's model table, on main.
   2. The fable-only label: Fable designs and reviews, coding may go elsewhere. Permanent: model table row on main since #1300 merged.
   3. Anything Fable designed is reviewed by Fable. Permanent: model table row on main since #1300 merged.
   4. An agent near 500k tokens is reassessed. Not a rule yet. Main has only the number inside the script that lists agents to reassess (tools/agents-to-reassess.py, #1301). The rule sentence is in the orchestrating skill on #1287's branch (the resume guard, unmerged).
   5. A model switch always gets a new brief. Not a rule yet: same sentence on #1287's branch only.
   6. Hold off on constantly restarting agents. Note only: inbox #1294 and the handoff file; in no skill and on no branch.
   7. The later band is not for after-the-refactor work. Note only as a rule. It was applied once (amber-ibis, the rules review's leftovers, moved to now in #1297), but docs/TODO.md's description of the bands does not say it.
   8. Code is typed wherever it can be, tests included. Not a rule yet. Main has the queue item (typed-everywhere, the work of typing the suites); the rule sentences in the godot, designing-classes and writing-tests skills are on #1277's branch, unmerged.

   The table closed with: "So 4, 5 and 8 become permanent when #1287 and #1277 merge. Only 6 and 7 have no rule text anywhere, and they need filing to become rules."

2. **The note.**

   > 1) okay 2) okay 3) okay 4) I thought implementation had already started? 5) should become a rule -- is it even relevant? can claude switch models mid-agent-session? 6) no need to make a rule -- that was just opus last session 7) that's more of a common sense thing -- making it a rule doesn't make sense since it would need there to always be a refactor 8) that was one of the earlier rules last session why did it never get implemented?
   >
   > do those things all make sense?

## #1305

1. **Context** (the assistant's):

   Said to the orchestrating session on 2026-11-10 (shortly after midnight, local time), while it ran two kinds of work side by side: pull requests that change how the project is worked on (the hook that refuses resuming an oversized sub-agent, #1287; the usage report script, #1289; the fable-only line on queue entries with its CI check, #1302; the filing of inbox #1298, #1304) and pull requests of the refactor (minty-quail: #1262, #1276, #1277). The refactor is the entry the player put first, with everything else after it (inbox #1210 in gentle-owl). Right after, the player asked how far the current round of meta and project changes is, and how far the refactor is.

2. **The note.**

   > let's make it a rule that changes to skills/claude files/rules/hooks/general project scripts etc. always get done first and have highest priority. since those are tools needed to write code in the first place the sooner we get them the sooner they will be applied

3. **The player's words.**

   > goes ahead of everything else in the queue, including the refactor you put first. -- what do you mean by that? the refactor is not about meta changes

4. **Context** (the assistant's):

   A question about the orchestrator's reading of the rule above, which it had stated as: "work on how the project is worked on (skills, CLAUDE.md, rules, hooks, general scripts under tools/) goes ahead of everything else in the queue, including the refactor you put first." The player's message begins by quoting that sentence's end. The orchestrator answered: the refactor is game code and not meta work; the refactor-first rule (inbox #1210 in gentle-owl) had held everything else back until it is done, and the new rule lifts that for meta work only: it starts at once, its pull requests are reviewed and merged before the refactor's when both wait, and the refactor keeps running beside it. Built that way in pull request 1306, marked as the orchestrator's reading.

5. **The player's words.**

   > so just to be clear, you're not writing "goes before the refactor" literally in the rule, right? refactor is not a thing that will always exist so it doesn't make sense to reference it in rules

6. **Context** (the assistant's):

   Said after the orchestrator explained its reading (meta work is not parked behind the refactor, and its pull requests go first while the refactor keeps running) and that the reading is written into pull request 1306. The orchestrator checked the pull request's added lines: none names the refactor. The skill says such work is startable "ahead of the queue's order and of an entry the player has put first".

## #1307

1. **Context** (the assistant's):

   Said to the orchestrating session on 2026-11-09, right after it reported: "The machine is heavily loaded (load average about 60), so timing-based hook tests are flaking locally. I'm judging those by CI and starting no extra builders until reviews drain." The tests meant are the ones with a time bound: the write guard's timed 64 KB cases in tools/test_rules_hooks.sh (a bound of 8 s) and a timing case of tools/test_codex_hooks.py (5 s), which several builders and reviewers that evening reported as local failures under load.

2. **The note.**

   > always read test times from CI -- that's where they matter anyway

3. **The player's words.**

   > I think it's common sense, but just to be clear, the CI timing reading applies for when you need the numbers. if you do an optimization obviously you need to measure locally

4. **Context** (the assistant's):

   Said a few minutes after the rule above, once the orchestrator had stated its reading: a time a test reports (a suite's duration, a check with a time bound) is taken from CI's run, a time bound that fails locally is not counted against a change, and game performance measurements by a probe (dawn time, frame cost) are not covered. A builder was already writing the rule into the verify skill with that boundary marked as the filer's proposal; with these words the boundary is the player's.

5. **The player's words.**

   > an optimization is measured locally -- what I mean by that -- while writing the optimization you might want to check different versions in quick succession -- this should be done locally because the CI cycle is too slow for this. when proving that an optimization works use CI timings because they are more reliable than local timings

6. **Context** (the assistant's):

   Said after the orchestrator summarised the player's earlier words on this note as "an optimization is measured locally" (in a status table: "the test-times rule, being built, with your boundary: an optimization is measured locally"). The player's message begins by quoting that phrase. It corrects the orchestrator's earlier reading, which had left every measurement of the game by a probe outside the rule.

7. **The player's words.**

   > and this only applies to things that are CI measurable anyway -- tests
   >
   > if you do a game optimization this does not apply

8. **Context** (the assistant's):

   Two messages sent one after the other, right after the player's explanation above (versions compared locally while an optimization is written; the proof from CI's timings). The orchestrator had just told the builder of the rule to find out what CI can time and to report as a fork anything it cannot, such as a probe of the game's dawn time or frame cost. These words settle that: the rule is about tests, which CI measures, and an optimization of the game is outside it.

## #1348

1. **Context** (the assistant's):

   The player's answer, typed on the You line of the board question `amber-ibis-order` (Nappy board, Main tab, 2026-11-11). The question as shown:

   - Question: does amber-ibis, what the rules review found outside the rule files, move ahead of the refactor now that work on skills, rules, hooks and scripts goes first? (blocks moving amber-ibis, nothing else)
   - Context:
     - Yesterday you put it in the band now, after the refactor: "now of course with after" (inbox #1295). The wait itself was my proposal, since many of its items are comments and docs in files the refactor is rewriting.
     - Today you made the rule that changes to skills, CLAUDE files, rules, hooks and general project scripts are always done first (inbox #1305).
     - Its three tool items: the citation checker misses a citation after a comma; gaps in some tools' help text; old brief files left behind.
     - Its five other items touch the game's code, tests or docs: three rules no test holds (the lethal field across a day, closures through the planner, no pelican picture), two suites the skills name that do not exist, and small false sentences in comments.
     - Moving all of it now means edits in files the refactor is about to rewrite, done twice or merged by hand.
     - Leaving all of it keeps three tool fixes waiting behind the refactor, against today's rule.
     - My pick: split it. The three tool items go first as their own entry; the five that touch the game's code and tests stay after the refactor.

2. **The note.**

   > split it

3. **Read as:** (the assistant's interpretation, not the player's words)

   The orchestrator's pick is taken: amber-ibis's three tool items (the citation checker missing a citation after a comma, the gaps in some tools' help text, the old brief files left behind) move into an entry of their own that goes first under the tooling-first rule (inbox #1305); the five items that touch the game's code, tests or comments stay in amber-ibis, after the refactor.

## #1349

1. **Context** (the assistant's):

   The player's answer, typed on the You line of the board question `naming-rule-everywhere` (Nappy board, Main tab, 2026-11-11). The question as shown:

   - Question: when the refactor puts a field behind a method, how far beyond yes-or-no fields should "the method gets a new name" go? (the yes-or-no part is built on my pick; nothing wider is built before you answer)
   - Context:
     - The trap: if a field becomes a method of the same name, a line left behind that still reads it without parentheses keeps loading and answers wrongly without any error: always yes in a yes-or-no test, never equal in a check for being there, no branch taken in a match.
     - Being written now (#1310): a yes-or-no field's method always gets a new name, in every part of the code (is_finished becomes is_gone()), so a line left behind fails instead. The events' design, whose open points you answered here, already did this for the events.
     - Not covered: other fields read in a way that stays silent. Two in the events: an event row's pursuit part, checked for being there 34 times; its look (which family of pictures it draws), read in a match 15 times. The events' design names their accessors after the fields (pursuit(), look()).
     - Three reviews showed that a rule listing which reads are safe cannot be written reliably: each round found one more read that stays silent.
     - Option A, stop at yes-or-no fields. Nothing more to rename. A missed read of another field stays silent unless a search or a test finds it.
     - Option B, always a new name, a number's method included. Needs no knowledge of the engine. Costs a name for every converted field and renames accessors across the events' design (speed(), pursuit(), look()).
     - Option C, only a number keeps its name. New names for parts, kinds and the like; speed() stays. Still renames the events' part accessors. Leaves a number's method read without parentheses in the common ways that stay silent: stored in a variable without a stated type, made into text, handed on untyped, tested as yes-or-no.
     - My pick: A, plus one step in every conversion: its pull request shows a search for the old name read without parentheses coming back empty. That covers the read a conversion misses at the cost of one command, without renaming the design's accessors.

2. **The note.**

   > A

3. **Read as:** (the assistant's interpretation, not the player's words)

   Option A: the new-name rule stays at yes-or-no fields, as designing-classes has it; no accessor of the events' design is renamed. Whether the pick's added step (each conversion's pull request shows a search for the old name read without parentheses coming back empty) is taken with it is asked on the board's Me line; it is not written into a rule before the answer.

## #1350

1. **Context** (the assistant's):

   The player's answer, typed on the You line of the board question `moved-reads-list` (Nappy board, Main tab, 2026-11-11). The question as shown:

   - Question: when the refactor only moves code (a function into a new file, a class nested inside another into a file of its own), may the list of today's reads of another class's field gain lines for the reads that moved? (blocks #1318's merge and the next placement step, the day plan's record lifted into a file of its own)
   - Context:
     - What you said yes to: today's reads "listed once in a shrinking list", where a new one fails CI (inbox #1182 in gray-dolphin).
     - What comes next: the placement track lifts the day plan's record (EventScheduler.Planned, what each event placed for the day is) into its own file as EventPlan. The check cannot see the fields of a class nested inside another, so about 93 of today's reads of it are in no list. Lifted, the check sees them, and the list gains those lines though no read was added. Moving seven scheduler functions into a new file adds lines the same way: the same reads under a new file name.
     - #1318 (open) makes the check pass such a move and still fail every real new read; its review found one hole, being fixed now.
     - Option A, a read that only moved passes and the list gains its lines. No new read is ever let through. Cost: the list's length stops being a running count of what is left; the lifted reads are converted later, module by module.
     - Option B, the list only ever shrinks. A pull request that moves code converts the moved reads to methods in the same pull request. Cost: the record's lift grows from a scripted rename to converting about 93 reads in 16 files, and each breakup step carries its reads' conversion.
     - Changing course later is cheap either way: under A the lifted reads are converted in a later pull request; nothing of the lift is redone.
     - My pick: A. The reads exist today, only unseen; listing them is the list becoming true, not growing.

2. **The note.**

   > A

3. **Read as:** (the assistant's interpretation, not the player's words)

   Option A: a read that only moved with its code passes the field-read check and the list gains its line; no new read is let through. #1318 merges as built (after its last delta review), and the placement track's lift of the day plan's record into its own file (EventPlan) is a scripted rename whose lifted reads are listed and converted later, module by module.
