extends Node

# Room 클래스는 RoomData를 상속받아 모델링과 형태를 추가합니다.
class_name Room

# RoomData 인스턴스
@export var room_data: RoomData

# 방의 색상
var room_color: Color
# 생성자
#func _init(room_data: RoomData) -> void:
	#self.room_data = room_data

# 방의 위치들 설정
func set_positions(new_positions: Array[Vector3i]) -> void:
	room_data.set_positions(new_positions)

# 방의 위치들 가져오기
func get_positions() -> Array[Vector3i]:
	return room_data.get_positions()

# 문 추가
func add_door(position: Vector3i, direction: Vector3i) -> void:
	room_data.add_door(position, direction)

# 문 제거
func remove_door(position: Vector3i) -> void:
	room_data.remove_door(position)

# 문의 위치들 가져오기
func get_doors() -> Dictionary[Vector3i, Vector3i]:
	return room_data.get_doors()

# 특정 위치에 문이 있는지 확인
func has_door(position: Vector3i) -> bool:
	return room_data.has_door(position)

# 방향을 기준으로 특정 위치에 문이 있는지 확인
func is_door_in_direction(position: Vector3i, direction: Vector3i) -> bool:
	return room_data.is_door_in_direction(position, direction)

# 방의 위치와 차지하는 공간을 표시하는 함수
func display_room() -> void:
	for position in get_positions():
		var cube = create_cube(Vector3(position.x, position.y, position.z))
		add_child(cube)

# 랜덤 색상 생성 함수
func generate_random_color() -> Color:
	return Color(randf(), randf(), randf())

# 방의 색상 설정 함수
func set_room_color(color: Color) -> void:
	room_color = color

# 정육면체 MeshInstance를 생성하는 함수
func create_cube(position: Vector3):
	var cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.transform.origin = position
	return cube

func _ready() -> void:
	set_room_color(generate_random_color())
	display_room()
