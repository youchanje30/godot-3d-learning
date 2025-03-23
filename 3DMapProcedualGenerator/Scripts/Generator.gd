extends Node3D

@export var generate_rooms_cnt : int = 10
var room_path : String = "res://3DMapProcedualGenerator/Rooms/"
var q = [] # pos, angle

func _init() -> void:
	q.push_back([Vector3.ZERO, 0])

func _ready() -> void:
	GenerateMaps()

#region Generation Methods
### 배치가 불가능한 경우를 막기 위해 여러번 실행한다. 방 생성 개수를 맞추기 위함
func GenerateMaps() -> void:
	for _i in generate_rooms_cnt:
		await GenerationRoomCycle()
		## 방 생성 확인을 위해 딜레이 추가
		await get_tree().create_timer(0.25).timeout

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
	for passage in room.get_passage_data():
		q.append(passage)
