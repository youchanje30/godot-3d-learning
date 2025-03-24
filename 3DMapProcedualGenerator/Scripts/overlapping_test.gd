extends Node3D
@onready var navigation_region_3d: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	await get_tree().create_timer(30).timeout
	navigation_region_3d.bake_navigation_mesh()
