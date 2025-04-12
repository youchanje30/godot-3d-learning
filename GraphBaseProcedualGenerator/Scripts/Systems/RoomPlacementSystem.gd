extends Node
class_name RoomPlacementSystem

var grid_system: GridSystem
var collision_system: CollisionSystem

const ROTATIONS = [0, 1, 2, 3]  # 0°, 90°, 180°, 270°

func _init(grid: GridSystem, collision: CollisionSystem) -> void:
	grid_system = grid
	collision_system = collision

func rotate_vector(vec: Vector3i, angle: int) -> Vector3i:
	match angle:
		0: return vec
		1: return Vector3i(vec.z, vec.y, -vec.x)
		2: return Vector3i(-vec.x, vec.y, -vec.z)
		3: return Vector3i(-vec.z, vec.y, vec.x)
	return vec

func rotate_positions(positions: Array[Vector3i], angle: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for pos in positions:
		result.append(rotate_vector(pos, angle))
	return result

func get_direction_from_angle(angle: int) -> Vector3i:
	match angle:
		0: return Vector3i.BACK
		1: return Vector3i.RIGHT
		2: return Vector3i.FORWARD
		3: return Vector3i.LEFT
	return Vector3i.BACK

func try_place_room(room: Room, target_pos: Vector3i, preferred_angle: int = -1) -> bool:
	var positions = room.get_positions()
	var doors = room.get_doors()
	
	var angles = ROTATIONS if preferred_angle == -1 else [preferred_angle]
	
	for angle in angles:
		var rotated_positions = rotate_positions(positions, angle)
		if collision_system.can_place_room(rotated_positions, target_pos):
			# Place room
			for pos in rotated_positions:
				grid_system.occupy_cell(pos + target_pos, room)
			
			# Handle doors
			for door_pos in doors:
				var rotated_door_pos = rotate_vector(door_pos, angle)
				var door_direction = rotate_vector(doors[door_pos], angle)
				grid_system.add_special_cell(rotated_door_pos + target_pos, rotated_door_pos + target_pos + door_direction)
			room.apply_transform(target_pos, angle)
			return true
	return false

func try_place_random_room(room: Room) -> bool:
	var special_cells = grid_system.get_all_special_cells()
	if special_cells.is_empty():
		print("No special cells found")
		return false
	
	var keys = special_cells.keys()
	var random_key = keys[randi() % keys.size()]
	# var target_pos = grid_system.key_to_vector(random_key)
	# var direction = special_cells[random_key]
	
	# # Calculate preferred angle based on the direction
	

	var target_pos = special_cells[random_key]
	var dir = target_pos - grid_system.key_to_vector(random_key)
	var preferred_angle = -1
	if dir == Vector3i.BACK: preferred_angle = 0
	elif dir == Vector3i.RIGHT: preferred_angle = 1
	elif dir == Vector3i.FORWARD: preferred_angle = 2
	elif dir == Vector3i.LEFT: preferred_angle = 3

	return try_place_room(room, target_pos, preferred_angle) 
