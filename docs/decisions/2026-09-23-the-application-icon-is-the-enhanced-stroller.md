## The application icon is the enhanced stroller · built 2026-09-23

*(The player, 2026-09-23: "can we update the icon of the game with the enhanced version?")* The
application icon is now the root `icon.png`, 256×256, LANCZOS-downscaled from the comic-identity
pass's `art/icon_stroller_640.png` (the outlined, shaded stroller with the sleeping Zs on the
rounded slate plate), alpha preserved, instead of the flat root `icon.svg`. **256px** is the
largest size either of `project.godot`'s two readers of `config/icon` — Godot's own window/dock
icon and the web export's generated favicon, through `export_presets.cfg`'s
`html/export_icon=true` — ever scales up to, so nothing asks the source for more detail than it
has, and it downscales cleanly to every smaller size a favicon needs.

`icon.svg` and its `.import` sidecar are removed now that nothing reads them. The **svg-art**
skill's sentence "A game SVG has no `.import` sidecar, except the root `icon.svg`." now reads "A
game SVG has no `.import` sidecar." outright, with a note that the imported `icon.png` is a raster
outside the rule rather than an exception to it.

**Rejected:** nothing — the swap is a straight substitution. `art/icon_stroller*.svg` and
`art/logo.svg` keep their own comments naming `icon.svg` as design lineage rather than as the live
icon, since they describe their own history rather than claim to be bound.
