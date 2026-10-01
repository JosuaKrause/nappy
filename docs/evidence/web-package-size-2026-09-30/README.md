# Web package test exclusion

This file records the package-filter experiment. The subsequent
[custom engine comparison](engine-comparison.md) records the smaller Web runtime and passing
stock/custom browser checks, including saves and a real day transition.

## Question

How much of the exported web resource package consists of repository tests, and can those files be excluded without breaking the exported game?

## Result

The web export preset excludes `tests/*`. On the same Godot 4.7.2 source tree, resources and export templates, this reduces the PCK from 3,574,448 bytes to 1,935,752 bytes, a reduction of 1,638,696 bytes (45.84%). Fixed local `gzip -9 -n` output falls from 3,394,534 bytes to 1,803,116 bytes, a reduction of 1,591,418 bytes (46.88%).

The filtered package passes the package audit and boots through day 1 with Godot loading that exported PCK as its main pack. The audit finds no direct `tests/` path and no literal `res://tests/` reference in another packed file.

## Measurement

The baseline revision is `e71f2abd066e5361fdf03753eacf72618bdfcfa5`. The filtered revision is `3083308a77ff15ec77196f7b731135fdb032429d`. Both exports use Godot `4.7.2.stable.official.ed1daf0bf`, the same local export templates, the `measurement` release tag and macOS arm64. Each checkout runs `./tools/check.sh` before `RELEASE_TAG=measurement ./tools/export-web.sh`.

| Measurement | Baseline | Filtered | Change |
|---|---:|---:|---:|
| PCK bytes | 3,574,448 | 1,935,752 | -1,638,696 (-45.84%) |
| `gzip -9 -n` bytes | 3,394,534 | 1,803,116 | -1,591,418 (-46.88%) |
| Packed files | 596 | 292 | -304 |
| Direct `tests/` paths | 300 | 0 | -300 |
| Other packed files containing literal `res://tests/` | 6 | 0 | -6 |
| Atlas source members still packed | 0 | 0 | 0 |
| Orphan atlas pages | 0 | 0 | 0 |

The baseline PCK SHA-256 is `6f6917e90c8fc7284d80816d2136c42dd6f800208ebdef709479230fcb02ea42`. The filtered PCK SHA-256 is `8221da35795b10c51a3a910c71b9e80e3488a1622cf269ebd6dbdc34fc1378c7`.

The six baseline references outside direct test paths include exported test or probe scenes and Godot's global class cache. This is a focused guard for direct paths and plain packed references. It does not prove that every possible compressed or compiled script dependency is absent.

## Exported runtime check

The filtered artifact exits successfully after this bounded headless boot:

```sh
/Applications/Godot.app/Contents/MacOS/Godot \
  --headless \
  --main-pack build/web/measurement/index.pck \
  --quit-after 120 \
  -- \
  --no-save
```

The run reaches day 1 and reports no missing resource or class error. This loads the actual exported PCK through the matching native Godot runtime. A headless Chromium attempt downloads the exported HTML, JavaScript, WebAssembly and PCK and reaches Godot's full progress splash, but does not advance to a gameplay frame within the bounded run. Browser boot therefore remains inconclusive.

## Reproduction

Use separate scratch worktrees so generated imports and exports cannot cross between revisions. From the repository root:

```sh
scratch="$(mktemp -d)"
git fetch origin refs/pull/443/head
git worktree add --detach "$scratch/baseline" e71f2abd
git worktree add --detach "$scratch/filtered" 3083308a

cd "$scratch/baseline"
./tools/check.sh
RELEASE_TAG=measurement ./tools/export-web.sh
gzip -9 -n -c build/web/measurement/index.pck > "$scratch/baseline.pck.gz"
shasum -a 256 build/web/measurement/index.pck
wc -c build/web/measurement/index.pck "$scratch/baseline.pck.gz"

cd "$scratch/filtered"
./tools/check.sh
RELEASE_TAG=measurement ./tools/export-web.sh
gzip -9 -n -c build/web/measurement/index.pck > "$scratch/filtered.pck.gz"
shasum -a 256 build/web/measurement/index.pck
wc -c build/web/measurement/index.pck "$scratch/filtered.pck.gz"
"$scratch/filtered/tools/audit-pck.sh" \
  "$scratch/baseline/build/web/measurement/index.pck"
"$scratch/filtered/tools/audit-pck.sh" \
  "$scratch/filtered/build/web/measurement/index.pck" --fatal
```

The generated packages are not retained in this evidence directory. The commands recreate them from the recorded revisions.

## Limits

The fixed local gzip comparison makes compression deterministic, but it is not a CDN transfer measurement. No release upload or CDN response is measured here. The result does not claim a browser load-time improvement, and the browser runtime check remains inconclusive. The compatibility evidence is the successful native runtime boot from the exported PCK plus the bounded path and literal-reference audit. The change does not alter engine modules or production game code.
