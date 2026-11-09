# The halo's arithmetic and the caret's projection

Read this before touching `ExcitementHalo`, `EntityHalo`, `ExcitementSource.net_landed()`,
`expected_impact_at()` or `caret_strength()`. The arithmetic itself is the `ExcitementHalo` class
docstring and the "Entity halo" row of `docs/EVENTS.md`, "The visual vocabulary"; this file holds
what keeps the halo the one narrow exception to "no rings", and what the amber caret measures.

## The halo: one cue, traced from the thing, for the cost charged now

- **One cue, not a general licence to draw.** Nothing else in the vocabulary gets a halo of its own
  by analogy to this one. `ExcitementHalo._select_sources()` decides which entities earn one, once a
  frame, and `EntityHalo` is the one place that draws. **The whole crowd is in the candidate set**
  (M92-the-halo-says-how-much-it-cost), cars on a busy street and people on a busy sidewalk alike,
  so the source is attributed exactly. `CONTRIBUTION_FLOOR` and `MAX_SOURCES` are what keep a busy
  sidewalk legible.
- **Traced from the thing, never sized to its reach** (M89-a-halo-says-what-is-costing-her).
  `EntityHalo` re-runs the entity's own body-drawing at a ring of offsets `HALO_MARGIN` (4px) out,
  flattened to one colour by `assets/shaders/excitement_halo.gdshader`. A `canvas_item` shader on
  the entity's own sprite cannot do it alone: it writes only inside its own rect, so a dilation is
  clipped at the silhouette's edge. **A radius that means anything about reach is the ring this
  exception does not authorise.**
- **For the cost being charged right now, not for what exists.** Colour is `_colour_for()`, linear
  through `Palette.HALO_MID` over `ExcitementSource.net_landed()`: the source's traced `landed()` less
  its share of the decay the bar took in the same window, floored at zero. A rim reads red only
  while the bar is climbing because of it (PLAYTEST-112 2). Transparency is `_magnitude_for()` over
  the same net on a curve that saturates early: only the amount received counts, colour and
  transparency are not the same number, and transparency emphasizes low values (PLAYTEST-38 3). Both channels ease rather
  than jump (PLAYTEST-38 3).
- **Soft and under everything.** Each rim is a child of its own entity with `show_behind_parent`, so
  Y-sort places it behind the entity, the crowd and the player; it stays a hint rather than a wall,
  and the caret, the badge and the exclamation mark keep meaning exactly what they meant.

## The amber caret moves her too

**The amber caret is the one exception.** It is the net gain she very likely gets if she keeps
doing what she is doing, so the halo roughly matches it when she does (PLAYTEST-115 7).
`expected_impact_at()` moves her too, at her own current velocity, and nets what she would gain
against what her own current decay gives back over the horizon (`Baby.decay_rate()`,
`Baby.current_sensitivity()`), floored at zero — the forward half of `net_landed()`'s sentence.
`ExcitementHalo` sums every live candidate's projected gross once a frame and publishes that total;
each source then subtracts its proportional share of the horizon's decay through `net_landed()`. A
caller that does not supply a shared total subtracts the whole horizon's decay from that source
alone.
