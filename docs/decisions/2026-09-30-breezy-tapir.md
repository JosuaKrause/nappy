# breezy-tapir — Reduce the Web download with test exclusion and a smaller engine runtime · 2026-09-30

The player asks to inspect the downloaded package, identifies test exclusion as an easy win,
and requests unused Godot modules be disabled in the same PR as a build-time change. Their
words are in [cozy-walrus, exclude tests from the downloaded game](../playtests/2026-09-30-cozy-walrus.md).
The [package report](../evidence/web-package-size-2026-09-30/README.md),
[live download](../evidence/web-package-size-2026-09-30/live-download.md) and
[engine comparison](../evidence/web-package-size-2026-09-30/engine-comparison.md) retain the
inputs, hashes, exact measurement conditions and reproduction.

The live v0.21.2 download on September 30 contains 13,714,383 gzip body bytes across the engine,
loader and game package, excluding HTML, icons, analytics and HTTP overhead. The engine is
about three quarters of that transfer. The package contains 300 direct test entries. The
same-source test-filter comparison reduces PCK bytes from 3,574,448 to 1,935,752, and fixed
local gzip from 3,394,534 to 1,803,116, a 46.88% compressed reduction. Local tests remain intact.
The artifact audit rejects test paths and literal test-resource references, preserving its
duplicate-atlas and orphan-page checks. The filtered artifact has neither tests nor those
references; native exported-package boot also reaches day 1.

A custom Web engine runtime, called an export template by Godot, removes audited unused 3D,
3D physics, XR, navigation, model-import, networking, media and alternate image-format modules.
The normal editor, native tests and debug Web export retain the stock engine. The release
runtime retains advanced text, fonts, 2D physics, tile maps, shaders, PNG/WebP and runtime image
composition, JSON, saves and JavaScriptBridge. All twelve exported compressed textures contain
WebP payloads; decoder removal is checked against actual artifacts, not just source searches.
The exact conservative profile is a build choice open to revision when runtime needs change.

The reproducible build pins Godot 4.7.2 source, Emscripten 4.0.20 and SCons 4.9.1, verifies
source/bootstrap archives, and caches a threadless release template keyed by build inputs and
host. Export verifies its receipt and content hash, rejecting missing, stale or corrupt output.
Generated sources and binaries stay outside Godot imports and version control. Only release
builds need the custom runtime. A separate workflow compiles, exports and checks it in Chrome
without publishing; deployment uses the same recipe and browser check while preserving the
existing tag and test gates.

With identical filtered PCKs, fixed gzip shrinks the engine from 10,054,758 to 7,159,098 bytes
and the loader from 68,471 to 62,334: 2,901,797 bytes saved, with the engine alone 28.8% smaller.
The compared PCK is 1,935,816 bytes, or 1,803,160 under fixed gzip. Its Web-only version-lookup
guard accounts for a different source checkpoint from the earlier filter experiment. These
local figures are not added to the differently compressed live CDN transfer. The comparison
measures the validated replacement recipe, not individual modules or an observed loading-time
improvement. An exploratory Emscripten 6.0.1 build is excluded; the accepted compiler matches
the stock runtime's reported version.

Both stock and custom runtimes pass the same real WebAssembly browser checks with disposable
profiles and blocked analytics: title, keyboard play, persisted save and same-seed reload with
one nerve spent, a won day followed through its summary into day 2, later-day resource boots
and the escape interior. Textures, text and baked version/commit metadata render in inspected
screenshots. These are headless desktop Chrome/SwiftShader checks, not phone measurements or
a complete campaign/escape finish. Both retain the same pre-existing overlapping FS.syncfs
warning during save/reload; persistence succeeds and no engine error or JS exception remains.

The stock control reveals version lookup trying to execute Git on Web, where subprocesses are
unsupported. A narrow Web guard returns the existing unknown-source fallback and preserves
baked export metadata and native Git lookup. The browser harness records startup failures,
bounds connection waits and cleans up disposable resources, including invalid-browser cases
identified during independent review. No save-system or gameplay redesign is included.

Local validation includes import/boot, the existing pause and telemetry suites, CLI regression
checks under Node 22, lint, artifact audits, template-receipt checks, evidence arithmetic/hashes
and both browser controls. Local game testing is partial; the full suite belongs to CI. Compact
evidence is seven files totaling 88,119 bytes; expanded browser/compiler artifacts stay in scratch
and CI artifacts. Both requested implementation items leave the queue together. No release or
merge is performed by this work.
