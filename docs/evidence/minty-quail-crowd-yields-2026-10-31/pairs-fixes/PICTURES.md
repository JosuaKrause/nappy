# C2b before/after pictures

Base = origin/main 21171ee0 (before C2b), head = f9e82530. Same machine, recipe, seed and moment for each pair. `before/` is base,
`after/` is head, `pairs/` has them side by side (base left, head right), `recipes/` has the recipes (see recipes/README.txt).
All stills are `tools/shot.sh ... --recipe-mode scripted --player-view --no-save --invincible`.

1. m1-dog.png (dog through walkers, 2.8s): shows the yielding, weakly. The dog is at the same spot in both. The walker to the right of
   the dog (about x1075) is a body-length lower on head than on base, off the dog's line; on base it is nearer the line. Other walkers
   are the same. Subtle at one frame; the existing five-frame set (docs/evidence/minty-quail-crowd-yields-2026-10-31/pairs) is the stronger one.
2. m2-car-dog.png (crowd car and the dog crossing its lane, 2.85s): shows it. Base: the car has driven up behind the dog, its nose about
   a car-length (about 40px) from it and still closing. Head: the car is about 80px (screen) further back, held behind the dog in its lane.
   One frame; the dog is not overlapped on either, so the frame shows a gap, not a car driving through.
3. m3-column-1.4.png and m3-column-1.6.png (day 13 column through walkers crossing the main road at a junction): clear at 1.4s, milder at 1.6s.
   Three pinned walkers cross the main road on the junction's north crossing as the lead truck drives through. 1.4s: on base a walker is
   alongside the lead truck, overlapping it; on head the two walkers have stopped at the kerb short of the truck. 1.6s: head walkers still
   hold a step back from the crossing; base walkers are already in it. m3-column-1.2.png is the frame before (nothing differs yet).
   The convoy has civilian cars mixed in among the trucks; the walkers are the three pinned ones, the crowd walkers are on the sidewalks.
4. m4-tear-cop-3.6.png (policeman on foot from a torn poster, running up the main road through a crossing where walkers cross, day 8,
   seed 13): shows it, modestly. At 3.6s on base a walker stands against the policeman's left side, overlapping him; on head that walker
   is 40px (screen) to the right of him, clear. m4-tear-cop-3.2.png and -4.0.png are the frames either side; 3.2 has a walker beside the
   arrow on head and none there on base, 4.0 is near-identical on both. The recipe is rigged: four pinned walkers cross the main road at
   the junction the policeman crosses, timed to his arrival; the policeman is the real poster-pursuit one, not placed by the recipe.
   This is the policeman only; the robber, van guard and guardsman rows are the same pursuit shape and were not pictured separately.
5. m5-stall-1.8.png and m5-stall-2.4.png (walkers meeting a market stall standing on the sidewalk): does NOT show the change. The stall
   fills the footway (its body is a band across both lanes), and on both base and head the walkers walk up to it and turn back; the frames
   are the same. m5-cafe-2.1.png and m5-cafe-2.7.png (cafe tables with seated people, same recipe): same, no difference. I could not
   stage a walker meeting a standing stall or van on open ground (a SQUARE tile, which the stall allows, was not found), nor a van
   standing where a walker can pass it: delivery_van and ice_cream_van park on the carriageway beside the sidewalk, so no walker meets them.
   A pinned walker that meets the stall on base does not walk through it in these runs, which contradicts "on base it walks through";
   this may be the footway-closing check that holds walkers at a sidewalk event on both.
6. m6-firetruck-19.png and m6-firetruck-23.png (crowd cars beside the parked fire truck, day 3, crowd on): does NOT show the change. Two
   crowd cars are in the other lane beside the parked truck in both, at the same places. The truck parks in the near westbound lane and
   the cars were in the lane next to it, not behind it, so nothing stands behind a figure or turns round. A pinned car meant to arrive
   behind the truck as it parked (130px/s from x3900) never came into frame at 12.5s to 17.5s on either checkout, so there is no picture
   of a car standing behind the parked truck or turning round behind it. A car standing behind a figure in its lane is shown by pair 2.
