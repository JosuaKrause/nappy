---
name: illustrated-png
description: Add or revise illustrated PNG textures and their reproducible integration workflow. Use before changing assets/illustrated or src/visuals, or preparing an illustrated checkout for testing.
---

# Illustrated PNG pipeline

The graphics overhaul uses real PNG assets and compositors. A presentation component reads the
existing simulation; it never becomes a second simulation.

For texture authoring, registration or a test handoff, read
[the integration procedure](references/texture-integration.md). It carries the ordered checks,
coordinate conventions and failure diagnosis; use the existing commands before inventing another
tool. Historical incidents and measurements belong in `docs/DECISIONS.md`, not in this skill.

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
- Preserve source PNGs and their `.import` sidecars together. Sidecars hold import configuration
  and resource identity; they are repository files even though Godot generates them. Preserve new
  evidence sidecars too. The ignored `.godot/` directory holds the rebuildable imported cache.
- Record exact extraction commands and tool versions for derived PNGs. Preserve the approved
  source, write a versioned output and inspect retained detail as well as transparent gaps.
- Directional sheets are ordered `N, NE, E, SE, S, SW, W, NW`. Record genuine symmetry explicitly;
  never silently mirror a view. Manifests state regions, pivots, layer order and variant contract.

## Runtime contract

The visual child receives only displacement its logical owner actually applied. It may solve
planted feet, choose an authored direction and update texture regions, but never changes the
owner's position, collision, traffic/crowd rules or gameplay RNG. Reset it wherever the owner is
teleported, recycled or reset.

Do not use a generic crowd look for an authored event, or a generic pedestrian for a car. An
unfinished family remains visibly unfinished until it has its own assets and binding.

Endpoint equality is only a connectivity check. Review natural rest posture, per-facing stride,
foreshortening and arm reach separately. Never stretch a painted arm to legitimize a pram placed
beyond its natural reach. Calibrate complete assemblies, including all pram layers, at gameplay
scale. Check inherited filtering and source alpha before blaming a pixelated result on resolution.

## Preparing the test checkout

After switching or integrating an asset branch, run `./tools/check.sh` in the exact folder the
player will use. A different worktree's successful import does not populate this one's `.godot/`.
`tools/run.sh` detects missing global classes and `.import` sidecars whose imported copy is
absent, and repairs both by running the import pass; `shot.sh` and the headless boot commands
below do not, so a populated class cache alone does not establish that the checkout can draw.

Then boot with `--illustrated` explicitly, using the bounded headless command in the procedure.
Read the first resource/parse error, not just repeated `new()` or nil errors downstream. A normal
legacy boot does not exercise the illustrated binding. Preserve sidecars after the import pass
and inspect the working tree before handing the folder over.

## Review gate

Run `./tools/check.sh` and the focused affected suites; the full suite is CI's job. Inspect
`project.godot` after imports. A visual change also needs one purposeful bounded capture when the
environment permits. Check real gameplay scale, y-sorting, occlusion/cue legibility,
and contact between feet/wheels and ground. If capture aborts or is unavailable, report that visual
validation as unverified rather than claiming it passed.

Do not extend a reviewed asset family to other gameplay families until the player has seen and
accepted the gate that applies to it.
