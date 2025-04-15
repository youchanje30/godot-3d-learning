extends Node3D

class_name RegionManager

signal region_activated(region_id: String)
signal region_deactivated(region_id: String)

var active_regions: Dictionary = {}  # region_id -> NavigationRegion3D
var region_bounds: Dictionary = {}   # region_id -> AABB
var player_tracker: Node3D

@export var activation_distance: float = 50.0  # 활성화 거리

func _ready() -> void:
	# 플레이어 찾기
	await get_tree().create_timer(0.1).timeout
	player_tracker = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player_tracker:
		update_active_regions()

func register_region(region_id: String, region: NavigationRegion3D, bounds: AABB) -> void:
	region_bounds[region_id] = bounds
	
	# 초기에는 비활성화
	region.enabled = false
	active_regions[region_id] = region

func update_active_regions() -> void:
	var player_pos = player_tracker.global_position
	
	# 각 지역 확인
	for region_id in region_bounds.keys():
		var bounds = region_bounds[region_id]
		var distance = calculate_distance_to_bounds(player_pos, bounds)
		
		if distance <= activation_distance:
			activate_region(region_id)
		else:
			deactivate_region(region_id)

func activate_region(region_id: String) -> void:
	if not active_regions.has(region_id):
		return
		
	var region = active_regions[region_id]
	if not region.enabled:
		region.enabled = true
		emit_signal("region_activated", region_id)

func deactivate_region(region_id: String) -> void:
	if not active_regions.has(region_id):
		return
		
	var region = active_regions[region_id]
	if region.enabled:
		region.enabled = false
		emit_signal("region_deactivated", region_id)

func calculate_distance_to_bounds(point: Vector3, bounds: AABB) -> float:
	var closest = point.clamp(bounds.position, bounds.position + bounds.size)
	return point.distance_to(closest) 
