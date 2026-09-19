# Father B-contact comparison

[Open the comparison sheet](sheet/comparison.png). It answers whether the four affected
illustrated B poses have reviewable anatomy. The fresh candidate fails the side and front-diagonal
ownership checks and is not installed. The image is diagnostic evidence for human inspection,
not a proposed replacement family or approval of any pose.

The four rows show south/front, north/back, east/side and southeast/front diagonal. West and
southwest use the side and diagonal mirrors; the unchanged northeast/northwest family is outside
this four-pose diagnostic. Each row compares the installed A contact, installed C together pose,
installed B contact, intended SVG B contact and fresh candidate B. The upper versions use 3×
scale; each native image sits beneath its enlargement. The final image column shows the raw
candidate at 210px visible stature so its hip-to-shoe contours remain inspectable. The SVG uses
the existing Godot native/3× renders; the PNG enlargements use nearest-neighbor scaling.

| Candidate view | Visible anatomy |
|---|---|
| Front | The image-right anatomical left leg advances; the image-left leg recedes. The intended leg leads. Head and hand proportions still need acceptance against A/C. |
| Back | The image-right shoe is higher, but its visible sole makes advancing away versus lifting behind ambiguous. This does not establish the required contact. |
| Side | The uninterrupted foreground thigh runs down-right to the advancing shoe. The required near thigh should run down-left to the trailing shoe. The whole figure also overflows the runtime canvas. |
| Front diagonal | The foreground thigh again connects down-right to the advancing shoe. The required image-right near hip to left trailing shoe chain remains absent. |

The blue candidate box marks its unchanged intended runtime canvas. Diagnostic padding preserves
all pixels outside that box. No figure is shrunk, stretched, clipped or installed to conceal a
registration failure. Each candidate has 45px visible stature on a 46px-high canvas; the candidate
uses the existing C upper-body opacity centroid for horizontal placement. This follows
`../review-raster.py` until its clipping gate. The side exceeds that gate: x = -16 and width = 319
on its 312px-wide 12× working canvas. The sheet retains 12 native pixels of transparent diagnostic
padding on each side, which is not a runtime offset or asset canvas change.

`candidate-raw.png` is the unchanged built-in imagegen output. `prompt.txt` is the exact prompt
with ordered reference roles. The pose reference is the corrected SVG sheet; the identity
reference is cropped above the pelvis; the two official comic references supply style. No earlier
rejected output is a generation input. The candidate's raw alpha is preserved; no background
removal, pixel retouching or upper/lower-body splicing is applied.

`inputs.json` pins the generated output, prompt, references, assembly dependencies and protected
runtime A/C/B images. `sheet/measurements.json` records raw/cell dimensions, extracted bounds,
registration placement, clipping verdicts, software version and output hashes. The source image
is 2011×782; its four cell boundaries are x = 0, 503, 1006, 1508, 2011. Each cell spans the full
height. No mirroring is applied in this sheet. The script fails if a recorded input changes.

Regenerate from the repository root with the locked Python 3.14 / Pillow environment and a fresh
output directory. Labels use Pillow's bundled default font; no system font is required.

```sh
uv run python docs/evidence/male-player-2026-09-19/b-contact/review-2026-09-19/assemble.py \
  --output-dir /tmp/father-b-comparison
```

The one-time `--freeze-inputs` option creates the input record only when none exists; it refuses
to overwrite it. Generation is nondeterministic; this command reproduces extraction and sheet
assembly from the preserved output. Compare output hashes against `sheet/measurements.json`.

Static anatomy and scale are the coverage here. This sheet does not establish walking motion,
live hand-to-stroller contact, full-family consistency or completed PNG correction. All runtime
PNGs, source artwork and gameplay remain untouched by this diagnostic.
