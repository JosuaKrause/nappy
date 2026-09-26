## M129 — Regular spent parks are spoiled; one late park is fenced · corrected 2026-09-26

PLAYTEST-140 statements 8–9 clarify the original request: a used park is spoiled with events,
its ground stays walkable, and the router avoids it; a fence is allowed for one park once, later
in the game. The earlier all-parks-closed implementation recorded below was superseded on this
PR before the graphics repair. The branch selects at most one physical fence from accepted used
areas in act III or later and persists that choice; the swing is protected on its own day.
The PR description now states that distinction rather than the superseded all-parks mechanism.
