*Proposed, not asked for:* the player asked for three stages on chargers, and the masked man is not
one; the audit found his drawing inverted, and this item is that defect alone.

**The masked man on the escape's stairs is drawn standing while he waits, not lunging.** The audit
found his stages inverted: `_draw_masked_pursuer()` draws `GUARD_LUNGING_BY_VIEW` whenever
`_stands_still_now()` is false, which it is while he waits, so the waiting man reads as charging and
he is drawn standing only after he notices her. He runs a fixed line up the shaft rather than at
her, so he is outside the three-stage rule as the audit reads it; the item
is the inversion alone.
