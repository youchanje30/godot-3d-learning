extends Node3D


@export var generate_rooms_cnt : int = 10
@export var room_path : String = "res://3DMapProcedualGenerator/Rooms/"
var q = []

func _init() -> void:
	q.push_back([Vector3.ZERO, Vector3(0, 1, 0)])

func _ready() -> void:
	GenerateMaps()

func GetRandomFromPath(path : String):
	var resource_files = DirAccess.get_files_at(path)
	var random_resource = resource_files[randi() % resource_files.size()]
	var data = load(path + random_resource).instantiate()
	return data

#func can_place_room(position: Vector3, size: Vector3) -> bool:
	#var half_size = size / 2.0
	#var aabb = AABB(position - half_size, size)
	#var query_params = PhysicsShapeQueryParameters3D.new()
	#var box_shape = BoxShape3D.new()
	#box_shape.size = size
	#query_params.shape = box_shape
	#query_params.transform = Transform3D(Basis(), position)
	#query_params.collision_mask = 1 # 기본 충돌 레이어라고 가정
	#query_params.exclude = existing_rooms
#
	#var space_state = get_world_3d().get_direct_space_state()
	#var results = space_state.intersect_shape(query_params)
	#
	#return results.is_empty()

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
				if not room: break

				var room_size = room.get_size()
				var new_room_pos = attach_pos + attach_dir * (room_size / 2.0)
				add_child(room)
				room.position = new_room_pos

				if not room.has_overlapping():
					generated_cnt += 1
					room_generate_succeeded = true
					print("방 생성 성공:", new_room_pos, room_size)
					q.erase(data)
					var passage_data = room.get_passage_data()
					for d in passage_data:
						q.append(d)
				else:
					room.queue_free()
					print("방 생성 실패 (겹침):", attach_pos, new_room_pos, room_size)

				try_room_cnt += 1
			try_pos_cnt += 1

		if not room_generate_succeeded:
			print("위치 시도 3번, 방 시도 5번 모두 실패.")
			break

func sign(n: float) -> float:
	if n > 0:
		return 1.0
	elif n < 0:
		return -1.0
	else:
		return 0.0
