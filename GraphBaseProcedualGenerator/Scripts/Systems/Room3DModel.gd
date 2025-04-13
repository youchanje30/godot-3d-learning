extends Node

class_name Room3DModel

var model_instance: Node3D = null
var room_data: RoomData
var debug_visualization: Node3D = null

# 3D 모델 씬으로부터 로드
func load_from_scene(scene_path: String) -> bool:
	var scene = load(scene_path)
	if not scene:
		return false
		
	if model_instance:
		model_instance.queue_free()
	
	model_instance = scene.instantiate()
	if not model_instance:
		return false
	
	add_child(model_instance)
	hide_debug_visualization()  # 실제 모델이 로드되면 디버그 시각화는 숨김
	return true

# 디버그 시각화 생성
func create_debug_visualization(positions: Array[Vector3i], doors: Dictionary[Vector3i, Vector3i], color: Color) -> void:
	if debug_visualization:
		debug_visualization.queue_free()
	
	debug_visualization = Node3D.new()
	add_child(debug_visualization)
	
	# 방 블록 표시
	for position in positions:
		var cube = create_debug_cube(Vector3(position.x, position.y, position.z), color)
		cube.scale = Vector3.ONE * 0.75
		debug_visualization.add_child(cube)
	
	# 문과 연결 표시
	for door_pos in doors:
		# 문 위치에 큐브 추가 (일반 블록과 동일한 크기)
		var door_cube = create_debug_cube(Vector3(door_pos.x, door_pos.y, door_pos.z), color)
		door_cube.scale = Vector3.ONE * 0.75
		debug_visualization.add_child(door_cube)
		
		# 문 방향을 나타내는 얇은 큐브 추가
		var direction = doors[door_pos]
		var connection = create_door_connection(
			Vector3(door_pos.x, door_pos.y, door_pos.z),
			Vector3(direction.x, direction.y, direction.z),
			color
		)
		debug_visualization.add_child(connection)

# 디버그용 큐브 생성
func create_debug_cube(position: Vector3, color: Color) -> MeshInstance3D:
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8  # 약간 투명하게
	cube.set_surface_override_material(0, material)
	return cube

# 문 연결 표시용 얇은 큐브 생성
func create_door_connection(start_pos: Vector3, direction: Vector3, color: Color) -> MeshInstance3D:
	var connection = MeshInstance3D.new()
	connection.mesh = BoxMesh.new()
	
	# 방향에 따라 스케일과 위치 조정
	var scale = Vector3.ONE * 0.2  # 기본적으로 얇게
	var offset = direction * 0.5  # 방향의 절반만큼 이동
	
	# 방향에 따라 적절한 축으로 늘리기
	if abs(direction.x) > 0:
		scale.x = 1.0  # X 방향으로는 길게
	elif abs(direction.z) > 0:
		scale.z = 1.0  # Z 방향으로는 길게
	elif abs(direction.y) > 0:
		scale.y = 1.0  # Y 방향으로는 길게
	
	connection.scale = scale
	connection.transform.origin = start_pos + offset
	
	# 재질 설정
	var material = StandardMaterial3D.new()
	material.albedo_color = color.lightened(0.2)  # 약간 밝게
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.6  # 더 투명하게
	connection.set_surface_override_material(0, material)
	
	return connection

# 모델 표시/숨김
func show() -> void:
	if model_instance:
		model_instance.visible = true
	elif debug_visualization:
		debug_visualization.visible = true

func hide() -> void:
	if model_instance:
		model_instance.visible = false
	elif debug_visualization:
		debug_visualization.visible = false

func show_debug_visualization() -> void:
	if debug_visualization:
		debug_visualization.visible = true

func hide_debug_visualization() -> void:
	if debug_visualization:
		debug_visualization.visible = false

# 모델 변환 설정
func set_transform(position: Vector3, rotation_y: float) -> void:
	if model_instance:
		model_instance.position = position
		model_instance.rotation.y = rotation_y
	if debug_visualization:
		debug_visualization.position = position
		debug_visualization.rotation.y = rotation_y

# 3D 모델에서 RoomData 추출
func extract_room_data() -> RoomData:
	var data = RoomData.new()
	
	if model_instance:
		# 실제 모델이 있는 경우
		var aabb = get_model_bounds()
		var min_pos = Vector3i(floor(aabb.position.x), floor(aabb.position.y), floor(aabb.position.z))
		var max_pos = Vector3i(ceil(aabb.end.x), ceil(aabb.end.y), ceil(aabb.end.z))
		
		for x in range(min_pos.x, max_pos.x):
			for y in range(min_pos.y, max_pos.y):
				for z in range(min_pos.z, max_pos.z):
					data.add_position(Vector3i(x, y, z))
		
		detect_doors(data)
	
	return data

# 모델의 바운딩 박스 얻기
func get_model_bounds() -> AABB:
	if not model_instance:
		return AABB()
	
	var total_aabb = AABB()
	for child in model_instance.get_children():
		if child is MeshInstance3D:
			var mesh_aabb = child.get_aabb()
			if total_aabb == AABB():
				total_aabb = mesh_aabb
			else:
				total_aabb = total_aabb.merge(mesh_aabb)
	
	return total_aabb

# 문 노드들 찾기 (문 노드는 "Door" 그룹에 속해있다고 가정)
func get_door_nodes() -> Array:
	var doors = []
	if not model_instance:
		return doors
	
	for child in model_instance.get_children():
		if child.is_in_group("Door"):
			doors.append(child)
	
	return doors

# 문 위치 감지 및 설정
func detect_doors(data: RoomData) -> void:
	var door_nodes = get_door_nodes()
	for door in door_nodes:
		var door_pos = Vector3i(door.global_position)
		var door_direction = detect_door_direction(door)
		data.add_door(door_pos, door_direction)

# 문의 방향 감지
func detect_door_direction(door_node: Node) -> Vector3i:
	# 문의 forward 방향이나 rotation을 기반으로 방향 결정
	return Vector3i.FORWARD 