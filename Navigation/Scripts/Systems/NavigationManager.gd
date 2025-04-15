# Navigation/Scripts/Systems/NavigationManager.gd
extends Node3D

class_name NavigationManager

signal path_found(entity_id: int, path: Array[Vector3])
signal navigation_failed(entity_id: int, reason: String)

# 내비게이션 설정
@export_category("Navigation Settings")
@export var agent_radius: float = 0.5
@export var agent_height: float = 2.0
@export var max_slope: float = 45.0

# 내비게이션 영역 관리
var nav_regions: Dictionary = {}  # region_id -> NavigationRegion3D
var active_paths: Dictionary = {} # entity_id -> current_path

func _ready() -> void:
	# 내비게이션 서버 초기화
	NavigationServer3D.set_active(true)
	
	# 기본 설정 적용
	var map_rid = get_world_3d().navigation_map
	NavigationServer3D.map_set_active(map_rid, true)
	NavigationServer3D.map_set_cell_size(map_rid, 0.25)
	NavigationServer3D.map_set_edge_connection_margin(map_rid, 0.5)

func register_navigation_region(region_id: String, region: NavigationRegion3D) -> void:
	nav_regions[region_id] = region
	
func remove_navigation_region(region_id: String) -> void:
	if nav_regions.has(region_id):
		nav_regions.erase(region_id)

func find_path(entity_id: int, from: Vector3, to: Vector3, 
			   custom_params: Dictionary = {}) -> Array[Vector3]:
	var map_rid = get_world_3d().navigation_map
	var params = NavigationPathQueryParameters3D.new()
	
	# 기본 파라미터 설정
	params.start_position = from
	params.target_position = to
	params.navigation_layers = 1
	
	# 에이전트 특성 설정
	params.agent_height = custom_params.get("height", agent_height)
	params.agent_radius = custom_params.get("radius", agent_radius)
	
	# 경로 탐색
	var path_query = NavigationPathQueryResult3D.new()
	NavigationServer3D.query_path(params, path_query)
	
	var path = path_query.get_path()
	
	if path.is_empty():
		emit_signal("navigation_failed", entity_id, "No path found")
		return []
	
	active_paths[entity_id] = path
	emit_signal("path_found", entity_id, path)
	return path

func update_path(entity_id: int, current_pos: Vector3) -> void:
	if not active_paths.has(entity_id):
		return
		
	var current_path = active_paths[entity_id]
	if current_path.is_empty():
		return
		
	# 목적지까지의 새로운 경로 계산이 필요한지 확인
	var target = current_path[-1]
	var new_path = find_path(entity_id, current_pos, target)
	
	if not new_path.is_empty():
		active_paths[entity_id] = new_path

func clear_path(entity_id: int) -> void:
	if active_paths.has(entity_id):
		active_paths.erase(entity_id)

func get_current_path(entity_id: int) -> Array[Vector3]:
	return active_paths.get(entity_id, [])
