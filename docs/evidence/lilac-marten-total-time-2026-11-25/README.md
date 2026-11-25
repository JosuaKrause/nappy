# Ending screens with the total game time (lilac-marten, total-time)

Claim: the run's ending (`ending-bad.png` GAME OVER, `ending-good.png` THE END) shows the run's total
and the last day's own clock; the escape's epilogue (`epilogue.png`) shows the escape's clock and the
run's total.

Limits: dated runtime evidence of one build. The screens are raised by the `--ending` rig, which has
no day behind it, so for these stills the rig was temporarily patched in `src/main.gd` (not
committed) to set the run's play ticks to 22620 (12:34.000), hand the ending a last day of 84.5 s,
and, for `epilogue.png`, raise the epilogue on a tunnel exit with a 42.5 s escape. The numbers are
those inputs, not a played run.

Source: branch feature-lilac-marten-total-time on the base 7224d0a84. Command:
`tools/shot.sh out.png 3 --ending <bad|good|neutral> --no-save`.
