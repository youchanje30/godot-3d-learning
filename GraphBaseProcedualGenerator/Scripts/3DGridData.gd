extends Node

# Dictionary를 사용하여 채워진 셀 저장
# 키: 벡터 좌표를 문자열로 변환 "x,y,z"
# 값: 셀 정보 (차있음 = true, 추가 정보는 필요에 따라)
var filled_cells = {}

# 특수 셀을 위한 Dictionary
# 키: 벡터 좌표를 문자열로 변환 "x,y,z"
# 값: 방향 정보 (문 위치)
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
	filled_cells[vector_to_key(position)] = {"data": data, "room": room_node}

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

# 회전된 테트로미노 블록이 유효한지 확인
func can_rotate_block(block_positions: Array[Vector3i], angle_option: int) -> bool:
	var rotated_positions = rotate_vectors(block_positions, angle_option)
	# 충돌 검사
	return can_place_blocks(rotated_positions)

# 벡터 배열을 최적화된 방식으로 회전
func rotate_vectors(vectors: Array[Vector3i], angle_option: int) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	
	for vec in vectors:
		var new_vec: Vector3i
		
		match angle_option:
			0: # 0 degrees - no change
				new_vec = Vector3i(vec.x, vec.y, vec.z)
			
			1: # 90 degrees
				# x' = z, z' = -x
				new_vec = Vector3i(vec.z, vec.y, -vec.x)
			
			2: # 180 degrees
				# x' = -x, z' = -z
				new_vec = Vector3i(-vec.x, vec.y, -vec.z)
			
			3: # 270 degrees
				# x' = -z, z' = x
				new_vec = Vector3i(-vec.z, vec.y, vec.x)
			
			_: # Default: no rotation
				new_vec = Vector3i(vec.x, vec.y, vec.z)
		
		result.append(new_vec)
	
	return result
