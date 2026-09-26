## M109 — Muted quiet-square paving — 2026-09-12

PLAYTEST-65 reports that the illustrated quiet square is too bright and stands out negatively.
The built-in image generator redraws the existing four-slab SVG concept as darker cool slate,
using the approved urban/cardinal references for style and the sidewalk for neighboring material
values. The native 32×32 tile stays fully opaque with large, low-contrast slab joints and no
objects, curb or street paint. Registration is a direct LANCZOS downsample of the retained output;
the runtime uses the same source mapping and geometry.

The RGB-channel mean falls from 127.2796 to 99.7236. A separate weighted brightness measurement
using 0.2126R + 0.7152G + 0.0722B falls from 130.0525 to 98.5561. Repeated native and enlarged
tiles retain clean joins and sit between the darker asphalt and warmer sidewalk without a pale
focal patch. These measurements describe the images before the game's palette modulation.

`docs/evidence/quiet-square-2026-09-12/` retains the exact prompt, raw generator output, approved
style references, rendered SVG input and its renderer, frozen comparison materials, and guarded
registration/install scripts. Its frozen-input rebuild is independent of the installed PNG.
The runtime asset's SHA-256 is ab2778c32eba5d5719211a501baeb6fd85153a34cf736370c62174f568961029.
The shared checkout passes import/boot, the focused visual suite and doc/XML lint.
The open visual question is whether its muted stone remains recognizable as a quiet square in
gameplay; that is recorded in `REVIEW.md`.
