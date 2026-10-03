# Attribute and clean browser scratch by job ownership

Audit the browser-run and external browser-build paths for temporary material beyond
the profile: extracted/downloaded copies, compiler trees and operating-system
signing clones. The browser-check tool already removes its own disposable profile;
the session-cleanup skill covers the broader ownership and retention rules. Automatic
attribution and cleanup of those other paths remain unimplemented.

**Proposed, not asked for:** register exact paths and owning processes when a job creates
or discovers attributable scratch, stop and wait for those processes, retain relevant
results and failure diagnostics, then remove only disposable job-owned intermediates.
If reliable attribution is unavailable, report the candidate and the missing evidence;
do not guess an owner from a name or date. Caller-selected output directories remain
outputs unless their owner explicitly releases them.

The player's earlier removal request names six specific Chrome clone directories.
It does not authorize deleting the installed browser, regular profiles or arbitrary
application/OS caches. Test ownership and retention with isolated fixtures; no test
should delete real browser or system data.
