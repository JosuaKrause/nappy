# velvet-puffin — A resume of a sub-agent is refused once past 400k tokens of context, and nothing counts turns · 2026-11-09

**The ask.** "what about 400k? note, this is different than the 500k rule for reassessing agents --
this should kick in earlier since it's about resuming agents, no?", "yes, 400k as mr budget said",
"no turn count", "no turn counters is fine I think -- context is a better measure"
(merry-badger #1298). The hook itself the player approved in the session that reviewed the week's
usage: "hook yes, usage report script yes, and the ungraded agent list", with "no rule changes --
that worked well. it's fine if it goes a bit over now and then" (inbox #1291).

**Why a hook.** The orchestrating skill already said that an agent stays on one task and that no
agent grows huge (inbox #874 in minty-dolphin), and each single resume was still decided by "a warm
agent is reused" (inbox #896 in plaid-raven): one design agent was kept on through resumes for 37
hours and 2,295 turns, through three automatic compactions, its hand-backs reporting 507k, 628k,
733k and 776k tokens and each followed by another resume. A rule that has to be remembered did not
hold at the one moment it mattered.

## What was built

- **The hook `.claude/hooks/resume-guard.py`**, on every `SendMessage`: it finds the sub-agent the
  message goes to, and refuses the message once when that agent's context in its latest turn is
  past 400k tokens or its context was compacted automatically. The same message sent again passes.
  It counts no turns, never breaks a session (an error passes the message and is logged), and
  spends no model tokens.
- **The refusal asks one question**: a follow-up on the agent's own pull request (a delta review,
  review or CI fixes, a merge of `main`, a stop or wrap-up) is sent again; new work goes to a fresh
  agent briefed from the brief file and what the old agent left. The reassessment at 500k applies
  on top.
- **One owner for the number**: the sentence "A resume is refused once past 400k tokens of context"
  in the orchestrating skill's `references/writing-a-brief.md`. The hook reads the number out of
  that sentence and holds none; its test fails on a reworded, removed or doubled sentence.
- **Three numbers, each of context and none of turns**: about 300k is the size a task is scoped to
  finish under, which nothing enforces; 400k is the refusal; 500k is the reassessment, which the
  refusal's pull request only named; the pull request that wrote its rule is the section "The
  reassessment at 500k", below. `references/writing-a-brief.md` drops "about 150 turns" and the
  aim of 30 to 60 turns for a review, and `tools/agents-to-reassess.py` reads the scoping sentence in its
  new wording and flags nothing for turns alone; its `turns` column stays as information.
- **The skills** say what the hook enforces: the orchestrating skill's opening list, its bullet on
  an agent staying on one task, and the using-tools paragraph on the hooks. Two more sentences of
  the orchestrating skill change what the orchestrator does: the model table's row for review fixes
  reads "the builder, while warm", since a fix on the agent's own pull request is sent again at any
  size, and the bullet on reusing a warm agent sends work on its own pull request, the next step of
  the same change included, back to it while it is warm and under the size a resume is refused at;
  past that size only the refusal's short follow-up jobs go back.

## Measured

The usage-review session's figures for sub-agents since 2026-10-31, over 750 resumes: at 400k, 89
refusals in 9 days, 19 of them long follow-ups; at 300k, 132 refusals; at 500k, 49. At 400k to 500k
of context a fresh agent breaks even at about 31 turns on Opus and 24 on Sonnet, against a 75th
percentile of 15 turns for a delta review, 25 for fixes, 24 for a merge, 15 for a stop and 44 for
new work. They are cost only: what a warm agent knows of its pull request is not in them, and the
player does not act on cost alone (inbox #1291).

## Tried and replaced

- **A refusal at about 150 turns or 300k tokens**, the limit `references/writing-a-brief.md` held,
  an orchestrator's proposal of 2026-10-31 that the player never set. It was built first.
  Replayed by the usage-review session over the resumes since 2026-10-31 it would have refused
  132 times, most of them short, cheap follow-ups.
- **A refusal at 500k, tokens only**, the usage-review session's first recommendation. The player
  asked for it earlier than the reassessment, since it is about resuming.
- **A turn trigger beside the context**: it would add 37 refusals in 9 days to catch little, and a
  turn costs whatever its context costs.
- **A tolerance inside the hook** on top of its number: the distance between the size a task is
  scoped to and the size a resume is refused at already is the room the player's "it's fine if it
  goes a bit over now and then" asks for.
- **"Never for more work"** as the refusal's wording in the first build: the refusal asks its one
  question instead, and only new work goes to a fresh agent.
- **A sentence in the refusal that work never moves to another model by a resume, only by a new
  brief**, which the design's refusal text held and the hook and its test carried. It was taken
  out: a resume carries no choice of model, since a message goes to the agent as it runs, so the
  sentence warned of something a resume cannot do. The player's words on a change of model belong
  to the reassessment, and `reassessment-rule.md` holds them.
- **A warm-agent bullet that named only review fixes, a delta review and a merge of `main`**, the
  first fix of that bullet: it took the next step of a change away from a warm agent under the
  size, where the player's rule bounds the reuse by the agent's size and not by the kind of job
  (inbox #896 in plaid-raven), and the later words narrow it past 400k only.

## Choices open to the player's overturn

The filer's. Marked so in the skills: a refusal is remembered per sender, target and exact message
text and never cleared within a session; which jobs the refusal's two lists name; "past" is
strictly more than the number; the reworded item on a cold agent's follow-up in
`references/writing-a-brief.md`. Held by the hook alone, and named only here and in the pull
request: the refusal prints exact token counts; exactly one matching sentence is required and a
size of zero is unreadable. And one in `tools/agents-to-reassess.py`: its `turns` column still
shows a turn count, for information, as a sign an agent is stuck, where the table the player
agreed to has no turn counters anywhere; no limit and no flag reads it. And the orchestrator's
ruling: the refusal carries no sentence about a model, though the player's words are "never switch
a model with the full context. when switching a model do a new brief" (merry-badger #1298).

## The reassessment at 500k

**The ask.** "if a subagent grows to like 500k it should be reassessed whether that agent model is
suitable for that kind of work or whether it got stuck or into an infinite loop", "let's go with
500k", "(of course there are exceptions)", "do a script that tells you which agents to reassess",
and "also never switch a model with the full context. when switching a model do a new brief"
(merry-badger #1298).

**What was written**, in the orchestrating skill, the entry's last item:

- **The rule**, in the opening list and as a bullet of "What the orchestrator keeps" beside the one
  on an agent staying on one task: a sub-agent whose context reaches about 500k tokens is
  reassessed before it goes on or is sent anything more, for whether its model suits the work,
  whether it is stuck and whether it is looping; `tools/agents-to-reassess.py` flags it, run by the
  recurring check on the running agents, whose bullet names the script.
- **The change of model** as a clause of that bullet: work that moves to another model starts from
  a new brief written for that model's agent, never from the old agent's context.
- **What it narrows**, said beside the rule that a task is scoped and never policed
  (inbox #896 in plaid-raven): the recurring check's reading of each running agent's size, by the
  script from the agent's transcript, is the one exception to the orchestrator not watching an
  agent's count while it runs; it costs the agent no turn. The resume hook reads a size too, only
  when a message is sent, which is no watching.
- **Two small corrections to the bullet on reusing a warm agent**, notes of the resume refusal's
  last review: an agent compacted automatically is named beside the size, and a line is rewrapped.

**Choices open to the player's overturn**, each marked so in the skill:

- The reassessment is a judgement and not a stop: a running agent goes on meanwhile and one found
  fine goes on after it. It happens once the agent is flagged and before it is sent anything more.
- The orchestrator judges which case is an exception.
- The check that reads a running agent's size is the recurring one, about every 30 minutes; the
  table the player agreed to names the 45-minute check.
- No exception is named in the rule. The usage-review session proposed three (an agent whose
  context is mostly the output of runs, one that finished its change cleanly, one already on
  Fable), and they stand in the skill only as that proposal.
- The change of model is a clause and not a rule of its own. Asked which of the evening's rules are
  permanent, the player said of it "should become a rule -- is it even relevant? can claude switch
  models mid-agent-session?" (inbox #1303). The orchestrator's answer: a sub-agent's model is set
  when it is spawned and a resume carries no choice of one, so a change of model is always a new
  agent, and the words decide only that the new agent is briefed afresh.
