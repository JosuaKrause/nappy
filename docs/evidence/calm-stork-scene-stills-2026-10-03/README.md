# Scene composition and action evidence

Ten requested stills, their capture manifests (`*-capture.json`), and their complete headless
action manifests (`*.json`) are retained here. Generic logs, incidental screenshots and
duplicate takes are omitted. The manifests identify the recipe hash, construction context,
engine, physics rate, initial state and observations; capture manifests identify the exact
frozen tick and actors. A capture ends at its selected moment, so its `playback_complete` is
false; the separate headless manifest proves that the complete scripted action passes.

| Stills | Source revision | What the still establishes |
|---|---|---|
| `power-station-hall`, `power-station-yard` | `8941448c` | Real adjoining dead-end walls: the hall covers the facade, the fenced yard keeps it. |
| `trailer-choice` | `052fb4c1` | A populated alternate street after the mother's wrong-way approach and backtrack; selected restaurant guests are one block east. |
| `trailer-blower` | `177191c8` | The father and selected leaf blower beside an industrial facade with manually placed existing duct, HVAC and vent fixtures. |
| `trailer-dog`, `trailer-title`, `trailer-gatehouse` | `052fb4c1` | Charging dog beside a skylight roof, park-side title, and father approaching horizontally toward the existing vertical gate. |
| `trailer-trucks` | `b148986e` | Three army trucks beside the south-facing mother with varied posters on both buildings; barrier revision pending. |
| `trailer-chase` | `052fb4c1` | A visible carrying stride beside a pursuing guard. |
| `trailer-city` | `052fb4c1` | The complete active city after zooming out from the mother's doorstep. |

Sources are reachable through PR #457. Godot 4.7.2 stable, macOS Apple M2, Compatibility OpenGL,
1280×720, 30 Hz physics. Reproduce at the listed source with
`tools/scene-recipes.sh --recipe scene-recipes/NAME.json --screenshots --output /tmp/new-scene`.
The command uses `--player-view`, `--no-save`, scripted playback and the saved `capture_at`.
Fetch `refs/pull/457/head` when a source revision is absent locally. No video is made.

The blower preview selects its event explicitly, with no normal scheduler or additional seals.
Its full ordinary crowd records 32 visible walkers (24 left, 8 right), four visible cars and
the single selected leaf blower at capture tick 15. The source checkout has only unrelated
queue/playtest documentation edits during capture; runtime and recipe sources match the named
revision. The capture uses no invincibility. The industrial roof and north-side approach are
composition choices for review.

The revised scenes use production crowd counts and only explicitly selected events and structures.
The normal event scheduler and seal selection do not add unrequested objects.
The truck formation is the actual day-13 happening; its spacing is not a trio of lookalikes.
The gate is a real region checkpoint. The choice scene's leaf blower is a composition choice;
the requested action is the turnaround and other route. The manifests check all three phases.

At capture tick 42 the chase records speed 168, carrying, contact gait frame 2 and an active
pursuing guard; the same-tick observations match. The production carrying animation uses the
same three pictures for walking and running, with faster cadence at running speed. This still
shows the clearest existing contact pose, not newly drawn running art. Stills establish
composition; action observations and displacement checks establish movement.

The wide city capture reports 2,048 visible walkers and 344 visible cars. The population
test checks moving walkers and cars in every quadrant. This recipe explicitly
populates the whole view at the ordinary field's area density; ordinary game density is
unchanged. Its population test checks actual displacement in every quadrant. Close-scene
`capture_activity` counts instead cover actors whose ground positions are in that picture;
visual review checks occlusion separately.
