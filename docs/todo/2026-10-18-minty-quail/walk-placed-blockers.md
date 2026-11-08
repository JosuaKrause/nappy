# Day 13's task always finds a roadblock to swap

**The ask.** Day 13's task rides a roadblock the day placed near the chalk mark, or swaps one in,
out of her sight, in place of an event the day placed there; asked what happens when nothing can be
swapped, "it can always swap -- we already discussed this", and no fallback (inbox #1185 in
gray-dolphin).

**Read as:** the task never goes without a roadblock and none is ever added mid-walk, so the swap
must always find a candidate. On 480 real chalk marks (20 cities, 24 each) the swap as built finds
nothing at 33 (6.9%, on 11 cities): at 25 no event within 1,024px of her paths stands where a swap
is allowed, and at 8 a roadblock's own placement rules refuse the candidate (a held street, the
calm ground she has not used yet, a region door's clearance). Record minty-quail-crisp-koala has
the measure; `tests/probes/minty_quail_day13_real_marks.gd` reruns it and names each miss's reason.

**Build:** widen the swap's search until every mark finds a candidate: past 1,024px along her
paths, and to the events on streets a route runs along where the event is out of her view, keeping
every rule a roadblock is placed under (never the main road, the region wall's bodies, a door or a
scar). The probe's misses go to zero on the same 480 marks, and the pull request says the
distances the widened swap gives.
