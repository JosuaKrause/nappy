# rosy-chipmunk — Does the save symbol say what a desktop browser kept · 2026-10-02


**Does the save symbol show what the browser actually kept on a desktop browser?** On the iPhone
that lost its saves, saving in Safari works on v0.22.0, confirmed with the person who reported it
([quiet-yak](../playtests/2026-10-03-quiet-yak.md), #468); what is left is the desktop. On a desktop browser, the symbol should
show for each save, fully for at least a second and then fading over a second and a half, never
struck. It shows for deleting the save too. Dismiss the title (that writes the save, so the symbol
shows once), open the pause screen and hold the restart: the deletion shows the symbol, and it
stays up through the reload onto the title. Dismiss that title and the symbol shows again for the
save the new run writes, so a second held restart straight after deletes a save and shows the
symbol again. A restart shows nothing only when the run has already ended and deleted its own save:
let a day lose the last nerve. The run ends the moment that day does, so the deletion's symbol
comes up over the losing day's own summary, not over the ending, and on a desktop browser has
usually faded within about two and a half seconds, before you continue to the ending screen. Hold
the restart on the ending screen and no new symbol comes up. Held on the losing day's summary
while that symbol is still up, the same symbol carries over the reload onto the title; it is the
run's own deletion, not the restart's. On the web the symbol must never stay up for good: hold a
restart on a day's summary while its end-of-day save is still unanswered (slow the connection, or
background the page first) and the symbol on the new title still fades once the browser answers,
or fails after five seconds and shows struck for ten. The same holds for a won day 14 that hands
the run to the escape: continue past its summary while its save is still unanswered and the
symbol stays up into the escape, then fades or shows struck the same way. Reopen a game closed between days and no
symbol shows over the title, while a game closed mid-day shows it once over the title; pressing
past the title and the day brief shows it again, for the save the day's start writes. Record is
`docs/decisions/2026-10-02-rosy-chipmunk.md`.
