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

func get_angle_from_direction(dir: Vector3i) -> int:
	if dir == Vector3i.BACK: return 0
	elif dir == Vector3i.RIGHT: return 1
	elif dir == Vector3i.FORWARD: return 2
	elif dir == Vector3i.LEFT: return 3
	return 0

func try_place_room(room: Room, target_pos: Vector3i, preferred_angle: int = -1) -> bool:
	var positions = room.get_positions()
	var doors = room.get_doors()
	
	# If preferred_angle is specified, we need to check if doors align properly
	if preferred_angle != -1:
		for door_pos in doors:
			var door_direction = doors[door_pos]
			# Calculate required rotation to align door with preferred direction
			var door_angle = get_angle_from_direction(door_direction)
			var required_angle = (preferred_angle - door_angle + 4) % 4
			
			# Calculate the position where the door should be after rotation
			var rotated_door_pos = rotate_vector(door_pos, required_angle)
			var needed_offset = target_pos - rotated_door_pos
			
			# Check if room can be placed at this position
			var rotated_positions = rotate_positions(positions, required_angle)
			var moved_positions : Array[Vector3i] = []
			for pos in rotated_positions:
				moved_positions.append(pos + needed_offset)
			
			if collision_system.can_place_room(moved_positions, Vector3i.ZERO):
				# Place room
				for pos in moved_positions:
					grid_system.occupy_cell(pos, room)
				
				# Handle doors
				for d_pos in doors:
					var rot_door_pos = rotate_vector(d_pos, required_angle)
					var rot_door_dir = rotate_vector(doors[d_pos], required_angle)
					var final_door_pos = rot_door_pos + needed_offset
					grid_system.add_special_cell(final_door_pos, final_door_pos + rot_door_dir)
				
				room.apply_transform(needed_offset, required_angle)
				return true
		return false
	
	# If no preferred angle, try all rotations
	for angle in ROTATIONS:
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

	preferred_angle = (preferred_angle + 2) % 4

	return try_place_room(room, target_pos, preferred_angle) 
