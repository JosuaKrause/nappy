priority: now
upnext: true

# velvet-puffin — A sub-agent at 500k tokens is reassessed, and a model switch is a new brief · filed 2026-11-09

**The ask.** In the orchestrating session, after a night of fix rounds in which several builders
grew past 250k tokens of context, the player said "another guidance: if a subagent grows to like
500k it should be reassessed whether that agent model is suitable for that kind of work or whether
it got stuck or into an infinite loop", then "also never switch a model with the full context. when
switching a model do a new brief", and, after the orchestrator had measured the running sub-agents
from their transcript files with a one-off script, "do a script that tells you which agents to
reassess" (merry-badger #1298).

In the session that reviewed the week's usage the player weighed the number: "(of course there are
exceptions)", "I'm considering a rule 500k tokens or more trigger a reassessment whether it's the
right model", "what about 400k?", and, told that 400k would roughly quadruple the reassessments with
most ending in "fine as is", "let's go with 500k" (merry-badger #1298).

On the hook that refuses, once, the resume of an oversized sub-agent, the player asked "what about
400k? note, this is different than the 500k rule for reassessing agents -- this should kick in
earlier since it's about resuming agents, no?", answered the usage-review session's recommendation
with "yes, 400k as mr budget said" and "no turn count", and in that session "no turn counters is
fine I think -- context is a better measure". Shown the resulting table (400k of context: the
resume refusal; 500k: the model reassessment; 300k: a sizing target for a brief, not enforced; no
turn counters anywhere), the player said "it comes from mr budget but I fully agree"
(merry-badger #1298).

Of filing it, the player said: "the other agent added some color to the 500k rule. let's file that
and do it next" (merry-badger #1298). **Read as:** this note is filed alone, ahead of the other open
notes, and its rule is built next, which is the entry's `upnext: true`.

**Read as:** three numbers, each of context tokens and none of turns. A task is sized to finish
under about 300k, which nothing enforces. A resume of a sub-agent past 400k, or of one that
compacted automatically, is refused once. A sub-agent that reaches about 500k is reassessed: whether
its model suits the work, whether it is stuck, whether it is looping. Work that moves to another
model starts from a new brief and never carries the old agent's context over.

**What answers the script already.** `tools/agents-to-reassess.py` prints, for a session's running
sub-agents, each one's context size and why to reassess it: at or past 500k tokens, compacted
automatically, quiet, or looping. Its `--help` says what it measures.

**What answers the resume's number already.** `.claude/hooks/resume-guard.py` refuses, once, the
resume of a sub-agent past 400k tokens of context or of one compacted automatically, and the
orchestrating skill's `references/writing-a-brief.md` holds the three numbers; no limit counts
turns.

**The item.** `reassessment-rule.md` is the rule's sentence in the orchestrating skill.

*Proposed, not asked for:* the band `now`, since the player named none.
