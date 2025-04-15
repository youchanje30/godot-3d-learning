extends BaseNavigator

class_name AgentNavigator

enum AgentType {
	NORMAL,     # 일반적인 이동
	CAREFUL,    # 조심스러운 이동 (더 넓은 회피 반경)
	AGGRESSIVE  # 공격적 이동 (좁은 회피 반경)
}

@export var agent_type: AgentType = AgentType.NORMAL:
	set(value):
		agent_type = value
		_update_agent_parameters()

@export var update_path_interval: float = 0.5
@export var max_speed: float = 5.0
@export var acceleration: float = 8.0
@export var avoidance_priority: float = 0.5

var path_update_timer: float = 0.0
var current_velocity: Vector3 = Vector3.ZERO
var target_node: Node3D

func _ready() -> void:
	super._ready()
	_update_agent_parameters()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if target_node:
		path_update_timer += delta
		if path_update_timer >= update_path_interval:
			path_update_timer = 0.0
			navigate_to(target_node.global_position)

func set_target(node: Node3D) -> void:
	target_node = node
	if target_node:
		navigate_to(target_node.global_position)

func _update_agent_parameters() -> void:
	match agent_type:
		AgentType.NORMAL:
			navigation_agent.radius = 0.5
			navigation_agent.path_max_distance = 50.0
			navigation_agent.avoidance_priority = 0.5
			navigation_agent.max_speed = max_speed
			
		AgentType.CAREFUL:
			navigation_agent.radius = 1.0
			navigation_agent.path_max_distance = 100.0
			navigation_agent.avoidance_priority = 0.8
			navigation_agent.max_speed = max_speed * 0.8
			
		AgentType.AGGRESSIVE:
			navigation_agent.radius = 0.3
			navigation_agent.path_max_distance = 30.0
			navigation_agent.avoidance_priority = 0.2
			navigation_agent.max_speed = max_speed * 1.2

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	if not parent_node:
		return
	
	# 가속도를 적용한 속도 계산
	current_velocity = current_velocity.move_toward(
		safe_velocity,
		acceleration * get_physics_process_delta_time()
	)
	
	# 이동 적용
	parent_node.global_position += current_velocity * get_physics_process_delta_time()
	
	# 회전 처리
	if current_velocity.length_squared() > 0.1:
		var target_rotation = atan2(current_velocity.x, current_velocity.z)
		parent_node.rotation.y = lerp_angle(
			parent_node.rotation.y,
			target_rotation,
			rotation_speed * get_physics_process_delta_time()
		)

func set_avoidance_priority(priority: float) -> void:
	navigation_agent.avoidance_priority = clamp(priority, 0.0, 1.0)

func set_path_update_interval(interval: float) -> void:
	update_path_interval = max(0.1, interval) 
