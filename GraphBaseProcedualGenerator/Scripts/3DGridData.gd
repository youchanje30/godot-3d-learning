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

# 키를 벡터로 변환 (필요한 경우)
func key_to_vector(key: String) -> Vector3i:
	var parts = key.split(",")
	return Vector3i(int(parts[0]), int(parts[1]), int(parts[2]))

# 셀 채우기
func fill_cell(position: Vector3i, room_node: Node, data = true) -> void:
	#filled_cells[vector_to_key(position)] = {"data": data, "room": room_node}
	filled_cells[vector_to_key(position)] = room_node
	print(vector_to_key(position) , "filled")

# 셀 비우기
func clear_cell(position: Vector3i) -> void:
	var key = vector_to_key(position)
	if filled_cells.has(key):
		filled_cells.erase(key)

# 셀이 채워져 있는지 확인
func is_cell_filled(position: Vector3i) -> bool:
	return filled_cells.has(vector_to_key(position))

# 셀 데이터 가져오기
func get_cell_data(position: Vector3i):
	return filled_cells.get(vector_to_key(position), null)

# 특수 셀 추가
func add_special_cell(position: Vector3i, direction: Vector3i) -> void:
	special_cells[vector_to_key(position)] = direction

# 특수 셀 데이터 가져오기
func get_special_cell_data(position: Vector3i):
	return special_cells.get(vector_to_key(position), null)

# 특수 셀을 통해 이동할 수 있는 다음 방의 위치 계산
func get_next_room_position(current_position: Vector3i, door_position: Vector3i) -> Vector3i:
	if not special_cells.has(vector_to_key(door_position)):
		return Vector3i.ZERO
	var direction = special_cells[vector_to_key(door_position)]
	return current_position + direction

# 테트로미노 블록이 유효한 위치인지 확인 (충돌 없음)
func can_place_blocks(block_positions: Array[Vector3i]) -> bool:
	for pos in block_positions:
		# 이미 채워진 셀이라면 배치 불가
		if is_cell_filled(pos):
			return false
	return true


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

func get_angle_from_direction(dir : Vector3i)->int:
	if dir == Vector3i.BACK: return 0
	if dir == Vector3i.RIGHT: return 1
	if dir == Vector3i.FORWARD: return 2
	if dir == Vector3i.LEFT: return 3
	return 0


func try_place_random_room(room : Room)->bool:
	var k = special_cells.keys().pick_random()
	var target_pos = special_cells[k]
	var dir = get_angle_from_direction(target_pos - key_to_vector(k))
	var rev_dir = (dir + 2) % 4
	return try_place_room(room, target_pos, rev_dir)


func try_place_room(room : Room, target : Vector3i, dir_angle : int)->bool:
	var doors = room.get_doors()
	for k in doors:
		var pivot_position = k
		var angle = (dir_angle - get_angle_from_direction(doors[k]) + 12) % 4
		var need_move = target - get_vector_from_angle(pivot_position, angle)
		var moved_positions = move_vectors(rotate_vectors(room.get_positions(), angle), need_move)
		
		var can = false
		for pos in moved_positions:
			if is_cell_filled(pos): can = true
		
		if can: continue
		
		for pos in moved_positions: fill_cell(pos, room)
		for ke in doors:
			var cur_pos = get_vector_from_angle(ke, angle) + need_move
			var that_pos = cur_pos + get_normalized_vec_from_angle((angle + get_angle_from_direction(doors[ke])) % 4)
			add_special_cell(cur_pos, that_pos)
		room.display_room_position(moved_positions)
		room.rotate_time = angle
		room.off_set_position = need_move
		return true
	return false

func move_vectors(vectors: Array[Vector3i], OffSet: Vector3i) -> Array[Vector3i]:
	var result : Array[Vector3i] = []
	for vec in vectors: result.append(vec + OffSet)
	return result


# 회전된 테트로미노 블록이 유효한지 확인
func can_rotate_block(block_positions: Array[Vector3i], angle_option: int) -> bool:
	var rotated_positions = rotate_vectors(block_positions, angle_option)
	# 충돌 검사
	return can_place_blocks(rotated_positions)

func get_front_door(pos : Vector3i, angle_option : int)->Vector3i:
	return pos + get_normalized_vec_from_angle(angle_option)

# 벡터 배열을 최적화된 방식으로 회전
func rotate_vectors(vectors: Array[Vector3i], angle_option: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for vec in vectors: result.append(get_vector_from_angle(vec, angle_option))
	return result

func get_vector_from_angle(vec : Vector3i, angle_option : int)->Vector3i:
	match angle_option:
		0: # 0 degrees - no change
			return Vector3i(vec.x, vec.y, vec.z)
		1: # 90 degrees  --  x' = z, z' = -x
			return Vector3i(vec.z, vec.y, -vec.x)
		2: # 180 degrees --  x' = -x, z' = -z
			return  Vector3i(-vec.x, vec.y, -vec.z)
		3: # 270 degrees --  x' = -z, z' = x
			return Vector3i(-vec.z, vec.y, vec.x)
	return Vector3i(vec.x, vec.y, vec.z)

func get_normalized_vec_from_angle(angle : int)->Vector3i:
	if angle == 0: return Vector3i.BACK
	if angle == 1: return Vector3i.RIGHT 
	if angle == 2: return Vector3i.FORWARD
	if angle == 3: return Vector3i.LEFT
	return Vector3i.BACK
