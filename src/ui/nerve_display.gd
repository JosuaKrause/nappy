class_name NerveDisplay
## The one place nerves become text on screen — a star per nerve, `-` for none, and never a digit.
##
## Consistency is the whole point: `Hud`, `DaySummary` and `PauseScreen` each show the count
## somewhere, and reading it through one function rather than five copies is what keeps a digit
## or a word for the count from creeping back into a sixth place that shows it.
static func stars(nerves: int) -> String:
	return "*".repeat(nerves) if nerves > 0 else "-"
