# Measure peak storage and enforce a disk-space preflight

Measure the peak additional allocation of representative worktree creation, asset
imports, Web-template builds and capture batches on their destination volumes.
Record the workload, retained outputs, environment and uncertainty before selecting
defaults. The existing sparse-checkout and headroom rules require an estimate and
reserve; the command-line tools do not yet enforce that preflight.

**Proposed, not asked for:** use configurable required headroom based on those measured
peaks, check before allocating a batch, and fail with the measured available space
and a smaller-batch or cleanup action when it is insufficient. Keep help and invalid
arguments free of side effects. Do not impose an arbitrary universal threshold or
treat allocated directory sizes as exclusively reclaimable space. Verify insufficient
space and unknown-estimate paths through fixtures without filling a real drive.
