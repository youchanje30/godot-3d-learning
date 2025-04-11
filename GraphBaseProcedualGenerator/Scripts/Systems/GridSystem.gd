extends Node
class_name GridSystem

var grid_data: Dictionary = {}
var special_cells: Dictionary = {}

func vector_to_key(vec: Vector3i) -> String:
	return "%d,%d,%d" % [vec.x, vec.y, vec.z]

func key_to_vector(key: String) -> Vector3i:
	var parts = key.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))

func is_cell_occupied(position: Vector3i) -> bool:
	return grid_data.has(vector_to_key(position))

func occupy_cell(position: Vector3i, room: Node) -> void:
	grid_data[vector_to_key(position)] = room

func clear_cell(position: Vector3i) -> void:
	var key = vector_to_key(position)
	if grid_data.has(key):
		grid_data.erase(key)

func add_special_cell(position: Vector3i, direction: Vector3i) -> void:
	special_cells[vector_to_key(position)] = direction

func get_special_cell(position: Vector3i) -> Vector3i:
	return special_cells.get(vector_to_key(position), Vector3i.ZERO)

func has_special_cell(position: Vector3i) -> bool:
	return special_cells.has(vector_to_key(position))

func get_cell_data(position: Vector3i) -> Node:
	return grid_data.get(vector_to_key(position))

func get_all_special_cells() -> Dictionary:
	return special_cells 
