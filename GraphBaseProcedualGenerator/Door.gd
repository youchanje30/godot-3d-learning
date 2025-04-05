extends Node3D
class_name DoorNode

@export var direction: Vector3i = Vector3i(0, 0, 1)  # Direction the door faces
@export var auto_create_visual: bool = true
@export var door_size: Vector3 = Vector3(1, 2, 0.2)  # Width, height, thickness
@export var door_material: Material

func _ready():
	if auto_create_visual:
		create_door_visual()

# Returns the direction vector for this door
func get_direction() -> Vector3i:
	return direction

# Creates a visual representation of the door
func create_door_visual():
	var mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	var door_mesh = BoxMesh.new()
	door_mesh.size = door_size
	
	if door_material:
		door_mesh.material = door_material
	
	mesh_instance.mesh = door_mesh
	
	# Position the door based on direction
	if direction == Vector3i.FORWARD or direction == Vector3i.BACK:
		mesh_instance.position.x = -door_size.x / 2  # Center horizontally
	elif direction == Vector3i.LEFT or direction == Vector3i.RIGHT:
		mesh_instance.position.z = -door_size.x / 2  # Center horizontally
	
	mesh_instance.position.y = door_size.y / 2  # Position at ground level with height adjustment
	
	# Rotate the door based on direction
	if direction == Vector3i.FORWARD:
		mesh_instance.rotate_y(0)
	elif direction == Vector3i.BACK:
		mesh_instance.rotate_y(PI)
	elif direction == Vector3i.LEFT:
		mesh_instance.rotate_y(PI/2)
	elif direction == Vector3i.RIGHT:
		mesh_instance.rotate_y(-PI/2)
