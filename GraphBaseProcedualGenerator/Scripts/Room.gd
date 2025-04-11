extends Node

# Room 클래스는 RoomData를 상속받아 모델링과 형태를 추가합니다.
class_name Room

# RoomData 인스턴스
@export var room_data: RoomData

var off_set_position = Vector3i.ZERO
var rotate_time = 0
# 방의 색상
var room_color: Color
var world_position: Vector3i
var rotation_angle: int

# 방의 위치들 가져오기
func get_positions() -> Array[Vector3i]:
	return room_data.get_positions()

# 문 추가
func add_door(position: Vector3i, direction: Vector3i) -> void:
	room_data.add_door(position, direction)

# 문 제거
func remove_door(position: Vector3i) -> void:
	room_data.remove_door(position)

# 문의 위치들 가져오기
func get_doors() -> Dictionary[Vector3i, Vector3i]:
	return room_data.get_doors()

# 특정 위치에 문이 있는지 확인
func has_door(position: Vector3i) -> bool:
	return room_data.has_door(position)

# 방향을 기준으로 특정 위치에 문이 있는지 확인
func is_door_in_direction(position: Vector3i, direction: Vector3i) -> bool:
	return room_data.is_door_in_direction(position, direction)

# 방의 위치와 차지하는 공간을 표시하는 함수
func display_room() -> void:
	# Clear existing visualization
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	# Display room blocks
	for position in get_positions():
		var rotated_pos = rotate_vector(position, rotation_angle)
		var world_pos = rotated_pos + world_position
		var cube = create_cube(Vector3(world_pos.x, world_pos.y, world_pos.z))
		cube.scale = Vector3.ONE * 0.75
		add_child(cube)
	
	# Display doors
	for door_pos in get_doors():
		var rotated_pos = rotate_vector(door_pos, rotation_angle)
		var world_pos = rotated_pos + world_position
		var cube = create_cube(Vector3(world_pos.x, world_pos.y, world_pos.z))
		add_child(cube)

func display_room_position(positions : Array[Vector3i]) -> void:
	for pos in positions:
		var cube = add_cube(pos)
		add_child(cube)

func display_door_position(pos : Vector3i) -> void:
	var cube = add_door_pos(pos)
	add_child(cube)

# 랜덤 색상 생성 함수
func generate_random_color() -> Color:
	return Color(randf(), randf(), randf())

# 방의 색상 설정 함수
func set_room_color(color: Color) -> void:
	room_color = color

# 정육면체 MeshInstance를 생성하는 함수
func create_cube(position: Vector3) -> MeshInstance3D:
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	var material = StandardMaterial3D.new()
	material.albedo_color = room_color
	cube.set_surface_override_material(0, material)
	return cube

func add_cube(pos : Vector3):
	var cube = create_cube(pos)
	cube.scale = Vector3.ONE * 0.75
	return cube

func add_door_pos(pos : Vector3):
	var cube = create_cube(pos)
	cube.scale = Vector3.ONE * 1
	return cube

func _ready() -> void:
	set_room_color(generate_random_color())

func apply_transform(position: Vector3i, angle: int) -> void:
	world_position = position
	rotation_angle = angle
	display_room()

func rotate_vector(vec: Vector3i, angle: int) -> Vector3i:
	match angle:
		0: return vec
		1: return Vector3i(vec.z, vec.y, -vec.x)
		2: return Vector3i(-vec.x, vec.y, -vec.z)
		3: return Vector3i(-vec.z, vec.y, vec.x)
	return vec
