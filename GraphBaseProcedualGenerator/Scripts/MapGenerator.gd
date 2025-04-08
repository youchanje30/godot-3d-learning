extends Node

# 맵 생성기

@export var grid_data: Node  # 이미 씬에 추가된 3DGridData 노드
@export var path: String = "res://GraphBaseProcedualGenerator/Rooms/"  # 방 파일들이 있는 폴더 경로

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


func GetRandomFromPath(path : String):
	var resource_files = DirAccess.get_files_at(path)
	var random_resource = resource_files[randi() % resource_files.size()]
	var data = load(path + random_resource).instantiate()
	return data

# 방을 추가할 수 있는지 확인하는 함수
func can_place_room(room: Room, position: Vector3i) -> bool:
	for pos in room.get_positions():
		if grid_data.is_cell_filled(position + pos):
			return false
	return true

## 문을 통해 방을 추가하는 함수

## 방의 문을 선택하고 방을 추가하는 함수
#func add_room_with_door_logic(room: Room) -> bool:
	#for door_position in room.get_doors().keys():
		#if try_add_room_at_door(room, door_position, 5, 3):
			#return true
	#return false

# 맵 생성 함수
func generate_map() -> void:
	# 시작 방 추가
	var start_room_instance = start_room.instantiate()
	add_child(start_room_instance)
	all_rooms.append(start_room_instance)
	grid_data.try_place_room(start_room_instance, Vector3i.ZERO, 0)


	# 문을 통해 추가 가능한 방을 순차적으로 추가
	var generated_rooms = 0
	var max_rooms_to_generate = 30
	for i in range(max_rooms_to_generate):
		var select_room = all_rooms[randi_range(0, all_rooms.size()-1)]
		
		var doors = select_room.get_doors()
		var k = doors.keys().pick_random()
		
		
		var rotated_pos = grid_data.get_vector_from_angle(k, select_room.rotate_time)
		var moved_pos = rotated_pos + select_room.off_set_position
		
		var total_angle = (select_room.rotate_time + grid_data.get_angle_from_direction(doors[k])) % 4
		var add_pos = grid_data.get_normalized_vec_from_angle(total_angle)
		
		var total_pos = add_pos + moved_pos
		var rev_door_angle = (total_angle + 2) % 4
		
		for ii in range(30):
			var room = GetRandomFromPath(path)
			add_child(room)
			if not grid_data.try_place_room(room, total_pos, rev_door_angle): #grid_data.get_normalized_vec_from_angle(rev_door_angle)):
				room.queue_free()
				continue
			all_rooms.append(room)
			break


# 예제 사용법
func _ready() -> void:
	randomize()
	#load_room_files()
	generate_map()
