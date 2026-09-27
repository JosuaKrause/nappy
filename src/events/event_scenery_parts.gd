class_name EventSceneryParts
extends RefCounted
## Registered vector spans in painter order; split-scenes.py preserves their source artwork.

const LAYERS := {
	"burst_water_main": [
		["burst_water_main_static_0", 26, 21, 148, 29, false],
		["burst_water_main_motion_1", 38, 29, 126, 19, true],
		["burst_water_main_static_2", 62, 15, 76, 33, false],
		["burst_water_main_motion_3", 76, 37, 49, 6, true],
		["burst_water_main_static_4", 51, 22, 98, 28, false],
		["burst_water_main_motion_5", 63, 1, 74, 40, true],
		["burst_water_main_static_6", 3, 1, 194, 42, false],
	],
	"burst_water_main_vertical": [
		["burst_water_main_vertical_static_0", 3, 1, 43, 170, false],
		["burst_water_main_vertical_motion_1", 8, 40, 31, 117, true],
		["burst_water_main_vertical_static_2", 7, 49, 36, 95, false],
		["burst_water_main_vertical_motion_3", 15, 114, 21, 15, true],
		["burst_water_main_vertical_static_4", 0, 72, 50, 79, false],
		["burst_water_main_vertical_motion_5", 0, 82, 50, 40, true],
		["burst_water_main_vertical_static_6", 14, 166, 22, 33, false],
	],
	"car_accident": [
		["car_accident_static_0", 10, 5, 123, 45, false],
		["car_accident_motion_1", 74, 0, 23, 14, true],
		["car_accident_static_2", 173, 5, 17, 44, false],
	],
	"car_accident_vertical": [
		["car_accident_vertical_static_0", 0, 1, 50, 118, false],
		["car_accident_vertical_motion_1", 27, 48, 22, 19, true],
		["car_accident_vertical_static_2", 15, 153, 20, 44, false],
	],
}
