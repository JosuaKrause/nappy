The Hard Mode checkbox is selectable by a press, a click or a touch anywhere on its box and its label
text grown by 5%, never less than its catch today, on every input the other title buttons take.
Find why the player cannot select it (see the README's candidates), fix that, and build its catch
from `ButtonGeometry`'s 1.05 rather than a constant of its own, as the larger of the two. A test in
`tests/test_run_checkpoints.gd` pins a press just inside the 5% edge of the box and of the label,
on touch and on mouse, and fails on today's code if the cause is in the catch.
