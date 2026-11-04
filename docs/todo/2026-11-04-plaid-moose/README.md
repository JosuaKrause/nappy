priority: now
upnext: true

# plaid-moose — The verify skill says how to design unit tests: isolated components, injection · filed 2026-11-04


**The ask.** Answering the board question drawn-art-tests on how the tests check what the game
draws, the player: "what are we testing here? the placement of the elements is defined by the rng
which can be tested in isolation. the drawing happens through general drawing code which is also
tested in isolation elsewhere. if you're just testing the holder for it the inject a mock drawer
that confirms that all elements are properly drawn" (inbox #1018 in brisk-ferret). Then: "take the
answer as a more general statement on how to design unit tests: the core is to break down the
problem into individual components that are isolated. don't write tests for components that are
already tested. use dependency injection to confirm correctness. if you are reading a private member
or creating an escape hatch you're either trying to test too much at once, are not using dependency
injection as intended, or are trying to test internals in a setting where external functionality
matters" (inbox #1018 in brisk-ferret), then "this is not a hard rule but rather a guidance" and
"and hypotheticals here are also not exhaustive. there could be other reasons to end up in this
situation that I don't mention" (inbox #1018 in brisk-ferret).

**Read as:** a testing guideline for the whole project, not a hard rule. Break the problem into
isolated components and test each on its own. Do not retest a component already tested elsewhere.
Confirm a component's correctness by injecting its dependencies through the paths the game uses. A
private read or an escape hatch in a test is a warning sign, not a ban: it usually means testing too
much at once, not injecting as intended, or testing internals where outside behaviour matters, and
those reasons are examples, not the only ones. The drawn-art case itself is filed in minty-quail's
item tests-public-seams, not here.

**When.** Told the band proposed was `now`, the player: "proposed at the now band, -- let's do immediate instead", and then "there are tiers higher than now!" (inbox #1024 in brisk-ferret). Read as: up next, the marker above every band that the player once put as "immediately after the current items are done" (mossy-ferret), so the entry keeps `now` and carries `upnext: true`; not `bug`, which the player did not name.

*Proposed, not asked for:* that the guidance goes in
the **verify** skill's "Testing policy" section, worded as guidance.
