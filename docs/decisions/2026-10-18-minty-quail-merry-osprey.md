# minty-quail — The live event's phase goes private (tests-own-class-members) · 2026-11-23

**What was asked.** `tests-own-class-members.md`: a member only its own class and the tests use becomes internal, its
tests checking what the class does from outside (curly-rabbit #1098); `event-interface.md` section 4.2 kept the live
event's `phase` public until its suites observed a phase another way. Built as #1668 by a Sonnet agent from an Opus
design.

**What was built.** Every read of the phase outside the live event's file asks its phase questions (whether it is
telegraphing, waiting, on its way out, gone, only its barrier), each first compared with the stored phase on every
frame. Whether it has charged is not the same as being past its warning (it is true while a held lunge still warns,
and for a restored masked man), so the day 13 hold and the masked man's cases ask "its warning has run, it is not
waiting, not leaving, not gone" through a helper each; the robber's charge keeps "has charged and is not telegraphing",
which agreed on every frame. `transition()` stays public for the suites that still call it.

**Measured.** Check counts unchanged; each rewritten check was shown failing with its rule broken. The two probes that
print a phase word print it from the questions, so their hash chains changed once.
