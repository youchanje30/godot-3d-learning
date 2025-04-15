extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $AgentNavigator/NavigationAgent3D

var movement_speed: float = 5.0
var movement_target_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Make sure to not await during _ready
	call_deferred("actor_setup")

func actor_setup() -> void:
	# Wait for the first physics frame so the NavigationServer can sync
	await get_tree().physics_frame
	
	# Set random initial movement target
	set_movement_target(Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))

func set_movement_target(target_position: Vector3) -> void:
	navigation_agent.target_position = target_position

func _physics_process(delta: float) -> void:
	if navigation_agent.is_navigation_finished():
		# When reached the target, set a new random target
		set_movement_target(Vector3(randf_range(-10, 10), 0, randf_range(-10, 10)))
		return
		
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	
	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed
	
	velocity = new_velocity
	move_and_slide()
	
	# Look in the movement direction
	if velocity.length() > 0.1:
		look_at(global_position + velocity.normalized(), Vector3.UP)

func get_current_navigation_path() -> PackedVector3Array:
	return navigation_agent.get_current_navigation_path() 