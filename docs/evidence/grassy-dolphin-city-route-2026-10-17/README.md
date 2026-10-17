# grassy-dolphin: the escape's city route, a sidewalk open and the kerb tint

What these show: the escape's city section on seed 38 after the change on
`feature/grassy-dolphin-city-route` (source revision 9a452ff5, shown in the readout). A roadblock's
band stands across the street east of the first junction south of the service exit; its bounding
box (debug layer 3, the green capsule) covers the north sidewalk and the carriageway and leaves the
south sidewalk open from junction to junction. The kerb lines of that street carry the route's
yellow tint (M145), which is faint by design and easiest to see in the enlarged crop.

Limits: one seed and one street. That every chain street keeps a sidewalk open is held by
`tests/test_finale.gd` (a flood past every body on nine seeds), not by these frames. The scene is
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

## A van and a band on one street, and the tint beside a plain kerb

Seed 1, at revision b64fa907 (shown in the readout), where the review asked for the pair that used
to close a street: a van and a roadblock's band on the same chain street.

- `van-and-band-north-sidewalk-open.png`: east of the junction she stands in, a roadblock's band
  (the green capsule of debug layer 3) spans the carriageway and the south sidewalk, with the van
  parked on the south sidewalk at its foot; the north sidewalk stays open past both. The double
  exclamation mark over her is the roadblock's guard noticing her (`--invincible`).
- `kerb-chain-street-tinted.png` and `kerb-sealed-street-plain.png`: the south kerb of the street
  east of the junction (a chain street) and of the street west of it (sealed), cropped from the
  same frame and enlarged 4x (nearest neighbour). The first carries the route's yellow tint and the
  second is the plain kerb, at night in both.

Limits: one seed and one street. The frame was taken before `EventDef.stands_for_its_notice`
(PR #757) reaches the roadblock row, so the guard's movement during his notice may differ after it;
the band is the same either way.

Commands (1280x720):

    tools/shot.sh van-band.png 3.3 --seed 1 --start-escape city --invincible --press ui_accept 0.3 --walk 0.6p2.4s --layers 3
    # crops, from that frame: (830,320)-(950,370) and (10,320)-(130,370), each resized 4x nearest
