extends Node3D

@export var size : Vector3
@export var passages : Array[Node3D]
@onready var area_3d: Area3D = $"Room Surface/Area3D"

func get_size()->Vector3:
	return size

func get_passage_data():
	var data = []
	for passage in passages:
		var add = []
		add.append(passage.position)
		add.append(passage.get_direction())
		data.append(add)
	return data

#func _process(delta: float) -> void:
	#print(area_3d.has_overlapping_areas())

func has_overlapping()->bool:
	return area_3d.has_overlapping_areas()
