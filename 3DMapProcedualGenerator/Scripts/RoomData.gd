extends Node3D

@export var size : Vector3
@export var passages : Array[Node3D]

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
