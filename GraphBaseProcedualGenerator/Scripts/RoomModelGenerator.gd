extends Node3D

const ROOM_SCALE = 2.8
const BASIC_ROOM_SCENE = preload("res://GraphBaseProcedualGenerator/RoomsModel/basic_room.tscn")

var created_rooms: Dictionary = {}
var door_connections: Array[Node3D] = []

func generate_from_grid_system(grid_system: GridSystem, all_rooms: Array[Room]) -> void:
	print("Starting room generation...")
	
	# Clear existing door connections
	for connection in door_connections:
		if connection:
			connection.queue_free()
	door_connections.clear()
	
	# First pass: Create rooms from actual Room instances
	for room in all_rooms:
		if room and is_instance_valid(room):
			print("Processing room at position: ", room.world_position, " with color: ", room.room_color)
			create_room_from_instance(room)
		else:
			print("Invalid room instance found")
	
	print("Total rooms created: ", created_rooms.size())
	
	# Second pass: Handle connections
	for room in all_rooms:
		if not room or not is_instance_valid(room):
			continue
			
		var doors = room.get_doors()
		for door_pos in doors:
			var door_dir = doors[door_pos]
			var rotated_pos = room.rotate_vector(door_pos, room.rotation_angle)
			var world_door_pos = rotated_pos + room.world_position
			var target_pos = world_door_pos + door_dir
			
			print("Checking door connection: ", world_door_pos, " -> ", target_pos)
			create_door_connection(Vector3(world_door_pos), Vector3(target_pos))

func create_room_from_instance(room: Room) -> void:
	# Get all positions for this room
	var positions = room.get_positions()
	print("Room has ", positions.size(), " positions")
	
	# Create a parent node for all room parts
	var room_parent = Node3D.new()
	room_parent.position = Vector3(room.world_position.x, room.world_position.y, room.world_position.z) * ROOM_SCALE
	add_child(room_parent)
	
	# Create material for the room
	var material = StandardMaterial3D.new()
	material.albedo_color = room.room_color
	material.roughness = 0.7
	material.metallic = 0.1
	
	# Create room parts for each position
	for pos in positions:
		var rotated_pos = room.rotate_vector(pos, room.rotation_angle)
		var local_pos = Vector3(rotated_pos.x, rotated_pos.y, rotated_pos.z) * ROOM_SCALE
		
		var room_part = BASIC_ROOM_SCENE.instantiate()
		room_part.position = local_pos
		room_parent.add_child(room_part)
		
		# Create CSG parent for this room part
		var csg_parent = CSGCombiner3D.new()
		room_part.add_child(csg_parent)
		
		# Apply material to all CSGBox3D nodes
		var box_nodes = room_part.find_children("*", "CSGBox3D")
		if box_nodes.is_empty():
			print("Warning: No CSGBox3D nodes found in room part")
			continue
			
		for child in box_nodes:
			var original_parent = child.get_parent()
			original_parent.remove_child(child)
			csg_parent.add_child(child)
			child.material = material
			child.operation = CSGShape3D.OPERATION_UNION
	
	print("Created room with color: ", material.albedo_color, " at base position: ", room.world_position)
	created_rooms[room.world_position] = room_parent

func create_door_connection(pos1: Vector3, pos2: Vector3) -> void:
	var connection = CSGBox3D.new()
	
	# Calculate direction and rotation
	var direction = pos2 - pos1
	var center_pos = (pos1 + pos2) / 2.0 * ROOM_SCALE
	
	# Set size based on direction
	var size = Vector3(0.3, 0.3, 0.3) * ROOM_SCALE  # Default size for connection indicator
	
	# Set material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 0, 1)  # Yellow color for connections
	material.emission_enabled = true  # Make it glow
	material.emission = Color(1, 1, 0, 1)
	material.emission_energy = 0.5
	connection.material = material
	
	# Set transform
	connection.position = center_pos
	connection.size = size
	
	# Add to scene and store reference
	add_child(connection)
	door_connections.append(connection)
	print("Created door connection at: ", center_pos) 
