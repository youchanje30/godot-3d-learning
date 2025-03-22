extends Node3D


@export var generate_rooms_cnt : int = 10
var q = []
var path = "res://3DMapProcedualGenerator/Rooms/"


func _init() -> void:
	q.push_back([Vector3.ZERO, Vector3(0, 0, 1)])
	GenerateMaps()

func GenerateMaps()->void:
	var generated_cnt = 0
	while generated_cnt < generate_rooms_cnt:
		# 위치 3번, 방 5번 시도 해보기
		var room_generate_succed = false
		var try_pos_cnt = 0
		while try_pos_cnt < 3:
			# 위치 선택하기
			var data = q.pick_random()
			var pos = data[0]
			var try_room_cnt = 0
			while try_room_cnt < 5:
				# 방 선택하기
				var room = GetRandomFromPath(path)
				add_child(room)
				var size = room.get_size()
				var dir = pos
				if data[1].x != 0:
					dir.x = (data[1].x/abs(data[1].x)) * size.x / 2 + pos.x
				if data[1].z != 0:
					dir.z = (data[1].z/abs(data[1].z)) * size.z / 2 + pos.z
				
				# dir은 정중앙임
				# 시작 지점은 -1/2로 통일 끝 지점은 +1/2로 통일
				var start_pos = Vector3(dir.x - size.x/2, dir.y - size.y/2, dir.z - size.z/2)
				var end_pos = Vector3(dir.x + size.x/2, dir.y + size.y/2, dir.z + size.z/2)
				var check = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
				
	pass


func GetRandomFromPath(path : String):
	var resource_files = DirAccess.get_files_at(path)
	var random_resource = resource_files[randi() % resource_files.size()]
	var data = load(path + random_resource).instantiate()
	return data
