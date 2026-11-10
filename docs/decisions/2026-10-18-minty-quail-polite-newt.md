# minty-quail — A probe prints what every row's look draws (minty-quail, the events' interface) · 2026-11-10

**The ask.** The events' interface design's step "the looks ask the live event and are handed
their settings" (`docs/todo/2026-10-18-minty-quail/event-interface.md`, row 2b) is a refactor at
parity. Its parity rests on the run log line for line and two identity probes (what every source
charges her, and every event, crowd agent and meter on every tick), and neither sees a picture: a
look that draws a different frame passes both. The planning agent that cut row 2b into six pull
requests added this probe as the first of them, so the five conversions can show they draw what
they drew; the orchestrator kept it. Proposed, not asked for, open to the player's overturn.

## What was built

`tests/probes/look_fingerprint.gd`: every catalogue row is stood on open ground and on an
east-west street with a recording drawer, a shared `WhereSheIs` told once a tick and the pictures'
atlas, and stepped 540 ticks at 30 a second under the drives that reach its look (she stays away;
she walks up, stands beside it and walks on; she walks away and the row leaves; and six hand-in
states: a crossing pelican, a silenced mast, a boom raised then lowered, a guard's raised hand, a
chat begun, a protest handed a moving point), a moving row given a route east so its gait is
drawn. It prints a `LK` line per drawn picture (what it is drawn on, its rect, colour and band,
every float as the hex of its 64-bit value) and, when they change, the look's answers and where
each drawing node stands; `LK_SEEN` names the look classes met (all ten) and `LK_COST` what its
redraws cost. Two runs hash the same.

## What it sees, and what it does not

Each of the planner's six seeded mistakes changes the hash (two pictures of one case swapped, a
look's gait answering false, a spread's slice count off by one, a posted guard's side flipped, a
look hidden by its hold, a term out of the picture's key). Five more did not: swapping the
charging dog's resting and alert pictures, and taking the waiting, chatting, stopped-her or leaving
term alone out of the picture's key, since no drive shows the dog's two pictures and each of those
terms changes at the same sample as another. A pull request that touches one of them adds the drive
that reaches it. What a look draws straight on the canvas (a ground shadow, a dog's lead, a muzzle
flash) no headless probe sees; those builders list such lines for the reviewer.
