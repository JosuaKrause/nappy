# M109, the comic dogs walking in the game

Two `tools/shot.sh` bursts of the installed comic dogs on `feature/comic-dogs-preview` at commit
`b6bfdbfc`, a default (PNG) bake, each kept as its whole run folder. `--invincible` holds the day
open so the capture can wait for the dog; nothing here is about cost or a loss.

## The normal dog, on a dog walker's lead

```sh
tools/shot.sh out.png 14 --seed 4242 --day 2 --force dog_walker 2 --follow dog_walker \
    --zoom 2.5 --invincible --walk north --press snapshot_burst 9
```

`rig-171340-seed4242-v0.20.0-46-gb6bfdbfc/`: the camera follows a dog walker heading west, so the
dog draws its side pictures mirrored. Over the three seconds of
`asked/burst-12553526-001/` it walks step, rest, opposite step, rest at the dog walker's 32px/s,
a beat about every 545ms, which the crops show as runs of six or seven frames per picture.
[`dog-crops.png`](rig-171340-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-12553526-001/dog-crops.png)
is every frame's crop at 3× with its measured time;
[`dog-crops.gif`](rig-171340-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-12553526-001/dog-crops.gif)
plays them at the burst's own frame times.

## The charging dog

```sh
tools/shot.sh out.png 6 --seed 4242 --day 4 --invincible --spawn event:charging_dog --walk east \
    --follow charging_dog --zoom 2 --press snapshot_burst 0.5
```

`rig-171758-seed4242-v0.20.0-46-gb6bfdbfc/`: one of day 4's placed charging dogs, beside which
`--spawn` puts her. It holds its gallop picture through the telegraph, turns and comes for her,
then keeps with her as she walks east, alternating its gallop and gathered pictures;
`auto/001-attempt1-chase-charging_dog.png` is the game's own capture on the chase line.
[`dog-crops.png`](rig-171758-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-4085226-001/dog-crops.png)
and [`dog-crops.gif`](rig-171758-seed4242-v0.20.0-46-gb6bfdbfc/asked/burst-4085226-001/dog-crops.gif)
are its crops.

## Rebuild the crops

```sh
uv run python docs/evidence/m109-comic-dogs-in-game-2026-09-27/crop-bursts.py
```

`crop-bursts.py` reads only the committed frames and `burst.json` files and writes the sheet and
GIF beside each burst; its crop windows are fixed per burst, since `--follow` keeps the followed
event near one spot on the screen. A burst shows the moving assembly in one place on one seed; the
review sheets under `docs/evidence/comic-dogs-2026-09-27/` show every facing.
