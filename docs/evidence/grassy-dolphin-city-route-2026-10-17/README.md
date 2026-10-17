# grassy-dolphin: the escape's city route, a sidewalk open and the kerb tint

What these show: the escape's city section on seed 38 after the change on
`feature/grassy-dolphin-city-route` (source revision 9a452ff5, shown in the readout). A roadblock's
band stands across the street east of the first junction south of the service exit; its bounding
box (debug layer 3, the green capsule) covers the north sidewalk and the carriageway and leaves the
south sidewalk open from junction to junction. The kerb lines of that street carry the route's
yellow tint (M145), which is faint by design and easiest to see in the enlarged crop.

Limits: one seed and one street. That every chain street keeps a sidewalk open is held by
`tests/test_finale.gd` (a flood past every body on eight seeds), not by these frames. The scene is
night, so the tint reads fainter than on a day. The run is `--invincible`, and in the first frame
the roadblock's guard has already left his post and reached her; the band he left is what stays.

Files:

- `roadblock-far-sidewalk-open.png`: the band across the street, with the open south sidewalk past it.
- `roadblock-far-sidewalk-open-crop.png`: the same frame cropped to the junction and enlarged 2x
  (nearest neighbour), for the tinted kerbs.
- `escape-start-guards-at-post.png`: where she comes out, the two guards still at the band at the
  bottom of the frame.

Commands (1280x720):

    tools/shot.sh roadblock.png 2.2 --seed 38 --start-escape city --zoom 0.6 --invincible --press ui_accept 0.3 --walk 0.6p1.2s --layers 3
    tools/shot.sh start.png 1.5 --seed 38 --start-escape city --zoom 0.5 --invincible --press ui_accept 0.3 --layers 3
