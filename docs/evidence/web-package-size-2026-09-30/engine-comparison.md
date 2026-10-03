# Custom Web engine comparison

The custom Web engine runtime (Godot export template) reduces the engine's fixed local gzip
size by 2,895,660 bytes, or 28.8%, with the same filtered game package in both controls.
The loader saves another 6,137 gzip bytes. These are measured downloads' constituent file
sizes under local compression, not an observed CDN transfer or a loading-speed measurement.

| File | Stock bytes | Custom bytes | Stock `gzip -9 -n` | Custom `gzip -9 -n` |
| --- | ---: | ---: | ---: | ---: |
| WebAssembly engine | 39,514,754 | 29,130,361 | 10,054,758 | 7,159,098 |
| JavaScript loader | 279,815 | 251,073 | 68,471 | 62,334 |
| Identical filtered PCK | 1,935,816 | 1,935,816 | 1,803,160 | 1,803,160 |

The engine and loader together save 2,901,797 bytes under that fixed compression. This table
does not add the separate test-exclusion experiment to an incompatible live transfer baseline.
The live CDN's stock engine body is 10,248,949 bytes; local stock gzip is 10,054,758 bytes.
They are different measurements. There is no new release or CDN measurement here.

## Inputs and dependency audit

The game/export revision is `48e41ab705617ba5a29bb03c0fffa2f30c59e96a`, release stamp
`engine-measurement`, with clean tracked runtime sources and the matching full Godot 4.7.2
editor. The custom engine is built from unmodified source
`ed1daf0bf001b61586d9930840f2f1394092c079`, Emscripten 4.0.20 and SCons 4.9.1 on macOS arm64.
The stock engine reports the same source revision and compiler version. Both are release,
threadless WebAssembly without GDExtension support. The custom build uses size optimization,
thin LTO and no debug symbols. Exact source/bootstrap hashes, flags and dependency reasoning
are in `tools/web-template/pins.env`, `profile.args` and its README; file and collector hashes
are in [engine-results.json](engine-results.json).

The stock control is copied from the custom export, with only its engine, loader and worklets
replaced by the official threadless release template's files; its HTML's Wasm size is updated.
The two PCKs have the same SHA-256. This compares an official stock build with the custom recipe,
not two engine builds made on one host with every official build-environment detail reproduced.
It establishes the actual size reduction of the validated replacement, not a per-module
attribution or a runtime-performance improvement.

Unused 3D/physics/XR, navigation, model import, networking, media and alternate image-format
modules are removed. No automatic class pruning or text-server replacement is used. The
compiled module header retains BCDEC, FreeType, GDScript, Godot Physics 2D, JPG, MSDFGen, Regex,
SVG, TextServerAdvanced, VisualShader and WebP. Core 2D nodes, TileMapLayer, shaders, PNG, JSON,
image composition, FileAccess, JavaScriptBridge and the browser filesystem remain available.

Inspection of every exported GST2 texture header finds twelve WebP-backed `.ctex` files and no
Basis or GPU-compressed texture payload. This is stronger than inferring a decoder dependency
from the preset's desktop-compression toggle. The release PCK audit finds no test paths,
retained plain test references, duplicate atlas constituents or orphan atlas pages.

## Actual browser verification

Both controls pass the same bounded harness in headless Chrome 154.0.8037.59 on macOS arm64,
using ANGLE SwiftShader and WebGL 2.0. Each run uses a fresh browser profile and a private
localhost origin; neither can touch the player's save. External analytics are blocked.
The retained run order is custom, then stock. No timing comparison is made between those runs.

The checks reach the title, press real keyboard input to begin and walk, read the persisted
IndexedDB save, reload it with the same run seed and exactly one nerve spent, win a day through
a near-full-meter walk home, continue its real summary into day 2, boot days 8 and 14, and boot
the escape interior. Later-day query boots and the escape boot are resource-compatibility checks;
they do not claim a complete fourteen-day playthrough or an escape finish. The normal save cases
have independent random seeds; the transition and resource cases use seed 4242.

The agent inspects the custom title, day-2 and escape screenshots: textures and text render,
and the baked `engine-measurement (48e41ab7)` version/commit is visible. The persisted save also
carries that same build string. Both controls finish with no Godot error or JavaScript exception.
Both emit the same pre-existing Emscripten warning about overlapping `FS.syncfs` calls during
save/reload, four times in each retained run; persistence succeeds. This check is not a claim
that the save implementation is warning-free or proof against a forcibly killed browser.

Exploratory attempts are excluded from acceptance: an initial shell-splash assertion waits for
an element Godot removes, and an escape assertion waits for an outdoor-finale log while testing
the interior. The corrected harness checks splash removal and interior atlas acquisition.
The stock control exposes unsupported `OS.execute("git", ...)` calls in version lookup; the
verified PCK contains the narrow Web guard that returns `unknown` and lets the title use its
baked metadata. Native Git lookup remains covered by the existing pause/telemetry suites.
An initial Emscripten 6.0.1 compile succeeds but is not used in this comparison; 4.0.20 matches
the stock runtime's reported compiler.

## Reproduction

Use a fresh worktree at the recorded revision, a Godot 4.7.2 editor, Node 22 and Chrome. Install
the official 4.7.2 templates to supply the stock control. `STOCK_WEB_TEMPLATE` names that
installation's `web_nothreads_release.zip`; `BROWSER` names Chrome's executable, and `GODOT`
overrides the editor path if needed. From the repository root:

```sh
scratch="$(mktemp -d)"
git fetch origin refs/pull/443/head
git worktree add --detach "$scratch/source" 48e41ab705617ba5a29bb03c0fffa2f30c59e96a
cd "$scratch/source"
./tools/build-web-template.sh --jobs 4
./tools/check.sh
RELEASE_TAG=engine-measurement ./tools/export-web.sh
node tools/web-template/compare.mjs --export build/web \
  --stock-template "$STOCK_WEB_TEMPLATE" --output "$scratch/comparison"
node tools/web-template/browser-check.mjs --export "$scratch/comparison/stock" \
  --output "$scratch/stock-browser" --browser "$BROWSER"
node tools/web-template/browser-check.mjs --export "$scratch/comparison/trimmed" \
  --output "$scratch/custom-browser" --browser "$BROWSER"
./tools/audit-pck.sh build/web/engine-measurement/index.pck --fatal
```

`compare.mjs` refuses an existing output directory, measures actual `gzip -9 -n` output and
checks identical PCK hashes. Each browser run records its results, console, Chrome diagnostics
and screenshots. Compiler/download/export artifacts and expanded browser output stay in scratch
space; this evidence retains only compact results and these commands. Host/browser/build
differences can change bytes and runtime logs on a rerun; hashes identify this measurement.
