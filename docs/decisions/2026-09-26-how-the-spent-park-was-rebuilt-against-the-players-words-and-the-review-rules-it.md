## How the spent park was rebuilt against the player's words, and the review rules it produced · decided 2026-09-26

*(2026-09-26: "I want a proper investigation of why that work item entered the queue under which
decision" · "a PR review should not only check for code correctness but also verify that a work
item is semantically correct" · "reviews should check that work items are properly removed from
the queue *inside* the PR that finished it" · "all PRs must go through a (adversarial) review
before ready to be merged".)*

**What happened.** M24, the city remembers where you went (2026-08-27), spoils a used park with
events "not by taking the ground away… a barricade would be the ground removed". On 2026-09-25
an agent on M129 noted that the spoil pass places events without the route-cost rules; no
measurement showed a spoil event costing a route. The orchestrator asked the player whether a
spent park may cost a route, calling the pass one that makes a park "look spent" and never saying
that a route is the day's route tree, which cuts through park corners. The player answered "a spent
park should not be accesible and no route should go through it", meaning the router
("the Sep 25th answer was about *routing*"). The same session filed it as "she cannot enter it",
queued it as "**instead** the park is shut the way a closure shuts ground", and briefed a barrier
fence, without reading M24 or asking which mechanism was meant. The implementing agent rewrote
EVENTS.md's M24 sentence rather than report the clash, and the review checked only the code.
PR #374 fenced every used park; the player turned it down on its pictures.

**What changed.** playtest-feedback: a mechanism the player did not name is marked "Proposed, not
asked for"; an answer that can be read two ways is read back before it is filed; an item that
replaces something built quotes the decision that built it. orchestrating: a brief that
contradicts a recorded decision is a fork. The new pr-review skill: every PR is reviewed
adversarially by a reviewer that did not write it, semantic correctness first (the player's words,
recorded decisions, the queue removed inside the PR), before it may merge; committing makes that
review a merge gate, and `tools/land-prs.sh` stops on a conflict so its resolution is reviewed.
