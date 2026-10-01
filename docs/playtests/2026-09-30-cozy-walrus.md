# Playtest cozy-walrus — Exclude tests from the downloaded game

2026-09-30.

## Context and requested inspection

While investigating faster loading and lazy scenery preparation, the player asks:

> for the loading investigation a start would be to inspect how big the package is that is getting downloaded

The assistant reads the deployed v0.21.2 responses and reports 13.71 MB transferred with gzip
across the engine, game package and loader. It reports 1.60 MB of test payloads inside the
decoded game package, about 45% of that package, and proposes excluding tests with the exact
compressed saving verified against a rebuilt export.

> test file exclusion would be an easy win

The assistant will exclude tests, verify the exported game starts, measure the resulting size,
and add a package audit that rejects test resources. The audit is the assistant's proposed
regression guard rather than a mechanism specified by the player.

## Engine modularity

> is the engine modularized? can we exclude unused content?

The assistant confirms that Godot supports custom export templates with unused modules and
classes compiled out. It identifies 3D as a candidate, with other modules requiring an audit,
and says the compressed engine saving needs measurement. The package-exclusion work does not
change the engine template.

## Permission

During the same investigation the player explicitly authorizes branch work:

> you can commit and push and create prs

## The same PR includes the smaller engine build

After the assistant confirms that Godot can compile unused modules out of a custom export
template, the player asks:

> what about turning off unused godot modules? does that go into 443 as well?

> that's also only necessary for the build, really

The assistant agrees to include this in the same download-reduction PR, retaining the full
development editor and making the Web export template smaller through a reproducible build
profile. The work includes compressed-size measurement and exported-game compatibility checks.

> mark PRs a ready if you're done with them so I can review as well

The assistant marks the completed scenery investigation ready and keeps this expanded loading
PR draft until its custom engine build is verified.
## Review of the completed download changes

The player reviews the test exclusion, custom runtime and browser evidence. Their full feedback
below defines the module-restoration guidance and deployment corrections; measurements stay
unchanged.

> Review of 4940a8c4 — not ready yet. One CI fix, one wording addition, two small cleanups.
>
> **1. CI: `gates` fails.** `tools/ci_code_pr_queue.py` wants a closed queue item, but
> breezy-tapir (keep tests out of the web download) was filed and closed inside this PR, so
> nothing under docs/todo/ is deleted relative to main. Add to the description:
> `No queue item: breezy-tapir was filed and closed inside this PR; its record is docs/decisions/2026-09-30-breezy-tapir.md`
>
> **2. Say which modules are dropped, and how to bring one back.** The removal table in
> `tools/web-template/README.md` says why each group is gone. Please add:
>
> - **A "needed again when" column** naming the game feature that would bring each group back.
>   For example: Ogg/Vorbis or MP3 for streamed music (the per-act beds in M100, small, real, and
>   nobody's — its audio item); 2D navigation for NavigationAgent2D/NavigationRegion2D; noise for
>   FastNoiseLite/NoiseTexture2D; ZIP for ZIPReader/ZIPPacker; TLS/networking for HTTPRequest or
>   WebSocket; 3D for any 3D node.
>   WAV sound effects need nothing, so say that too.
> - **A "Turning a module back on" section with the steps:**
>   1. Delete its line from `profile.args`. Godot's default is on. Check the module's own
>      `config.py` for modules it depends on, which also need to come back.
>   2. Run `tools/build-web-template.sh`. The cache key changes, so it rebuilds.
>   3. Run `tools/export-web.sh` and `browser-check.mjs`.
>   4. If the browser check can't see the feature (it can't hear audio), extend it until it can.
>   5. Put the new gzip engine size in the PR.
>
>   Note that the `web-template` workflow reruns on its own, since `profile.args` is in its paths.
> - **Why this matters:** the editor, the tests and `serve-web.sh` (a debug export) all use the
>   stock engine. A feature that needs a dropped module works everywhere I'd try it and fails
>   only on the published site.
>
> Then point at that section from the places the work will start:
>
> - **The sound-effects skill**, which loads automatically on any `.ogg`/`.mp3` edit: one sentence
>   saying the release Web engine has no Ogg/Vorbis or MP3 decoder until it is turned back on.
> - **The godot skill**, which loads on every `.gd` edit: one sentence listing the dropped
>   feature families with a link to the section.
> - **The M100 audio item:** one line saying streamed music needs the decoders turned back on in
>   the release engine.
> - **The header comment of `profile.args` itself**, plus the README's "Verifying a build"
>   paragraph: adding a feature may need a line removed, not only that changing the profile
>   needs a rebuild.
>
> **3. Evidence README.** `docs/evidence/web-package-size-2026-09-30/README.md` says in its Limits
> section "the browser runtime check remains inconclusive" and "The change does not alter engine
> modules", while its header says the engine comparison passes. Scope both sentences to that first
> experiment.
>
> **4. Deploy permissions.** The build job now downloads and runs the Emscripten toolchain while
> inheriting the workflow-wide `pages: write` and `id-token: write`. Move those two onto the job
> that publishes.
>
> Optional: GitHub drops caches unused for a week, so a release tagged after a quiet week compiles
> Godot inside the deploy job. A sentence in the web-template README is enough.
>
> No need to rerun the size measurements. I checked the arithmetic, the evidence footprint and
> the release browser gate.
