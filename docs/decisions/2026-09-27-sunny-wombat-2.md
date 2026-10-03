# sunny-wombat — The mark's big message breaks between sentences, and the HUD line stays short · built 2026-10-03

*([sandy-marten](../playtests/2026-09-27-sandy-marten.md): the break falls at a sentence end only
where the text must wrap; the rest of the entry is [sunny-wombat](2026-09-27-sunny-wombat.md),
PR #419. On 2026-10-03, in conversation, captured as inbox notes #479–#483: "so HUD line and brief
line are not the same -- the brief should properly break the lines -- the HUD should always have a
short version that gets to the point (we can somehow shorten the "somewhere out there")"; asked
which prefix, "out there:"; "when I touch the mark the message that shows in big can be the long
version it just needs to be broken properly. but the small HUD line should be the shortened
version"; "this is what the PR should be about")*

**Built (PR #469).** Two texts, two treatments.

**The big message on touching a mark is the long version, broken between sentences.**
`Hud._on_resistance_step_completed()` (`src/ui/hud.gd`) passes the mark's brief through
`SentenceLines.break_for_label()` before showing it on the `Teach` label, which is 1040px wide (its
own scene offsets) with word autowrap, so a brief too wide for one line breaks at the sentence end
that balances it and a single over-long sentence still wraps by word. Of the briefs the game ships,
only day 13's "Walk up to the roadblock. See how close they let you come." is too wide, and it
breaks after its first sentence.

**The bottom-left HUD task line is one short line that never wraps.** It reads "out there: " and
the step's short `header` (M132's instruction clause), or a pickup's title, in both the ordinary
and the debug line; the label has no width limit and no wrap. `tests/test_hud.gd` measures every
step's line at the label's font and size and holds it within 280px, the width of the meters above
it; the widest is "out there: your neighbor, on the way home" at 249px. The prefix was "somewhere
out there: ", which put three lines over 300px.

**What this replaces.** The PR first wrapped the HUD task line at 280px through `SentenceLines`,
from the filer's "Proposed, not asked for: the task line is included at all". The player had never
asked for it, and measured against the real task lines it wrapped three of them mid-phrase; it was
removed before merging.

**Open to overturn:** the `Teach` label's 1040px width is its scene offsets.

**Verified.** `tests/test_hud.gd` checks every real mark brief only gains breaks at sentence ends,
a synthetic long two-sentence brief breaks after its first sentence, and every task line fits one
line. No picture: no dev flag reaches a touched mark.
