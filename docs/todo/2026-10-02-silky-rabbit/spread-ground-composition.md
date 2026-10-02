# Spread nearby ground-region preparation across frames

Divide the creation of nearby ground regions on the game's actual camera-driven residency
path into bounded steps scheduled across frames. The player's issue and scope correction are
in this entry's README and its linked playtest. Deferring an unchanged whole region build
once, or only spreading construction of the loading-time shared sheet, does not satisfy it.

Keep the smaller loading boundary and wider unload boundary. Pending work must be resumed
without duplicating it and canceled when it is no longer needed, on a reset or after a change
that makes its saved inputs stale. Publish complete current ground before it enters view;
partial cells must not be mistaken for a completed resident region. Retain a synchronous
correctness path for the safety guard, explicit relocation, boot and day/finale destination
preparation where the player cannot be allowed to see missing ground.

Preserve cell sources and atlas coordinates, current route-curb tint, seeded variants, water
separation and phase, off-screen gameplay, collision, map facts and unloading. A region built
from changed city state must reflect that state, including changes while it was pending or
unloaded. Do not change city geometry, gameplay RNG, saves or the loading-time image recipe.

Verify that ordinary dynamic preparation crosses frames, incomplete work is not published,
pending work is safely canceled or refreshed, and complete regions match the independent
ground reference. Check reversals, loading/unloading boundaries, day changes, orientation and
relocation. Measure per-step cost and any remaining indivisible renderer work; distinguish
the queue's CPU timer from the full rendered-frame cost and native evidence from browser or
phone claims. Retain compact reproducible evidence under the verification rules and update
the live docs that describe preparation scheduling. Browser/phone perception remains a human
review item if it cannot be checked in this session.

The player's further request in gentle-moose, compare ground preparation before and after,
adds a controlled before-and-after experiment. Compare the actual atomic nearby-region
runtime, a global one-section-per-frame candidate, and the per-region stepped runtime using
the same collector, seed, itinerary, engine, viewport, warmup and measurement windows.
Retain all interleaved trials, source and collector identity, per-frame tails and maxima,
preparation cost, steady allocation/drawing overhead, missing-region counts and emergency
completions. Strategy microfixtures alone do not establish before-and-after impact on the
production residency path. Name what the rendered-frame measurement includes and keep
browser, GPU, presentation and whole-game claims within the experiment's actual scope.
