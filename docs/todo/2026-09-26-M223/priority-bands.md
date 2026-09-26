**The queue has no shared order list; each entry carries its own priority** *("what's the point
of any of this if there is still a centralized TODO.md ordering list? can we think of a better
solution there? a priority system?" · "1 sounds good with. only change I would do is for "now" do
reverse chronological maybe?"; [2026-09-26-brisk-heron](../../playtests/2026-09-26-brisk-heron.md),
statements 13–14)*. Every entry's `README.md` opens with a `priority:` line naming one band of a
fixed set, `now`, `next`, `later` or `parked`, and, where the entry truly waits on another, an
`after: <entry name>` line. A command (for example `tools/queue.sh`, cli-tools and a using-tools
catalogue row) prints the queue: bands in that order, `now` newest first and the others oldest
first by the entry's date name, each entry moved behind whatever it names in `after:`. `TODO.md`
keeps its header and says to run the command; its order list goes, and so does anything else in it
that belongs to one entry (the "Bind prepared environment art" table moves into its entry). The lint
rejects an entry with no `priority:` line, a band outside the set, and an `after:` naming no entry
or making a cycle. Moving an entry between bands edits one line of one file, so two PRs collide only
when they change the same entry. Every current entry gets its band in the overhaul above, from the
order the list gives today, with the player shown the result. The bands and the command are the
orchestrator's proposal, agreed to; newest-first within `now` was said with a "maybe" and is shown
to the player before the overhaul relies on it.
