---
name: illustrated-png
description: Build or revise the illustrated PNG presentation pipeline — reference-conditioned assets, directional manifests, alpha validation and review gates. Use before changing assets/illustrated or src/visuals.
---

# Illustrated PNG pipeline

The graphics overhaul uses real PNG assets and compositors. A presentation component reads the
existing simulation; it never becomes a second simulation.

## Reference authority

Inspect these images before generating or accepting illustrated art:

1. `docs/evidence/graphics-reference-mother.jpeg` defines the mother and pram: high brown bun,
   green coat, patterned scarf, jeans and practical dark shoes.
2. `docs/evidence/graphics-reference-urban-01.jpeg` and
   `docs/evidence/graphics-reference-urban-02.jpeg` define illustrated urban linework, material,
   apartment frontage, storefront density, street furniture, vehicle and pedestrian detail.
3. `docs/evidence/graphics-reference-cardinal.jpeg` is the floor for the available cardinal
   perspective. It does not lower the illustration or material target.

Do not derive style from archived experiments or an unapproved generated concept. Read
`docs/PLAYTEST-30.md`, `docs/VISUALS.md` and `docs/LUNA_HANDOFF.md` for the current accepted scope
before proposing a new family.

## Asset workflow

- Read the `imagegen` skill and use the built-in generator for new raster art. Inspect local
  reference images with `view_image` before generation so they are available as reference input.
- State the input images' roles in the prompt. Generate a new versioned sibling; never overwrite a
  reviewed source asset without an explicit request.
- A generated PNG must have real alpha where it is layered. Check it with `sips -g hasAlpha`; an
  image of a checkerboard is not transparency. A ground plate may deliberately be opaque.
- Keep a generation record beside the assets: exact prompt, reference inputs, output role, alpha
  result, and any rejected alternative worth avoiding. Keep a manifest beside directional or
  modular sheets.
- Directional sheets are ordered `N, NE, E, SE, S, SW, W, NW`. Record genuine symmetry explicitly;
  never silently mirror a view. Manifests state regions, pivots, layer order and variant contract.

## Runtime contract

The visual child receives only displacement its logical owner actually applied. It may solve
planted feet, choose an authored direction and update texture regions, but never changes the
owner's position, collision, traffic/crowd rules or gameplay RNG. Reset it wherever the owner is
teleported, recycled or reset.

Do not use a generic crowd look for an authored event, or a generic pedestrian for a car. An
unfinished family remains visibly unfinished until it has its own assets and binding.

## Review gate

Run `./tools/check.sh` and the focused affected suites; the full suite is CI's job. Inspect
`project.godot` after imports. A visual change also needs one purposeful bounded capture when the
environment permits. Check real gameplay scale, y-sorting, occlusion/cue legibility,
and contact between feet/wheels and ground. If capture aborts or is unavailable, report that visual
validation as unverified rather than claiming it passed.

Do not extend a reviewed asset family to other gameplay families until the player has seen and
accepted the gate that applies to it.
