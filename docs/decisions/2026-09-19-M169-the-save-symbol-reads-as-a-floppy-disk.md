## M169 — The save symbol reads as a floppy disk · built 2026-09-19

> "the save icon is basically a white square" ([PLAYTEST-94](../playtests/PLAYTEST-94.md), on a phone)

> "make it bluish and the metal parts should be silver/gray" · "no tint for the save symbol"
> ([PLAYTEST-95](../playtests/PLAYTEST-95.md))

`assets/ui/save.svg` was three white shapes told apart by opacity alone — the body at 0.85, the
shutter at 1.0, the label at 0.35 — and `SaveIndicator` tinted and faded the whole texture with one
modulate, `Palette.CHALK_DONE`, so the differences shrank with the fade and were gone at the 48px it
is shown at.

**Built:** the symbol carries its own colors and is never tinted. The chamfered case is a muted
blue (`#5f7a99`), the shutter a silver gray (`#a8adb3`) with a darker slot (`#4a4e54`), the label a
pale paper (`#ede8de`), on the geometry the three shapes always had. `SaveIndicator` fades it with
a white modulate and nothing else; the peak alpha stays 0.9, the value the tint carried, so the
hold and the fade are timed as they were. `pause.svg`, `restart.svg` and `continue.svg` stay white
and tinted: this is the one symbol of the set with colors of its own, by the player's instruction.

**Tried first and replaced the same day:** one white path with the shutter and the label cut out
as holes (`fill-rule="evenodd"`), still tinted green. It read as a floppy disk on a dark ground
and weakly on a light one, since a hole shows whatever is behind it; the player saw it and asked
for color. **Rejected before that:** the body as an outline with the shutter and label filled
inside it, which leaves all three the same white.

**Chosen where the player said nothing, and then accepted on the render** *("the latest version
(blue with gray) looks good")*: the label's paper color rather than a hole, the slot in the
shutter, and the exact blue and gray.

Checked on a headless render through Godot's own SVG loader, each state under the modulate it
really had, at 48px and 16px on a dark and a light ground:
`evidence/m169-save-symbol-2026-09-19/save-symbol-color-comparison-3x.png`. Whether it is noticed
without distracting on a phone is `REVIEW.md`'s.
