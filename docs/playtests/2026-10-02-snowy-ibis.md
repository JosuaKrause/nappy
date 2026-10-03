# Playtest snowy-ibis — Mobile ground stepping does not visibly remove stutter

2026-10-02.

The assistant reports that PR452, silky-rabbit's ground preparation across
frames, is merged and the player's v0.21.5 deployment succeeds. The native
comparison finds a modest ordinary-route improvement, mixed slow-rate tails
and increased steady drawing/allocation. The player chose merging to obtain
phone evidence rather than accepting the native result as a perceptible fix.

The player reports the mobile test and asks for a recommendation among keeping
the code, reverting it while keeping findings, or disabling it behind a toggle:

> I tested the smeared loading on mobile. I can't say that the stuttering really went away -- we will have to look in a different direction. what do you think about the code changes? should we keep our findings and revert the code? should we keep the code (it does improve a little bit on paper)? or should we make it optional and set the toggle to off?

This report does not identify a device, browser, route or controlled atomic versus
stepped comparison. It does not claim that ground is uninvolved or that every
coverage, water, transition and orientation check was performed.

The assistant recommends preserving findings and reverting the stepped runtime
implementation while retaining nearby loading/unloading. The measured native
gain is about 0.13ms in the controlled fixture, with extra draw calls, allocation
and lifecycle bookkeeping. A shipped default-off toggle retains two code paths
to maintain; pinned historical revisions already support future comparisons.
This is a recommendation, not a player decision or authorization to revert.
The runtime stays unchanged pending the player's choice. Further attribution
belongs to the existing M159, a slow frame names the frame that was slow, work.
