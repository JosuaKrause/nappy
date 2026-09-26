## M66 — The dusk map shows what the player did · built 2026-09-02

*(2026-09-02: "the dusk picture should contain the entire route a player took", and "prioritize the
telemetry update to show what the player actually did during the play on the second day picture —
where they went, which events they activated, where they ran.")*

**The plan with what happened to it drawn over the top**, which is the shape the dusk map already
had for the resistance marks. Three layers: the trail she left, the stretches she ran, and which
planned events actually reached her.

**Sampled by distance, not by frame**, so the trail is bounded and framerate-independent — a
180-second day is a few hundred points at one per tile, and a rig at 400fps and a player at 60
produce the same picture. It is a list in memory handed to the renderer at dusk; nothing is written
per sample and the log's format does not change.

**Met means she entered the event's own `outer_radius`**, the field she can feel — not that
`EventManager.stream_around` had loaded the row into the world at 900px, which is more than twice a
typical row's reach. *"Was near it" and "it reached her" are different days*, and only the narrow
question says whether a placement did anything. Kept keyed by the plan object itself so the map can
ask about the same list it is already drawing, and once met stays met: streaming a row out and back
does not un-meet it.

**The rig had to be fixed before the feature could be photographed.** `--walk` held one direction
for the whole run, so every dusk map was a speck at the first building on that heading. *(2026-09-02:
"why not allow for a sequence of button presses? like 1s5e meaning 1 second south then press 5
seconds east — that way you get a guaranteed path that is not stuck.")* `--walk` now takes a script
of timed presses, pressing the same `move_*` actions a keyboard does, backwards compatible with the
bare direction words. **Deterministic is the point**: the same script on the same seed walks the
same route, so a picture of it is reproducible evidence rather than one run that happened to go
somewhere.

**One map was diagnosed as a renderer defect and was not.** Pixel-diffing dawn against dusk showed
the trail drawn correctly, hugging the bottom tile row where nothing at a glance would find it. The
wrong diagnosis was the orchestrator's; recorded so the next reader does not go looking for a bug
that was never there.

**The committed evidence carries no met pip**, and that is stated rather than re-run for a
flattering picture: the only row that reached her was sited by the director ahead of her and has no
dawn position to draw. The pip is proven by the suite instead.
