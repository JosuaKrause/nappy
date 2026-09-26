## M147 — Every picture loaded before it is needed · built 2026-09-14

*(2026-09-14, [PLAYTEST-75](../playtests/PLAYTEST-75.md): "I feel whenever a new entity/image/
sprite is shown there is a visible stutter. this would be an argument *for* a full atlas so
sprites don't need to be loaded in late".)* Two agent commits on `feature/m147-warm-textures`,
reviewed on the PR.

**What was true.** `TextureResolver.resolve()` loaded each picture's PNG transfer from disk
the first time that picture was drawn, inside the frame, once per distinct picture per run;
the prop, rig and ground transfers (19, 35 and 72 of them) were loaded that way, and
`EntityHalo` built its shader material at the first halo, which the Compatibility renderer
compiles at first draw. **Not the events' pictures**, corrected the same evening: those are
`preload`ed SVG imports with no PNG transfers at all, loaded when the script loads at boot,
so they were never late — the warm test that resolves every texture `EventInstance` preloads
passes because there is nothing there to load, not because the pass loaded it.

**What it is.** First, the probe: the resolver counts every transfer it loads (`load_count()`)
and the `spike` line's context says `N pictures loaded` when the count moved in the spike
frame, beside her tile and the live event count. Then the fix: `TextureResolver.warm()`,
called from both boot paths before the first day, walks the transfer root with `DirAccess`,
derives each PNG's source SVG, and runs `resolve()` on the pair so the cache is full before
play — 86 pictures in about 180 ms on the desktop, printed beside "city generated". Not the
ground manifest, which lists only the ground's own bases and components; `DirAccess` was
checked against a real exported pack, whose listing carries only the `.png.import` names, so
either name is trimmed to one candidate. Under `--svg` it does nothing. The halo's shader is
compiled by a real draw: Godot 4.7 has no precompile for the Compatibility renderer (the
pipeline cache is a RenderingDevice feature), so a throwaway node at world origin draws one
frame with the shared material and is freed two `process_frame`s later — at the origin, since
an off-screen canvas item is culled and compiles nothing, and no camera exists yet at that
point in either boot. Both boot paths are coroutines now; `_process`'s existing guard on the
player and baby covers the two-frame gap. Tests: after `warm()`, resolving every texture
`EventInstance` preloads (read off its constant map) moves the count by zero; under `--svg`
it loads nothing; a late load names itself in the spike line.

**Measured, on the headless rig** (`tools/shot.sh`, seed 3265820891, six seconds, `--spikes`):
with the probe alone, seconds two and three each carried a spike (29.0 and 25.5 ms against
means of 13.2 and 12.1) and frames two to four read 74 to 78 fps with worst frames of 29.0,
25.5 and 19.8 ms; with every picture warm the two spikes are gone and the same seconds read
85 to 90 fps with worst frames of 18.3, 11.9 and 11.1 ms. Neither run's spike line carried
`pictures loaded`: the loads land in the first frame of a report interval, which the spike
rule never makes a candidate, so the field's proof is its test. A 74.5 ms spike at 6.1 s in
the warm run says "nothing else changed" — the hitch M138 and M144 describe is still there,
just no longer joined by the late loads. The laptop's reading is the `REVIEW.md` item.

**On the laptop, the hitch is still there with every picture warm.** *(2026-09-14, playtest 75,
the stutter branch on the laptop.)* A run with "86 pictures warmed in 233 ms" at boot read 85
to 91 fps with a worst frame of 24 to 26 ms in every second outside its bursts — the same
frame v0.10.6 read — so the late loads were the headless rig's early spikes and not the
laptop's once-a-second frame. What the same run also showed: a burst's per-frame readback
makes every frame 60 to 76 ms, and in such a second no bar is twice the mean, so the graph's
amber disappears under a burst while its red does not; the player read that as the burst
preventing spikes. What is left for the hitch is what M138 listed minus the pictures: the
present path between the engine and the driver (OpenGL on Metal), or something in the game
on a cadence the `spike` line, run with `--spikes`, would catch as "nothing else changed" —
which is exactly the line that would send the search to the driver side.

**Choices made where the entry was silent, open to overturn.** The ground's own component PNGs
are warmed too, harmlessly; a transfer with no loadable source is skipped with a warning
rather than failing the boot; the escape boot prints its warm line alone since it has no
"city generated" line to sit beside.
