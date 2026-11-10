# The reassessment at 500k is a sentence in the orchestrating skill

**The ask.** "if a subagent grows to like 500k it should be reassessed whether that agent model is
suitable for that kind of work or whether it got stuck or into an infinite loop", "let's go with
500k", "(of course there are exceptions)", and "also never switch a model with the full context.
when switching a model do a new brief" (merry-badger #1298).

**What to write.** The orchestrating skill (`.claude/skills/orchestrating/SKILL.md`) says, in its
opening list and in "What the orchestrator keeps" beside the bullet on an agent staying on one
task, that a sub-agent whose context reaches about 500k tokens is reassessed before it goes on or
is sent anything more: whether its model suits that kind of work, whether it is stuck, and whether
it is looping. The sentence names `tools/agents-to-reassess.py` as what flags such an agent, run
by the recurring check on running agents, and says that there are exceptions, as the player's
words do. It carries one clause for the model switch: when the reassessment, or anything else,
moves work to another model, the other model's agent starts from a new brief written for it, never
from the old agent's context. The skill's "Proposed, not asked for" names what in the sentence is
the filer's.

**Read as:** the reassessment is a judgement the orchestrator makes at 500k, not a stop: an agent
found fine goes on.

**What it narrows, and what stands.** The orchestrating skill says today that a task is scoped
under the limit by construction and never policed, and that the orchestrator does not watch an
agent's count while it runs (inbox #896 in plaid-raven). The player's later words make one
exception: "do a script that tells you which agents to reassess", and "it comes from mr budget but
I fully agree" of a table which, as the note's context gives it, has the reassessment reach any
agent that reaches 500k, flagged by the script or the 45-minute check, running or not
(merry-badger #1298). **Read as:** a running agent's
size is read at the recurring check, by the script, from its transcript, which costs the agent no
turn; everything else of that rule stands: a brief carries no size line, an agent is never asked
to count its own turns or tokens, and a task is still sized before it is spawned. The sentence
written into the skill says so beside the rule it narrows.

**Open, and built on the reading until the player says otherwise.** Asked on 2026-11-09 which of
the evening's rules are permanent, the player said of the model switch: "should become a rule -- is
it even relevant? can claude switch models mid-agent-session?" (inbox #1303). The orchestrator's
answer: a sub-agent's model is set when it is spawned and a resume carries no choice of model, so a
change of model is always a new agent; what the player's words still decide is that the new agent
is briefed afresh and is not handed the old one's transcript or context. So the model switch is one
clause of the reassessment's sentence, not a rule of its own, unless the player drops it.

*Proposed, not asked for:*

- **Which exceptions.** The player said only that there are exceptions. The usage-review session
  proposed three: an agent whose context is mostly run output (measuring, capturing), an agent that
  finished its change cleanly, and an agent already on Fable. They are that session's and are
  written, if at all, as a proposal.
- **That the check which reads a running agent's size is the recurring one**, run about every
  30 minutes while agents work; the table, as the note's context gives it, names the 45-minute
  check.
