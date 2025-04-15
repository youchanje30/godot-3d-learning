# Navigation/Scripts/Entities/BaseNavigator.gd
extends Node

class_name BaseNavigator

signal destination_reached
signal navigation_failed(reason: String)

@export var movement_speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var arrival_distance: float = 0.5
@export var target_desired_distance: float = 1.0
@export var path_max_distance: float = 50.0

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var parent_node: Node3D

func _ready() -> void:
	parent_node = get_parent() as Node3D
	if not parent_node:
		push_error("BaseNavigator must be child of a Node3D")
		return
		
	# NavigationAgent3D 설정
	navigation_agent.path_desired_distance = arrival_distance
	navigation_agent.target_desired_distance = target_desired_distance
	navigation_agent.path_max_distance = path_max_distance
	
	# 신호 연결
	navigation_agent.navigation_finished.connect(_on_navigation_finished)
	navigation_agent.path_changed.connect(_on_path_changed)
	navigation_agent.velocity_computed.connect(_on_velocity_computed)
	
	# 초기 설정
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	navigation_agent.max_speed = movement_speed

func navigate_to(target_pos: Vector3) -> void:
	if not parent_node:
		return
		
	navigation_agent.target_position = target_pos

func _physics_process(delta: float) -> void:
	if not parent_node or navigation_agent.is_navigation_finished():
		return
		
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var current_position: Vector3 = parent_node.global_position
	
	# 이동 방향 계산
	var new_velocity = (next_path_position - current_position).normalized() * movement_speed
	
	# 회피 시스템 사용
	navigation_agent.velocity = new_velocity

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not parent_node:
		return
		
	# 실제 이동 적용
	parent_node.global_position += safe_velocity * get_physics_process_delta_time()
	
	# 회전 처리
	if safe_velocity.length_squared() > 0.1:
		var target_rotation = atan2(safe_velocity.x, safe_velocity.z)
		parent_node.rotation.y = lerp_angle(
			parent_node.rotation.y,
			target_rotation,
			rotation_speed * get_physics_process_delta_time()
		)

func _on_navigation_finished() -> void:
	emit_signal("destination_reached")

func _on_path_changed() -> void:
	# 경로가 변경되었을 때의 처리
	pass

func stop_navigation() -> void:
	if navigation_agent:
		navigation_agent.target_position = parent_node.global_position

func set_movement_parameters(params: Dictionary) -> void:
	if params.has("movement_speed"):
		movement_speed = params.movement_speed
		navigation_agent.max_speed = movement_speed
	
	if params.has("arrival_distance"):
		arrival_distance = params.arrival_distance
		navigation_agent.path_desired_distance = arrival_distance
	
	if params.has("avoidance_enabled"):
		navigation_agent.avoidance_enabled = params.avoidance_enabled
	
	if params.has("radius"):
		navigation_agent.radius = params.radius
