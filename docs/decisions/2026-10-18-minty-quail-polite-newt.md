# minty-quail — A probe prints what every row's look draws (minty-quail, the events' interface) · 2026-11-10

**The ask.** The events' interface design's step "the looks ask the live event and are handed
their settings" (`docs/todo/2026-10-18-minty-quail/event-interface.md`, row 2b) is a refactor at
parity. Its parity rests on the run log line for line and two identity probes (what every source
charges her, and every event, crowd agent and meter on every tick), and neither sees a picture: a
look that draws a different frame passes both. The planning agent that cut row 2b into six pull
requests added this probe as the first of them, so the five conversions can show they draw what
they drew; the orchestrator kept it. Proposed, not asked for, open to the player's overturn.

## What was built

`tests/probes/look_fingerprint.gd`: every catalogue row, each row's full-heat copy
(`EventCatalogue.heated()`) and last-day copy (`for_day()`) where either differs from the row, and
the rows the game stands from them (the policeman a patrol car lets out through day 8 and the
guardsman of the last day, each as a stop and as a hunt, the burning building, the guard a task
sends) are stood on open ground and on an east-west street with a recording drawer, a shared
`WhereSheIs` told once a tick and the pictures' atlas, and stepped 540 ticks at 30 a second under
the drives that reach each look (she stays away; she walks up, stands beside it and walks on; she
walks away and the row leaves; and six hand-in states: a crossing pelican, a silenced mast, a boom
raised then lowered, a guard's raised hand, a chat begun, a protest handed a moving point), a
moving row given a route east so its gait is drawn. It prints a `LK` line per drawn picture (what
it is drawn on, its rect, colour and band, every float as the hex of its 64-bit value) and, when
they change, the look's answers and where each drawing node stands, leaving out the roadblock's far
guard's place, which his node sets on the engine's physics tick (his drawn pictures stay in);
`LK_SEEN` names the look classes met (all ten) and `LK_COST` what its redraws cost, timed on events
of its own after the fingerprint, so the cost pass adds no `LK` line. Two runs hash the same.

## What it sees, and what it does not

Each seeded mistake changes the hash: two pictures of one case swapped, a look's gait answering
false, a spread's slice count off by one, a posted guard's side flipped, a look hidden by its hold,
a term out of the picture's key where it changes alone, the charging dog's resting and alert
pictures swapped (the dog of the last day, a row the first version did not stand), the far guard's
heading flipped, the chaser's drawing removed, the policeman's alert and waiting pictures swapped. Unseen: a term of the picture's key taken out alone
when it changes at the same sample as another (waiting, chatting, leaving), and the stopped-her term,
true only for the man a vehicle lets out whose catch is a stop; no sample separates them, so the
reviewer of a pull request that touches the key reads those lines. What a look draws straight on the
canvas (a ground shadow, a dog's lead, a muzzle flash) no headless probe sees; those builders list
such lines for the reviewer. Nor are the protest's and the leaf blower's second stride frames drawn
(`PROTESTER_BY_VIEW_B`, `LEAF_BLOWER_BY_VIEW_B`): only a row sent off down a chosen way
(`leave_along()`) would draw them, and no drive sends one.
