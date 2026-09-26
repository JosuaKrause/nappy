## M137 — The contact is whoever she hands the note to, and the trap comes to her · asked for 2026-09-13

> "not the first yeller she reaches but the first yeller she interacts with. so the task is
> always solved by going to any yeller she notices. maybe spawn the robber in pursuing mode
> offscreen when she interacts with the yeller so it runs towards her from offscreen."

[PLAYTEST-71](../../playtests/PLAYTEST-71.md). The **events** rule governs the robber's spawn; the
telegraph contract it names is the constraint on *off screen*.

**What is true today.** `ResistanceDirector._track_first_reached` re-points the perform step's
contact every frame onto the nearest live look-alike she is within reach of, so a yeller she
walks past and leaves is not kept; whichever one she then touches completes the step
(`DECISIONS.md`, M132). The trap is a separate rule: `_maybe_set_a_trap` stands an
`alley_robbery` at dawn inside a band around the position the day seeded, waiting, and it wakes
when she comes within its `pursues_within`; a contact she hands over anywhere else is unguarded.
*The trap guards the seeded yeller only · overturned on 2026-09-13.*
