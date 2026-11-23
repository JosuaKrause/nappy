priority: later

# gray-elk — EventOfficer's trail and vehicle and EventPursuit's outrun_for are public and read only in their own files · filed 2026-11-23

No player's words name this finding; it is the filer's, and the band `later` is the filer's proposal, not asked for.

**Found** by the review of pull request #1656 (minty-quail row 5, the live event's behaviours).

**What holds today.** `EventOfficer.trail` (the points a man walks back along to his vehicle) and `EventOfficer.vehicle` (the vehicle that let him out) in `src/events/behaviours/event_officer.gd`, and `EventPursuit.outrun_for` (how long she has been running from a pursuer) in `src/events/behaviours/event_pursuit.gd`, are public vars that no other file reads: `rg -n "\.trail\b|\.vehicle\b|outrun_for" src tests tools --glob '*.gd'` finds the three only in their own files, the other hits being `Mover.vehicle()`, the telemetry observer's own `trail()`, and the string key `"outrun_for"` of the save state a suite writes. `tools/test_only_members.txt` does not list them, since no test reads them either, so no check holds them. `designing-classes` says a field is not API.

**What the fix must hold.** The three become underscore-private (`_trail`, `_vehicle`, `_outrun_for`), each file's own reads and its save and restore keeping the save's key names, and the same `rg` as above finds no read from outside the two files. The save state's keys do not change, so a saved event restores as before.

**Proposed, not asked for:** the band `later`, and the names with an underscore.
