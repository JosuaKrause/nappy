# Playtest snowy-newt — Disk accumulation and safeguards

2026-10-03.

During scene implementation the player reports:

> hmm, I'm getting warnings about disk usage running out

After the assistant says it is checking worktrees and generated caches:

> are you not cleaning up test runs etc.?

The player requests a storage investigation and durable record:

> can you check where all the storage is used up?

> record where things accumulate

> so we can build safeguards

> to not fill the harddrive up

After the assistant identifies about 1 GB of tracked evidence per worktree:

> are you not checking out shallow with depth = 1 for worktrees?

The assistant explains that worktrees share Git history and do not have independent
clone depths; sparse checkout can avoid materializing unrelated tracked evidence.

On using the existing worktree retirement script for safeguards, the player says:

> you can edit prune merged

On other storage accumulators:

> besides that any other accumulations of data?

On attribution of the measured temporary storage:

> tmp was all from you?

> what about private var folders?

After the storage and Chrome-clone breakdown, the player asks:

> let's clean up tmp and make sure it's always getting cleaned up when done

For the six identified Chrome clone directories, the player explicitly asks:

> remove the six chrome directories and make another note about cleanups
