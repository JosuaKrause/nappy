# jolly-lynx — The game stays on Godot rather than three.js · 2026-10-18 · not from an entry


The player: "I've been thinking of maybe switching over to three.js what are the pros and cons of
that?", and after the answer, "Okay fair enough" (minty-lemur #793).

**Decided: stay on Godot.** The answer weighed, for three.js: a smaller page that loads only what it
uses, the browser as the only platform with its own tools, HTML/CSS for text and menus, and npm and
TypeScript. Against: a rewrite of about 82,000 lines of GDScript in `src/` and 90,000 in `tests/`;
three.js only renders (no scene tree, physics, collision, tilemaps, y-sorting, input or audio mixing),
and is 3D where the game is a top-down 2D sprite game (PixiJS or Phaser would fit better); the headless
test rigs, probes, cost table, scene recipes and the trailer's frame-locked movie writer are Godot's;
and months of work with no new gameplay. If load time or phone performance is the concern, measure
and shrink the Godot web export first.
