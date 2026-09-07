shader_type canvas_item;

// Flattens whatever `EventInstance._draw_halo()` re-draws through this material to a single flat
// colour, keeping only the shape the texture's own alpha carries. That is the whole of "draw the
// sprite in a uniform colour multiple times" — the shader half of the hack the player asked for,
// made cheap because it never has to trace an outline: the ring of offsets that turns a flattened
// silhouette into a rim is `_draw_halo()`'s own job, not this file's.
//
// **One `ShaderMaterial`, shared by every `EventInstance`'s halo child** (`EventInstance
// ._halo_material()`), so a per-source colour or strength cannot live in an ordinary `uniform` —
// that would be one value for every instance drawing through this material at once, not one per
// instance. `CanvasItem.modulate` was tried first and does not reach a custom fragment function at
// all: unlike the shaderless draw path, a fragment shader that writes `COLOR` is not re-multiplied
// by the node's own modulate afterward, so a plain `COLOR = vec4(1.0, 1.0, 1.0, a)` rendered white
// regardless of which entity it belonged to. `instance uniform` is Godot's actual per-instance
// channel with no per-instance material: one declaration, one value per `CanvasItem` that draws
// with it, set through `set_instance_shader_parameter()` rather than through the material at all.
// `EventInstance.set_halo_strength()` sets it: `Palette.EXCITEMENT_FIELD` for colour, current
// strength for alpha.
instance uniform vec4 halo_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// The texture's own colours (skin, a jacket, a barricade's paint) are discarded outright — only
	// its alpha survives, as the shape of the silhouette; `halo_colour` supplies the flat colour and
	// the current strength in its place, so the halo's colour comes entirely from
	// `set_halo_strength()` rather than from what the redrawn sprite looked like.
	COLOR = vec4(halo_colour.rgb, texture(TEXTURE, UV).a * halo_colour.a);
}
