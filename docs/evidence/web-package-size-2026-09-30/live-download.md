# Live web download inspection — September 30, 2026

This inspection reads the deployed v0.21.2 page and its three main binary/script responses.
It does not export a modified game or measure a browser's time to first play. HTTP observations
are captured at 2026-10-01 00:53–00:54 UTC (September 30 in America/New_York).

## Transfer sizes

| File | Decoded bytes | HTTP body bytes transferred | Encoding |
| --- | ---: | ---: | --- |
| Engine WebAssembly | 39,514,754 | 10,248,949 | gzip |
| Game package | 3,574,448 | 3,395,992 | gzip |
| JavaScript loader | 279,815 | 69,442 | gzip |
| Total for these three files | 43,369,017 | 13,714,383 | |

MB in discussion means decimal millions of bytes. The total excludes HTML, icons, analytics,
HTTP/TLS overhead and any browser-specific additional requests. These are successful fresh
unconditional curl responses with compression accepted, not a measured browser waterfall or
warm-cache transfer. A browser may negotiate a different encoding, validate cache or reuse
cached responses. The downloaded bytes match the page's package and WebAssembly fileSizes.

All three responses carry `Cache-Control: max-age=600` and `Vary: Accept-Encoding`. The page
names release-versioned URLs. The engine supplies about 74.7% of these three compressed bodies;
the game package supplies 24.8%. Lazy scene preparation operates after this package is available
and does not on its own avoid downloading its contents.

## Package contents

The downloaded pack's format-4 directory contains 596 entries. Every entry's recorded length
and MD5 digest is checked against its payload. Payload totals are 3,525,852 bytes; the remaining
48,596 bytes are package structure/alignment. Its header identifies Godot 4.7.2.

| Payload group | Bytes |
| --- | ---: |
| `tests/` (300 entries) | 1,603,734 |
| `src/` | 916,730 |
| `.godot/` (imported resources and metadata) | 902,200 |
| `assets/` | 69,328 |
| Icon source and import sidecar | 25,836 |
| Compiled project settings | 7,212 |
| Scene remaps | 812 |

The test entries account for 44.9% of the full decoded package. This live inspection supplies
the baseline for the companion export comparison; its own bytes are not a measured saving.
The v0.21.2 export preset uses `all_resources` and does not exclude tests. Production references,
resource/class registration and an exported-game boot must be checked before accepting such a
change. The companion comparison uses a rebuilt export, not a subtraction claimed as transfer
savings. Its fixed local gzip result is distinct from these observed CDN bodies.

Across all paths, texture payloads (`.ctex`) total 840,374 bytes. The largest is the events atlas,
485,706 bytes. Compiled/source scripts total 2,506,464 bytes. These on-disk compressed texture
sizes do not describe decoded pixel/GPU residency.

The existing `tools/audit-pck.sh --fatal` passes against the downloaded pack: it finds eleven
atlas groups, no orphan pages, and no constituent duplicate among the current membership's
712 source members. The pack and membership are from different checkpoints, so this is the
existing audit's precise comparison, not proof that the export carries no unnecessary resource.

## Reproduction and limits

Fetch `https://nappy.josuakrause.com/` and identify its `GODOT_CONFIG` before measuring the latest
release. To repeat this checkpoint, use `https://nappy.josuakrause.com/v0.21.2/index.wasm`,
`index.pck` and `index.js`. For each, curl's `--compressed --dump-header` retains response
headers; `--write-out '%{size_download}'` records compressed HTTP body bytes while the output
file is decoded. Check decoded lengths and SHA-256 against the snapshot before comparing.
Run the retained package reader on the downloaded pack; it validates payload checksums and
derives the directory breakdown. The reader never executes downloaded contents.

Retained evidence is compact metadata, the directory breakdown and the reader. The 43 MB of
downloaded binaries remain scratch and are not committed. Request elapsed times are deliberately
excluded from loading-speed claims: these concurrent downloads on a desktop connection do not
measure a serial critical path, phone connection, compilation, GPU upload or first playable frame.

The scenery investigation and this download inspection answer distinct parts of loading.
Neither establishes that most human players see only a small fraction of a day; that requires
representative player trajectories or additional explicitly labeled synthetic coverage evidence.

## Engine reduction candidate

The player asks whether the engine is modular and unused content can be excluded. Godot supports
compiling custom export templates with unwanted modules/classes disabled; changing the game
package's export filters does not change the engine binary. The official
[size guide](https://docs.godotengine.org/en/latest/engine_details/development/compiling/optimizing_for_size.html)
and [build-profile guide](https://docs.godotengine.org/en/stable/tutorials/editor/using_engine_compilation_configuration_editor.html)
describe this workflow. Automatic feature detection needs an audit for dynamically used features.

The current preset selects the stock threadless template and has no custom template path. A
first candidate is a version-matched 2D-only template, with further removal of unused 3D/XR,
navigation, networking or media modules only after checking their dependencies and actual
runtime use. A narrow source search finds no direct Node3D/3D physics, engine navigation-agent,
ENet/WebSocket/WebRTC or video-player references under src/scenes; absence from that search is
not a complete dependency audit or proof that a module is removable. The game uses
JavaScriptBridge for browser integration and saves, JSON for state/atlas metadata, 2D physics,
TileMapLayer, image composition and shaders; those capabilities must survive.

The [Web compilation guide](https://docs.godotengine.org/en/stable/engine_details/development/compiling/compiling_for_web.html)
describes building the replacement template with Emscripten and SCons and retaining threadless
operation. No engine build/profile is implemented or benchmarked in this inspection. A future
comparison must pin the matching engine source/toolchain, compare gzip sizes to the stock build,
and exercise the exported game, saves, title/day/escape scenes and browser integration. This is
a candidate for reducing the largest download component, not a promised percentage saving.
