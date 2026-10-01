Exclude test resources from the Web export without deleting local tests or removing runtime
resources. Compare an unchanged baseline export and the filtered export under identical build
conditions, including decoded pack bytes and a fixed local gzip comparison; do not represent
local compression as observed CDN transfer. Inspect the actual exported directory and verify
the exported game starts without missing-resource or class-registration errors.

**Proposed, not asked for:** extend the existing package audit so a release fails if test suites,
probes or their exported remaps return. Preserve its duplicate-atlas and orphan-page checks.
Keep relevant resource/class references valid and add a focused regression fixture for the
artifact-level rejection. Retain compact sizes/provenance and the live download inspection.
Engine trimming and lazy scenery are separate work, not prerequisites for this bounded change.
