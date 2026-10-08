**Keep development scene recipes out of production.**
[pebbly-hare](../../playtests/2026-10-08-pebbly-hare.md), inbox #622, asks whether the recipes
have a Godot ignore file and whether they are included in the production build. The published
v0.25.5 package contains 22 recipe JSON files and this directory has no `.gdignore`.

**Proposed, not asked for:** exclude the development recipe directory from production exports
using Godot's ignore/export settings, while keeping the checked-in files usable by local scene
tools. Extend the package audit to reject an accidentally bundled recipe and prove the exclusion
against a real exported package. The alternative is continuing to ship these development inputs.
This does not change ordinary game behavior or request a new release. Retain compact provenance
for the current-package finding and the corrected export, without committing either whole pack.
