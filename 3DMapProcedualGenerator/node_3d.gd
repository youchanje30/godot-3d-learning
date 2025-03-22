extends Node3D

@onready var area_3d: Area3D = $Area3D
@onready var area_3d_2: Area3D = $Area3D2


func _process(delta: float) -> void:
	print(area_3d.has_overlapping_areas())
