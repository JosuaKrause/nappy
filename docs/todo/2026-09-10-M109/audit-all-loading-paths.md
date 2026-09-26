Audit all loading paths: shared drawing helpers, direct textures, TileSets, scenes/resources,
UI buttons and identity/export consumers. The application icon is done — it is the root
`icon.png`, bound directly rather than through the SVG-override comparison, since nothing
else reads `icon.svg` any more (`DECISIONS.md`, the application icon is the enhanced
stroller). Provide registered PNG bindings for every remaining live SVG without altering
draw transforms; verify both flag states and missing/mismatched fallback. The SVG override
remains the comparison control during review.
