---
name: illustrated-png
description: Generate, register and install illustrated PNGs under art/illustrated/, including SVG transfers and explicitly authorized direct-PNG families. Load BEFORE adding or changing a PNG there.
---

# Illustrated PNG workflow

**The rules not to miss:**

- **Claude Code stops at generation: it has no image generator.** A new PNG is the work of a host
  that has one; a Claude Code session asked for one says so and stops rather than improvise.
- **Nothing is converted to PNG for now**; a conversion waits until the player finds a use for one
  (inbox #927 in tiny-lark).
- **The pelican cyclist is never converted** (minty-hedgehog #437).
- **The SVG comes first**: a PNG's SVG is authored and reviewed before it, never made afterwards.
- **PNG-first is a bounded exception the player authorizes for one family at a time.**
- **The presentation is chosen by the bake, not by the running game.**
- **A runtime PNG is committed on its own, with no `.import` sidecar** (the **godot** skill,
  "Structure").
- **A new picture needs its line in `assets/atlases/membership.json`**, or no bake draws it.
- **A transfer PNG whose size disagrees with its SVG fails the bake by name.**

What a Claude Code session does here is what needs no generator: registering, installing and
checking PNGs that exist, their atlas membership, and their review. The generation procedure
(which references have authority, how a family's directions, frames and variants are kept one
family, raw outputs, extraction and alpha) is `references/generation.md`, read by a host that can
generate before it does. Revising a walking frame of a family that exists is
`references/leg-contact-corrections.md`.

**An agent's sparse worktree leaves out `docs/evidence/` and `docs/style-references/`**, the two
folders this work reads and writes: a new file there is committed with `git add --sparse <path>`,
and a task that reads what is already there asks for a worktree made with
`tools/agent-setup.sh ... --include <path>`.

## What a PNG is here

**Every PNG asset normally has a corresponding SVG asset, and the SVG comes first.** Author
and review the SVG before generating its PNG; do not create an SVG after the fact to legitimize
a PNG-only asset. Keep the SVG as the editable source of subject and functional placement. Record
the source/derivative pair in the family's evidence manifest, including UI and identity assets.
Nothing is converted to PNG for now; a conversion waits until the player finds a use for one (inbox #927 in tiny-lark).
Raw generator outputs belong with generation evidence, not in the runtime asset catalogue.

**The pelican cyclist is never converted.** `art/events/pelican_cyclist*.svg` stays SVG by the
player's word (minty-hedgehog #437): the bake rasterizes it like any SVG, and no illustrated PNG of
it is generated or placed under `art/illustrated/`. **The rule is unenforced**: no suite or check
fails if one appears there.

The player may authorize a bounded PNG-first family when photographs or a reviewed generated
concept define the subject more faithfully than an existing SVG. The M109 rooftop equipment
(`art/illustrated/roof-equipment/`) is the one such family. Preserve its exact
raw generated source, prompt, hashes, deterministic registration, native anchors and human review
verdict in family evidence; list each direct PNG in atlas membership. This authorization does not
make PNG-first the default for another family.

Read `docs/VISUALS.md` and
[the integration procedure](references/texture-integration.md) before working on this presentation.
**The presentation is chosen by the bake, not by the running game.** The default
`tools/bake-atlases.sh` takes the registered PNG wherever one exists beside its SVG, and the
SVG's own raster everywhere else; `tools/bake-atlases.sh --svg` uses the SVG sources for those
pairs and is a custom local build, never the release. Approved direct-PNG members remain in both
modes because they have no SVG counterpart. There is no runtime flag for either — a build is
whichever bake wrote its pages. Both use the same drawing and animation code.

## Asset contract

- SVG transfers use `art/illustrated/svg-transfer/<family>/<name>.png`, corresponding to
  `art/<family>/<name>.svg`; an expressly authorized PNG-first family uses its own named folder
  below `art/illustrated/` and direct atlas membership. Match native canvas dimensions, ground anchors and functional
  placement. Preserve the generated artwork's true alpha and expressive silhouette; do not
  reapply the SVG's primitive alpha mask to a redrawn figure or prop. Opaque ground stays fully
  opaque and functional markings retain their joins. Verify outlines, transparent gaps and
  internal placement visually as well as checking canvas registration.
- **Commit a runtime PNG on its own, with no `.import` sidecar.** `art/` is behind a `.gdignore`,
  and the **godot** skill, "Structure", owns that rule and says what the bake does instead.
- **A new or changed picture is not in the game until the pages are rebaked**, and every tool
  that starts the engine does that for you: `tools/bake-atlases.sh` compares a hash per source
  and bakes when one moved or when a PNG has newly appeared beside an SVG it baked from, which
  is what installing a transfer for an existing picture is. A new picture also needs a line in
  `assets/atlases/membership.json` naming the group it belongs on, in `members` if both bakes draw
  it or `members_png`/`members_svg` if only one does — a bake reads and hashes its own mode's
  lists alone, so it is baked nowhere and `AtlasTable` answers `has_region()` false for it until
  that line exists.
- **A transfer PNG whose size disagrees with its SVG fails the bake by name.** There is no fallback: the
  game holds no second copy of the picture to fall back to, so a mismatch is a committed mistake
  rather than an unfinished art drop to work around.

## Runtime and review

Keep every script used to create retained graphics, comparison sheets, walking rollouts and GIFs
beside its output in the family's evidence folder, named as the **session-captures** skill says a
new evidence folder is named. Include source paths and hashes, extraction
bounds, frame order, mirroring, scale, GIF timing, tool/font requirements and exact regeneration
commands. Preserve immutable inputs or fail loudly when their hashes change. The folder's own
`GENERATION.md` or `README.md` is the recipe, and no index lists them: link it from the family's
graphics documentation (`docs/GRAPHICS.md`) so it can be found again.
Distinguish nondeterministic image generation from reproducible extraction and assembly of its
saved output. A temporary script or chat-only command is insufficient provenance.

For opaque ground tiles, extraction, boundary joints and the layered variant/damage/grass
composition are in [the ground-tile reference](references/ground-tiles.md).

For a transfer without an approved placement change, resolve textures only. Keep original scale,
offsets, animation, mirroring, sorting, shadows, camera and gameplay behavior. A missing transfer
PNG bakes from its SVG; a mis-sized transfer fails the bake by name. A direct PNG has no SVG
fallback. Do not hide an unfinished family with unrelated generated art.

Run the import/boot check in the exact checkout the player will use, then focused suites
(`tools/test.sh` always bakes PNG). Read the first resource error; passing assertions
do not excuse script or import errors. Read `verify` before tests or captures and use at most one
or two purposeful gameplay captures. Report source registration, appearance and player acceptance
separately. SVG-first style transfer remains the default outside the authorized exceptions. Review each family's visual result without treating workflow approval as proof
that every generated image is correct.
