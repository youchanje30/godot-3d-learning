extends Node

# 맵 생성기

@export var room_templates_path: String = "res://GraphBaseProcedualGenerator/Rooms/"
@export var max_rooms: int = 30
@export var try_place_rooms_count: int = 10
@export var room_placement_delay: float = 0.25
@export var connect_room_color: Color = Color(randf(), randf(), randf())

var grid_system: GridSystem
var collision_system: CollisionSystem
var room_placement_system: RoomPlacementSystem
var room_factory: RoomFactory

var all_rooms: Array[Room] = []

func _ready() -> void:
	randomize()
	initialize_systems()
	await get_tree().create_timer(0.2).timeout
	generate_map()

func initialize_systems() -> void:
	grid_system = GridSystem.new()
	collision_system = CollisionSystem.new(grid_system)
	room_placement_system = RoomPlacementSystem.new(grid_system, collision_system)
	room_factory = RoomFactory.new(room_templates_path)
	
	add_child(grid_system)

func generate_map() -> void:
	# Place start room
	var start_room = room_factory.create_room("room.tscn")
	if not start_room:
		print("Failed to create start room")
		return
		
	add_child(start_room)
	all_rooms.append(start_room)
	
	if not room_placement_system.try_place_room(start_room, Vector3i.ZERO, 0):
		print("Failed to place start room")
		return
	
	# Generate additional rooms
	for i in range(max_rooms):
		await get_tree().create_timer(room_placement_delay).timeout
		
		var success = false
		for j in range(try_place_rooms_count):
			var room = room_factory.create_random_room()
			if not room:
				print("Failed to create room")
				continue
			
			add_child(room)
			
			if room_placement_system.try_place_random_room(room):
				print("Placed room")
				all_rooms.append(room)
				success = true
				break
			else:
				room.queue_free()
		if not success:
			print("Failed to place room")
	# Final door check
	await get_tree().create_timer(10).timeout
	check_doors()

func check_doors() -> void:
	var special_cells = grid_system.get_all_special_cells()
	for key in special_cells.keys():
		if not special_cells.has(key):
			continue
			
		var target_pos = special_cells[key]
		if not special_cells.has(grid_system.vector_to_key(target_pos)):
			continue
			
		var cur_pos = grid_system.key_to_vector(key)
		if cur_pos != special_cells[grid_system.vector_to_key(target_pos)]:
			continue
			
		# Remove connected doors
		special_cells.erase(key)
		special_cells.erase(grid_system.vector_to_key(target_pos))
		
		# Visualize connection
		var cube1 = create_connection_marker(cur_pos)
		var cube2 = create_connection_marker(target_pos)
		add_child(cube1)
		add_child(cube2)

func create_connection_marker(position: Vector3) -> MeshInstance3D:
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	var material = StandardMaterial3D.new()
	material.albedo_color = connect_room_color
	cube.set_surface_override_material(0, material)
	return cube
