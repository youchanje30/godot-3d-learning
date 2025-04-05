extends Node3D
class_name RoomTemplate

@export var size: Vector3i = Vector3i(3, 1, 3)  # Room size in grid units
@export var doors: Array[Node3D] = []  # Array of door/passage nodes

@onready var collision_area: Area3D = $"Room Surface/Area3D"

# Visual representation options
@export_group("Visualization")
@export var auto_create_mesh: bool = true
@export var wall_thickness: float = 0.2
@export var floor_height: float = 0.1
@export var ceiling_height: float = 0.1
@export var wall_material: Material
@export var floor_material: Material
@export var ceiling_material: Material

func _ready():
	if auto_create_mesh:
		create_room_mesh()
	
	# Make sure collision area is set up
	if not collision_area:
		create_collision_area()

# Returns positions occupied by this room in local space
func get_occupied_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	
	for x in range(size.x):
		for y in range(size.y):
			for z in range(size.z):
				positions.append(Vector3i(x, y, z))
	
	return positions

# Returns dictionary of door positions and their directions
func get_door_data() -> Dictionary:
	var door_data = {}
	
	for door in doors:
		if door and door.has_method("get_direction"):
			var local_pos = Vector3i(door.position)
			var direction = door.get_direction()
			door_data[local_pos] = direction
	
	return door_data

# Check if this room overlaps with anything
func has_overlapping() -> bool:
	if collision_area:
		return collision_area.has_overlapping_areas()
	return false

# Creates a basic visual representation of the room
func create_room_mesh():
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var array_mesh = ArrayMesh.new()
	
	# Create floor
	var floor_mesh = BoxMesh.new()
	floor_mesh.size = Vector3(size.x, floor_height, size.z)
	if floor_material:
		floor_mesh.material = floor_material
	
	var floor_instance = MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.position = Vector3(size.x/2, -floor_height/2, size.z/2)
	add_child(floor_instance)
	
	# Create ceiling
	var ceiling_mesh = BoxMesh.new()
	ceiling_mesh.size = Vector3(size.x, ceiling_height, size.z)
	if ceiling_material:
		ceiling_mesh.material = ceiling_material
	
	var ceiling_instance = MeshInstance3D.new()
	ceiling_instance.mesh = ceiling_mesh
	ceiling_instance.position = Vector3(size.x/2, size.y + ceiling_height/2, size.z/2)
	add_child(ceiling_instance)
	
	# Create walls (avoiding door positions)
	create_walls()

func create_walls():
	var door_positions = get_door_data().keys()
	
	# Create north and south walls
	for x in range(size.x):
		for y in range(size.y):
			# North wall (z=0)
			if not Vector3i(x, y, 0) in door_positions:
				create_wall_segment(Vector3(x, y, 0), Vector3(1, 1, wall_thickness))
			
			# South wall (z=size.z)
			if not Vector3i(x, y, size.z) in door_positions:
				create_wall_segment(Vector3(x, y, size.z), Vector3(1, 1, wall_thickness))
	
	# Create east and west walls
	for z in range(size.z):
		for y in range(size.y):
			# East wall (x=0)
			if not Vector3i(0, y, z) in door_positions:
				create_wall_segment(Vector3(0, y, z), Vector3(wall_thickness, 1, 1))
			
			# West wall (x=size.x)
			if not Vector3i(size.x, y, z) in door_positions:
				create_wall_segment(Vector3(size.x, y, z), Vector3(wall_thickness, 1, 1))

func create_wall_segment(pos: Vector3, size: Vector3):
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	
	if wall_material:
		wall_mesh.material = wall_material
	
	var wall_instance = MeshInstance3D.new()
	wall_instance.mesh = wall_mesh
	wall_instance.position = pos
	add_child(wall_instance)

func create_collision_area():
	collision_area = Area3D.new()
	add_child(collision_area)
	
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(size)
	
	collision_shape.shape = box_shape
	collision_shape.position = Vector3(size.x/2, size.y/2, size.z/2)
	
	collision_area.add_child(collision_shape)
	collision_area.collision_layer = 2  # Adjust according to your layer setup
	collision_area.collision_mask = 2
