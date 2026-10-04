# The man shouting in a browser: charged, never ringed — 2026-10-04

**Question.** In a browser, does walking beside a live `homeless_yeller` charge the meter and light
his halo, as it does natively (M205, PLAYTEST-140 statement 4, PLAYTEST-144 statements 21, 24, 27)?

**Conclusion.** He charges her, but his rim never draws. In every browser run below, the
developer readout's `incoming` line rises as he paces toward her standing on the doorstep and falls
to zero once he is past his 210px reach. His rim stays dark while the rims of a walker and a car
beside him draw. A print added for the run showed his rim's own alpha easing to 0.75 while nothing
showed on screen, with 45 to 48 rims alive at once.

The cause is in the engine. On the Compatibility renderer, which is what the Web export runs, each
canvas item that draws with an `instance uniform` gets a 16-`vec4` block, given out
first-free-first. The canvas shader can read only 256 `vec4`s of that buffer (Godot 4.7.2,
`#define MAX_GLOBAL_SHADER_UNIFORMS 256 // TODO: this is arbitrary for now` in
`drivers/gles3/rasterizer_canvas_gles3.cpp`), so it can read sixteen blocks. Every `EventInstance`
built its rim in `_ready()`, about 45 of them at dawn, so most events held a block past the
sixteenth and drew nothing for as long as they lived. With the fix, as it stands at `995e83ad`, a
rim exists only while it is lit or fading and is freed on the spot once faded, and `ExcitementHalo`
keeps the rims alive at once within `EntityHalo.RIM_BUDGET` by having a new pick wait for a block
rather than cutting a fade. Run the same way, that build rings him.

**The stills** are cropped to her, him and the readout, at the same seed and day:

| File | Build | What it shows |
|---|---|---|
| `released-v0.23.0.png` | the released page, nappy.josuakrause.com, v0.23.0 (custom template) | him at 94px, `incoming` 18.57/s, no rim on him; a car's rim drawn |
| `before-e904eb17.png` | local release export of `e904eb17` (`main` before the fix), stock template | him at 147px, `incoming` 29.44/s, no rim on him; a walker's rim drawn |
| `after-995e83ad.png` | local release export of `995e83ad` (the fix, on PR #525: `git fetch origin refs/pull/525/head` first), stock template | him at 105px, `incoming` 32.14/s, his rim drawn orange-red |

`probe-console.txt` holds his own lines from a run of `e904eb17` with `probe.patch` applied: `d`
is his distance from her, `c_player` his excitement/s at her, `rims` the `EntityHalo` nodes alive,
and `rim_alpha` his rim's target and drawn alpha. The lines show 17.2/s at 112px, alpha 0.75, and
45 to 48 rims alive.

`probe-console-995e83ad.txt` holds the same print from a run of `995e83ad` with
`probe-995e83ad.patch` applied, which prints only while a man shouting is within 400px of her
(day 2 has four; one paces past her) and adds `rims_peak_1s`, the most rims alive at once over the
last second. His rim exists only once he is picked (`rim_alpha` is `<null>` before), eases to 0.75
as he closes to 120px and 16.5/s, and is still lit at 165px when the run ends. Between one and four rims are alive at
once, against 45 to 48 before the fix.

**Environment.** macOS 26.6.2 on an Apple M2, Godot 4.7.2.stable.official.ed1daf0bf, Google Chrome
154.0.8037.95, headless (`--headless=new`, SwiftShader WebGL2, whose `MAX_UNIFORM_BLOCK_SIZE` is
65536), 1280x720. In this Mac's own desktop Chrome (ANGLE on Metal) the limit is 16384. The
16-block ceiling is the shader's array size, so it is the same under both limits.

**Rerun**, from a checkout of the build to look at, with Node 22 and Chrome:

    docs/evidence/m205-yeller-halo-web-2026-10-04/export-stock-release.sh "$TMPDIR/m205-web"
    node docs/evidence/m205-yeller-halo-web-2026-10-04/drive.mjs --dir "$TMPDIR/m205-web" \
        --query '?debug=1&seed=6&day=2' --keys 'space@3' --seconds 16 --shots 1 \
        --output "$TMPDIR/m205-run"

The first command exports a release build with Godot's stock template, the kind every release
before the custom template shipped. Set `GODOT=` to use another engine binary, and restore
`export_presets.cfg` afterwards. The second serves the export, opens it in a throwaway headless
Chrome profile and presses Space at 3s to start the day. It then stands her on the doorstep for 16
seconds and writes a still each second, plus `console.log` and the browser scratch report. Use
`--url https://nappy.josuakrause.com/` instead of `--dir` to drive the released page. On seed 6,
day 2, the man shouting paces the sidewalk past her doorstep within his field for the first ten
seconds of the day. For the print, `git apply probe.patch` onto `e904eb17`, or
`probe-995e83ad.patch` onto `995e83ad`, before exporting, and `git checkout -- src/` afterwards.

**Limits.** No phone was run. The local exports use the stock template, not the custom one CI
builds: building that template needs Emscripten. The released page is a custom-template build and
shows the same dark rim. The meter half of the report does not reproduce: in every run here he
charges her, 17.2/s of his own at 112px in the first probe and nothing once he is past his 210px
reach. Those are instants with her standing still, not `docs/COSTS.md`'s walking, pulse-averaged
figure. **The head's run never fills the budget**: at most four rims are alive in it, so a pick
waiting for a block, and a rim freed mid-frame giving its block back before the frame's new rims
take theirs, are not seen in a browser here. Those rest on `tests/test_halo.gd` and on the engine
source named in `EntityHalo`'s class doc.
