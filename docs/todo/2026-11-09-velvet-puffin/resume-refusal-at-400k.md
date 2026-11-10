# A resume is refused once at 400k tokens, and nothing counts turns

**The ask.** "what about 400k? note, this is different than the 500k rule for reassessing agents --
this should kick in earlier since it's about resuming agents, no?", "yes, 400k as mr budget said",
"no turn count", "no turn counters is fine I think -- context is a better measure", and, of the
table that put the resume refusal at 400k, the reassessment at 500k and a sizing target at 300k
with no turn counters anywhere, "it comes from mr budget but I fully agree" (merry-badger #1298).

**What to build.** The hook that refuses, once, the resume of a sub-agent that has outgrown the
limit (`.claude/hooks/resume-guard.py`) refuses on the context alone: a sub-agent past 400k tokens,
or one that compacted automatically. Its refusal asks one question: a follow-up on the agent's own
pull request (a delta review, review or CI fixes, a merge of `main`, a stop or wrap-up) is sent
again and goes through, and new work goes to a fresh agent from a brief. The orchestrating skill's
`references/writing-a-brief.md` gives about 300k tokens as the size a task is scoped to finish
under, which nothing enforces, and 400k as the point of the refusal; neither it, the hook, nor
`tools/agents-to-reassess.py` counts turns as a limit. The reassessment at 500k
(`reassessment-rule.md`) applies on top.

**This item is being built** in the pull request that adds the hook: a design by Fable, the code by
another model, the review Fable's, as the player said of it: "okay, fable can design and review"
(merry-badger #1298).

*Proposed, not asked for:* the refusal's two kinds of follow-up and what counts as each, which are
the usage-review session's recommendation that the player's "yes, 400k as mr budget said" accepted
as a whole; a turn count shown for information, as a sign an agent is stuck, in the script's
output.
