# Visual presentation

**Every PNG asset has a corresponding SVG asset. The SVG is always authored and reviewed first.**
SVG-first authoring followed by style transfer is the approved graphics workflow. Keep source SVGs
editable and record each SVG/PNG pair; generated source sheets are generation evidence.

The game uses a registered PNG when one exists. `--svg`, or `?svg=1` on the web,
forces original SVG graphics. The same drawing code handles both formats.
The transferred artwork covers the mother's pushing and carrying animation frames and the pram's
five authored views, supplying eight directions through explicit east/west mirroring. Other
families use SVGs. Compare directions, gait frames and state variants together so the mother
carrying the baby reads as the same woman pushing the stroller.

## Reference roles

The source SVG defines the subject, colors, pose, direction, canvas, silhouette and placement.
`evidence/graphics-reference-urban-01.jpeg` supplies the diagonal illustrated urban style;
`evidence/graphics-reference-cardinal.jpeg` supplies the style-transferred gameplay reference.
Use these for linework and material treatment only. Exclude their interface, debug notes and
annotations. Do not change perspective or redesign the SVG subject to match a reference.

## Replacement contract

`TextureResolver` maps `assets/<family>/<name>.svg` to
`assets/illustrated/svg-transfer/<family>/<name>.png`. Missing or differently sized PNGs fall
back to the SVG. Drawing transforms, animation timing, mirroring, ground anchors, sorting,
collision and camera framing remain the existing game's responsibility.

Each PNG must match the SVG's native dimensions and rasterized alpha exactly. The registration
step enforces this boundary; interior detail and visual quality still require inspection.
Generation and extraction are documented in
[the cardinal generation record](evidence/style-transfer-2026-09-10/GENERATION.md) and
[the diagonal generation record](evidence/style-transfer-eight-directions-2026-09-10/GENERATION.md).
The [carrying generation record](evidence/style-transfer-player-family-2026-09-12/GENERATION.md)
preserves the shared source grid, existing-family identity reference and background correction;
its native and enlarged comparisons show both mother states across every direction and frame.
The [eight-direction source comparison](evidence/style-transfer-eight-directions-2026-09-10/eight-directions-comparison.png)
shows both formats at matching scale and ground offsets.

## Review

Review the detail at gameplay size, consistency across animation frames, transparent gaps,
ground contact and unchanged placement. Pixel registration alone does not establish acceptance.
The remaining catalogue work is in [TODO.md](TODO.md): M108, eight-direction entity graphics,
then M109, convert the SVG catalogue to PNG. [PLAYTEST-51](playtests/PLAYTEST-51.md) records the
approval and source-first requirement. Workflow approval does not replace each asset's review.

Use the [illustrated PNG skill](../.claude/skills/illustrated-png/SKILL.md) for integration.
Historical artwork and instructions are indexed in `DECISIONS.md`; the rejected graphics
archive is evidence only and must not become a style reference.
