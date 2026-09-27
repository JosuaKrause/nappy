**Resolve the remaining review findings on the scenery-animation checkpoint.**

The player agrees to the review assessment in
[Sunny lynx](../../playtests/2026-09-26-sunny-lynx.md), and explicitly approves every visual
change. Retain the approved appearance while fixing the existing PR's defects.

Share the water shader resource across configurations and tree reentry, keep independent
material parameters where required, and warm the shader through a real draw in both boot paths.
Preserve M147's first-use loading guarantee. Prove resource reuse in focused tests; verify actual
rendered warmup and a first approach to water without claiming headless tests establish compilation.

Keep the event manager's sole runtime atlas ownership; fix standalone fixtures that now build
scenery without acquiring their page, and audit analogous callers. Rename the redraw test to
state that separated smoke/spray do not change the owner's key. Replace weak static-frame checks
with meaningful structural/composition checks, without rejecting legitimate layer overlap.
Centralize rotor registration and check the authored crop against it rather than repeating a
constant's literal. Move the source generator and required helper into tools with CLI/tooling
contracts, catalogue entries, generated-file guidance and unchanged-output verification.

Write the partial-animation guarantee into current graphics documentation and authoring skills;
the [remaining sprite audit](audit-remaining-partial-animation.md) remains separate. Record visual
approval and close the appearance question, retain other handoff guidance, normalize the original
evidence folder's name and every live reference, and update the PR description. Retain historical
measurement identities. Run affected gates, resolve CI failures in this PR and obtain an independent
review of the final corrections. No merge or release is authorized.
