# Playtest cozy-pelican — Saving on an iPhone, and a save symbol that waits for the browser

2026-10-02.

Not played by the player; a report the player passes on from somebody playing the released page,
and the player's instructions on the save symbol that follow it in conversation.

## The report

> "according to some user saving on iphone does not work. they use safari and don't use
> incognito or any third party adblock. pop-up blocking is enabled. however, they tested on ipad
> (also with pop-up blocking) and it works correctly there"

The assistant reads the save path and answers that nothing in the game treats an iPhone
differently, and names two weaknesses that would fail on one device and not another:

- **Storage refused at boot is silent.** When Safari will not open IndexedDB (the database the
  web build copies `user://` into, and the only copy a reload finds), Godot prints "IndexedDB not
  available" to the console and runs on memory alone; the game plays normally and the save
  symbol still flashes, because `main._save_now()` flashes it the moment the in-memory file is
  written. Safari's *Block All Cookies* setting, or Screen Time's website-data restriction, does
  this, and either can differ between two of one person's devices.
- **A lost IndexedDB connection is never reopened.** Emscripten opens the connection once and
  keeps it for the page's lifetime (`IDBFS.getDB` caches it in `IDBFS.dbs`, with no close
  handler), and iOS Safari is known to lose that connection from a page left in the background
  under memory pressure ("Connection to Indexed Database server lost"). Every later flush then
  fails until a reload, and both the game's own `FS.syncfs(false, function(err) {})` in
  `GameSave._write_now()` and Godot's own flush ignore the failure. An iPhone has far less memory
  than an iPad.

It also names two things that would read the same to the player: a Home Screen icon keeps its
own storage apart from the Safari tab, and a run resumes at the dawn of the day it was in, never
mid-day, which an iPhone shows far more often since iOS throws a background tab out sooner. It
proposes (1) waiting for the IndexedDB flush, and on a failure dropping the cached connection and
retrying once, (2) flashing the save symbol only when the flush succeeded, and (3) saying on the
title screen when the browser is not keeping saves, which needs the player's wording; and asks
whether to build (1) and (2) now.

## What the player said

> "are we currently using the save symbol? we should show it until it is fully confirmed saved.
> also, if saving is unavailable it should show up with a strike through"

> "also, yes, do the fixes"

"The fixes" are the assistant's (1) and (2) above. The strike through is read as the answer to
(3): the symbol says saving is unavailable, and nothing is written on the title screen.

## What is asked for, as statements

1. **The save symbol shows until the save is fully confirmed.** It comes up the moment a save
   starts and stays fully shown until the write has actually landed — on the web, until IndexedDB
   reports the flush done — and only then holds and fades as it does today.
2. **When saving is unavailable, the symbol shows with a strike through.** Unavailable covers a
   browser that refused storage at boot and a write or flush that failed.
3. **A failed flush reconnects and retries** (the assistant's (1), accepted with "do the fixes").

## How long the symbol shows

Later the same day, with the work above on its open pull request, the player asked:

> "what are the timings of the symbol showing? it shouldn't show if the save takes less than
> 100ms and it should always show for at least 1s -- if it fails it show for at least 10s"

The assistant answered with the timings as built: the symbol comes up at full the moment a save
starts, stays at full while the save is unanswered, then holds 1.5s and fades 1.5s once it is
answered, struck or not. A desktop save is answered in the same frame; a web flush normally
within a fraction of a second, and one that never answers counts as failed after 5s. It then
asked three questions, each with options.

**First:** a desktop save is written in the same frame, so a symbol hidden under 100ms would never
show there, which partly overturns PLAYTEST-82's "Also show a small save symbol for a few seconds
after saving — That way it's clear when a state was saved". Should a fast save show nothing at
all? The options were "Yes, show nothing" (no symbol for a save answered within 100ms, anywhere)
and "Web only" (the 100ms rule only on the web). The player answered in their own words:

> "okay always show it. but show it for at least a second"

**Second:** a failure can come back in under 100ms, for example when the browser refused storage
at boot. Should a failure that fast still show the struck symbol for its 10s? The player chose
"Yes, always show it": a save that was not kept always shows the struck symbol for at least 10s.

**Third:** how the minimum fits with today's hold and fade. The options were "Full for min, then
fade" (fully shown until the save is answered and the symbol has been up at least 1s, or 10s if
struck, counted from when it appears; then the 1.5s fade, with the 1.5s hold after the answer
gone), "Min includes the fade" (at least 1s or 10s from appearing to gone, fade inside it) and
"Min after the answer" (at least 1s or 10s fully shown counted from the answer, then the fade).
The player chose "Full for min, then fade".

### What is asked for, as statements

4. **Every save shows the symbol.** There is no 100ms threshold; the first answer dropped it.
5. **The symbol is fully shown for at least 1s**, counted from when it appears, and for longer
   while the save is still unanswered; then it fades over 1.5s. This replaces statement 1's
   "holds and fades as it does today".
6. **A save that was not kept shows the struck symbol fully for at least 10s**, counted from when
   it appears, then the same fade; however fast the failure came back.

## Deleting the save shows the symbol too

Asked when saving happens, the assistant listed the save moments and added that a day that ends
the run writes nothing, because ending the run (`GameState._end_run()`) has already deleted the
save file; the held restart deletes it too (`main._restart_run()`). The player answered, quoting
that sentence:

> "If that day ended the run, it skips the save, because ending the run already deleted the save
> file. -- show deleting the save file with a save symbol as well. every change in the save state
> needs to show the symbol"

### What is asked for, as statements

7. **Every change in the save state shows the symbol**: a write, and a deletion of the save file
   alike, with the same timings as a save (statements 4 to 6) and the same strike when the change
   was not kept.
8. **Deleting the save when a run ends shows the symbol**, and so does the held restart that
   deletes it. A restart with no save left to delete (a run that already ended and deleted it)
   changes nothing, so it shows nothing.

PLAYTEST-80's "nothing new is drawn for it" is about the control that clears a save (the held
restart that already existed, rather than a new button) and stays true; this asks for the save
symbol, not a new control.

## The strike, the save at opening, and the strike's red

After an adversarial review of the pull request, the assistant asked three questions, each with
options.

**First:** a save fails and its struck symbol goes up for its 10s; the player taps through the
summary within about 3s and the next save (the dawn save) is kept. As built, that kept save clears
the strike at once, so the strike was up only about 3s. Should a later kept save cut the strike
short? The options were "Keep the full 10s" (the struck picture stays its 10s even over a save
that worked) and "Newest answer wins" (a kept save clears the strike at once, so the symbol never
says "not kept" about a kept save). The player chose **"Newest answer wins"**.

**Second:** opening a saved game that was closed between days charges nothing, yet the game
writes the save at once with identical contents and flashes the symbol. Should a save that changes
nothing stay quiet? The options were "Skip it when unchanged" (opening a game closed between days
writes nothing and shows nothing; one closed mid-day still charges the nerve, writes at once and
shows the symbol) and "Keep the write". The player answered in their own words:

> "either it saves with one less nerve and a cleared "during active game" flag. or you defer
> saving to the actual day start"

Read as: opening a game whose day was under way charges the nerve and writes at once, with one
nerve fewer and the day-under-way flag cleared; opening one closed between days writes nothing
then, and the next write is the day's own start.

**Third:** the strike's red is the traffic lights' red (`Palette.SIGNAL_RED`), which a note in
`src/palette.gd` keeps to the traffic lamps. Should the strike get a red of its own? The options
were "Own red" and "Keep signal red". The player chose **"Keep signal red"**.

### What is asked for, as statements

9. **The strike follows the newest answer**: a later save that is kept clears the strike at once,
   even inside an earlier failure's 10s.
10. **Opening a saved game writes only when it charged a day**: a game closed mid-day is charged
    and written at once (one nerve fewer, no day under way); a game closed between days writes
    nothing until the day starts.
11. **The strike keeps the traffic lights' red.**
