# Playtest 45 — Illustrated texture integration · 2026-09-08

## Player report

> the player texture is missing. the legs of the mustard and red people look odd -- slanted when goind east/west and moving outwards when going north/south. from the reference image you created I can tell that the distance between pram and player is too large forcing the arms the stretch unnaturally long. also, the pram is pixelated for some reason. document/create skills/etc for making the process of adding textures reproducible. note down all traps and footguns so we can be faster in the future

The player supplies [this gameplay image](evidence/run-195148-seed1407488451-v0.7.0-34-g4ae11f4/asked/008s-attempt1-asked.png).
The complete originating run folder is preserved beside it, including the log and map. The image
shows the legacy mother/pram comparison without its illustrated counterpart. The directional
movement observations are the player's report; a still does not establish their motion.
The generated assembly image mentioned by the player is diagnostic evidence, not an approved
style reference. Its exact identity is not specified in this message.

## Import and repository feedback

> why do you keep removing import files? they always have been part of the repo

The player also reports these runtime errors before this image review:

```text
SCRIPT ERROR: Invalid call. Nonexistent function 'new' in base 'GDScript'.
          at: Stroller._ensure_modular_person (res://src/player/stroller.gd:146)
          GDScript backtrace (most recent call first):
              [0] _ensure_modular_person (res://src/player/stroller.gd:146)
              [1] _physics_process (res://src/player/stroller.gd:214)
SCRIPT ERROR: Invalid call. Nonexistent function 'apply_displacement' in base 'Nil'.
          at: Stroller._physics_process (res://src/player/stroller.gd:217)
          GDScript backtrace (most recent call first):
              [0] _physics_process (res://src/player/stroller.gd:217)
```

The supplied error report repeats this pair twice. Preserve `.import` sidecars as repository
assets; generated status does not make them disposable. The requested process documentation
must cover preparing the actual test checkout, inspecting the first load error, and keeping
source acceptance, mathematical attachment checks and visual acceptance distinct.

## Relationship to existing requests

This is a further report against PLAYTEST-43's connected anatomy and legacy-scale requirements,
with PLAYTEST-44's selected transparent v3 pram retained. Add explicit acceptance for natural
east/west leg posture, north/south stride direction, mother-to-handle reach without stretched
arms, and illustrated pram quality at gameplay scale. Do not treat these as accepted because
endpoint tests pass. Track the repair in the existing illustrated actor queue rather than
creating a competing design.
