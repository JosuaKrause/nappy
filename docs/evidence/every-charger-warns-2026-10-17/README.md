# every charger warns (2026-10-17)

**The claim.** Every charger that does not arrive charging shows a warning before it charges
(inbox #764): the policeman a vehicle lets out has a raised-hand picture of his own in every view,
drawn as the guard's alert is, and in play each charger's stages are the ones the strips below
show.

## The policeman's alert, five views

[policeman-alert-v1.png](policeman-alert-v1.png), sha256
`871d665925e880723621842dc7c202cb766c1a767990d71ff9469ac6b988f199`, from
[policeman-alert-v1.json](policeman-alert-v1.json). Each row is one view, top to bottom front,
front diagonal, side, back diagonal and back; the columns are `policeman_waiting_<view>.svg`,
the new `policeman_alert_<view>.svg`, `policeman_lunging_<view>.svg`, and the guard's
`guard_alert_<view>.svg` for comparison. The top block is game scale, the bottom 6x, both on the
sidewalk's ground colour, each picture standing on its row's ground line at its bottom centre.

**Drawn** from the waiting picture by `art/events/policeman_alert_*.svg`'s own header comments:
feet planted wider, one arm raised palm out at head height — his left in front and behind, the
near arm in front of his face in the side view, the far arm in the diagonals — the other arm
and the baton at the hip as they were. Front and back keep the waiting picture's 22x44 canvas;
side and diagonals widen to 26x44 with the figure moved 2px, as the guard's alert does, so the
body stands where the waiting picture's does over the same bottom-centre anchor.

**Command**, from the repository root, after `./tools/check.sh`:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . \
    --script docs/evidence/every-charger-warns-2026-10-17/render-sheet.gd -- \
    --repo "$PWD" --spec docs/evidence/every-charger-warns-2026-10-17/policeman-alert-v1.json \
    --output <fresh>.png
```

`render-sheet.gd` is the teal-trout views sheet's renderer, copied unchanged.

**Limits.** A source preview through the engine's SVG parser, not a capture of the game: the
in-game strips are below.

## The strips

Each strip is cut from a frame-locked recording of its recipe, at the labelled time into the clip.

- [strip-dog.png](strip-dog.png) (sha256 `61bcbe3c…`), from [recipes/dog.json](recipes/dog.json),
  day 5: sitting; alert once she is inside its 130px radius at about 2.3s; still alert at 8.0s with
  her standing outside its 104px stand-off, longer than the 4.5s its notice ran before; sitting
  again the moment she walks back out.
- [strip-robber.png](strip-robber.png) (`a14aad53…`), from [recipes/robber.json](recipes/robber.json),
  day 8: waiting; his two-frame alert walk once she steps inside 180px; she walks back out at
  about 2.2s and, out of his radius, he waits hood up where his walk had got him, not at his post.
- [strip-roadblock.png](strip-roadblock.png) (`9331d665…`), from
  [recipes/roadblock.json](recipes/roadblock.json), day 7, heat 4: posted; hand raised at his post
  from about 2.3s, still raised at 4.0s and 6.0s with her standing inside his radius, longer than
  the 1.8s his notice ran before; back at the band and posted once she walks out.
- [strip-patrol.png](strip-patrol.png) (`f8eb4ba7…`), from [recipes/patrol.json](recipes/patrol.json),
  day 6, heat 3: the investigating car stops; its policeman gets out with his hand raised
  (`policeman_alert_*`) and stands in place for a second; he charges and stops her.
- [strip-van-day8.png](strip-van-day8.png) (`d7da3d86…`) and
  [strip-van-day9.png](strip-van-day9.png) (`a994065b…`), from
  [recipes/van-day8.json](recipes/van-day8.json) and [recipes/van-day9.json](recipes/van-day9.json),
  heat 4: the hunting unmarked van lets out its two men, policemen on day 8 and guardsmen on day
  9, who stand in place with their hands raised for a second and then charge.

**Recipes.** `dog.json`, `robber.json` and `roadblock.json` are the teal-trout wired evidence's
recipes (`docs/evidence/teal-trout-wired-2026-10-17/recipes/`, not in this checkout's sparse
tree) with only `name`, `playback.walk` and `playback.duration` changed, so she stands inside the
radius past the old notice and then walks back out: `1p1.25w6p2e3p` for 13.5s, `1p0.2n0.8p1.2s3p`
for 7.2s, `1p1.3s4p1.5n3p` for 10.5s. `patrol.json` and the two van recipes are the teal-trout
audit's `patrol.json` and `van.json` with only `name` (and the van's `setup.day`) changed.

**Command**, for each recipe, from the repository root:

```sh
tools/record.sh --out ecw-<name>.mp4 -- \
    --recipe "$PWD/docs/evidence/every-charger-warns-2026-10-17/recipes/<name>.json" \
    --invincible --after <the recipe's playback.duration plus 1.5>
```

then [strip.py](strip.py), which cuts each frame with `ffmpeg -ss <time>`, crops it, scales it with
nearest-neighbour and labels it with Pillow, refusing to overwrite a strip:

```sh
python3 strip.py build/records/ecw-<name>.mp4 <fresh>.png <x,y,w,h> <scale, v for a column> <time:label>...
```

with the crop, scale and labels each strip's own panels carry (dog `360,270,520,120 2v`, robber
`540,20,200,500 1`, roadblock `420,40,400,660 1`, patrol `520,0,280,560 1`, vans
`400,230,420,410 1`).

**Retained**: the strips, the recipes, and each recording's own `settings.json` and
`manifest.json` under `provenance/<name>/`. The clips and the movie writer's frames stay in
scratch.

**Limits.** One staging per charger, under `--invincible`. The doubled red caret over a charger
during its warning is the existing cue that its course would end her day, not part of this change.
The door guard and the masked man are not shown: the door guard's stages are unchanged, and the
masked man's alert is pinned by `tests/test_event_views.gd`.
