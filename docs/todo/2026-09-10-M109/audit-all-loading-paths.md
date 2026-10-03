Audit all loading paths: shared drawing helpers, direct textures, TileSets, scenes/resources,
UI buttons and identity/export consumers. The application icon is done — it is the root
`icon.png`, bound directly rather than through the SVG-override comparison, since nothing
else reads `icon.svg` any more (`DECISIONS.md`, the application icon is the enhanced
stroller). Provide registered PNG bindings for every remaining live SVG without altering
draw transforms unless the player explicitly requests a placement change. Verify default PNG
and custom SVG bakes, missing-transfer fallback and mismatched-size rejection. The custom SVG
bake supplies the comparison control; presentation is chosen by the bake, with no runtime flag.
