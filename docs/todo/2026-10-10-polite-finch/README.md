priority: now

# polite-finch — One catalogue holds every text the game shows · filed 2026-10-10


[mossy-beaver](../../playtests/2026-10-10-mossy-beaver.md), inbox #650. Asked where the texts on
screen live, the session answered that no single file collects them: the title and pause texts are
in `src/ui/title_screen.gd` and `src/ui/pause_screen.gd`, the help lines with their button symbols
in `src/ui/help_text.gd`, the day briefs and the loss and summary lines in
`src/day/day_controller.gd`, `src/main.gd` and `src/events/event_catalogue.gd`, and the indoor lines
under `src/interior/`. The player:

> yeah we need a text catalogue instead of spreading it all across the codebase

And, on a text that broke onto three lines where two were asked for (the
[feathery-puffin](../2026-10-10-feathery-puffin/README.md) entry):

> I can't find the exact text (we need that catalogue)

The band is the filer's proposal: the player named none, and the catalogue is what finding the
line-break bug's text needs.
