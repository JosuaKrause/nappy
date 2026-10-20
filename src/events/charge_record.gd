class_name ChargeRecord
extends RefCounted
## One charger's charge as it is counted: its warning, its start, and the one way it ended.
##
## **The one owner of the rule that a charge that began ends in exactly one way** — caught
## (`pursuit_caught`), cut short by the day or the section ending some other way
## (`pursuit_cut_short`), or over without catching her (`pursuit_ended`, shaken off or outlasted)
## *(inbox #764 in minty-lemur: a charging counter is independent of an ended day)*. Every path that
## ends a charge — the catch, the day's end closing what is still running, the charger giving up or
## leaving — asks this record, and the first to ask is the only one heard. A warning is said once,
## and a charge begins once. Nothing that decides anything reads it.

## The name the charge is counted under, asked at the moment it is said: a charger's name can be
## settled after it is made (the day-3 lesson's dog, day 13's task guard).
var _name: Callable
## The bus the charge is said on, handed in by the charger.
var _bus: Node

## Whether its warning has been said, its charge has begun, and its charge has ended.
var warned := false
var began := false
var ended := false

func _init(name_of: Callable, bus: Node) -> void:
	_name = name_of
	_bus = bus

## Its warning going up, said once.
func warn() -> void:
	if warned:
		return
	warned = true
	_bus.pursuit_warned.emit(_name.call())

## It comes for her, said once.
func begin() -> void:
	if began:
		return
	began = true
	_bus.pursuit_began.emit(_name.call())

## Its charge caught her.
func catch() -> void:
	if _may_end():
		_bus.pursuit_caught.emit(_name.call())

## Its charge was still running when the day or the section ended some other way.
func cut_short() -> void:
	if _may_end():
		_bus.pursuit_cut_short.emit(_name.call())

## Its charge is over without catching her: `shaken_off` when she outran it, otherwise outlasted.
func end(shaken_off: bool) -> void:
	if _may_end():
		_bus.pursuit_ended.emit(_name.call(), shaken_off)

## Whether a charge that began has not yet ended, marking it ended when it has not: the one gate
## all three endings pass, so whichever comes first is the only one said.
func _may_end() -> bool:
	if not began or ended:
		return false
	ended = true
	return true
