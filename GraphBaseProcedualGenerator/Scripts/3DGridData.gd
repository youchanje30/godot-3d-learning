extends Node

# Dictionary를 사용하여 채워진 셀 저장
# 키: 벡터 좌표를 문자열로 변환 "x,y,z"
# 값: 셀 정보 (차있음 = true, 추가 정보는 필요에 따라)
var filled_cells = {}

# 특수 셀을 위한 Dictionary
# 키: 벡터 좌표를 문자열로 변환 "x,y,z"
# 값: 바라보는 곳의 좌표?
var special_cells = {}

# 벡터를 딕셔너리 키로 변환
func vector_to_key(vec: Vector3i) -> String:
	return "%d,%d,%d" % [vec.x, vec.y, vec.z]

# 키를 벡터로 변환
func key_to_vector(key: String) -> Vector3i:
	var parts = key.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))

# 셀 관리 함수들
func fill_cell(position: Vector3i, room_node: Node) -> void:
	filled_cells[vector_to_key(position)] = room_node

func is_cell_filled(position: Vector3i) -> bool:
	return filled_cells.has(vector_to_key(position))

func get_cell_data(position: Vector3i):
	return filled_cells.get(vector_to_key(position), null)

# 특수 셀 관리
func add_special_cell(position: Vector3i, direction: Vector3i) -> void:
	special_cells[vector_to_key(position)] = direction

func get_special_cell_data(position: Vector3i):
	return special_cells.get(vector_to_key(position), null)

# 방향 관련 상수
const DIRECTIONS = {
	BACK = 0,
	RIGHT = 1,
	FORWARD = 2,
	LEFT = 3
}

const DIRECTION_VECTORS = {
	0: Vector3i.BACK,
	1: Vector3i.RIGHT,
	2: Vector3i.FORWARD,
	3: Vector3i.LEFT
}

# 방향 변환 함수
func get_angle_from_direction(dir: Vector3i) -> int:
	if dir == Vector3i.BACK: return DIRECTIONS.BACK
	if dir == Vector3i.RIGHT: return DIRECTIONS.RIGHT
	if dir == Vector3i.FORWARD: return DIRECTIONS.FORWARD
	if dir == Vector3i.LEFT: return DIRECTIONS.LEFT
	return DIRECTIONS.BACK

func get_normalized_vec_from_angle(angle: int) -> Vector3i:
	return DIRECTION_VECTORS.get(angle, Vector3i.BACK)

# 회전 관련 함수
func rotate_vectors(vectors: Array[Vector3i], angle_option: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(vectors.size())
	
	match angle_option:
		0: # 0도
			result = vectors.duplicate()
		1: # 90도
			for i in vectors.size():
				result[i] = Vector3i(vectors[i].z, vectors[i].y, -vectors[i].x)
		2: # 180도
			for i in vectors.size():
				result[i] = Vector3i(-vectors[i].x, vectors[i].y, -vectors[i].z)
		3: # 270도
			for i in vectors.size():
				result[i] = Vector3i(-vectors[i].z, vectors[i].y, vectors[i].x)
	
	return result

# 방 배치 관련 함수
func try_place_random_room(room: Room) -> bool:
	var keys = special_cells.keys()
	if keys.is_empty(): return false
	
	var k = keys.pick_random()
	var target_pos = special_cells[k]
	var dir = get_angle_from_direction(target_pos - key_to_vector(k))
	return try_place_room(room, target_pos, (dir + 2) % 4)

func try_place_room(room: Room, target: Vector3i, dir_angle: int) -> bool:
	var doors = room.get_doors()
	var positions = room.get_positions()
	
	for door_pos in doors:
		var angle = (dir_angle - get_angle_from_direction(doors[door_pos]) + 12) % 4
		var need_move = target - get_vector_from_angle(door_pos, angle)
		
		# 회전과 이동을 한번만 수행
		var rotated_positions = rotate_vectors(positions, angle) 
		var moved_positions = move_vectors(rotated_positions, need_move)
		
		# 문 위치도 같이 회전/이동
		var rotated_doors = {}
		for door in doors:
			var rotated_door_pos = get_vector_from_angle(door, angle)
			var moved_door_pos = rotated_door_pos + need_move
			rotated_doors[moved_door_pos] = get_normalized_vec_from_angle((angle + get_angle_from_direction(doors[door])) % 4)
		
		# 충돌 검사
		var has_collision = false
		for pos in moved_positions:
			if is_cell_filled(pos):
				has_collision = true
				break
		
		if has_collision:
			continue
		
		# 방 배치
		for pos in moved_positions:
			fill_cell(pos, room)
		
		# 문 처리 - 미리 계산된 위치 사용
		for door_pos_temp in rotated_doors.keys():
			add_special_cell(door_pos_temp, door_pos_temp + rotated_doors[door_pos_temp])
		
		room.display_room_position(moved_positions)
		room.rotate_time = angle
		room.off_set_position = need_move
		return true
	
	return false

func move_vectors(vectors: Array[Vector3i], offset: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	result.resize(vectors.size())
	for i in vectors.size():
		result[i] = vectors[i] + offset
	return result

func get_vector_from_angle(vec: Vector3i, angle_option: int) -> Vector3i:
	match angle_option:
		0: return vec
		1: return Vector3i(vec.z, vec.y, -vec.x)
		2: return Vector3i(-vec.x, vec.y, -vec.z)
		3: return Vector3i(-vec.z, vec.y, vec.x)
	return vec

func check_doors():
	for k in special_cells.keys():
		if not special_cells.has(k): continue
		var target_pos = special_cells[k]
		if not special_cells.has(vector_to_key(target_pos)): continue
		
		var cur_pos = key_to_vector(k)
		if cur_pos != special_cells[vector_to_key(target_pos)]: continue
		special_cells.erase(k)
		special_cells.erase(vector_to_key(target_pos))
		add_child(create_cube(cur_pos))
		add_child(create_cube(target_pos))


func create_cube(position: Vector3):
	var cube : MeshInstance3D = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	cube.set_surface_override_material(0, material)
	return cube

var color : Color
func generate_random_color() -> Color:
	return Color(randf(), randf(), randf())
func _ready() -> void: color = generate_random_color()
