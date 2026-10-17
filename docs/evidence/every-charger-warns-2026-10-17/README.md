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
