# Playtest 95 — The save symbol is a blue disk with silver metal

**Date:** 2026-09-19

Said in conversation on seeing the redrawn save symbol in PR #236's description
(`evidence/m169-save-symbol-2026-09-19/save-symbol-before-after-3x.png`): one shape in the soft
green of a touched chalk mark, the shutter and the label cut out of it as holes. No run attached.

## What the player said

> "make it bluish and the metal parts should be silver/gray"

And, told that the runtime tint would have to go for the colors to survive:

> "no tint for the save symbol"

## What is asked for, as statements

1. **The disk's body is bluish.** The symbol carries its own color rather than being a white
   shape tinted `Palette.CHALK_DONE` green at runtime.
2. **The metal parts are silver or gray.** On the face of a floppy disk the metal part is the
   sliding shutter at the top.
3. **What this collides with, and what gives.** `assets/ui/save.svg` is white on transparent like
   `pause.svg`, `restart.svg` and `continue.svg`, and `SaveIndicator` tints it with the same
   modulate that fades it. A symbol with two colors of its own cannot be tinted by one: the
   modulate keeps the fade and loses the tint. The player confirmed it: *"no tint for the save
   symbol"*. The other three symbols are untouched.

## The verdict on the redrawn symbol

On seeing the blue disk with the silver shutter, the slot and the paper label in PR #236's
description (`evidence/m169-save-symbol-2026-09-19/save-symbol-color-comparison-3x.png`):

> "the latest version (blue with gray) looks good"

4. **The blue-and-gray symbol is accepted as drawn**, the paper label and the shutter's slot
   included, on the render. It has not been seen on a phone in play.

## What was not spoken to

Whether the symbol is noticed without distracting
on a phone, which stays in `REVIEW.md`.
