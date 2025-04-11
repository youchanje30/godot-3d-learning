extends Node
class_name CollisionSystem

var grid_system: GridSystem

func _init(grid: GridSystem) -> void:
	grid_system = grid

func check_collision(positions: Array[Vector3i]) -> bool:
	for pos in positions:
		if grid_system.is_cell_occupied(pos):
			return true
	return false

func get_valid_positions(room_positions: Array[Vector3i], target_pos: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for pos in room_positions:
		var world_pos = pos + target_pos
		if not grid_system.is_cell_occupied(world_pos):
			result.append(world_pos)
	return result

func can_place_room(room_positions: Array[Vector3i], target_pos: Vector3i) -> bool:
	return get_valid_positions(room_positions, target_pos).size() == room_positions.size() 
