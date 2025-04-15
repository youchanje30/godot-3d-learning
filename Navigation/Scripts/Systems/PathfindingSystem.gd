# Navigation/Scripts/Systems/PathfindingSystem.gd
extends Node3D

class_name PathfindingSystem

var navigation_manager: NavigationManager
var path_smoothing_enabled: bool = true

func _init(nav_manager: NavigationManager) -> void:
	navigation_manager = nav_manager

func find_path(entity_id: int, from: Vector3, to: Vector3, 
			   params: Dictionary = {}) -> Array[Vector3]:
	var path = navigation_manager.find_path(entity_id, from, to, params)
	
	if path_smoothing_enabled:
		path = smooth_path(path)
	
	return path

func smooth_path(path: Array[Vector3]) -> Array[Vector3]:
	if path.size() <= 2:
		return path
		
	var smoothed_path: Array[Vector3] = []
	smoothed_path.append(path[0])
	
	var current_point = 1
	while current_point < path.size() - 1:
		var current_pos = path[current_point]
		var next_pos = path[current_point + 1]
		
		# 경로 단순화: 불필요한 중간 점 제거
		if can_move_directly(smoothed_path[-1], next_pos):
			current_point += 1
			continue
			
		smoothed_path.append(current_pos)
		current_point += 1
	
	smoothed_path.append(path[-1])
	return smoothed_path

func can_move_directly(from: Vector3, to: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = from
	query.to = to
	query.collision_mask = 1  # 충돌 레이어 설정
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()
