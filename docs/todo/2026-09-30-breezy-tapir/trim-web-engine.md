Compile unused Godot modules out of the Web export template as part of the same loading work.
Keep the development editor and ordinary local tests full-featured. Audit what the running game
and exported resources actually require; preserve 2D physics, tile maps, shaders, runtime image
composition, text rendering, JSON, saves and browser integration. A narrow source-name search
or automatic feature detector is a starting point, not proof a dependency can be removed.

**Proposed, not asked for:** version-control the module/build profile and a reproducible cached
template build using matching pinned Godot source and toolchain. Wire the Web release export
and release pipeline to that artifact while preserving the existing tag-only publication gate.
Generated engine binaries remain build artifacts. The exact module list follows the audit.
Start conservatively with unused 3D capabilities and removable modules; do not trade appearance,
text behavior or gameplay for smaller size. Changing text renderer is not assumed authorized.

Compare stock and trimmed engines under fixed compression settings with the same filtered game
package. Measure actual Wasm/JavaScript/template size changes and keep local gzip distinct from
CDN transfer. Verify the custom engine in the browser, not only by loading the PCK with the full
native editor. Test startup, ordinary play, saves/resume, day transitions and escape resources
with bounded reproducible runs. Preserve threadless deployment and JavaScriptBridge behavior.
Keep measured limitations explicit; no merge or release is part of this task.
