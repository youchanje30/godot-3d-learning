extends Node

# 맵 생성기

@export var grid_data: Node  # 이미 씬에 추가된 3DGridData 노드
@export var path: String = "res://GraphBaseProcedualGenerator/Rooms"  # 방 파일들이 있는 폴더 경로

var room_files: Array = []  # Room 파일 리스트

# 시작 방을 추가
var start_room:=preload("res://GraphBaseProcedualGenerator/Rooms/room.tscn")

# 모든 방의 데이터 저장 (문을 통해 추가된 방 포함)
var all_rooms: Array[Room] = []

# 폴더 내의 Room 파일들을 탐색하는 함수
func load_room_files() -> void:
	var dir = DirAccess.get_files_at(path)
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name:
			if file_name.ends_with(".tscn"):
				room_files.append(path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory: ", path)

# Room 파일을 랜덤으로 선택하여 로드하는 함수
func load_random_room():
	if room_files.size() > 0:
		var random_index = randi() % room_files.size()
		var room_path = room_files[random_index]
		var room_scene = load(room_path)
		return room_scene
	return null

# 문을 연결하거나 벽으로 막는 함수
func connect_or_block_doors(room: Room) -> void:
	pass
	#for door_position in room.get_doors().keys():
		#var next_room_position = grid_data.get_next_room_position(room.global_transform.origin, door_position)
		#if next_room_position and grid_data.is_cell_filled(next_room_position):
			## 다음 방이 존재하면 문을 연결
			#print("Connecting door at ", door_position, " to room at ", next_room_position)
		#else:
			## 다음 방이 존재하지 않으면 벽으로 막음
			#print("Blocking door at ", door_position)
			#var wall = create_cube(room.global_transform.origin + door_position)
			#add_child(wall)


# 방을 추가할 수 있는지 확인하는 함수
func can_place_room(room: Room, position: Vector3i) -> bool:
	for pos in room.get_positions():
		if grid_data.is_cell_filled(position + pos):
			return false
	return true

# 문을 통해 방을 추가하는 함수
func try_add_room_at_door(room: Room, door_position: Vector3i, max_room_attempts: int, max_door_attempts: int) -> bool:
	for i in range(max_door_attempts):
		var off_set = grid_data.get_next_room_position(room.global_transform.origin, door_position)
		
		for ii in range(max_room_attempts):
			var random_room_scene = load_random_room()
			var new_room_instance = random_room_scene.instantiate()
			add_child(new_room_instance)
			var pos = new_room_instance.get_positions()
			pos = grid_data.rotate_vectors(pos, get_rotate(door_position))
			var total_pos = []
			for vec in pos: total_pos.push_back(vec + off_set)
			if not grid_data.can_place_blocks(total_pos): continue
			for vec in total_pos: grid_data.fill_cell(vec, new_room_instance)
			for dic in new_room_instance.get_doors():
				grid_data.add_special_cell(dic.key, dic.value)
			
	return false

func get_rotate(vec):
	if vec == Vector3i(0, 0, 1): return 0
	if vec == Vector3i(1, 0, 0): return 1
	if vec == Vector3i(0, 0, -1): return 2
	if vec == Vector3i(-1, 0, 0): return 3
	return 0

# 방의 문을 선택하고 방을 추가하는 함수
func add_room_with_door_logic(room: Room) -> bool:
	for door_position in room.get_doors().keys():
		if try_add_room_at_door(room, door_position, 5, 3):
			return true
	return false

# 맵 생성 함수
func generate_map() -> void:
	# 시작 방 추가
	var start_room_instance = start_room.instantiate()
	all_rooms.append(start_room_instance)
	add_child(start_room_instance)
	grid_data.fill_cell(Vector3i(start_room_instance.global_transform.origin), start_room_instance)

	# 문을 통해 추가 가능한 방을 순차적으로 추가
	var generated_rooms = 0
	var max_rooms_to_generate = 30
	
	for i in range(max_rooms_to_generate):
	#while generated_rooms < max_rooms_to_generate:
		for room in all_rooms:
			if add_room_with_door_logic(room):
				generated_rooms += 1
				if generated_rooms >= max_rooms_to_generate:
					break
			if generated_rooms >= max_rooms_to_generate:
				break

	# 방의 문을 연결하거나 벽으로 막음
	for room in all_rooms:
		connect_or_block_doors(room)


# 예제 사용법
func _ready() -> void:
	randomize()
	#load_room_files()
	generate_map()
