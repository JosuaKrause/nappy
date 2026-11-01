# Tuning holds shared balance numbers only

`src/autoload/tuning.gd` holds 261 constants, 141 of them used by exactly one file.

**Build:** constants used by one owner move to it. Read **balance** before moving any number a player can
feel; nothing changes value.
