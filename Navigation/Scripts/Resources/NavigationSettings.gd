extends Resource

class_name NavigationSettings

@export_category("Agent Settings")
@export var agent_radius: float = 0.5
@export var agent_height: float = 2.0
@export var max_slope: float = 45.0

@export_category("Pathfinding Settings")
@export var path_smoothing: bool = true
@export var path_max_distance: float = 100.0
@export var path_update_interval: float = 0.5

@export_category("Region Settings")
@export var region_activation_distance: float = 50.0
@export var region_update_interval: float = 0.2

func get_agent_params() -> Dictionary:
	return {
		"radius": agent_radius,
		"height": agent_height,
		"max_slope": max_slope
	} 
