# Playtest 26 — 2026-09-05

## Graphics throughout

> "the graphics of this game are currently placeholders only (among even some graphical bugs and glitches) -- make the game look good throughout"

The request covers the whole presentation: city surfaces and architecture, scenery, the mother
and pram, crowds, events, and interface screens. Existing visual defects are part of the work.
The alley floor, roofless slivers, floating home door and tunnel mouth are also recorded in
[PLAYTEST-24.md](PLAYTEST-24.md); the fence and junction paint are recorded under M49.

## The first approach is rejected

> "are you kidding me? your thought of improving graphics is to make the outlines of existing assets thicker? I'm talking about a full overhaul of the graphics as if nothing had existed before. also, one major thing you apparently missed is that we currently have *no animations*"

> "rethink graphics from ground up!"

> "by rethinking I mean *everything* including the title screen etc etc"

## Depth and occlusion

> "for roofs you could even go a half or so tile into the tile above to give a sense of depth"

> "or even better for roofs that need to go in the space above make things behind them show up but transparent (or better even use a dotted transparency -- every other pixel or so fully transparent)"

> "it shouldn't look like it's actually transparent so a more stylistic approach would work here"

## Rendering pipeline and implementation

> "maybe experiment with 3d models and an orthogonal projection? I leave that judgement to you. if you need extra tools, like blender. let me know"

> "and use luna agents for the actual work (like how it should be written in your instructions)"

## Showing what is happening

> "also think about how we could visually indicate which entity is currently responsible for the increase in excitement in a subtle way"

> "check if main has updated as well. another idea maybe the city can visibly deterioate towards the end garbage starts accumulating. loose papers etc flying around in the street. maybe sidewalk tiles having some cracks every now and then (from the armored trucks maybe?). also rethink how graphics are handled. maybe some graphics could benefit from being pngs or so instead of svg or some other format altogether"

> "also maybe you find a better solution to indicating the current objective other than using protesters to point in the direction or maybe scavenger hunt chalk marks on regular paths? also feel free to challenge prior design guidelines"

## Godot launch failure

> "you crashed godot"

The attached macOS crash report identifies Godot 4.7.2, process 24261, incident
648CB20E-8F7A-4114-9006-17AE894731AB, at 17:18:19 on 2026-09-05. It reports SIGABRT during
application registration. The diagnostic is separate from a GDScript error or an art verdict.
