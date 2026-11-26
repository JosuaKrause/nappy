# silver-egret — Do the cars' shadows now read as ground contact · 2026-11-25

### cars-stand-on-their-wheels

- **Question:** silver-egret, do the cars and vans now read as standing on their wheels? (built on my pick)
- **Context:**
  - **What was asked:** a shadow sits where the object meets the ground, a car's only where its wheels would be, never above its roof (minty-hedgehog 1).
  - **What was built:** each car or van now casts one small oval under each pair of wheels, sitting on the line its tyres stand on, where before one oval or capsule lay behind its whole picture and showed above the roof of a car coming at you or driving away.
  - **What to do:** play a day with traffic on the desktop build (`tools/run.sh --seed 4242 --day 4`, so the police car patrols), stand at a junction on a busy street and watch cars pass side on, come at you, drive away end on and turn the corner. Walk past a parked delivery van on the sidewalk, and on day 13 or later (`--day 13`) watch an army truck go by.
  - **What to look for:** each oval under a pair of tyres, none showing above a roof or behind a body with nothing under it. The sheets in `docs/evidence/silver-egret-shadows-2026-11-25/` show every car and van in all eight directions, before and after.
  - **Cost of a no:** the ovals' three numbers (`POINT_WHEEL_SHARE`, `WHEEL_OVAL_SHARE`, `WHEEL_DEPTH`) were chosen by eye and each is one constant; a change to them is cheap.
  - **My pick:** yes if the ovals read as ground under the wheels on the street; say which car or view reads wrong if not.
  - **You:** 
  - **Me:** 

### vans-stand-on-their-wheels

- **Question:** silver-egret, do the night raid's riot van and the moving van now read as standing on their wheels? (built on my pick)
- **Context:**
  - **What was asked:** a shadow sits where the object meets the ground, a car's only where its wheels would be (minty-hedgehog 1).
  - **What was built:** the riot van (the dark van with mesh on its windows that the night raid parks, its officers round it) and the moving van (the lorry at the kerb with its ramp down, a seal on a sidewalk) each cast two ovals under their wheel pairs, where before one oval wider than the van lay under the whole scene round it. What the two block, and where the officers stand, has not moved.
  - **What to do:** play day 10 (`tools/run.sh --seed 4242 --day 10`) to the night raid's van, and look at it from the sides you can reach; on a day with a moving van sealing a sidewalk, walk past it on an east-west street (side on) and on a north-south one (end on).
  - **What to look for:** an oval under each pair of tyres, none spilling past the van. `vans-sheet.png` in `docs/evidence/silver-egret-swing-and-vans-2026-11-25/` shows the riot van in all eight directions and the moving van side on and end on, before and after.
  - **Cost of a no:** how far the ovals stand from the van's middle is one constant (`SCENE_BODY_SHARE`), chosen by eye.
  - **My pick:** yes if they read as the other vans do; say which view reads wrong if not.
  - **You:** 
  - **Me:** 

### swing-frame-stands-on-its-feet

- **Question:** silver-egret, does the playground swing frame now read as standing on its feet, and is day 12's swing still easy to touch? (built on my pick)
- **Context:**
  - **What was asked:** a shadow sits where the object meets the ground (minty-hedgehog 1); the swing frame's was one capsule as wide as its picture under all of it.
  - **What was built:** one oval under each of its two A-frames, on the line its feet stand on. Day 12's task (go to the swing in one park before the police close it) is still done by touching the same spot at the frame's base (an ellipse 56 by 34px across, the size of the frame's picture), and both ovals lie inside it; the red arrow finds the spot and no mark is drawn there, since a red-arrow destination draws no chalk mark.
  - **What to do:** play day 12 (`tools/run.sh --seed 4242 --day 12`), read the chalk mark, follow the red arrow to the swing and walk into the frame's base from a side.
  - **What to look for:** the ovals under the feet and nowhere else, and the task completing where you expect it to as you reach the frame. `swing-sheet.png` and the two `ingame-swing` stills in `docs/evidence/silver-egret-swing-and-vans-2026-11-25/` show it before and after, one sheet with the touch spot traced.
  - **Cost of a no:** where the ovals stand is one constant (`SWING_A_FRAME_SHARE`); a spot that is hard to find without the old shadow is a finding to report.
  - **My pick:** yes on both; say if the spot is hard to find.
  - **You:** 
  - **Me:** 

### police-car-still-floats

- **Question:** silver-egret, does the police car still look like it floats? (built on my pick)
- **Context:**
  - **What was asked:** the police car's shadow made it look floating (azure-koala 10).
  - **What to do:** play day 4 (`tools/run.sh --seed 4242 --day 4`, so the police car patrols) and follow the police car, side on, on its diagonals as it turns a corner, and end on.
  - **What was built:** its shadow is the same two ovals under its wheels, set on the line its tyres stand on; while it rides, its body bobs up one pixel and the shadow stays on the ground (the second ride frame, shown on `cars-sheet.png`).
  - **My pick:** no, it reads as standing on the road in all eight directions on the sheet; confirm in play.
  - **You:** 
  - **Me:** 

### shadow-pictures-instead-of-ovals

- **Question:** silver-egret, if the ovals still read wrong, do you want the other way you named: a picture of its own for each object's shadow? (built on my pick)
- **Context:**
  - **What was asked:** you gave two ways and chose neither (minty-hedgehog 1): keep the ovals and adjust their number and extent, or draw a custom shadow for each object that resembles what a shadow of that object would look like. The ovals are the first way, built open to your overturn.
  - **The second way:** a picture of its own for each object's shadow, drawn to look like that object's shadow rather than built from ovals. The shadows-from-pictures entry (plaid-chipmunk) is where such pictures would be drawn on their own atlas page.
  - **What it collides with:** your note that the ellipse shadows do not work well (velvet-marten #700) answered a cost question, drawing shadows as pictures for speed, and is not read as choosing the second way.
  - **What each answer costs:** keeping the ovals costs nothing more; the second way is a picture to draw for every object, and the plaid-chipmunk page is where they land.
  - **My pick:** keep the ovals unless the first two questions answer no.
  - **You:** 
  - **Me:** 
