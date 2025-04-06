extends Resource
class_name RoomData
# RoomData 클래스

# 방이 차지하고 있는 위치들
@export var positions: Array[Vector3i] = []
# 방의 문 위치와 방향 (Dictionary)
# 키: 문 위치 (Vector3i)
# 값: 문 방향 (Vector3i)
@export var doors: Dictionary[Vector3i, Vector3i] = {}

# 생성자
func _init(positions: Array[Vector3i] = [], doors: Dictionary[Vector3i, Vector3i] = {}) -> void:
	self.positions = positions
	self.doors = doors

# 방의 위치들 설정
func set_positions(new_positions: Array[Vector3i]) -> void:
	positions = new_positions

# 방의 위치들 가져오기
func get_positions() -> Array[Vector3i]:
	return positions

# 문 추가
func add_door(position: Vector3i, direction: Vector3i) -> void:
	doors[position] = direction

# 문 제거
func remove_door(position: Vector3i) -> void:
	if doors.has(position):
		doors.erase(position)

# 문의 위치들 가져오기
func get_doors() -> Dictionary[Vector3i, Vector3i]:
	return doors

# 특정 위치에 문이 있는지 확인
func has_door(position: Vector3i) -> bool:
	return doors.has(position)

# 방향을 기준으로 특정 위치에 문이 있는지 확인
func is_door_in_direction(position: Vector3i, direction: Vector3i) -> bool:
	return doors.get(position) == direction
