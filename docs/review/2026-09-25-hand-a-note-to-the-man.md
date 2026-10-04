**Hand a note to the man shouting on day 6 or later** (a run with the earlier tasks done, not
`--invincible`, since the subject is a cost). A robber comes at her from off screen, announced by
the screen-edge badge first. **Does he read as the price of the errand rather than bad luck, is
the badge warning enough to run, and does a 2s warning with a 6s chase read as pursuit?** Walking
away he catches her in about 7.5s; standing still, in about 2s. Then **hand the van's package over
on day 7**: a guard comes at her the same way. **Does he read the same way the robber does, or does
the different picture and loss line change the answer?**

On a street where he starts to her side rather than above or below her — about a fifth to a
quarter of handovers, depending on the row (`tests/probes/m137_trap_arrival.gd`) — walking directly
away from the handover outlasts him. **Does that read as a fair escape, or as the badge lying about
what she can outwalk?**

Since M205, the man she just left keeps shouting — and charging her — for 2.5s after the handover,
longer than the robber's own 2.0s notice, so both are live at once: standing still, the robber
catches her (about 2.2s) before the man would have stopped shouting on his own. **Does the robber
closing in while the man is still shouting at her read as one cost or as two things landing on top
of each other, more than a walker should have to answer at once?**

**To watch the man's own part rather than the cost, play day 6 with `--invincible`** (checked
against `src/dev/dev_flags.gd`'s `invincible()`: nothing ends the day —
`DayController._ignores_loss()` reads the flag — and the day clock and the excitement meter both
hold still, so the robber's own catch cannot cut the observation short). Hand the note over and
keep watching: for the 2.5s he still shouts, the robber is also closing in behind his own badge.
**Can you tell the note has already been taken before he goes quiet and walks off, or does the
robber's badge and approach crowd out that read?** When he does go quiet and walk away (the
robber now visible, or
already caught up with her): **does it still read as "he took it," with nothing written
anywhere?** Watching him leave: **does his straight line ever take him through a building or
across a road in a way that looks wrong?**

Record is `docs/decisions/2026-09-13-M137.md`, the trap comes to her.
