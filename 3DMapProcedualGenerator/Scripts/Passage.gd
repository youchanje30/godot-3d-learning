extends Node3D

@export var direction : Vector3
@export var angle : int

func get_direction():
	return direction

func get_angle():
	return angle + global_rotation_degrees.y
