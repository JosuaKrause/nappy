priority: later
after: 2026-10-18-minty-quail

# tawny-marmot — The doubled red NOW mark measures from the field's core, not from the catch · filed 2026-11-23

**What is wrong.** `WarningBoard.warn_about_the_ground_she_is_on()` (`src/events/simulation/warning_board.gd`) raises the red `NOW` mark over her head when a moving lethal thing closes on her. It measures `gap` as the distance to the event minus `instance.core_within()`, the radius of the event's core, and raises `NOW` when `gap <= closing * LETHAL_MARK_LEAD`. For the hunting roadblock the guard catches her at 28px but its core is 86px, and for the stairwell's masked man the catch is 23.5px against a core of 28px. So the mark is measured from a circle that is not where the catch happens, and the mark can come earlier (or, where the core is smaller than the catch, later) than the moment the strike is meant to be warned of. It is a cue: it changes what she is shown, so **cues** governs the fix. A filing from a review, not from the player's words; the band, `later`, is the filer's proposal.

**Found by** the design of pull request 1692 (`.claude/briefs/designs/minty-quail-blocking-reach.md`, untracked in the orchestrator's checkout).

**What a builder does.** Decide, per event, which distance the mark is the warning of (the catch the thing strikes at, not the core), measure `gap` from that, and say in the entry's record what each row's catch and core are. Where the answer is a method on `EventInstance` or `EventDef`, `warn_about_the_ground_she_is_on()` asks it and reads no field.

**Shown fixed.** A suite puts her at the roadblock guard's catch distance plus the closing lead and sees `NOW` raised there and not at 86px, and the same for the stairwell's masked man; the visual cue vocabulary in `docs/` and **cues** stay true.
