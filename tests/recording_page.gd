extends RefCounted
## The page a counter sends to, for a suite: an outbox that records the scripts it is asked to
## evaluate and the platform of a released web page with `count.js` loaded, handed to a
## `VisitCounter` (`send_through()`) so its real gate and send path run and `names()` lists the
## names its events were counted under, in the order they were.

## The scripts the outbox was asked to evaluate, in order.
var _scripts: Array[String] = []
## The event name each script counts, in order.
var _names: Array[String] = []

const _PREFIX := "try { window.goatcounter.count("
const _SUFFIX := "); } catch (e) {}"

## The scripts the outbox was asked to evaluate, in order: the list itself, which grows as events
## are counted.
func scripts() -> Array[String]:
	return _scripts

## The event name each script counts, in order: the list itself, which grows as events are counted.
func names() -> Array[String]:
	return _names

## An outbox whose evaluator is this page's recorder.
func outbox() -> GoatCounterOutbox:
	return GoatCounterOutbox.new(_evaluate)

## A release's version, the build every visitor of the site's root gets.
const RELEASE_VERSION := "v0.30.0"

## The answers of a released web page whose `count.js` has loaded.
static func platform() -> GoatCounterPlatform:
	return GoatCounterPlatform.new(true, false, func() -> bool: return true, RELEASE_VERSION)

## The options `script` hands `count()`, parsed back out of the line, or empty where the line is
## not the one call `GoatCounterOutbox` writes.
static func options_of(script: String) -> Dictionary:
	if not script.begins_with(_PREFIX) or not script.ends_with(_SUFFIX):
		return {}
	var parsed: Variant = JSON.parse_string(script.substr(_PREFIX.length(),
			script.length() - _PREFIX.length() - _SUFFIX.length()))
	return parsed if parsed is Dictionary else {}

func _evaluate(script: String) -> void:
	_scripts.append(script)
	_names.append(str(options_of(script).get("path", "")))
