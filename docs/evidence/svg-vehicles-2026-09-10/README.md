# Vehicle, animal and rider SVG source review

These source previews cover M108, eight-direction entity graphics, and the mouse and riot-van
end view for M103, the drawings the queue owes. The added SVGs are prepared artwork; runtime
selection, collision, tinting, animation, shadows and traffic paths retain their current bindings.
No illustrated PNG derivative is part of this set.

[facings.csv](facings.csv) gives every N, NE, E, SE, S, SW, W and NW source, mirror operation,
native canvas, bottom-centre canvas anchor, alpha bounds, layer order, review sheet, intended
consumer/use and owning work item. M108, eight-direction entity graphics, binds the live actors;
M111, cars follow their turns, supplies curved crowd-car motion; M56, the resistance is noticed,
owns raid states; M100, small, real, and nobody's, and M102, the finale, own mouse use.
Its 144 rows cover eighteen family/state combinations. The source addition contains 78 SVGs:
eight crowd-car layers, thirty-six event-vehicle views, thirty-two animal/rider views, and the
mouse side and riot-van end sources. Each game source has its import sidecar.

Each sheet cell shows a Godot SVG render at 3× and an additional native-size render at its lower
left. Both preserve native proportions; they are not fitted to a common object size. The neutral
background is evidence presentation, not baked into the source. Sheets include every mirrored
view and the existing side sources, so differences in source style and native scale remain visible.

- [Working vehicles](vehicles-working.png): delivery van, fire engine, ice-cream van and lorry.
- [Security and moving vehicles](vehicles-security.png): unmarked van, riot van, army truck and moving van.
- [Car layers and police car](cars-layered.png): green-tinted crowd-car body plus untinted trim;
  the police-car source retains its baked colors.
- [Cats and dogs](animals.png): crouched/running cats and held/charging dogs.
- [Birds, rider and mouse](birds-rider-mouse.png): both pigeon wing phases, cyclist and mouse.

Front means S; back means N; front_diagonal means SE; back_diagonal means NE.
SW and NW reflect their matching east-facing diagonal about the canvas anchor. Animals and
the bicycle have no side-specific markings. Vehicle mirror reuse follows the catalogue's
stylized bilateral construction: hatch/door and equipment layouts repeat on the opposite flank,
and there is no text to reverse. The police light-bar colors mirror with the entire vehicle,
as they do in its canonical side view. This is an art symmetry choice, not a new gameplay rule.

The existing delivery van, fire engine, unmarked van, riot van, army truck and moving van side
pictures visibly place the cab at the left. The matrix labels those sources W and mirrors them
for E. Other side sources face E. This describes authored geometry; the current runtime
heading selector remains unchanged. The moving-van vertical scene and all canonical side
pictures remain available under their existing bindings.

The new large-vehicle canvases are 34×50 for ends and 56×50 for diagonals. Tire contact lies
around y45 in ends and y46 in diagonals; the moving van's extended loading ramp reaches farther
down the canvas. Cars use 30×46 ends and 52×42 diagonals, with paint and trim sharing each
canvas exactly. Cat additions use 30×24 ends and 38×24 diagonals; dog additions use 30×28 and
38×28. Pigeon phases share 22×18 canvases and body registration. The cyclist uses 30×44 ends
and 40×44 diagonals. Mouse views use 18×18 ends, 24×18 diagonals and a 24×14 side source.
The CSV distinguishes the canvas anchor from measured alpha bounds: neither is a collision
shape. The heading-binding milestone must check contact/shadow alignment in the live draw path.

Contact shadows and leads belong to the callers: EventInstance draws a separate shadow before
each vehicle/animal, per-bird shadows at ground positions, and code-drawn taut or trailing dog
leads. These source additions do not bake in duplicate shadows or leads. Crowd cars draw their
tinted paint first and untinted glass, tire and lamp trim second.

The source review uses Godot Image.load_svg_from_string at 1× and 3×, XML validation, the
repository import/boot check and documentation lint. Prepared sources require source previews;
no runtime binding is invented solely to photograph them. The full gameplay suite belongs to
CI; this artwork-only set introduces no gameplay tests.
