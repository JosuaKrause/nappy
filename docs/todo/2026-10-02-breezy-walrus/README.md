priority: now

# breezy-walrus — Choose ground preparation after the mobile test · filed 2026-10-02

The player cannot say that spreading ground preparation removed mobile stutter.
They ask whether to retain the code, revert it while preserving findings, or
keep it behind a default-off toggle. Their full words and context are in
[snowy-ibis, mobile ground stepping does not visibly remove stutter](../../playtests/2026-10-02-snowy-ibis.md).
They have not selected one of those options.

The merged choice is [silky-rabbit, nearby ground regions prepare across
frames](../../decisions/2026-10-02-silky-rabbit.md): per-region stepping is the
implementation for phone evaluation, with modest native gains and measured
steady costs. This entry does not overturn that runtime before a player choice.

**Proposed, not asked for:** preserve all experimental findings and restore
atomic preparation of each nearby region, retaining existing loading/unloading.
The measured benefit and mobile observation do not justify retaining the added
state or maintaining two shipped paths. This is the assistant's recommendation;
retaining stepped preparation or adding a toggle remain alternatives for the
player to choose. Mobile stutter attribution already belongs to M159, a slow
frame names the frame that was slow; this entry does not duplicate it.
