priority: next

# round-ferret — Build exact test and trailer scenes from saved recipes · filed 2026-10-02

The player asks for a scene builder using the standard city building components that can
guarantee requested outcomes, both for edge-case tests without searching seeds and for
trailer scenes that look as intended. They choose **saved recipes first** when offered
recipes, a visual editor, or both. [gray-otter, scene-builder request](../../playtests/2026-10-02-gray-otter.md)
records the complete request and the authoring question.

The player's concrete edge case is a building connecting to the power plant, where the
join needs special handling to avoid blank tiles. [minty-wombat, valid component joins](../../playtests/2026-10-02-minty-wombat.md)
records their clarification that edge cases need not include invalid states. Reproducing
unusual valid combinations of standard components is the test use to build first.

The player also accepts invalid-state fixtures if they cannot accidentally produce an
invalid scene, while emphasizing "I want to be able to make sure something could actually
appear". [frosty-finch, possible gameplay and explicit fixtures](../../playtests/2026-10-02-frosty-finch.md)
records this qualification. A normal recipe must establish that its arrangement is
possible under actual game generation and placement rules. A deliberately invalid test
fixture is explicitly distinguished from that guarantee.

[M203, roofs covering adjoining facades](../../decisions/2026-09-26-M203-a-front-nobody-can-stand-at-is-covered-by-the-roof-in-front-of-it.md)
records the relevant power-station hall/yard distinction: "a front column draws no facade
only where a roof extension actually covers it." The builder must make these joins
directly authorable so the renderer's special cases can be exercised without seed hunting.

**Proposed, not asked for:** the `next` band, a versioned JSON recipe format, the staged
construction and verification contracts in this folder, and the additional example scenes are
the filer's proposals. The player specifies the two uses and the recipe-first authoring
surface and power-plant join example; they do not specify a file format, a constraint
language, or the trailer example shots.
The alternative is a set of bespoke test scripts and trailer flags for each setup. A shared
recipe is proposed because a reproduced bug and a recorded shot need the same scene setup.

The generator builds a `CityMap` as data before `City.build()` creates its visible world.
`CityGenerator.generate()` tries adjacent seeds when its validation fails. `DevRig`'s spawn
targets locate something in an already generated city; they do not require that it exists.
These are integration points and limitations of the current tools, not an agreement that
the new builder should search seeds or accept a substitute for a required object.

[M204, the trailer cut](../2026-09-25-M204/README.md) remains the place for editing the
trailer. Its [recording-tools decision](../../decisions/2026-09-26-M204-and-M214-the-trailer-and-its-recording-tools.md)
records the existing frame-locked movie writer and repeated-render checks. The player's
earlier request is "the trailer will be a set of paths in pre determined seeds with fixed
events so we can reproduce it easily". Recipes supply the missing control of that setup;
they preserve the recording path and the requirement to show real gameplay. Completing
the builder does not complete the trailer's cut, captions, or visual approval.

The implementation items are [recipe construction](recipe-construction.md),
[runtime setup and replay](runtime-and-replay.md), and [examples and verification](examples-and-verification.md).
They form one feature: a saved recipe must run through the actual city, be usable in a
headless test, and be recordable by the existing tools before this entry is complete.
