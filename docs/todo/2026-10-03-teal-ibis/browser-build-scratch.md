# Find what the Web-template build leaves outside its own work directory

The browser-run half of the scratch cleanup is built ([the record](../../decisions/2026-10-03-teal-ibis-2.md)):
headless Chrome's code-signing copy is no longer made, and a copy is removed only when this run's
own browser provably held it. The browser **build** half is not. `tools/build-web-template.sh`
works in `build/web-template-work/`, but the Emscripten/LLVM link step, emsdk and the uv cache can
write outside it (`$TMPDIR`, caches in the home directory). During the one measured cache-miss
build, free space fell by about 6.3 GiB at its lowest, 2.3 times the `du` peak inside the work
directory, and ended about 3.55 GiB below where it started while 7 MiB was kept; other work
overlapped that window, so the dip proves no leak and explains nothing either. Rerun the build on a
quiet disk with `TMPDIR`, `EM_CACHE` and `UV_CACHE_DIR` pointed inside the work directory, then
compare `du` of everything outside it and the APFS local snapshots (`tmutil listlocalsnapshots /`),
which keep deleted blocks counted against free space.

**Proposed, not asked for:** what is found is cleaned by the same ownership rule as the browser
copy: removed only when this build provably made it, otherwise reported with the missing evidence.
