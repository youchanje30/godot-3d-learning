extends Node3D


@export var generate_rooms_cnt : int = 10
@export var room_path : String = "res://3DMapProcedualGenerator/Rooms/"
var q = []
var existing_rooms: Array[StaticBody3D] = []

func _init() -> void:
	q.push_back([Vector3.ZERO, Vector3(0, 0, 1)])

func _ready() -> void:
	GenerateMaps()



func GetRandomFromPath(path : String):
	var resource_files = DirAccess.get_files_at(path)
	var random_resource = resource_files[randi() % resource_files.size()]
	var data = load(path + random_resource).instantiate()
	return data

#func GetRandomFromPath(path : String) -> StaticBody3D:
	#var dir_access = DirAccess.open(path)
	#if dir_access == null:
		#printerr("디렉토리를 열 수 없습니다:", path)
		#return null
	#var resource_files = dir_access.get_files()
	#dir_access.close()
	#var valid_files = []
	#for file in resource_files:
		#if file.ends_with(".tscn") or file.ends_with(".glb"): # 씬 또는 glb 파일이라고 가정
			#valid_files.append(file)
			#
	#if valid_files.is_empty():
		#printerr("경로에 유효한 룸 파일이 없습니다:", path)
		#return null
	#var random_resource_path = path + valid_files[randi() % valid_files.size()]
	#var room_resource = load(random_resource_path)
	#if room_resource is Resource:
		#var room_instance = room_resource.instantiate() as StaticBody3D
		#if room_instance == null:
			#printerr("인스턴스화 실패 또는 StaticBody3D가 아님:", random_resource_path)
			#return null
		#return room_instance
	#else:
		#printerr("리소스를 로드하는 데 실패했습니다:", random_resource_path)
		#return null

func can_place_room(position: Vector3, size: Vector3) -> bool:
	var half_size = size / 2.0
	var aabb = AABB(position - half_size, size)
	var query_params = PhysicsShapeQueryParameters3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	query_params.shape = box_shape
	query_params.transform = Transform3D(Basis(), position)
	query_params.collision_mask = 1 # 기본 충돌 레이어라고 가정
	#query_params.exclude = existing_rooms

	var space_state = get_world_3d().get_direct_space_state()
	var results = space_state.intersect_shape(query_params)

	return results.is_empty()

func GenerateMaps() -> void:
	var generated_cnt = 0
	while generated_cnt < generate_rooms_cnt:
		var room_generate_succeeded = false
		var try_pos_cnt = 0
		while try_pos_cnt < 3 and not room_generate_succeeded:
			var data = q.pick_random()
			var attach_pos = data[0]
			var attach_dir = data[1]
			var try_room_cnt = 0
			while try_room_cnt < 5 and not room_generate_succeeded:
				var room = GetRandomFromPath(room_path)
				if not room:
					break

				var room_size = room.get_size()
				var new_room_pos = attach_pos + attach_dir * (room_size / 2.0)

				if can_place_room(new_room_pos, room_size):
					room.position = new_room_pos
					add_child(room)
					q.erase(data)
					
					#existing_rooms.append(room)
					generated_cnt += 1
					room_generate_succeeded = true
					print("방 생성 성공:", new_room_pos, room_size)

					var new_q_pos = new_room_pos + attach_dir * (room_size / 2.0)
					var new_q_dir = attach_dir.rotated(Vector3.UP, PI/2 * round(randf_range(-1.0, 1.0) * 2)) # 직각 방향으로 확장 시도 (랜덤 회전)
					if q.size() < generate_rooms_cnt * 2: # q 배열 크기 제한 (선택 사항)
						q.append([new_q_pos, new_q_dir])

				else:
					room.queue_free()
					print("방 생성 실패 (겹침):", new_room_pos, room_size)

				try_room_cnt += 1
			try_pos_cnt += 1

		if not room_generate_succeeded:
			print("위치 시도 3번, 방 시도 5번 모두 실패.")

func sign(n: float) -> float:
	if n > 0:
		return 1.0
	elif n < 0:
		return -1.0
	else:
		return 0.0
