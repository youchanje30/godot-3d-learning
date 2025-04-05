extends Node3D
class_name GraphDungeonGenerator

# Generation parameters
@export var room_count: int = 15
@export var max_connection_attempts: int = 10
@export var room_templates_path: String = "res://GraphBaseProcedualGenerator/Room/"
@export var min_distance_between_doors: float = 2.0
@export var show_generation_steps: bool = true
@export var step_delay: float = 0.1

# Core data structures
var grid = {}  # Dictionary: Vector3i position -> room data
var rooms = [] # Array of instantiated room nodes
var doors = {} # Dictionary: Vector3i position -> door data
var connections = [] # Array of connection data [from_pos, to_pos, direction]
var available_doors = [] # Array of available door positions [pos, direction]

# Room template resources
var room_templates = []

func _ready():
	randomize()
	load_room_templates()
	generate_dungeon()

func load_room_templates():
	var dir = DirAccess.open(room_templates_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var template = load(room_templates_path + file_name)
				if template:
					room_templates.append(template)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if room_templates.size() == 0:
		printerr("No room templates found in: ", room_templates_path)

func generate_dungeon():
	# Start with a single room at the origin
	var start_room = place_initial_room()
	if not start_room:
		printerr("Failed to place initial room")
		return
	
	# Add initial room's doors to available doors list
	register_room_doors(start_room)
	
	# Main generation loop
	var rooms_placed = 1
	var attempts = 0
	var max_attempts = room_count * 5  # Give some extra attempts to reach target
	
	while rooms_placed < room_count and attempts < max_attempts:
		attempts += 1
		
		# Try to connect a new room
		if available_doors.size() > 0:
			var door_data = available_doors[randi() % available_doors.size()]
			var connect_pos = door_data[0]
			var connect_dir = door_data[1]
			
			if try_place_room_at_door(connect_pos, connect_dir):
				rooms_placed += 1
				if show_generation_steps:
					await get_tree().create_timer(step_delay).timeout
	
	print("Dungeon generation complete. Placed ", rooms_placed, " rooms.")
	
	# After placing all rooms, try to make additional connections
	create_additional_connections()
	finalize_dungeon()

func place_initial_room() -> Node3D:
	if room_templates.size() == 0:
		return null
	
	var template = room_templates[randi() % room_templates.size()]
	var room_instance = template.instantiate()
	add_child(room_instance)
	
	# Register room in the grid
	var room_data = RoomData.new(room_instance)
	for pos in room_data.occupied_positions:
		grid[pos] = room_data
	
	rooms.append(room_instance)
	return room_instance

func try_place_room_at_door(door_pos: Vector3i, door_dir: Vector3i) -> bool:
	# Try each room template
	var templates_to_try = room_templates.duplicate()
	templates_to_try.shuffle()
	
	for template in templates_to_try:
		var room_instance = template.instantiate()
		add_child(room_instance)
		
		# Create room data 
		var room_data = RoomData.new(room_instance)
		
		# Try all doors in the template
		for room_door_pos in room_data.door_positions:
			var room_door_dir = room_data.door_directions[room_door_pos]
			
			# Check if this door can connect to our target door
			if room_door_dir == -door_dir:
				# Position and rotate the room to align doors
				var offset = door_pos - room_door_pos
				room_instance.global_position = Vector3(offset)
				
				# Rotate to align door directions
				var rotation = get_rotation_from_directions(room_door_dir, -door_dir)
				room_instance.global_rotation = rotation
				
				# Update room data after rotation
				room_data.update_after_rotation(rotation)
				
				# Check if room placement is valid
				if is_valid_room_placement(room_data, door_pos):
					# Register the room and connection
					for pos in room_data.occupied_positions:
						grid[pos] = room_data
					
					rooms.append(room_instance)
					
					# Register the connection
					connections.append([door_pos, door_pos + door_dir, door_dir])
					
					# Remove the used door from available doors
					remove_door(door_pos)
					
					# Register new doors from this room
					register_room_doors(room_instance)
					
					return true
				
		# If we get here, this template didn't work
		room_instance.queue_free()
	
	return false

func is_valid_room_placement(room_data, connecting_door_pos) -> bool:
	# Check if any position is already occupied
	for pos in room_data.occupied_positions:
		if pos in grid and pos != connecting_door_pos:
			return false
	
	return true

func register_room_doors(room_instance):
	var room_data = RoomData.new(room_instance)
	
	for door_pos in room_data.door_positions:
		var global_door_pos = Vector3i(room_instance.global_position) + door_pos
		var door_dir = room_data.door_directions[door_pos]
		
		# Apply room rotation to door direction
		var global_door_dir = apply_rotation_to_direction(door_dir, room_instance.global_rotation)
		
		# Check if the position the door leads to is free
		var target_pos = global_door_pos + global_door_dir
		if not target_pos in grid:
			available_doors.append([global_door_pos, global_door_dir])
			doors[global_door_pos] = {
				"room": room_instance,
				"direction": global_door_dir
			}

func remove_door(door_pos):
	for i in range(available_doors.size()):
		if available_doors[i][0] == door_pos:
			available_doors.remove_at(i)
			break

func create_additional_connections():
	# Try to make additional connections between existing rooms
	for attempts in range(max_connection_attempts):
		# Find two doors that could potentially connect
		var potential_connections = []
		
		for i in range(available_doors.size()):
			for j in range(i + 1, available_doors.size()):
				var door1 = available_doors[i]
				var door2 = available_doors[j]
				
				var door1_pos = door1[0]
				var door1_dir = door1[1]
				var door2_pos = door2[0]
				var door2_dir = door2[1]
				
				# Check if doors face each other
				if door1_dir == -door2_dir:
					# Check if doors are aligned
					var connection_vector = door2_pos - door1_pos
					if connection_vector.normalized() == door1_dir:
						# Check if there's nothing in between
						var distance = connection_vector.length()
						var clear_path = true
						
						for d in range(1, int(distance)):
							var check_pos = door1_pos + door1_dir * d
							if check_pos in grid:
								clear_path = false
								break
						
						if clear_path:
							potential_connections.append([door1_pos, door2_pos])
		
		if potential_connections.size() > 0:
			# Choose a random potential connection
			var connection = potential_connections[randi() % potential_connections.size()]
			var door1_pos = connection[0]
			var door2_pos = connection[1]
			
			# Create a corridor between these doors
			create_corridor(door1_pos, door2_pos)
			
			# Remove both doors from available list
			remove_door(door1_pos)
			remove_door(door2_pos)
			
			if show_generation_steps:
				await get_tree().create_timer(step_delay).timeout

func create_corridor(door1_pos, door2_pos):
	var direction = (door2_pos - door1_pos).normalized()
	var distance = (door2_pos - door1_pos).length()
	
	# Create corridor nodes
	var corridor_scene = preload("res://GraphBaseProcedualGenerator/Corridor.tscn")  # You'll need to create this
	var corridor = corridor_scene.instantiate()
	add_child(corridor)
	
	# Position and scale corridor
	corridor.global_position = Vector3(door1_pos) + (Vector3(direction) * 0.5)
	corridor.scale.z = distance - 1  # Adjust based on your corridor prefab
	
	# Rotate corridor to face the right direction
	var rotation = get_rotation_from_direction(direction)
	corridor.global_rotation = rotation
	
	# Register the connection
	connections.append([door1_pos, door2_pos, direction])

func get_rotation_from_directions(from_dir, to_dir) -> Vector3:
	var rotation = Vector3.ZERO
	
	# Handle the six cardinal directions
	if from_dir == Vector3i.FORWARD and to_dir == Vector3i.BACK:
		rotation = Vector3(0, deg_to_rad(180), 0)
	elif from_dir == Vector3i.BACK and to_dir == Vector3i.FORWARD:
		rotation = Vector3.ZERO
	elif from_dir == Vector3i.RIGHT and to_dir == Vector3i.LEFT:
		rotation = Vector3(0, deg_to_rad(90), 0)
	elif from_dir == Vector3i.LEFT and to_dir == Vector3i.RIGHT:
		rotation = Vector3(0, deg_to_rad(-90), 0)
	elif from_dir == Vector3i.UP and to_dir == Vector3i.DOWN:
		rotation = Vector3(deg_to_rad(90), 0, 0)
	elif from_dir == Vector3i.DOWN and to_dir == Vector3i.UP:
		rotation = Vector3(deg_to_rad(-90), 0, 0)
	
	return rotation

func get_rotation_from_direction(direction) -> Vector3:
	var rotation = Vector3.ZERO
	
	if direction == Vector3i.FORWARD:
		rotation = Vector3.ZERO
	elif direction == Vector3i.BACK:
		rotation = Vector3(0, deg_to_rad(180), 0)
	elif direction == Vector3i.RIGHT:
		rotation = Vector3(0, deg_to_rad(-90), 0)
	elif direction == Vector3i.LEFT:
		rotation = Vector3(0, deg_to_rad(90), 0)
	elif direction == Vector3i.UP:
		rotation = Vector3(deg_to_rad(-90), 0, 0)
	elif direction == Vector3i.DOWN:
		rotation = Vector3(deg_to_rad(90), 0, 0)
	
	return rotation

func apply_rotation_to_direction(dir: Vector3i, rotation: Vector3) -> Vector3i:
	var rot_matrix = Basis().rotated(Vector3(0, 1, 0), rotation.y)
	rot_matrix = rot_matrix.rotated(Vector3(1, 0, 0), rotation.x)
	rot_matrix = rot_matrix.rotated(Vector3(0, 0, 1), rotation.z)
	
	var rotated_dir = rot_matrix * Vector3(dir)
	
	# Convert back to Vector3i, rounding to nearest int
	return Vector3i(
		round(rotated_dir.x),
		round(rotated_dir.y),
		round(rotated_dir.z)
	)

func finalize_dungeon():
	# Create door visuals
	for door_pos in doors:
		create_door_visual(door_pos, doors[door_pos].direction)
	
	# Bake navigation mesh
	var nav_region = get_node_or_null("NavigationRegion3D")
	if nav_region:
		await get_tree().create_timer(0.5).timeout
		nav_region.bake_navigation_mesh()
	
	print("Dungeon finalized with ", connections.size(), " connections")


func create_door_visual(position, direction):
	var door_scene = preload("res://GraphBaseProcedualGenerator/door1.tscn") # You'll need to create this
	var door = door_scene.instantiate()
	add_child(door)
	
	door.global_position = Vector3(position)
	door.global_rotation = get_rotation_from_direction(direction)

# Helper class to store room data
class RoomData:
	var node: Node3D
	var occupied_positions: Array[Vector3i] = []
	var door_positions: Array = []
	var door_directions: Dictionary = {}
	
	func _init(room_node: Node3D):
		node = room_node
		
		# Get occupancy data from room if it supports the method
		if node.has_method("get_occupied_positions"):
			occupied_positions = node.get_occupied_positions()
		else:
			# Fallback: Use the room's size
			var size = Vector3i(2, 1, 2)  # Default size if not specified
			if node.has_method("get_size"):
				size = Vector3i(node.get_size())
			
			var pos = Vector3i(node.global_position)
			for x in range(pos.x, pos.x + size.x):
				for y in range(pos.y, pos.y + size.y):
					for z in range(pos.z, pos.z + size.z):
						occupied_positions.append(Vector3i(x, y, z))
		
		# Get door data from room
		if node.has_method("get_door_data"):
			var door_data = node.get_door_data()
			door_positions = door_data.keys()
			door_directions = door_data
		elif node.has_method("get_passage_data"):
			# Alternative method name
			var passages = node.get_passage_data()
			for passage in passages:
				var pos = Vector3i(passage[0])
				var dir = Vector3i() 
				
				# Handle direction based on angle if that's how it's stored
				if passage.size() > 1:
					var angle = passage[1]
					dir = Vector3i(int(sin(deg_to_rad(angle))), 0, int(cos(deg_to_rad(angle))))
				
				door_positions.append(pos)
				door_directions[pos] = dir
	
	func update_after_rotation(rotation: Vector3):
		# Apply rotation to all positions and directions
		var new_occupied = []
		for pos in occupied_positions:
			var rotated_pos = apply_rotation_to_vector(pos, rotation)
			new_occupied.append(rotated_pos)
		occupied_positions = new_occupied
		
		var new_door_positions = []
		var new_door_directions = {}
		
		for door_pos in door_positions:
			var rotated_pos = apply_rotation_to_vector(door_pos, rotation)
			var rotated_dir = apply_rotation_to_vector(door_directions[door_pos], rotation)
			
			new_door_positions.append(rotated_pos)
			new_door_directions[rotated_pos] = rotated_dir
		
		door_positions = new_door_positions
		door_directions = new_door_directions
	
	func apply_rotation_to_vector(vec: Vector3i, rotation: Vector3) -> Vector3i:
		var rot_matrix = Basis().rotated(Vector3(0, 1, 0), rotation.y)
		rot_matrix = rot_matrix.rotated(Vector3(1, 0, 0), rotation.x)
		rot_matrix = rot_matrix.rotated(Vector3(0, 0, 1), rotation.z)
		
		var rotated_vec = rot_matrix * Vector3(vec)
		
		# Convert back to Vector3i, rounding to nearest int
		return Vector3i(
			round(rotated_vec.x),
			round(rotated_vec.y),
			round(rotated_vec.z)
		)
