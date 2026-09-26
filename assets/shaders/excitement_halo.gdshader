shader_type canvas_item;

// Flattens whatever `EntityHalo._on_draw()` re-draws through this material to a single flat
// colour, keeping only the shape the texture's own alpha carries. That is the whole of "draw the
// sprite in a uniform colour multiple times" — the shader half of the hack the player asked for,
// made cheap because it never has to trace an outline: the ring of offsets that turns a flattened
// silhouette into a rim is `EntityHalo._on_draw()`'s own job, not this file's.
//
// **Every rim's own `ShaderMaterial`** (`EntityHalo._halo_material()`, one per instance) carries
// its own `halo_colour`, so a plain `uniform` — one value per material — is enough; nothing here
// needs Godot's per-`CanvasItem` `instance uniform` channel, whose value silently never reaches
// the fragment shader on this project's `gl_compatibility` renderer's Web/WebGL export (measured:
// `EntityHalo._process()` computed and logged a real target alpha there while no rim ever drew,
// though the same renderer draws it correctly natively). `CanvasItem.modulate` alone cannot stand
// in for either form: unlike the shaderless draw path, a fragment shader that writes `COLOR` is not
// re-multiplied by the node's own modulate afterward, so a plain `COLOR = vec4(1.0, 1.0, 1.0, a)`
// rendered white regardless of which entity it belonged to. `EntityHalo._process()` sets this
// uniform on its own material every frame it is easing: `Palette.EXCITEMENT_FIELD`-derived colour,
// current eased alpha for strength.
uniform vec4 halo_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// The texture's own colours (skin, a jacket, a barricade's paint) are discarded outright — only
	// its alpha survives, as the shape of the silhouette; `halo_colour` supplies the flat colour and
	// the current strength in its place, so the halo's colour comes entirely from
	// `set_halo_strength()` rather than from what the redrawn sprite looked like.
	COLOR = vec4(halo_colour.rgb, texture(TEXTURE, UV).a * halo_colour.a);
}
