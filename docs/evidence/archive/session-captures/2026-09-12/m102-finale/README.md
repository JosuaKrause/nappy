# M102, the finale — the two sections behind `--start-escape`

Runtime evidence for the escape sequence, taken on seed 4242 at 1280×720 with `--invincible`, so
the clock stands still at `3:00.000` and the excitement meter cannot end the run under the rig.
The HUD carries the word `INVINCIBLE` in both captures and every line of the run log is stamped
`0.0` because the clock never advanced; neither capture is a claim about what a real attempt
costs.

## Section one — the hallway, and an explosion's window flash

`section-one-hallway-window-flash.png`, from

```sh
tools/shot.sh out.png 22.04 --seed 4242 --start-escape --invincible
```

She is at her own door on the third floor with the baby asleep in her arms (sleepiness 100, the
`Z` over her shoulder). `InteriorEvents` fires an off-screen explosion every
`Tuning.FINALE_EXPLOSION_INTERVAL` (22 seconds) and flashes every hallway window for
`Tuning.FINALE_WINDOW_FLASH_SECONDS` (0.12 seconds), so the still is aimed at the first beat: the
six windows are carrying `hallway_wall_window_flash.svg` rather than the dark
`hallway_wall_window.svg` they wear either side of it. The clock above her reads `3:00.000` — the
finale's millisecond format, `%d:%02d.%03d`, where a day draws `%d:%02d`.

`section-one-hallway-window-flash-run.log` is that run's own trace.

## Section two — the city, the chain, the seals and the vehicles

`rig-145442-seed4242-v0.8.2-746-ga87f5bf-dirty/` is the whole run folder, from

```sh
tools/shot.sh out.png 12 --seed 4242 --start-escape city --invincible --walk north \
    --press snapshot_burst 7
```

`asked/burst-8950729-001/` holds 36 frames over 2.99 seconds with `burst.json`'s own timestamps,
and `burst-8950729-001.mp4` beside it is the viewing convenience; judge motion from the recorded
times, not from the file order. The rig walks north out of the service exit, which on this seed is
the first leg of the tunnel chain — the run log's plan line says what both chains cost.

`frame-0018.png` is the frame the record names: she is walking up the open sidewalk with the chain
ahead of her, an unmarked van moving on the carriageway to her left, and the street to her right
shut by a line of burnt-out cars and barricades — the sealing `SealPlanner.plan_finale()` lays on
every street off the two chains. By `frame-0036.png` a `roadblock` guard has left his post and is
on her, and an army truck is crossing the top of the view.

`section-two-city-chain-final-frame.png` is the same run's closing still at twelve seconds, kept
because it shows two danger carets at once at a junction.
