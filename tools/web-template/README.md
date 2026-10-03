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
`build/web-template-work/<key>/`; successful builds remove that scratch after writing the final
archive and receipt. Failed builds retain it and print its path for diagnosis or retry. An owned
lock under `build/web-template/` refuses concurrent builds in one checkout; an interrupted lock
needs its recorded process checked before removal. Before a cache miss downloads anything, the
builder checks that `build/`'s volume has room for the build's measured peak plus the reserve
`tools/lib_disk_headroom.sh` keeps free, and refuses with the shortfall when it does not. The
builder writes `build/.gdignore` before extracting any source, so Godot cannot import its
compiler or exported binaries.

## Module choices

`profile.args` is the complete explicit removal list. These choices are audited against the
pinned source's `SConstruct`, `platform/web/detect.py`, module `config.py` dependencies and the
game's scripts, scenes, atlas imports and actual exported texture headers. The profile does not
use automatic class pruning: dynamically created nodes and resources remain available.

| Removed group | Why the runtime does not need it | Needed again when |
| --- | --- | --- |
| 3D, 3D physics, XR; CSG, grid maps, model importers, mesh optimization, lightmapping and decomposition | The game uses Node2D, CanvasItem, TileMapLayer and 2D collision shapes. Its height/occlusion presentation does not use a 3D scene or physics server. | Any 3D node or resource, 3D physics or navigation, XR feature, or runtime model/mesh import enters the release. Restore the matching top-level `disable_*` switches as well as the modules the feature uses. |
| 2D/3D navigation servers and modules | City routes and pedestrian paths are computed by the game's street/route code. The ground TileSets supply drawing and collision, with no engine navigation regions or agents. | A release scene uses `NavigationAgent2D`, `NavigationRegion2D` or their 3D equivalents. For 2D, remove both `disable_navigation_2d=yes` and `module_navigation_2d_enabled=no`. |
| ENet, multiplayer, WebRTC/WebSocket, UPnP, TLS and JSON-RPC modules | Runtime browser integration uses JavaScriptBridge and browser APIs, not Godot network peers. JSON itself is core and remains enabled. GDScript's optional editor language-server dependencies are not required by a release runtime. | A feature uses `WebSocketPeer`, ENet, WebRTC, multiplayer replication, UPnP, JSON-RPC or an explicit TLS peer. Adding `HTTPRequest` or `HTTPClient` still requires a release-profile audit and browser coverage, but on Web their backend uses browser `fetch` and browser-managed TLS, so HTTP alone does not require `mbedtls`. |
| Theora, Ogg/Vorbis, MP3, interactive music and camera modules | The exported resource package contains no audio/video streams or camera feed. Core audio remains available. | Streamed Ogg/Vorbis or MP3 music is added, including the per-act beds queued in M100, small, real, and nobody's; Theora video, `AudioStreamPlaylist`/interactive streams or camera input also restore their matching module. WAV sound effects need no module restoration. |
| ASTC/Basis/ETC packing and BMP/DDS/HDR/KTX/TGA/EXR loaders | Current exports use lossless WebP-backed textures. | A release artifact carries one of these image or GPU-compressed texture formats, or runtime code loads one. Restore the format's loader and every dependency its `config.py` declares. |
| Procedural noise | The game has no runtime noise resource. | A release scene or script uses `FastNoiseLite`, `NoiseTexture2D` or `NoiseTexture3D`. |
| ZIP reader | The PCK loader is core and remains enabled; no runtime code opens or writes ZIP archives. | A release feature uses `ZIPReader` or `ZIPPacker`. |

The advanced text server, FreeType, MSDF generation, SVG/JPEG/WebP support and core PNG decoder
remain enabled. Their dependencies preserve the existing typography and image behavior.
The regular 2D renderer, shader language, image composition, physics, GUI controls, GDScript,
JSON, FileAccess, JavaScript evaluation and persistent browser filesystem remain enabled.
TileMapLayer is core in this source version; the profile does not invent a tilemap module flag.

## Turning a module back on

The editor, native tests and `tools/serve-web.sh` use stock engines. A feature that depends on a
removed capability can therefore work in every local place where it is tried and fail only in the
published release. Restore release capabilities as part of adding the feature:

1. Delete every matching opt-out line from `profile.args`; Godot enables these features by
   default. This includes a top-level `disable_*` switch and a `module_*_enabled=no` line when the
   profile has both. Read the pinned source's `modules/<name>/config.py` and restore the dependencies
   it declares too: for example, Vorbis adds Ogg, Theora adds Ogg and Vorbis, KTX adds Basis
   Universal, and FBX adds glTF.
2. Run `tools/build-web-template.sh`. The profile is part of the exact cache key, so the changed
   inputs rebuild the release template.
3. Run `tools/export-web.sh`, then run `tools/web-template/browser-check.mjs` against that release
   export as shown under Verification below.
4. Extend validation until it actually exercises the new feature. The current browser harness
   cannot hear audio, so audio work needs browser load/error coverage plus retained evidence that
   somebody listened to the exported feature.
5. Measure the rebuilt WebAssembly engine with the same fixed-gzip method as the existing engine
   comparison and put the new gzip engine size in the pull request.

Changes under `tools/web-template/`, including `profile.args`, automatically trigger the
`web-template` workflow. Under GitHub's
[default cache retention](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#usage-limits-and-eviction-policy),
an unused template cache can be evicted after more than seven days; a later release then compiles
the template in the deploy build job.

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
engine errors, screenshots and results in a new output directory, which is the caller's and is
never removed; the harness downloads and extracts nothing. It checks title startup,
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

## Browser scratch

The profile is not the only thing a browser run leaves. On macOS, Chrome copies its own
application bundle into `<user temp root>/X/<bundle id>.code_sign_clone/code_sign_clone.XXXXXX/`
at launch, so an update installed while it runs cannot break its signature. The copy is about
2 GiB allocated (copy-on-write, so removing it returns less than that); Chrome removes it after a
graceful close and leaves it behind when it is stopped with a signal. So the harness:

- launches Chrome with `--disable-features=MacAppCodeSignClone`, which makes no copy at all
  (other platforms ignore the unknown feature name);
- closes the browser through the protocol's `Browser.close` and waits for it to exit, falling back
  to `SIGTERM` and then `SIGKILL` only when it does not, and removes the profile after the exit;
- records, every two seconds while the browser runs and once more before closing it, every clone
  `lsof` shows a process of its own browser holding a file inside, with that process and path as
  the evidence (`browser-scratch.mjs`);
- after the exit, waits briefly for Chrome's own removal, then removes a recorded clone only when
  every recorded process has exited and `lsof` finds nothing on the system still holding it;
- reports, and leaves, a clone that appeared during the run without that evidence, and never looks
  further at a clone that existed before it started.

`scratch.json` in the output directory says how the browser was stopped and lists what was
removed, kept (with the reason) or not attributed (with the evidence missing). A name or a date
alone never makes a directory the run's. `browser-scratch.test.mjs` checks these rules against
fixture directories held open by a stand-in process, never against a real browser or system
directory; the `web-template` workflow runs it with `node --test`.
