# Playtest 30

## Illustrated actor scale and attachment review · 2026-09-06

The supplied gameplay capture is preserved as the complete run at
`evidence/archive/session-captures/2026-09-06/run-183801-seed3838722122-v0.4.1-112-g4813ca6/`.
It records the current broken state of the opt-in illustrated presentation; it is not an approved
art reference or an acceptance target.

The player reported the following visual findings while reviewing the illustrated gameplay:

> the player direction now is aligned but pedestrians have N and S flipped

> bodies are now rotated correctly -- scale of pedestrians and player are still different from each other and legs still above body and incorrectly connected

> legs are upside down - pedestrians are now even smaller than before - head of player is at its belly button

The latest capture narrows the next repair target:

> look at the size of the yeller on the left that's the scale we need. also now the player head is too high up

The requested repairs are to use the legacy `homeless_yeller` on the left of the capture as the
scale comparison for pedestrians and to lower the player head toward its body. Direction, body
rotation, leg orientation, leg-to-body connection and ground contact remain part of the same
illustrated presentation repair; the capture shows the defects rather than approving a result.
