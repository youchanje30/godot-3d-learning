extends Node

# Room 클래스는 RoomData를 상속받아 모델링과 형태를 추가합니다.
class_name Room

# RoomData 인스턴스
@export var room_data: RoomData
var model: Room3DModel = null
var world_position: Vector3i
var rotation_angle: int
var room_color: Color = Color.WHITE

# 방의 위치들 가져오기
func get_positions() -> Array[Vector3i]:
	return room_data.get_positions()

# 문 추가
func add_door(position: Vector3i, direction: Vector3i) -> void:
	room_data.add_door(position, direction)
	update_visualization()

# 문 제거
func remove_door(position: Vector3i) -> void:
	room_data.remove_door(position)
	update_visualization()

# 문의 위치들 가져오기
func get_doors() -> Dictionary[Vector3i, Vector3i]:
	return room_data.get_doors()

# 특정 위치에 문이 있는지 확인
func has_door(position: Vector3i) -> bool:
	return room_data.has_door(position)

# 방향을 기준으로 특정 위치에 문이 있는지 확인
func is_door_in_direction(position: Vector3i, direction: Vector3i) -> bool:
	return room_data.is_door_in_direction(position, direction)

# 3D 모델 로드
func load_model(scene_path: String) -> bool:
	if not model:
		model = Room3DModel.new()
		add_child(model)
	
	if not model.load_from_scene(scene_path):
		return false
	
	# 기존 RoomData가 없다면 모델에서 추출
	if not room_data:
		room_data = model.extract_room_data()
	
	return true

# 방의 위치와 회전 적용
func apply_transform(position: Vector3i, angle: int) -> void:
	world_position = position
	rotation_angle = angle
	
	if model:
		model.set_transform(Vector3(position), angle * PI / 2)
	update_visualization()

func rotate_vector(vec: Vector3i, angle: int) -> Vector3i:
	match angle:
		0: return vec
		1: return Vector3i(vec.z, vec.y, -vec.x)
		2: return Vector3i(-vec.x, vec.y, -vec.z)
		3: return Vector3i(-vec.z, vec.y, vec.x)
	return vec

# 배치 가능성 검증 (RoomData만으로)
func validate_placement(grid_system, collision_system) -> bool:
	var rotated_positions = []
	for pos in get_positions():
		var rotated_pos = rotate_vector(pos, rotation_angle)
		var world_pos = rotated_pos + world_position
		
		# 그리드 시스템과 충돌 체크
		if not grid_system.is_position_valid(world_pos) or collision_system.check_collision(world_pos):
			return false
		
		rotated_positions.append(world_pos)
	
	return true

# 시각화 업데이트
func update_visualization() -> void:
	if not model:
		model = Room3DModel.new()
		add_child(model)
	
	# 디버그 시각화 업데이트
	model.create_debug_visualization(get_positions(), get_doors(), room_color)
	model.set_transform(Vector3(world_position), rotation_angle * PI / 2)

# 3D 모델 표시/숨김
func show_model() -> void:
	if model:
		model.show()

func hide_model() -> void:
	if model:
		model.hide()

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
	if room_data:
		room_data.set_room_color(color)
	update_visualization()

# 정육면체 MeshInstance를 생성하는 함수
func create_cube(position: Vector3) -> MeshInstance3D:
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	var material = StandardMaterial3D.new()
	material.albedo_color = room_color
	material.roughness = 0.7
	material.metallic = 0.1
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
	if not room_data:
		room_data = RoomData.new()
	var random_color = generate_random_color()
	set_room_color(random_color)
