# minty-quail — The frame record is a handed sink and counts draws by listening; the torn posters are held by main (hidden statics) · 2026-11-02


minty-quail's `hidden-statics.md`: the frame record's switch and ledger, and the torn posters. The
item stays open for the statics read across the tree.

**Built.**
- `FrameRecord.on` and `FrameRecord.ledger` are fields of a `FrameRecord` object, since the recorder
  switched `on` at setup and off at exit. `FrameTiming` (`src/frame_timing.gd`) is the null sink every
  timed system holds by default, and `FrameRecord` extends it. `main` makes a `FrameRecord` when the
  run asks for a record; the `Sitting` holds it, so a recording survives a held restart; `main`
  hands it to the baby, the city (its scenery residency, its events and the crowd's timing), the
  building's events, the danger edges and the excitement halo; event instances get it through
  `EventWorld.timing`.
- The twenty `if FrameRecord.on` counter lines in the drawing code are gone: `FrameRecorder` counts
  `_draw()` calls by connecting the `draw` signal of the nodes it recognises, over the tree at setup
  and as nodes enter it, by class where it may name it and by a kind the view's nodes declare
  (`FrameTiming.DRAW_KIND_META`) where it may not. A page without a record connects nothing.
- `PosterArt` is an instance `main` holds and hands down through `City.poster_art`, `PosterWalls.art`
  and `Building.poster_art`, so the daily city does not recompose its 15 textures; a scene reload
  composes them once more.
- The layer map loses its `FrameRecord`, `FrameLedger` and `PosterArt._torn` entries, and the runner
  its resets of them.

**Open to overturn** (the builder's choices where the brief was silent): counting draws by listening
rather than handing a sink to each drawing class (a new drawing class must be named in
`draw_kind()` or declare the kind, as it once had to add its counter line); the poster art on
`main` rather than the `Sitting` (the layer map keeps the model-layer `Sitting` from naming it).

**Not measured on the phone:** a held sink read measured faster than the static read in a headless
microbenchmark; the remeasuring step reads the draw buckets on the phone.
