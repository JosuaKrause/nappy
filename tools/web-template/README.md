# Release Web runtime

`../build-web-template.sh` builds a custom Web engine runtime (Godot export template), only for
threadless release exports. Its archive is a build input; the compiled engine inside it becomes
the exported `.wasm` and JavaScript files, not a starter project shipped with the game. The full editor
imports and exports resources, and remains the engine for development and local tests. Debug
Web exports use the stock debug template. Release exports refuse a missing, stale or corrupted
custom template rather than silently substituting the stock runtime.

`pins.env` pins Godot source, the Emscripten SDK bootstrap and SCons. Both source archives have
SHA-256 checks before extraction. Emscripten 4.0.20 matches the compiler reported by the official
4.7.2 Web release template. The build explicitly selects Web/wasm32, release, no threads,
production, size optimization, thin LTO and no debug symbols. No engine source patch is applied.

The final archive and its receipt live under `build/web-template/`. Its cache key covers the
builder, pins, module profile and host OS/architecture; the receipt also hashes the actual zip.
There is no fallback cache prefix. Compilation scratch and downloads live under
`build/web-template-work/<key>/`. The builder writes `build/.gdignore` before extracting any
source, so Godot cannot import its compiler or exported binaries.

## Module choices

`profile.args` is the complete explicit removal list. These choices are audited against the
pinned source's `SConstruct`, `platform/web/detect.py`, module `config.py` dependencies and the
game's scripts, scenes, atlas imports and actual exported texture headers. The profile does not
use automatic class pruning: dynamically created nodes and resources remain available.

| Removed group | Why the runtime does not need it |
| --- | --- |
| 3D, 3D physics, XR; CSG, grid maps, model importers, mesh optimization, lightmapping and decomposition | The game uses Node2D, CanvasItem, TileMapLayer and 2D collision shapes. Its height/occlusion presentation does not use a 3D scene or physics server. |
| 2D/3D navigation servers and modules | City routes and pedestrian paths are computed by the game's street/route code. The ground TileSets supply drawing and collision, with no engine navigation regions or agents. |
| ENet, multiplayer, WebRTC/WebSocket, UPnP, TLS and JSON-RPC modules | Runtime browser integration uses JavaScriptBridge and browser APIs, not Godot network peers or HTTP/TLS clients. JSON itself is core and remains enabled. GDScript's optional editor language-server dependencies are not required by a release runtime. |
| Theora, Ogg/Vorbis, MP3, interactive music and camera modules | The exported resource package contains no audio/video streams or camera feed. Core audio remains available; installing a new media format requires revisiting the profile. |
| ASTC/Basis/ETC packing and BMP/DDS/HDR/KTX/TGA/EXR loaders, procedural noise and ZIP reader | Current exports use lossless WebP-backed textures and JSON resource tables. These alternative formats, noise resources and ZIP APIs have no runtime consumer. The PCK loader is core and remains enabled. |

The advanced text server, FreeType, MSDF generation, SVG/JPEG/WebP support and core PNG decoder
remain enabled. Their dependencies preserve the existing typography and image behavior.
The regular 2D renderer, shader language, image composition, physics, GUI controls, GDScript,
JSON, FileAccess, JavaScript evaluation and persistent browser filesystem remain enabled.
TileMapLayer is core in this source version; the profile does not invent a tilemap module flag.

The preset's desktop texture-compression switch is not evidence of each texture's encoding.
The actual pack inspection in the engine comparison checks the GST2 payload headers; browser
startup, later-day and escape checks exercise their decoders and runtime compositors.

## Verification

After changing pins or the profile, run the builder and release exporter, then:

```sh
node tools/web-template/browser-check.mjs --export build/web \
  --output /tmp/new-web-check --browser /path/to/google-chrome
```

The harness requires Node 22 and a Chrome/Chromium executable. It serves the export locally,
uses a fresh temporary browser profile, blocks external analytics, bounds each wait and records
engine errors, screenshots and results in a new output directory. It checks title startup,
keyboard input, an IndexedDB save and its reload with the same run seed and one nerve spent,
the ordinary summary-to-day-2 transition, days 8/14, and the escape interior. Query-driven later days are separate boots, not a claim of
playing through all days. Inspect the images for rendering and baked version metadata too.

The `web-template` workflow performs the same custom build/export/browser check without any
publication permission. It runs for changes to the build inputs, and supports manual dispatch;
ordinary unrelated PRs do not download the compiler. Deployment remains a version-tag operation
gated by the tagged commit's required game test check. It uses the same verified template cache
and runs the browser check on the exported game before publishing the Pages artifact.

The engine comparison under `docs/evidence/web-package-size-2026-09-30/` records source/toolchain
provenance, local gzip sizes and browser results. Local gzip bytes are not observed CDN transfer
sizes, and the browser check is compatibility evidence, not a load-time benchmark.

The official [size guide](https://docs.godotengine.org/en/stable/engine_details/development/compiling/optimizing_for_size.html),
[Web compilation guide](https://docs.godotengine.org/en/stable/engine_details/development/compiling/compiling_for_web.html)
and [build-profile guide](https://docs.godotengine.org/en/stable/tutorials/editor/using_engine_compilation_configuration_editor.html)
describe the mechanisms; the pinned engine source decides which options exist.
