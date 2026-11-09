# A job's storage cleanup

Part of **session-cleanup** (step 6b). Read it before removing anything a job did not record as its
own, after a browser run, and before multiplying worktrees or starting a large import, build or
capture batch: it says what counts as a job's own scratch, how worktrees are reviewed, what a
browser run leaves behind, and how free space is measured.

**A completed job cleans up its own scratch immediately, and the session verifies that it did.**
Temporary placement is not proof that a directory is disposable. Record exact scratch paths,
their owner and retained outputs when starting a worktree, build, capture or browser run. Scripts
use a scoped `EXIT` trap or `finally`, stop and wait for their child processes, retain diagnostic
logs/results and requested evidence, then remove only their own intermediate files. On failure,
preserve the evidence needed to diagnose it and name any retained directory and its next cleanup
step; do not silently leave a complete checkout or compiler tree behind as "temporary".

**Review worktrees with `tools/prune-merged.sh --all`.** It is a read-only candidate inventory;
`--all --apply` applies its safety checks again. Run the inventory through the same wrapped line as
the apply, which **committing** ("Branches") gives with its role, since the write guard denies the
script bare in every shape, its read-only ones included. Finished agents explicitly release their brief
with `cleanup: ready` after stopping and preserving useful ignored artifacts, and a released brief
goes with its branch when the script retires it. Locked, dirty,
unpushed or actively owned work stays. An unmerged but finished job may remove its own clean
scratch checkout only after confirming pushed recovery and retained evidence; retain the branch.
Never force-remove or unlock another job's checkout to make cleanup succeed.

**Browser runs own more than a profile.** Track downloaded/extracted browser copies, build trees,
profiles and signing-clone leftovers attributable to the run, including operating-system temp
locations outside `/tmp`. Stop the owning processes and check exact paths before removing them.
A browser's installed application, the player's regular profile and arbitrary OS/application
caches are not job-owned scratch. A one-time request to remove identified directories does not
authorize future blanket deletion of the application's temporary area.
`tools/web-template/browser-check.mjs` follows this for macOS Chrome's code-sign clone, a copy of
the browser's own bundle that Chrome removes after a graceful close and leaves behind when it is
killed: it launches Chrome with the clone disabled, closes it through the debugging protocol and
waits for it, removes only a clone `lsof` showed its own browser holding once nothing holds it,
and writes what it removed, kept or could not attribute to `scratch.json` in its output.

**Check actual free space before and after.** `du` gives allocated sizes that may overlap shared
copy-on-write blocks; it does not promise exclusive reclaimable bytes. `df` on each destination
volume measures the available headroom. Before multiplying worktrees or producing large imports,
builds or capture batches, compare estimated peak use with free space and a stated reserve.
When the peak is unknown, start with a bounded measurement or reuse an existing checkout rather
than claiming an arbitrary fixed threshold makes the job safe. The tools that allocate a batch
make that comparison themselves through `tools/lib_disk_headroom.sh` (**using-tools** lists them),
whose per-job estimates are peaks measured with `tools/measure-disk-peak.sh`, and refuse an
unmeasured job; a worktree made by hand compares the same file's worktree estimate with `df`.
Keep unrelated tracked archives out of new worktrees through sparse checkout (**orchestrating**).
