extends Node3D
@onready var base_room: Node3D = $"Base Room"
@onready var base_room_2: Node3D = $"Base Room2"



func _ready() -> void:
	await get_tree().create_timer(1).timeout
	base_room.global_position = Vector3.ZERO
	await get_tree().create_timer(0.01).timeout
	print(base_room.has_overlapping())
	await get_tree().create_timer(0.05).timeout
	print(base_room.has_overlapping())
