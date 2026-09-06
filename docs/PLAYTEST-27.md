# Playtest 27 — 2026-09-05

## Graphics throughout

> "the graphics of this game are currently placeholders only (among even some graphical bugs and glitches) -- make the game look good throughout"

The request covers the whole presentation: city surfaces and architecture, scenery, the mother
and pram, crowds, events, and interface screens. Existing visual defects are part of the work.
The alley floor, roofless slivers, floating home door and tunnel mouth are also recorded in
[PLAYTEST-24.md](PLAYTEST-24.md); the fence and junction paint are recorded under M49.

## Cardinal apartment-street review — 2026-09-06

> "looks good continue"

This approves the representative cardinal apartment-street direction: illustrated PNG ground,
continuous apartment frontage, roof depth and stable dotted occlusion. It does not approve the
whole renderer or replace the required movement, event, city, deterioration and screen work.

## Generated concept reference — 2026-09-06

> "btw [Image #1] how does this image play into all of this? this reference was never approved. if
> it is just a stale reference we can keep it for posterity if it is actively being used over the
> real references I provided then let's remove it and remove all references to it"

> "same applies to the graphics-studies -- we don't base our designs on those they were dead ends"

The generated concept was an active material, depth and deterioration reference in the redesign
brief, so it is removed. The supplied urban, cardinal-layout and mother images remain the visual
references; no generated concept image substitutes for them. The graphics studies are retained
only as rejected historical evidence and do not define the visual target.

> "[Image #1] and [Image #2] are the proper references to use"

`evidence/graphics-reference-mother.jpeg` and `evidence/graphics-reference-urban-01.jpeg` are the
authoritative mother/pram and illustrated urban references, respectively.

> "[Image #1] is also another reference to use"

`evidence/graphics-reference-urban-02.jpeg` is an additional authoritative illustrated urban
reference, including vehicles, street furniture, storefront density and pedestrian variety.

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

## Reviewing the architecture — 2026-09-06

> "can I review the proposed graphics to give feedback? in the godot runs you do I see single family houses even though we are in a city where apartment buildings would be more appropriate"

## Illustrated city references, camera and gait — 2026-09-06

> "it needs a lot of polishing still. let's rotate the view a little bit back to more sideways like it was before. we can cheat a bit for eg  multi-storey apartment blocks by cutting the north end short so you can draw their front with a fitting height without blocking the next street fully. the scene needs to look \"right enough\" for gameplay but doesn't have to be realistic. that means standalone viewed in a 3d modeling tool the models don't need to look correct. they only need to look fitting during gameplay (some games use warped/tilted models that look correct only from one single perspective for this purpose). one gripe I have with the video is that the leg movement happens independently from the movement on the ground so it looks like the objects are floating and just coincidentally moving their legs, too. but they don't use their leg movement for walking. the leg movement doesn't match their gait / walk. for 3d a rectangle and a circle for a person doesn't cut it any more. things need to be more detailed. the direction of 3d was to make things *easier* to model. if it's easier to just create more 2d drawings then let's go that route instead. make sure to regularly commit and push so we don't lose progress especially if we decide to go in different directions. [Image #1] here is the look I'm going for. whether to shift into a tilted grid as well is also an interesting avenue to explore. note this is a concept art the extra items on the bottom are not needed. the map is something we can think about later. same with faces of mother and child. hmm, the diagonal way could work with fully tall buildings with the transparency trick I was talking about earlier. or the building in the front of the scene could just disappear when walking in a way where the player would otherwise be occluded giving a clean street look. [Image #2] some more references. your call to decide whether to do 3d models or 2d graphics."

The supplied references are preserved as `evidence/graphics-reference-urban-01.jpeg` and
`evidence/graphics-reference-urban-02.jpeg`, respectively. They are user-supplied concept art,
not screenshots of the game or approval of their depicted extra controls.

> "make sure to commit and push everything *especially* before changing direction"

> "I'm warming up to the diagonal grid let's make that work"

> "also make sure to commit the reference images as well"

> "[Image #1] a draft closer to what we already have. [Image #2] a few variations. note this is intentionally closer to what we already have. the above direction is still what we're aiming for"

Both attachments for that message resolve to the same supplied file, preserved once as
`evidence/graphics-reference-cardinal.jpeg`.

> "all rejected ideas should stay in the same graphics overhaul branch so we can find them inside the branch instead of having dead unmerged branches. the svg overhaul we can make as separate PR and probably merge as is since it's just a tweak and it does look good compared to what we have right now."

> "let's not go diagonal for now but try to match the diagonal artworks style"

> "there should be no dangling branches"

> "on latest main there is some investigation on what it would take to go diagonal please have a look and add your own thoughts -- but for now we don't want to do it yet"

> "[Image #1] also make the woman with the stroller look like in this reference image"

That reference is preserved as `evidence/graphics-reference-mother.jpeg`.

> "main has updated again. maybe create 8 directional sprite sheets for all assets even if some direction is not currently used. that way we eliminate a lot of bugs. don't use svg anymore. if you can't generate images that you like you can draft the sheets and I can do the style transfer myself"

> "split character sprites into multiple parts so we can mix and match and combinatorically create many distinct looking pedestrians etc down the line (for now only create a few variations to be increased later)"
