**Measure what the baked pages cost, on the run log's own lines.** A page writes one
`texture` line when it is read — `atlas page '<group>' loaded in the <moment>: <ms> ms,
<W> x <H>`, the moment being `startup`, `day brief`, `escape` or `OUTSIDE` — and one when
its last reference goes, `atlas page '<group>' released after <s> s: <W> x <H>`; the boot
prints how many pages it holds from startup and in how long. Collect those on the
available native and desktop threadless web targets, with the page sizes as the
memory figure, and compare against the baseline retained from the runtime packer
(`DECISIONS.md`, M159 and M171). Distinguish the CPU read from GPU completion where the
platform allows it. No result here is assumed to explain the older laptop hitch, which
predates every atlas path, and the native-host evidence supports neither worker jobs nor
larger pages.

The phone check is a quick eye test; phone timing collection is optional and does not
block this baseline or subsequent attribution work
([sunny-chipmunk](../../playtests/2026-10-03-sunny-chipmunk.md): "phone profiling would be a
nice to have but honestly a quick eye test is good enough"). The possible methods in
[the stutter investigation](profile-the-current-phone-build-only.md) are retained ideas,
not required device setup. An eye test judges perceived smoothness, not exact bottlenecks.
