# silver-egret — Do the cars' shadows now read as ground contact · 2026-11-25

### cars-stand-on-their-wheels

- **Question:** silver-egret, do the cars and vans now read as standing on their wheels? (built on my pick)
- **Context:**
  - **What was asked:** a shadow sits where the object meets the ground, a car's only where its wheels would be, never above its roof (minty-hedgehog 1).
  - **What was built:** each car or van now casts one small oval under each pair of wheels, sitting on the line its tyres stand on, where before one oval or capsule lay behind its whole picture and showed above the roof of a car coming at you or driving away.
  - **What to do:** play a day with traffic on the desktop build (`tools/run.sh --seed 4242 --day 4`, so the police car patrols), stand at a junction on a busy street and watch cars pass side on, come at you, drive away end on and turn the corner. Walk past a parked delivery van on the sidewalk, and on day 13 or later (`--day 13`) watch an army truck go by.
  - **What to look for:** each oval under a pair of tyres, none showing above a roof or behind a body with nothing under it. The sheets in `docs/evidence/silver-egret-shadows-2026-11-25/` show every car and van in all eight directions, before and after.
  - **Left as they were:** the riot van of the night raid and the moving van keep their old oval across the whole van; the vans sheet shows both as they look now, and the entry's follow-up (`riot-and-moving-van.md`) is where they are built.
  - **Cost of a no:** the ovals' three numbers (`POINT_WHEEL_SHARE`, `WHEEL_OVAL_SHARE`, `WHEEL_DEPTH`) were chosen by eye and each is one constant; a change to them is cheap.
  - **My pick:** yes if the ovals read as ground under the wheels on the street; say which car or view reads wrong if not.
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
