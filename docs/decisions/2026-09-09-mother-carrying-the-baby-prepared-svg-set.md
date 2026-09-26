## Mother carrying the baby: prepared SVG set · 2026-09-09

PLAYTEST-50 asks for "basically the same set but instead of a stroller the baby is in her arms",
possibly for a finale whose design the player has not written. The six
`assets/rig/mother_carrying_{front,back,side}_{a,b}.svg` files preserve the existing mother's head,
clothes, leg poses, palette and registration. Front/back are 24×46 at (12,46); profile is 26×46
at (13,46), east-facing and mirrorable west. Both gait frames hold the same carrying pose.

The visual choice is a compact blue-grey blanket bundle across the chest: one arm supports the
head and neck, the other the wrapped body. Front and side views show the baby; the back view
naturally occludes most of it. This is ordinary carrying artwork, with no finale mood, trigger,
mechanics or runtime replacement inferred. GRAPHICS.md lists it as prepared and unbound.

All six were rendered with Godot and visually inspected. The previews are
`evidence/nappy-svg-mother_carrying_{front,back,side}_{a,b}.png`, enlarged threefold. XML validation
and import/boot check the integrated assets; no new gameplay test is needed for an unbound set.
