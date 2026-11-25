# amber-puffin — Judge the Voronoi water by eye and choose how it enters the game · 2026-11-25

### voronoi-water-look

- **Question:** amber-puffin, judge the Voronoi water: curved or straight outlines for the south water? (built on my pick)
- **Context:**
  - **What was asked:** a blue base with white lines that are the outlines of the regions round randomly placed centroids, each centroid's intensity oscillating so the outlines move "in a way water looks" (mossy-ferret #708), tried in a standalone experiment first.
  - **What to open:** `curved.gif` and `straight.gif` in [the evidence folder](../evidence/amber-puffin-voronoi-water-2026-11-25/README.md), each a quarter of the game's view at the desktop's scale, 6 s; `curved-full-view.png` is the whole view.
  - **For comparison:** today's water is `waterfront.gif` in the m159 scenery-animation evidence folder.
  - **Curved:** the intensity is taken off the distance to each centroid, so the outlines bend and sway. Where a region shrinks to nothing it leaves a short hook ending in open water.
  - **Straight:** the intensity is taken off the squared distance, so the outlines stay straight and the cells read as panes that slide; a shrinking region closes as a small triangle.
  - **Cost:** the same for both (3.1 and 3.2 ms a pass on the desktop at 1920x1080, see the drawing question).
  - **Changing course later:** one shader setting; both looks are what was asked for.
  - **My pick:** curved, since its outlines sway the way caustics on water do, where the straight one reads as cracked glass.
  - **You:** 
  - **Me:** 

### voronoi-water-settings

- **Question:** amber-puffin, keep the water's settings as they are, or change which? (built on my pick)
- **Context:**
  - **Cell size:** 48 world pixels between centroids on average; a ground tile is 32, so a cell is about one and a half tiles.
  - **Line width:** 1.25 world pixels, which is 2.5 screen pixels on the desktop and about 3.75 on a phone held sideways.
  - **Line brightness:** white at 85% over the blue.
  - **Intensity swing:** up to 0.25 of a cell to either side, so an outline moves by up to about 12 world pixels. A smaller swing draws fewer of the curved look's hooks and moves less.
  - **Periods:** each centroid swings on its own period between 3 and 7 s.
  - **Placement:** each centroid sits anywhere in the middle 80% of its cell; a wider spread made the drawing miss outlines.
  - **Cost:** none of these changes what a frame costs.
  - **My pick:** keep all of them for the first build in the game, where the water is seen beside the bulkhead and the bridge, and tune there; each is one number in the shader.
  - **You:** 
  - **Me:** 

### voronoi-water-drawing

- **Question:** amber-puffin, how does the water get drawn: live over the water, one live tile repeated, or a baked loop? (built on my pick)
- **Context:**
  - **No phone was measured.** The figures are this desktop's Apple M2 drawing as many pixels as a phone does: 1920x1080 (a phone held sideways at the ratio the player's phone reported, the game keeping 16:9) and 1280x720.
  - **So the ratios carry the choice, not the milliseconds**: a phone's GPU is slower than the M2 by a factor not measured, and the phone's renderer is already bound by the pixels it fills (velvet-marten's frame records).
  - **Live over the water:** the shader runs on every water pixel. One pass over a 1920x1080 canvas took 3.1 ms against 0.12 for a flat fill and 0.16 for today's water: about 25 times a flat fill and 10 to 20 times today's water. The water fills less than half the view, since the camera keeps her centred and she never stands south of the bulkhead. **This is the way a phone could make too slow.** Its outlines are sharp at any scale and nothing repeats.
  - **One live tile repeated:** a tile of eight cells (384 world pixels) is drawn every frame and repeated over the water. It costs about what today's water does (0.12 ms a pass) plus 0.21 ms for the tile itself, a fixed cost whatever the screen size. The pattern repeats every 384 world pixels (`tile-repeated-full-view.png` shows it), and drawn at one texel a world pixel its outlines are magnified two or three times on screen and soften.
  - **A baked loop:** the tile's frames are drawn once, ahead of time, and played back. It costs a frame what today's water does, and memory: a 12 s loop at 12 fps is 21 MB for the eight-cell tile at a byte a texel, 5 MB for a four-cell tile. It repeats in space like the live tile, and in time every 12 s.
  - **How far the figures can be trusted:** two runs differed. Today's water read 0.157 ms in the kept run and 0.245 in the earlier one, the curved lines 3.1 and 2.6, a flat fill 0.120 and 0.105; other agents' Godot test runs were going through both, and a pass as small as today's water is near the noise. So the live way's ratio to today's water is 10 in one run and 20 in the other; its ratio to a flat fill, about 25, held in both.
  - **Changing course later:** every way draws the same shader, so a switch is a change to how the south water's surface draws it, not a new picture.
  - **My pick:** one live tile repeated, since it costs about what the phone already pays for today's water and only the live way risks the phone's frame rate; if the repeat reads as too plain, the live way, measured on the phone before it ships.
  - **You:** 
  - **Me:** 
