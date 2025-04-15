# Navigation/Scripts/Entities/ChargeNavigator.gd
extends BaseNavigator

class_name ChargeNavigator

enum State {
	NORMAL,
	CHARGING,
	STUNNED
}

@export var charge_speed: float = 15.0
@export var charge_duration: float = 2.0
@export var stun_duration: float = 1.0
@export var charge_momentum: float = 0.95

var current_state: State = State.NORMAL
var charge_direction: Vector3
var charge_timer: float = 0.0
var stun_timer: float = 0.0
var original_avoidance_enabled: bool

func _ready() -> void:
	super._ready()
	original_avoidance_enabled = navigation_agent.avoidance_enabled

func _physics_process(delta: float) -> void:
	match current_state:
		State.NORMAL:
			super._physics_process(delta)
		State.CHARGING:
			handle_charge_state(delta)
		State.STUNNED:
			handle_stunned_state(delta)

func start_charge(direction: Vector3) -> void:
	if current_state != State.NORMAL:
		return
	
	current_state = State.CHARGING
	charge_direction = direction.normalized()
	charge_timer = charge_duration
	
	# 돌진 중에는 회피 시스템 비활성화
	navigation_agent.avoidance_enabled = false
	
	# 현재 내비게이션 중지
	stop_navigation()

func handle_charge_state(delta: float) -> void:
	charge_timer -= delta
	
	if charge_timer <= 0:
		enter_stunned_state()
		return
	
	var desired_velocity = charge_direction * charge_speed
	
	# 충돌 체크
	var space_state = parent_node.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = parent_node.global_position
	query.to = parent_node.global_position + desired_velocity * delta
	
	var result = space_state.intersect_ray(query)
	if result:
		handle_charge_collision(result)
		return
	
	# 이동 적용
	parent_node.global_position += desired_velocity * delta
	charge_speed *= charge_momentum

func handle_stunned_state(delta: float) -> void:
	stun_timer -= delta
	
	if stun_timer <= 0:
		exit_stunned_state()

func enter_stunned_state() -> void:
	current_state = State.STUNNED
	stun_timer = stun_duration
	navigation_agent.avoidance_enabled = original_avoidance_enabled

func exit_stunned_state() -> void:
	current_state = State.NORMAL
	navigation_agent.avoidance_enabled = original_avoidance_enabled
	
	# 마지막 목표 지점으로 다시 이동 시작
	if navigation_agent.target_position != parent_node.global_position:
		navigate_to(navigation_agent.target_position)

func handle_charge_collision(result: Dictionary) -> void:
	var collider = result.collider
	
	# 충돌체 처리
	if collider.has_method("take_damage"):
		collider.take_damage(charge_speed * 10)  # 예시 데미지 계산
	
	enter_stunned_state()
