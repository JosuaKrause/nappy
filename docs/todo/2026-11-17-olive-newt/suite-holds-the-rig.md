# The return-patrol check named for the rigged bag fails without the rig

*Proposed, not asked for:* `_test_each_patrol_comes_within_its_rigged_bag` in
`tests/test_return_patrols.gd` is arranged so that it fails when `_rig_the_next_patrol()` is removed
from `owe_the_return()`, for example by keeping the ordinary bag from handing out a patrol in it, or
it is renamed to what it does check, the one capped test then being the rig's only holder by intent.
Either way the suite tests its one module (**writing-tests**), with the bag mocked rather than
counted on.
