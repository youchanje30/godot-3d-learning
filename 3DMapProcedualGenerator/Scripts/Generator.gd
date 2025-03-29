extends Node3D

@export var generate_rooms_cnt : int = 10
var room_path : String = "res://3DMapProcedualGenerator/Room/"
var wall_path = preload("res://3DMapProcedualGenerator/Furiniture/fit_wall.tscn")
var door_path = preload("res://3DMapProcedualGenerator/door.tscn")
var q = [] # pos, angle
var used_q = []

func _init() -> void:
	## seed(1) 시드 설정으로 동일한 결과를 얻을 수 있다.
	## randomize() 시드를 랜덤으로 초기화 한다.
	#seed(1)
	q.push_back([Vector3.ZERO, 0])

func _ready() -> void:
	GenerateMaps()

#region Generation Methods
### 배치가 불가능한 경우를 막기 위해 여러번 실행한다. 방 생성 개수를 맞추기 위함
func GenerateMaps() -> void:
	## 방 생성
	for _i in generate_rooms_cnt:
		await GenerationRoomCycle()
		## 방 생성 확인을 위해 딜레이 추가
		await get_tree().create_timer(0.25).timeout
	
	
	## 벽 생성
	GenerationWall()
	
	## 문 생성
	GenerationDoor()

func GenerationRoomCycle() -> void:
	for _try_pos in 10:
		if await TryGenerateAndPlaceRoom(): return


func TryGenerateAndPlaceRoom() -> bool:
	## 데이터 없으면 종료
	var generation_data = SelectNextGenerationData()
	if generation_data == null: return false

	var attach_pos = generation_data[0]
	var attach_angle = generation_data[1]

	for _try_room in 10:
		var room = GetRandomFromPath(room_path)
		if not room: continue
		# 방 배치 시도
		if await IsSuccessPlaceRoom(room, attach_pos, attach_angle): return true

	print("생성 실패")
	return false

func IsSuccessPlaceRoom(room: Node3D, attach_pos: Vector3, attach_angle: float) -> bool:
	add_child(room)
	room.Attach(attach_pos, attach_angle)
	await get_tree().create_timer(0.05).timeout

	# 겹치지 않는 경우
	if not room.has_overlapping():
		SuccessGenerationRoom(room, [attach_pos, attach_angle])
		return true

	room.queue_free()
	# print("방 생성 실패 (겹침):", attach_pos, room.global_position, room.get_size())
	return false

#endregion



func GenerationWall():
	for data in q:
		var pos = data[0]
		var angle = data[1]
		var wall = wall_path.instantiate()
		add_child(wall)
		# attach 코드를 추가해서 어딘가로 바로 붙이고 싶다
		wall.global_position = pos
		
		wall.set_global_rotation_degrees(Vector3(0, angle, 0))

func GenerationDoor():
	for data in used_q:
		if randi_range(0, 5) > 1: continue
		var pos = data[0]
		var angle = data[1]
		var door = door_path.instantiate()
		add_child(door)
		door.global_position = pos
		door.set_global_rotation_degrees(Vector3(0, angle, 0))

func GetRandomFromPath(path : String):
	var resource_files = DirAccess.get_files_at(path)
	var random_resource = resource_files[randi() % resource_files.size()]
	var data = load(path + random_resource).instantiate()
	return data


func SelectNextGenerationData():
	if not q.is_empty(): return q.pick_random()

	print("큐가 비었음 이럴리가 없는데?")
	return null

func SuccessGenerationRoom(room: Node3D, data_to_remove: Array) -> void:
	print("방 생성 성공:", room.global_position, room.get_size())
	q.erase(data_to_remove)
	used_q.push_back(data_to_remove)
	for passage in room.get_passage_data():
		q.append(passage)
