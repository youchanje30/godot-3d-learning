extends Node
class_name RoomsPositionData

var occupied_positions: Array[Vector3i] = [] # 방 묶음이 차지하는 모든 좌표
var door_positions: Dictionary = {} # { position: Array<Vector3i> } - 각 문의 위치 (묶음 내 좌표)
var door_directions: Dictionary = {} # { position: Vector3i } - 각 문의 방향 (묶음 내 좌표)
var prefab: PackedScene # 이 묶음에 사용될 방 프리팹 (예: 복도)

func _init(room_prefab: PackedScene):
	prefab = room_prefab
	if prefab.has_method("get_occupied_positions") and prefab.has_method("get_door_data"):
		var positions_from_prefab = prefab.call("get_occupied_positions")
		var doors_from_prefab = prefab.call("get_door_data")

		if typeof(positions_from_prefab) == TYPE_ARRAY and typeof(positions_from_prefab[0]) == TYPE_VECTOR3I:
			occupied_positions = positions_from_prefab

		if typeof(doors_from_prefab) == TYPE_DICTIONARY:
			door_positions = doors_from_prefab.keys()
			door_directions = doors_from_prefab

	else:
		printerr("방 프리팹에 'get_occupied_positions' 또는 'get_door_data' 메서드가 없습니다.")

func can_attach_to(attach_point: Vector3i, attach_direction: Vector3i, existing_positions: Array[Vector3i]) -> bool:
	# 이 묶음의 문 위치를 기준으로 붙을 수 있는지 확인
	for door_pos_local in door_positions:
		var door_pos_global = attach_point + door_pos_local # 묶음이 놓일 때 문의 예상 글로벌 위치
		var door_dir_local: Vector3i = door_directions[door_pos_local]

		if door_dir_local == -attach_direction: # 문의 방향이 붙는 방향과 반대여야 함
			# 이 묶음이 놓일 때 차지하는 모든 좌표를 확인
			for occupied_local in occupied_positions:
				var occupied_global = attach_point + occupied_local
				if occupied_global in existing_positions and occupied_global != attach_point: # 시작점은 제외하고 겹치는지 확인
					return false
			return true
	return false

func attach_at(attach_point: Vector3i, attach_direction: Vector3i) -> Node3D:
	if prefab == null:
		printerr("프리팹이 설정되지 않았습니다.")
		return null

	# 문의 방향이 붙는 방향과 반대인 문 찾기
	var attaching_door_local: Vector3i = Vector3i.ZERO
	var found_door = false
	for door_pos_local in door_positions:
		if door_directions[door_pos_local] == -attach_direction:
			attaching_door_local = door_pos_local
			found_door = true
			break

	if not found_door:
		print("해당 방향으로 연결할 수 있는 문이 없습니다.")
		return null

	var room_instance = prefab.instantiate() as Node3D
	if room_instance.has_method("set_global_position"):
		room_instance.set_global_position(Vector3(attach_point - attaching_door_local)) # 묶음의 기준점을 attach_point에 맞춤

		# 방향에 맞춰 회전 (이전 로직 재활용)
		var target_rotation = Vector3.ZERO
		if attach_direction == Vector3i.FORWARD:
			if -attach_direction == Vector3i.BACK:
				target_rotation = Vector3(0, deg_to_rad(180), 0)
		elif attach_direction == Vector3i.BACK:
			if -attach_direction == Vector3i.FORWARD:
				target_rotation = Vector3.ZERO
		elif attach_direction == Vector3i.RIGHT:
			if -attach_direction == Vector3i.LEFT:
				target_rotation = Vector3(0, deg_to_rad(90), 0)
		elif attach_direction == Vector3i.LEFT:
			if -attach_direction == Vector3i.RIGHT:
				target_rotation = Vector3(0, deg_to_rad(-90), 0)
		elif attach_direction == Vector3i.UP:
			if -attach_direction == Vector3i.DOWN:
				target_rotation = Vector3(deg_to_rad(90), 0, 0)
		elif attach_direction == Vector3i.DOWN:
			if -attach_direction == Vector3i.UP:
				target_rotation = Vector3(deg_to_rad(-90), 0, 0)

		room_instance.set_global_rotation(target_rotation)

		return room_instance
	else:
		printerr("프리팹에 'set_global_position' 메서드가 없습니다.")
		room_instance.queue_free()
		return null

func get_occupied_global_positions(attach_point: Vector3i) -> Array[Vector3i]:
	var global_positions: Array[Vector3i] = []
	for local_pos in occupied_positions:
		global_positions.append(attach_point + local_pos)
	return global_positions

func get_door_global_positions(attach_point: Vector3i) -> Dictionary:
	var global_doors: Dictionary = {}
	for local_pos in door_positions:
		global_doors[attach_point + local_pos] = door_directions[local_pos]
	return global_doors
