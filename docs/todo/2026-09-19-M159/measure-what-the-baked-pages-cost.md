**Measure what the baked pages cost, on the run log's own lines.** A page writes one
`texture` line when it is read — `atlas page '<group>' loaded in the <moment>: <ms> ms,
<W> x <H>`, the moment being `startup`, `day brief`, `escape` or `OUTSIDE` — and one when
its last reference goes, `atlas page '<group>' released after <s> s: <W> x <H>`; the boot
prints how many pages it holds from startup and in how long. Collect those on the
threadless web export and on the phone as well as the desktop, with the page sizes as the
memory figure, and compare against the baseline retained from the runtime packer
(`DECISIONS.md`, M159 and M171). Distinguish the CPU read from GPU completion where the
platform allows it. No result here is assumed to explain the older laptop hitch, which
predates every atlas path, and the native-host evidence supports neither worker jobs nor
larger pages.
