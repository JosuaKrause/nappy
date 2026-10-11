# Playtest coral-lark — The policeman on foot, lag spikes on the phone, the park cordon, day 11's mast

2026-10-11.
Said as five inbox notes on GitHub Issues, #669, #670, #680, #684 and #694, and answered in comments on
them. Each note is recorded as it holds: first what its words answered, where a comment says so,
then the words themselves, whole, and each later word after what it answers. The questions and
context are the assistant's; only the quoted lines are the player's.

## #669

1. **What the note answered** (the assistant, on PR #663, sandy-ferret):

   Asked about PR #663 (sandy-ferret, the policeman on foot): (1) from resistance progress 3 every investigating police car lets out a policeman whose catch ends the day, though "ends the day" was chosen only for the torn poster's policeman and the heat ladder's lethal rung was meant to start at 4. Options: "Ends the day from 4 only (Recommended)", "Always ends the day", "Never ends the day". (2) On day 10 at full progress the night raid's riot van still pursues her at 130px/s like a person. Options: "Van stops, men get out (Recommended)" — it stops on its road and lets out officers on foot who pursue her, as the investigating car does; "Van only drives"; "Leave the van chasing".
   The player's first line answers (1), the second answers (2).

2. **The note.**

   > we make it somewhat costly. once the policeman reaches her they stop and walk back to the car
   > Van stops, men get out (Recommended)

3. **The player's further words.**

   > it needs to give a substantial cost but not lethal directly

4. **The player's further words.**

   > > never lethal 
   >
   > well if the excitement meter is already high it can be lethal

5. **The assistant asked:**

   Asked: (1) the night raid's riot van now stops and lets two officers out; when one catches her, is it like the car's (a big excitement hit, lethal only if the meter is already high, then they walk back; overturns M56's "ends the day" for the raid) — "Like the car's (Recommended)" — or "Ends the day (M56)", the raid's catch ends the day outright like the torn poster's policeman, only the investigating car's man a cost? (2) The abduction row's unmarked van still chases her itself at high heat: "Leave it for now (Recommended)" (queue it separately), or "Same as the police" (it stops when it notices her and lets men out on foot; no vehicle chases her anywhere). The player's first line answers (1), the second (2).

6. **The player's words, answering it:**

   > Ends the day (M56)
   > Same as the police

## #670

1. **The note.**

   > also, there are big lag spikes in the last few days -- I reported that already -- just wanted to give some more info

2. **The assistant asked:**

   Asked: (1) where the spikes show, since the earlier report is not in the repo and the note names no device — "Phone (web)", "Desktop (web)" or "Both"; (2) how to file it — "New entry, now (Recommended)": a new `now` entry to find which recent merge brought the spikes back and fix it, M159 unchanged; or "Add to M159" as more evidence. The player's first line answers (1), the second (2).

3. **The player's words.**

   > Phone (web)
   > New entry, now (Recommended)

4. **Context:**

   Said while the batch was being filed, after the assistant had said it could not find the earlier report of the lag spikes in the repo.

5. **The player's words.**

   > I reported it earlier as soft lock but now I also encountered non-soft lock versions

## #680

1. **Context** (the assistant):

   Said unprompted about PR #677 (plush-marten, day 12's park closed by a police cordon: officers arriving from off screen tape the park's edge one stretch at a time down to a last gap, and walk the park's people out), while its fixes were in review.

2. **The note.**

   > I like the visuals of closing the park

## #684

1. **What the note answered** (the assistant asked):

   Asked about cozy-lynx (day 11's rigged mast stands on her route): the routed second mast is placed on only 8-10 of 30 seeds, because the two line rules (its field must leave the route's junctions and sidewalk open) fail on most tiles of her route; the six fixed masts are already exempt from them. Options: "Exempt like fixed masts (Recommended)" — every mast skips the two line rules, keeping the mast-site, door-clearance, unused-calm, spacing and way-out checks; "Measure pulse reach only" — a new reading of a mast's reach over its pulse only; "Accept ~1 in 3 cities" — leave placement as is and test the share.

2. **The note.**

   > Exempt like fixed masts (Recommended)

## #694

1. **What the note answered** (the assistant):

   After the assistant closed day 12's softlock (snowy-trout) as not reproduced on headless desktop runs, when it had happened on the phone, and then asked whether to reopen feathery-quail (police cars vanishing; one path found and fixed, not confirmed to be the player's case) and silver-osprey (the loose dog; "indefinitely" never reproduced literally) "until you've confirmed them on the phone".

2. **The note.**

   > I confirmed them since I filed them. if you can't reproduce just ask me to provide a frame record
