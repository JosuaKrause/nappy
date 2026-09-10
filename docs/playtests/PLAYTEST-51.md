# Playtest 51 — 2026-09-10

## SVG-to-PNG style-transfer experiment

> let's try an experiment. instead of a full graphics overhaul let's try a simple style transfer. we take svg images we
> already have and create pngs from them that show the same thing but in the style of the reference images (the sample
> diagonal 2d and the already style transferred gameplay reference without the debug notes etc). the images should be able to be drop in replaced for the svgs so the size and positions must be the same. we can reuse the illustrated flag and archive the outcomes from the previous illustrated attempt (and remove the code for it and replace it with the new attempt)

> if that works we can update our graphics pipeline to always first generate the svg and then apply the style transfer

The experiment preserves each source SVG's canvas, subject placement, direction, pose and
runtime anchors. The urban diagonal illustration supplies style, while the supplied cardinal
gameplay illustration supplies the matching gameplay perspective; neither supplies UI or debug
annotations. The existing illustrated opt-in selects replacement PNG textures. The previous
illustrated attempt is archived and its runtime code is replaced. Adopting SVG-first authoring
followed by style transfer as the standard graphics pipeline depends on this experiment working.

## Transparency extraction

> there is a script to remove checkerboard if that makes things easier

The repository's `tools/remove-checkerboard.py` supplies the existing extraction step.

## Documentation and review

> Yes, update and archive the documentation

> don't call it an experiment in the documentation. if it works it will just be the way it is done

> create a pr

> can I see some conversion? maybe in the pr?
