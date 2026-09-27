priority: later

# tall-beaver — Release notes sort each PR by the category it names · filed 2026-09-27

> "For now the release notes look good. If we wanted to fix the issue you highlight we should make
> categorization explicit by pr via [category] but that's not something we need to do right now"

[coral-toad](../../playtests/2026-09-27-coral-toad.md), statement 2. The release notes
(`tools/release-notes.py`, from PR #402) put one bullet per squashed commit under **Game** or
**Tooling and docs**, and decide which by the paths the commit touched: any path under `src/`,
`art/`, `assets/` or `scenes/`, or `project.godot` or `icon.png`, makes it Game. That sorts a PR
whose only game-path change is a comment or a README as Game: #395 (the handoff doc leaves the
repository), #388 (the queue's priority bands) and #397 (the capture fix, dev code only) all land
there. The player's direction is that each PR names its category explicitly, and the notes sort
by that rather than by paths. Built after #402 merges, since the script is its.
