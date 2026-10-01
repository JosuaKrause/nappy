# Playtest cozy-walrus — Exclude tests from the downloaded game

2026-09-30.

## Context and requested inspection

While investigating faster loading and lazy scenery preparation, the player asks:

> for the loading investigation a start would be to inspect how big the package is that is getting downloaded

The assistant reads the deployed v0.21.2 responses and reports 13.71 MB transferred with gzip
across the engine, game package and loader. It reports 1.60 MB of test payloads inside the
decoded game package, about 45% of that package, and proposes excluding tests with the exact
compressed saving verified against a rebuilt export.

> test file exclusion would be an easy win

The assistant will exclude tests, verify the exported game starts, measure the resulting size,
and add a package audit that rejects test resources. The audit is the assistant's proposed
regression guard rather than a mechanism specified by the player.

## Engine modularity

> is the engine modularized? can we exclude unused content?

The assistant confirms that Godot supports custom export templates with unused modules and
classes compiled out. It identifies 3D as a candidate, with other modules requiring an audit,
and says the compressed engine saving needs measurement. The package-exclusion work does not
change the engine template.

## Permission

During the same investigation the player explicitly authorizes branch work:

> you can commit and push and create prs
