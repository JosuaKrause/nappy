class_name PlacementView
extends RefCounted
## **The three views on the city's events** (inbox #1185): on the route, route-adjacent and off the
## route. Each view has its own bag, and a location is filled from its view's bag (`docs/EVENTS.md`,
## "The three views and the placement order"). Which view a street is in is `Corridor.view_of()`'s
## answer, given once at dawn to every location of the street (`DayLocations.lay_out()`).
##
## A value and nothing else: no state, nothing that runs.

## - `ON_THE_ROUTE`: a street the day's routes run along, both its sidewalks.
## - `ROUTE_ADJACENT`: a street off the routes, one of whose two junctions a route crosses.
## - `OFF_THE_ROUTE`: every other street.
enum View { ON_THE_ROUTE, ROUTE_ADJACENT, OFF_THE_ROUTE }
