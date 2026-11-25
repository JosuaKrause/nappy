# gray-raven — The escape winnability probe and the docs: the walker is weaker, the escape is unchanged · 2026-11-17

**What it is.** The entry gray-raven (filed `bug` while read as a bug, inbox #1519 in breezy-magpie):
`tests/probes/escape_winnable.gd` walked out of the escape on about half its walks, while the docs
said "a plain walk gets out on 95 of 96".

**What was found: no game bug.** The "95 of 96" was measured on 2026-10-19 (the record
downy-tapir-2) by a stand-in walker inside the probe that walked a shortest path past the standing
bodies and played the lure at each roadblock: stood, ran back from the charge, waited for the guard
to leave, walked on. Today's probe walks with `RouteRig`, which does not play the lure. Over twelve
walks on main (seeds 4242, 1, 77, 9001, 23 and 5, to both exits) six got out and six were lost, and
the run log of each loss names a roadblock guard's charge after his warning with her inside his
radius, and nothing else. The bag is unchanged since then but for its empty marbles (one then, nine
since step 5). So the walker got weaker, not the escape harder. Today's walker cannot run on the old
commit (the rig was not on the escape's boot then), so the evidence is the losses' cause and the two
walkers' own texts.

**What was built.** `docs/EVENTS.md`'s escape section says how the walk is filled today (the
section's own bag, three rows a day uses and the escape's own explosion row, the building's rows
placed by its plan) and that `RouteRig` is a plain walker that loses the walks into a posted band.

**Set aside, and what would make it worth doing:** a probe walker that plays the lure over the whole
walk, so the probe's number means "a player gets out" again (the 2026-10-19 stand-in did this; the
finale rig plays the lure only on roadblock streets). Worth it if the player wants a winnability
number for lilac-marten's retune of the escape.
