# Expose the shared builder to tests and the game

**Proposed, not asked for:** a dev flag names the recipe; declare it in the shared
dev-flag surface. Validate before starting and report conflicts with other flags.
Keep recipe runs away from the player's save. A headless caller and a live launch
consume the same constructed data and retain its validation scope and fixture status.

**Proposed, not asked for:** recipes name initial day/progression, player position,
facing, parent, meters, pinned actors and a documented ambient default. Use real event
definitions, traffic/crowd actors and normal simulation. Later scheduling must not
overwrite required setup. Expose only supported fields and reject unsupported values.

Reuse the existing optional walking/input and camera rigs for action checks. Setup
finishes before the simulation clock begins. Tests distinguish initial construction
from required state at a named simulation tick. Report unmet conditions rather than
claiming success from startup alone. Record game/recipe/settings provenance and
distinguish state repeatability from pixel equality.

The trailer slice extends this seam with its actual scenes and configurable capture
time; the free-play slice exposes ordinary controls and exterior exploration for all
recipes. Neither slice is required to prove this builder and its join tests complete.
