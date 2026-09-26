## M132 — The resistance speaks loud enough to be heard · built 2026-09-13

*(2026-09-13, [PLAYTEST-69](../playtests/PLAYTEST-69.md): "the day text needs to be bigger to be
able to be noticed and it should show also when dying so if missed on the first try it can be
seen on the second try. the in game note should contain the same amount of info on what to do.
… so if the solution is the yeller it's always the first yeller you come close enough to hand
the note.")* Three agent commits on `feature/m132-resistance-speaks`, reviewed on the PR. The
standing rule that the *first* encounter carries no hint is untouched; everything here is what
the resistance says after a mark has been touched.

**Why the brief never showed at all on the reported run.** The summary appended the queued brief
inside a block gated on `GameState.has_joined_resistance()`, which is `resistance_progress > 0`
— and a pickup grants no progress. So the day-4 mark's own words were invisible on the summary
of the day they were found, lost *or* won, until a perform step later raised progress. The entry
had read this as a won-branch-only defect; it was a gate on the wrong counter.

**The brief is its own label.** `DaySummary` draws it as a separate 26pt line in
`Palette.CHALK_DONE`, the colour the touched mark itself turns, shown and cleared in `show_day()`
on every `DayResult` and independent of the tally, which keeps its own progress gate. The ending
and the finale hide it. Pinned by `tests/test_day_loop.gd`: a brief queued at progress 0 is
shown by a lost summary and cleared only then.

**The header names the instruction.** `Step.header` on the five perform steps carries the
pickup's own brief cut to its instruction clause — *the one who won't stop shouting*, *a van,
waiting*, *the one you go through, not around*, *before they paste over it*, *where they're
standing* — and the HUD's `somewhere out there:` line reads it; `Step.title` stays for the
progress dots. Pinned by `tests/test_hud.gd` for all five.

**The contact is the first look-alike she reaches.** *Asked for a hidden contact among
look-alikes · overturned on 2026-09-13.* `ResistanceDirector` re-points its rider every frame
onto whichever live instance sharing the step's `task_event_id` she first comes within reach of
(the seeded rider included), placing the touch point on the side facing her. Re-pointing was
chosen over placing the seeded contact nearest her route because the deadline reads the clock
and the trap reads the seeded position, so neither rule's code changes. The rule is generic
over the row id, so the van, the roadblock, the poster crew and the protest all get it; the
finale rides on nothing and is outside it. `docs/NARRATIVE.md`'s *a wrong candidate costs full
price* sentence is replaced.

**Open to overturn.** The trap still stands near the *seeded* rider only, so a look-alike she
reaches before it is never guarded; the agent read that as the point — there is no wrong
candidate left to guard against — rather than as a gap. If the guard is meant to travel with
the contact, it is one item. No capture was taken: no dev flag fast-forwards resistance
progress, so a rig cannot stand on a perform step; the played questions are in `REVIEW.md`.
