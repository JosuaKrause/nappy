class_name QuitOption
extends RefCounted
## Whether the game can quit itself, and the single place that question is answered.
##
## `SceneTree.quit()` does nothing on a Web export — the tab just sits there — so offering `Q`
## on the web is a key a screen told the player to press and watched fail. The axis is the
## **platform**, not the build: a debug Web build has exactly the same dead quit as a release
## one, which is why this reads `OS.has_feature("web")` rather than `OS.is_debug_build()` — the
## same axis `Telemetry.begin_run()` already uses to stay silent on the web.
##
## Read once per screen into a member (`TitleScreen._can_quit`, `PauseScreen._can_quit`) rather
## than asked here at each use site, because a test process is never a web export: a gate asked
## of the OS directly at every call site would leave the web shape asserted by nothing at all.
## `hud._debug` follows the same pattern for its own release/debug gate.
##
## **`--web` previews the web shape from a desktop debug build** (`RunConfig.web_preview`), the role
## `TouchInput`'s own `--touch` plays for its platform fact: without it, the hidden-`Q` hint this
## class exists to show can only be looked at by exporting the game and opening it in a browser.
## It only changes what a screen *shows*, never what quitting *does*. The run's configuration is
## handed in, so nothing here reads the command line; with none handed in the answer is the
## platform's alone.

static func available(config: RunConfig = null) -> bool:
	if config != null and config.web_preview:
		return false
	return not OS.has_feature("web")
